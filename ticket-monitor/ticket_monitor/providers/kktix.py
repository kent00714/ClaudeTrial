"""KKTIX (https://kktix.com).

Discovery uses the public event search page. Availability uses the JSON the
event's own registration page loads (/g/events/{slug}/register_info); its
shape is parsed defensively and falls back to scanning the event page text.
"""

from __future__ import annotations

import re
from urllib.parse import quote

from bs4 import BeautifulSoup

from ..http import HttpClient
from ..models import Availability, CheckResult, EventRef, Listing
from .base import classify, matches_any, normalize

SEARCH_URL = "https://kktix.com/events?search={q}"
REGISTER_INFO_URL = "https://kktix.com/g/events/{slug}/register_info"
_EVENT_RE = re.compile(r"(https://[a-z0-9\-]+\.kktix\.cc/events/([A-Za-z0-9_\-]+))")


def parse_search(html: str, keywords: list[str]) -> list[EventRef]:
    soup = BeautifulSoup(html, "html.parser")
    found: dict[str, EventRef] = {}
    for a in soup.find_all("a", href=True):
        m = _EVENT_RE.search(a["href"])
        if not m:
            continue
        url, slug = m.group(1), m.group(2)
        card = a.find_parent(["li", "div"]) or a
        text = normalize(a.get_text(" ") + " " + card.get_text(" "))
        if matches_any(text, keywords) and slug not in found:
            title = normalize(a.get_text(" ")) or slug
            found[slug] = EventRef("kktix", slug, title, url)
    return list(found.values())


def parse_register_info(data: dict, event: EventRef) -> list[Listing]:
    inventory = (data or {}).get("inventory") or {}
    ticket_inventory = inventory.get("ticketInventory") or {}
    listings = []
    for ticket in (data or {}).get("tickets") or []:
        ticket_id = str(ticket.get("id"))
        name = normalize(str(ticket.get("name", ticket_id)))
        remaining = ticket_inventory.get(ticket_id)
        if remaining is None:
            remaining = ticket_inventory.get(ticket.get("id"))
        if isinstance(remaining, int):
            status = Availability.AVAILABLE if remaining > 0 else Availability.SOLD_OUT
        else:
            status = classify(str(ticket.get("status", "")))
        listings.append(
            Listing(
                provider="kktix",
                key=f"{event.event_id}:{ticket_id}",
                title=f"{event.title} {name}",
                url=event.url,
                status=status,
                remaining=remaining if isinstance(remaining, int) else None,
            )
        )
    return listings


class KktixProvider:
    name = "kktix"

    def discover(self, http: HttpClient, keywords: list[str]) -> list[EventRef]:
        found: dict[str, EventRef] = {}
        for kw in keywords:
            for ev in parse_search(http.get_text(SEARCH_URL.format(q=quote(kw))), keywords):
                found.setdefault(ev.event_id, ev)
        return list(found.values())

    def check(self, http: HttpClient, event: EventRef, options: dict) -> CheckResult:
        result = CheckResult()
        try:
            data = http.get_json(REGISTER_INFO_URL.format(slug=event.event_id))
            result.listings = parse_register_info(data, event)
        except Exception as exc:
            result.errors.append(f"kktix register_info {event.event_id}: {exc}")

        if not result.listings:
            # Fallback: whole-page status from the public event page.
            text = BeautifulSoup(http.get_text(event.url), "html.parser").get_text(" ")
            result.listings.append(
                Listing("kktix", f"{event.event_id}:page", event.title, event.url, classify(text))
            )
        return result
