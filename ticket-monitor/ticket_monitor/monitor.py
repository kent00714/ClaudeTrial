"""Monitor loop: discover events, check availability, diff against saved state, alert on releases."""

from __future__ import annotations

import logging
import random
import time
import tomllib
from dataclasses import dataclass, field
from pathlib import Path

from .http import HttpClient
from .models import Availability, Change, EventRef, Listing
from .providers import GenericProvider, KktixProvider, TixcraftProvider
from .state import StateStore

log = logging.getLogger(__name__)

MIN_INTERVAL_SECONDS = 30  # hard floor so a typo in the config can't hammer a ticketing site


@dataclass
class Watch:
    provider: str
    event_id: str
    url: str = ""
    title: str = ""
    options: dict = field(default_factory=dict)


@dataclass
class Target:
    name: str
    keywords: list[str]
    providers: list[str]
    options: dict
    watches: list[Watch]


@dataclass
class Config:
    interval_seconds: int
    jitter_seconds: int
    min_host_interval_seconds: float
    discover_every: int
    state_file: Path
    sites: dict[str, GenericProvider]
    targets: list[Target]


def load_config(path: str | Path) -> Config:
    path = Path(path)
    raw = tomllib.loads(path.read_text(encoding="utf-8"))
    m = raw.get("monitor", {})
    sites = {
        s["name"]: GenericProvider(
            s["name"], s.get("listing_url", ""), s.get("selector"),
            s.get("available_patterns"), s.get("sold_out_patterns"),
        )
        for s in raw.get("sites", [])
    }
    targets = []
    for t in raw.get("targets", []):
        watches = [
            Watch(
                provider=w["provider"],
                event_id=w.get("event_id") or w["url"],
                url=w.get("url", ""),
                title=w.get("title", ""),
                options={k: v for k, v in w.items() if k not in {"provider", "event_id", "url", "title"}},
            )
            for w in t.get("watch", [])
        ]
        targets.append(
            Target(
                name=t["name"],
                keywords=t.get("keywords", []),
                providers=t.get("providers", ["tixcraft", "kktix"]),
                options={"check_areas": t.get("check_areas", False)},
                watches=watches,
            )
        )
    state_file = Path(m.get("state_file", "state.json"))
    if not state_file.is_absolute():
        state_file = path.parent / state_file
    return Config(
        interval_seconds=max(MIN_INTERVAL_SECONDS, int(m.get("interval_seconds", 120))),
        jitter_seconds=max(0, int(m.get("jitter_seconds", 30))),
        min_host_interval_seconds=float(m.get("min_host_interval_seconds", 5)),
        discover_every=max(1, int(m.get("discover_every", 10))),
        state_file=state_file,
        sites=sites,
        targets=targets,
    )


def diff_listing(prev: dict | None, cur: Listing, baseline: bool) -> Change | None:
    """Decide whether a listing's new state is worth an alert."""
    is_avail = cur.status is Availability.AVAILABLE
    if prev is None:
        if baseline or not is_avail:
            return None
        return Change("release", f"新開放可購：{cur.title}", cur.url, listing=cur)

    prev_status = prev.get("status")
    prev_remaining = prev.get("remaining")
    if is_avail and prev_status != Availability.AVAILABLE.value:
        return Change("release", f"釋票！{cur.title}（{prev_status} → 可購買）", cur.url, listing=cur)
    if (
        is_avail
        and isinstance(prev_remaining, int)
        and isinstance(cur.remaining, int)
        and cur.remaining > prev_remaining
    ):
        return Change(
            "release",
            f"加釋 {cur.remaining - prev_remaining} 張：{cur.title}（剩餘 {cur.remaining}）",
            cur.url,
            listing=cur,
        )
    prev_detail = prev.get("detail", "")
    if cur.detail.startswith("fingerprint=") and prev_detail and prev_detail != cur.detail:
        return Change("page_changed", f"頁面內容有變動：{cur.title}", cur.url, listing=cur)
    if prev_status != cur.status.value:
        return Change("status_changed", f"{cur.title}：{prev_status} → {cur.status.value}", cur.url, listing=cur)
    return None


