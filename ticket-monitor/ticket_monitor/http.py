"""Polite HTTP client: per-host minimum spacing between requests and a clear User-Agent."""

from __future__ import annotations

import time
from urllib.parse import urlparse

import requests

DEFAULT_USER_AGENT = (
    "Mozilla/5.0 (compatible; personal-ticket-monitor/0.1; read-only availability check)"
)


class HttpClient:
    def __init__(
        self,
        min_host_interval: float = 5.0,
        timeout: float = 20.0,
        user_agent: str = DEFAULT_USER_AGENT,
        session: requests.Session | None = None,
    ) -> None:
        self.min_host_interval = min_host_interval
        self.timeout = timeout
        self.session = session or requests.Session()
        self.session.headers.update(
            {
                "User-Agent": user_agent,
                "Accept-Language": "zh-TW,zh;q=0.9,en;q=0.8",
            }
        )
        self._last_hit: dict[str, float] = {}

    def _throttle(self, url: str) -> None:
        host = urlparse(url).netloc
        last = self._last_hit.get(host)
        if last is not None:
            wait = self.min_host_interval - (time.monotonic() - last)
            if wait > 0:
                time.sleep(wait)
        self._last_hit[host] = time.monotonic()

    def get_text(self, url: str) -> str:
        self._throttle(url)
        resp = self.session.get(url, timeout=self.timeout)
        resp.raise_for_status()
        resp.encoding = resp.encoding or resp.apparent_encoding
        return resp.text

    def get_json(self, url: str):
        self._throttle(url)
        resp = self.session.get(url, timeout=self.timeout, headers={"Accept": "application/json"})
        resp.raise_for_status()
        return resp.json()
