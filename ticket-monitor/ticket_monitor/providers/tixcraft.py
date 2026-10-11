"""拓元售票 tixCraft (https://tixcraft.com).

Public, login-free pages used:
  /activity                     event listing  -> discovery
  /activity/game/{event_id}     session list   -> per-session status (立即訂購 / 選購一空)
  /ticket/area/{event}/{game}   area list      -> per-area remaining seats (optional, may require login)
"""

from __future__ import annotations

import re
from urllib.parse import urljoin

from bs4 import BeautifulSoup

from ..http import HttpClient
from ..models import Availability, CheckResult, EventRef, Listing
from .base import classify, matches_any, normalize

BASE = "https://tixcraft.com"
_DETAIL_RE = re.compile(r"/activity/(?:detail|game)/([A-Za-z0-9_\-]+)")
_REMAINING_RE = re.compile(r"剩餘\s*(\d+)")


def parse_activity_list(html: str, keywords: list[str]) -> list[EventRef]:
    soup = BeautifulSoup(html, "html.parser")
    texts: dict[str, list[str]] = {}
    for a in soup.find_all("a", href=True):
        m = _DETAIL_RE.search(a["href"])
        if not m:
            continue
        event_id = m.group(1)
        # Titles usually sit next to the link (card layout), so include the
        # enclosing card's text and any image alt text.
        parts = [a.get_text(" "), a.get("title", "")]
        parts += [img.get("alt", "") for img in a.find_all("img")]
        card = a.find_parent(["div", "li"])
        if card is not None:
            parts.append(card.get_text(" "))
        texts.setdefault(event_id, []).extend(p for p in parts if p)

    events = []
    for event_id, parts in texts.items():
        blob = normalize(" ".join(parts))
        if matches_any(blob, keywords):
            title = _best_title(parts) or event_id
            events.append(
                EventRef("tixcraft", event_id, title, f"{BASE}/activity/detail/{event_id}")
            )
    return events


def _best_title(parts: list[str]) -> str:
    candidates = [normalize(p) for p in parts if 4 <= len(normalize(p)) <= 120]
    return max(candidates, key=len) if candidates else ""


def parse_game_list(html: str, event: EventRef) -> list[Listing]:
    soup = BeautifulSoup(html, "html.parser")
    table = soup.find(id="gameList") or soup
    listings = []
    for row in table.find_all("tr"):
        cells = row.find_all("td")
        if not cells:
            continue
        row_text = normalize(row.get_text(" "))
        when = normalize(cells[0].get_text(" "))
        name = normalize(cells[1].get_text(" ")) if len(cells) > 1 else ""
        status_text = normalize(cells[-1].get_text(" "))
        status = classify(status_text)
        if status is Availability.UNKNOWN:
            status = classify(row_text)

        # Key on the show time: sold-out rows have no buy link (and so no game id),
        # and the key must stay the same when the row flips to 立即訂購.
        buy_url = _find_area_url(row)
        listings.append(
            Listing(
                provider="tixcraft",
                key=f"{event.event_id}:{when}",
                title=normalize(f"{event.title} {when} {name}"),
                url=buy_url or f"{BASE}/activity/game/{event.event_id}",
                status=status,
                detail=status_text,
            )
        )
    return listings


def _find_area_url(row) -> str:
    for tag in row.find_all(True):
        for attr in ("data-href", "href", "onclick"):
            value = tag.get(attr)
            if value and "/ticket/area/" in value:
                m = re.search(r"(https?://[^'\"\s]+|/ticket/area/[^'\"\s]+)", value)
                if m:
                    return urljoin(BASE, m.group(1))
    return ""


def parse_area_list(html: str, session: Listing) -> list[Listing]:
    soup = BeautifulSoup(html, "html.parser")
    containers = soup.select(".area-list") or [soup]
    listings = []
    for container in containers:
        for li in container.find_all("li"):
            text = normalize(li.get_text(" "))
            if not text:
                continue
            m = _REMAINING_RE.search(text)
            if m:
                remaining = int(m.group(1))
                status = Availability.AVAILABLE if remaining > 0 else Availability.SOLD_OUT
            elif "已售完" in text:
                remaining, status = 0, Availability.SOLD_OUT
            elif "熱賣中" in text:
                remaining, status = None, Availability.AVAILABLE
            else:
                continue
            area_name = normalize(_REMAINING_RE.sub("", text).replace("已售完", "").replace("熱賣中", ""))
            listings.append(
                Listing(
                    provider="tixcraft",
                    key=f"{session.key}:{area_name}",
                    title=f"{session.title} {area_name}",
                    url=session.url,
                    status=status,
                    remaining=remaining,
                    detail=text,
                )
            )
    return listings


class TixcraftProvider:
    name = "tixcraft"

    def discover(self, http: HttpClient, keywords: list[str]) -> list[EventRef]:
        return parse_activity_list(http.get_text(f"{BASE}/activity"), keywords)

    def check(self, http: HttpClient, event: EventRef, options: dict) -> CheckResult:
        result = CheckResult()
        sessions = parse_game_list(http.get_text(f"{BASE}/activity/game/{event.event_id}"), event)
        if not sessions:
            result.errors.append(f"tixcraft {event.event_id}: no sessions parsed (page layout changed?)")
        result.listings.extend(sessions)

        if options.get("check_areas"):
            for session in sessions:
                if "/ticket/area/" not in session.url:
                    continue
                try:
                    result.listings.extend(parse_area_list(http.get_text(session.url), session))
                except Exception as exc:  # area pages may redirect to login
                    result.errors.append(f"tixcraft area {session.url}: {exc}")
        return result
