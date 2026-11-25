"""Preselección reproducible de pictogramas aprobados y candidatos externos."""

from concurrent.futures import ThreadPoolExecutor
import re

from .arasaac import ArasaacUnavailable
from .routine_generation import keywords, normalize


def best_local(term: str, pictures: list[tuple[str, dict]]) -> tuple[str, list[dict]]:
    if term:
        for level, matches in (
            ("exact", lambda label: label == term),
            ("prefix", lambda label: label.startswith(term)),
            ("contains", lambda label: term in label),
        ):
            candidates = [item for label, item in pictures if matches(label)]
            if candidates:
                return level, candidates
    return "unmatched", []


def contextual_candidates(term: str, results: list[dict]) -> list[dict]:
    required = keywords(term)
    if len(required) < 2:
        return []

    matches = [
        item for item in results
        if any(required == keywords(alias) for alias in [item["label"], *item.get("keywords", [])])
    ]
    return [
        {key: value for key, value in item.items() if key != "keywords"}
        for item in matches[:8]
    ]


def label_signature(expression: str) -> tuple[str, ...]:
    articles = {"el", "la", "los", "las", "un", "una", "unos", "unas"}
    contractions = {"al": "a", "del": "de"}
    return tuple(
        contractions.get(word, word)
        for word in re.findall(r"[^\W\d_]+", normalize(expression))
        if word not in articles
    )


def label_candidates(term: str, results: list[dict]) -> list[dict]:
    if not results:
        return []
    first, *alternatives = results
    signature = label_signature(term)
    matches = [first] if first["label"] == term else []
    for item in alternatives:
        aliases = [item["label"], *item.get("keywords", [])]
        if any(alias == term or (signature and label_signature(alias) == signature) for alias in aliases):
            matches.append(item)
    return [
        {key: value for key, value in item.items() if key != "keywords"}
        for item in matches[:8]
    ]


def associate(generated, catalog, arasaac, *, contextual_external=False, exact_label_lookup=False):
    def lookup_key(step):
        return step.label if exact_label_lookup else normalize(step.search_term)

    pictures = [(normalize(item["label"]), item) for item in catalog.list()]
    queries = {}
    matches = {}
    for step in generated.steps:
        key = lookup_key(step)
        if key in matches:
            continue
        level, candidates = best_local(normalize(key) if exact_label_lookup else key, pictures)
        matches[key] = (level, candidates)
        if key and not candidates:
            queries[key] = key if exact_label_lookup else " ".join(step.search_term.split())

    def search(term):
        try:
            if exact_label_lookup:
                return "arasaac", label_candidates(term, arasaac.search(term, include_keywords=True))
            if contextual_external:
                return "arasaac", contextual_candidates(term, arasaac.search(term, include_keywords=True))
            return "arasaac", arasaac.search(term)[:8]
        except ArasaacUnavailable:
            return "unavailable", []

    if queries:
        with ThreadPoolExecutor(max_workers=min(3, len(queries))) as pool:
            matches.update(zip(queries, pool.map(search, queries.values()), strict=True))

    steps = []
    for step in generated.steps:
        level, candidates = matches[lookup_key(step)]
        automatic = level == "arasaac" or len(candidates) == 1
        steps.append({
            **step.model_dump(),
            "association": level if len(candidates) <= 1 or level == "arasaac" else "ambiguous",
            "candidates": candidates,
            "selected": candidates[0] if automatic and candidates else None,
            "approved": False,
        })
    return {"name": generated.name, "steps": steps}