class Monitor:
    NOTIFY_KINDS = {"release", "new_event", "page_changed"}

    def __init__(self, config: Config, notifier, http: HttpClient | None = None) -> None:
        self.config = config
        self.notifier = notifier
        self.http = http or HttpClient(min_host_interval=config.min_host_interval_seconds)
        self.state = StateStore(config.state_file)
        self.providers = {"tixcraft": TixcraftProvider(), "kktix": KktixProvider(), **config.sites}
        self.cycle = 0

    def _provider(self, name: str):
        return self.providers.get(name) or GenericProvider(name)

    def _events_for(self, target: Target, discover: bool) -> tuple[list[tuple[EventRef, dict]], list[str]]:
        events: dict[str, tuple[EventRef, dict]] = {}
        errors: list[str] = []

        if discover:
            for name in target.providers:
                try:
                    for ev in self._provider(name).discover(self.http, target.keywords):
                        events[f"{ev.provider}:{ev.event_id}"] = (ev, target.options)
                except Exception as exc:
                    errors.append(f"discover {name}: {exc}")

        # Events seen before keep being checked even if the listing page drops them.
        for key, saved in self.state.events.items():
            if saved.get("target") == target.name and key not in events:
                ev = EventRef(saved["provider"], saved["event_id"], saved["title"], saved["url"])
                events[key] = (ev, target.options)

        for w in target.watches:
            url = w.url or (f"https://tixcraft.com/activity/detail/{w.event_id}" if w.provider == "tixcraft" else "")
            ev = EventRef(w.provider, w.event_id, w.title or target.name, url)
            events[f"{w.provider}:{w.event_id}"] = (ev, {**target.options, **w.options})
        return list(events.values()), errors

    def run_once(self) -> list[Change]:
        discover = self.cycle % self.config.discover_every == 0
        self.cycle += 1
        baseline = self.state.is_new
        changes: list[Change] = []
        available_now: list[Listing] = []

        for target in self.config.targets:
            events, errors = self._events_for(target, discover)
            for ev, options in events:
                ekey = f"{ev.provider}:{ev.event_id}"
                if ekey not in self.state.events:
                    if not baseline:
                        changes.append(Change("new_event", f"發現新活動：{ev.title}（{ev.provider}）", ev.url, event=ev))
                    self.state.events[ekey] = {
                        "provider": ev.provider, "event_id": ev.event_id,
                        "title": ev.title, "url": ev.url, "target": target.name,
                    }
                try:
                    result = self._provider(ev.provider).check(self.http, ev, options)
                except Exception as exc:
                    errors.append(f"check {ekey}: {exc}")
                    continue
                errors.extend(result.errors)
                for listing in result.listings:
                    lkey = f"{listing.provider}:{listing.key}"
                    change = diff_listing(self.state.listings.get(lkey), listing, baseline)
                    if change:
                        changes.append(change)
                    if listing.status is Availability.AVAILABLE:
                        available_now.append(listing)
                    self.state.listings[lkey] = {
                        "status": listing.status.value, "remaining": listing.remaining,
                        "detail": listing.detail, "title": listing.title, "url": listing.url,
                    }
            for err in errors:
                log.warning("[%s] %s", target.name, err)

        for c in changes:
            if c.kind in self.NOTIFY_KINDS:
                self.notifier.send(c.message, _body(c), c.url)
            else:
                log.info(c.message)

        if baseline:
            lines = [f"• {l.title}" + (f"（剩餘 {l.remaining}）" if l.remaining is not None else "") for l in available_now]
            body = "\n".join(lines) if lines else "目前沒有可購買的場次，有釋票會通知你。"
            self.notifier.send(f"票務監測已啟動：{len(self.state.listings)} 個項目", body)

        self.state.save()
        return changes

    def run_forever(self) -> None:
        while True:
            try:
                self.run_once()
            except Exception:
                log.exception("cycle failed")
            delay = self.config.interval_seconds + random.uniform(0, self.config.jitter_seconds)
            log.info("next check in %.0fs", delay)
            time.sleep(delay)


def _body(change: Change) -> str:
    if change.listing:
        l = change.listing
        parts = [f"狀態：{l.status.value}"]
        if l.remaining is not None:
            parts.append(f"剩餘：{l.remaining}")
        if l.detail and not l.detail.startswith("fingerprint="):
            parts.append(l.detail)
        return "｜".join(parts)
    if change.event:
        return f"平台：{change.event.provider}"
    return ""
