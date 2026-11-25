"""Preselección reproducible de pictogramas aprobados y candidatos externos."""

from concurrent.futures import ThreadPoolExecutor

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


def associate(generated, catalog, arasaac, *, contextual_external=False):
    pictures = [(normalize(item["label"]), item) for item in catalog.list()]
    queries = {}
    matches = {}
    for step in generated.steps:
        key = normalize(step.search_term)
        if key in matches:
            continue
        level, candidates = best_local(key, pictures)
        matches[key] = (level, candidates)
        if key and not candidates:
            queries[key] = " ".join(step.search_term.split())

    def search(term):
        try:
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
        level, candidates = matches[normalize(step.search_term)]
        automatic = level == "arasaac" or len(candidates) == 1
        steps.append({
            **step.model_dump(),
            "association": level if len(candidates) <= 1 or level == "arasaac" else "ambiguous",
            "candidates": candidates,
            "selected": candidates[0] if automatic and candidates else None,
            "approved": False,
        })
    return {"name": generated.name, "steps": steps}
