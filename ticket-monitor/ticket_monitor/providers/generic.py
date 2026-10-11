"""Generic page watcher for sites without a dedicated parser (ibon, 年代, 遠大, OPENTIX, udn, FamiTicket...).

Two jobs:
  * discovery: fetch a listing page and report links whose text matches a keyword
  * check: classify a page by configurable sold-out / available phrases and
    fingerprint its text so any change (e.g. a new 釋票 notice) is reported
"""

from __future__ import annotations

import hashlib
from urllib.parse import urljoin

from bs4 import BeautifulSoup

from ..http import HttpClient
from ..models import Availability, CheckResult, EventRef, Listing
from .base import classify, matches_any, normalize


def page_text(html: str, selector: str | None = None) -> str:
    soup = BeautifulSoup(html, "html.parser")
    for tag in soup(["script", "style", "noscript"]):
        tag.decompose()
    nodes = soup.select(selector) if selector else [soup]
    return normalize(" ".join(n.get_text(" ") for n in nodes))


def fingerprint(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


def parse_links(html: str, base_url: str, keywords: list[str], provider: str) -> list[EventRef]:
    soup = BeautifulSoup(html, "html.parser")
    found: dict[str, EventRef] = {}
    for a in soup.find_all("a", href=True):
        text = normalize(" ".join([a.get_text(" "), a.get("title", "")] + [i.get("alt", "") for i in a.find_all("img")]))
        if text and matches_any(text, keywords):
            url = urljoin(base_url, a["href"])
            found.setdefault(url, EventRef(provider, url, text[:120], url))
    return list(found.values())


def classify_with(text: str, available: list[str], sold_out: list[str]) -> Availability:
    lowered = text.lower()
    if sold_out and any(p.lower() in lowered for p in sold_out):
        return Availability.SOLD_OUT
    if available and any(p.lower() in lowered for p in available):
        return Availability.AVAILABLE
    return classify(text) if not (available or sold_out) else Availability.UNKNOWN


class GenericProvider:
    """Instantiated per configured site: name, listing_url and optional patterns."""

    def __init__(self, name: str, listing_url: str = "", selector: str | None = None,
                 available_patterns: list[str] | None = None,
                 sold_out_patterns: list[str] | None = None) -> None:
        self.name = name
        self.listing_url = listing_url
        self.selector = selector
        self.available_patterns = available_patterns or []
        self.sold_out_patterns = sold_out_patterns or []

    def discover(self, http: HttpClient, keywords: list[str]) -> list[EventRef]:
        if not self.listing_url:
            return []
        return parse_links(http.get_text(self.listing_url), self.listing_url, keywords, self.name)

    def check(self, http: HttpClient, event: EventRef, options: dict) -> CheckResult:
        text = page_text(http.get_text(event.url), options.get("selector") or self.selector)
        status = classify_with(
            text,
            options.get("available_patterns") or self.available_patterns,
            options.get("sold_out_patterns") or self.sold_out_patterns,
        )
        # Fingerprinting is opt-in: many pages carry rotating banners that would alert every cycle.
        detail = f"fingerprint={fingerprint(text)}" if options.get("notify_on_change") else ""
        return CheckResult(
            listings=[Listing(self.name, f"{event.event_id}:page", event.title, event.url, status, detail=detail)]
        )
