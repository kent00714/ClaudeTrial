"""Alert channels. Secrets come only from environment variables, never from the config file."""

from __future__ import annotations

import logging
import os

import requests

log = logging.getLogger(__name__)


class ConsoleNotifier:
    def send(self, title: str, body: str, url: str = "") -> None:
        print(f"\n🔔 {title}\n{body}\n{url}".rstrip(), flush=True)


class TelegramNotifier:
    def __init__(self, token: str, chat_id: str) -> None:
        self.token, self.chat_id = token, chat_id

    def send(self, title: str, body: str, url: str = "") -> None:
        requests.post(
            f"https://api.telegram.org/bot{self.token}/sendMessage",
            json={"chat_id": self.chat_id, "text": f"🔔 {title}\n{body}\n{url}".strip()},
            timeout=15,
        ).raise_for_status()


class DiscordNotifier:
    def __init__(self, webhook_url: str) -> None:
        self.webhook_url = webhook_url

    def send(self, title: str, body: str, url: str = "") -> None:
        requests.post(
            self.webhook_url,
            json={"content": f"🔔 **{title}**\n{body}\n{url}".strip()[:2000]},
            timeout=15,
        ).raise_for_status()


class NtfyNotifier:
    """https://ntfy.sh — free push notifications to the ntfy phone app, no account needed."""

    def __init__(self, topic: str, server: str = "https://ntfy.sh") -> None:
        self.topic, self.server = topic, server.rstrip("/")

    def send(self, title: str, body: str, url: str = "") -> None:
        # JSON publishing keeps non-ASCII titles intact (HTTP headers would not).
        payload = {"topic": self.topic, "title": title, "message": body, "priority": 5, "tags": ["ticket"]}
        if url:
            payload["click"] = url
        requests.post(self.server, json=payload, timeout=15).raise_for_status()


class MultiNotifier:
    def __init__(self, notifiers: list) -> None:
        self.notifiers = notifiers

    def send(self, title: str, body: str, url: str = "") -> None:
        for n in self.notifiers:
            try:
                n.send(title, body, url)
            except Exception as exc:
                log.warning("notifier %s failed: %s", type(n).__name__, exc)


def from_env(env: dict | None = None) -> MultiNotifier:
    env = os.environ if env is None else env
    notifiers: list = [ConsoleNotifier()]
    if env.get("TELEGRAM_BOT_TOKEN") and env.get("TELEGRAM_CHAT_ID"):
        notifiers.append(TelegramNotifier(env["TELEGRAM_BOT_TOKEN"], env["TELEGRAM_CHAT_ID"]))
    if env.get("DISCORD_WEBHOOK_URL"):
        notifiers.append(DiscordNotifier(env["DISCORD_WEBHOOK_URL"]))
    if env.get("NTFY_TOPIC"):
        notifiers.append(NtfyNotifier(env["NTFY_TOPIC"], env.get("NTFY_SERVER", "https://ntfy.sh")))
    return MultiNotifier(notifiers)
