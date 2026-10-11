"""Provider interface and shared text helpers."""

from __future__ import annotations

import re
from typing import Protocol

from ..http import HttpClient
from ..models import Availability, CheckResult, EventRef

SOLD_OUT_MARKERS = ("選購一空", "已售完", "售完", "完售", "sold out", "soldout", "매진")
AVAILABLE_MARKERS = ("立即訂購", "立即購票", "立即購買", "buy now", "book now")
NOT_ON_SALE_MARKERS = ("尚未開賣", "即將開賣", "開賣時間", "販售時間", "售票結束", "已結束", "coming soon")


class Provider(Protocol):
    name: str

    def discover(self, http: HttpClient, keywords: list[str]) -> list[EventRef]:
        """Find events on the site whose title matches any keyword."""

    def check(self, http: HttpClient, event: EventRef, options: dict) -> CheckResult:
        """Return the current availability of every session/area of the event."""


def normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text or "").strip()


def matches_any(text: str, keywords: list[str]) -> bool:
    lowered = normalize(text).lower()
    squashed = lowered.replace(" ", "")
    for kw in keywords:
        k = kw.lower().strip()
        if k and (k in lowered or k.replace(" ", "") in squashed):
            return True
    return False


def classify(text: str) -> Availability:
    """Classify a short status snippet. Sold-out wins over available because rows often contain both words."""
    t = normalize(text).lower()
    if any(m in t for m in SOLD_OUT_MARKERS):
        return Availability.SOLD_OUT
    if any(m in t for m in AVAILABLE_MARKERS):
        return Availability.AVAILABLE
    if any(m in t for m in NOT_ON_SALE_MARKERS):
        return Availability.NOT_ON_SALE
    return Availability.UNKNOWN
