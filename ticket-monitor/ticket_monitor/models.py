"""Core data types shared by providers, the monitor loop and notifiers."""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum


class Availability(str, Enum):
    AVAILABLE = "available"        # tickets can be bought right now
    SOLD_OUT = "sold_out"          # 選購一空 / 已售完
    NOT_ON_SALE = "not_on_sale"    # sale not started yet / sale ended
    UNKNOWN = "unknown"            # page could not be classified


@dataclass(frozen=True)
class EventRef:
    """An event found on a ticketing site (result of keyword discovery)."""

    provider: str
    event_id: str
    title: str
    url: str


@dataclass(frozen=True)
class Listing:
    """One purchasable unit on a site: a session (場次) or a seat area (區域)."""

    provider: str
    key: str                 # stable id, unique within the provider
    title: str
    url: str
    status: Availability
    remaining: int | None = None   # seats left, when the site exposes it
    detail: str = ""


@dataclass(frozen=True)
class Change:
    kind: str                # "release" | "new_event" | "page_changed" | "status_changed"
    message: str
    url: str
    listing: Listing | None = None
    event: EventRef | None = None


@dataclass
class CheckResult:
    listings: list[Listing] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)
