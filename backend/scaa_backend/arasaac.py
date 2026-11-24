"""Consulta del catálogo público de ARASAAC en español."""

from urllib.parse import quote
import json

import httpx

MAX_IMAGE_BYTES = 5 * 1024 * 1024
ATTRIBUTION = "Sergio Palao · Gobierno de Aragón · ARASAAC · CC BY-NC-SA"


class ArasaacUnavailable(Exception):
    pass


class ArasaacNotFound(Exception):
    pass


class ArasaacClient:
    def __init__(self, transport: httpx.BaseTransport | None = None):
        self.transport = transport

    def _get(self, url: str, limit: int) -> bytes:
        try:
            with httpx.Client(transport=self.transport, timeout=4.0) as client:
                with client.stream("GET", url) as response:
                    if response.status_code == 404:
                        raise ArasaacNotFound
                    response.raise_for_status()
                    payload = bytearray()
                    for chunk in response.iter_bytes(chunk_size=65536):
                        payload.extend(chunk)
                        if len(payload) > limit:
                            raise ArasaacUnavailable
                    return bytes(payload)
        except httpx.HTTPError as error:
            raise ArasaacUnavailable from error

    def search(self, query: str) -> list[dict]:
        try:
            data = json.loads(self._get(
                f"https://api.arasaac.org/api/pictograms/es/search/{quote(query, safe='')}",
                2 * 1024 * 1024,
            ))
        except ArasaacNotFound:
            return []
        except (ValueError, UnicodeError) as error:
            raise ArasaacUnavailable from error
        if not isinstance(data, list):
            raise ArasaacUnavailable
        results = []
        seen = set()
        for item in data:
            identifier = item.get("_id") if isinstance(item, dict) else None
            if type(identifier) is not int or not 0 < identifier <= 2**63 - 1 or identifier in seen:
                continue
            seen.add(identifier)
            words = item.get("keywords")
            keywords = [
                entry["keyword"].strip() for entry in words
                if isinstance(entry, dict) and isinstance(entry.get("keyword"), str)
                and entry["keyword"].strip() and not any(
                    0xD800 <= ord(char) <= 0xDFFF for char in entry["keyword"]
                )
            ] if isinstance(words, list) else []
            results.append({
                "external_id": identifier,
                "label": (keywords[0] if keywords else f"Pictograma {identifier}")[:100],
                "image_url": f"/api/v1/pictograms/arasaac/{identifier}/image",
                "attribution": ATTRIBUTION,
            })
            if len(results) == 24:
                break
        return results

    def image(self, identifier: int) -> bytes:
        return self._get(
            f"https://static.arasaac.org/pictograms/{identifier}/{identifier}_300.png",
            MAX_IMAGE_BYTES,
        )
