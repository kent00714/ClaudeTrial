import json
import tempfile
import unittest
from pathlib import Path

from ticket_monitor.models import Availability, Listing
from ticket_monitor.monitor import MIN_INTERVAL_SECONDS, Monitor, diff_listing, load_config

FIXTURES = Path(__file__).parent / "fixtures"


class FakeHttp:
    """Serves fixture HTML by URL; tests swap pages between cycles to simulate a release."""

    def __init__(self, pages: dict[str, str]) -> None:
        self.pages = pages
        self.requested: list[str] = []

    def get_text(self, url: str) -> str:
        self.requested.append(url)
        if url not in self.pages:
            raise RuntimeError(f"unexpected url {url}")
        return self.pages[url]

    def get_json(self, url: str):
        return json.loads(self.get_text(url))


class RecordingNotifier:
    def __init__(self) -> None:
        self.sent: list[tuple[str, str, str]] = []

    def send(self, title, body, url=""):
        self.sent.append((title, body, url))


CONFIG = """
[monitor]
interval_seconds = 5
state_file = "state.json"

[[targets]]
name = "金智媛"
keywords = ["金智媛", "WONEDERLAND"]
providers = ["tixcraft"]
"""


def fixture(name: str) -> str:
    return (FIXTURES / name).read_text(encoding="utf-8")


class DiffTests(unittest.TestCase):
    def listing(self, status, remaining=None, detail=""):
        return Listing("tixcraft", "k", "KJW", "u", status, remaining, detail)

    def test_sold_out_to_available_is_release(self):
        change = diff_listing({"status": "sold_out"}, self.listing(Availability.AVAILABLE), baseline=False)
        self.assertEqual(change.kind, "release")

    def test_remaining_increase_is_release(self):
        change = diff_listing({"status": "available", "remaining": 1}, self.listing(Availability.AVAILABLE, 4), False)
        self.assertEqual(change.kind, "release")
        self.assertIn("加釋 3 張", change.message)

    def test_remaining_decrease_is_quiet(self):
        self.assertIsNone(diff_listing({"status": "available", "remaining": 4}, self.listing(Availability.AVAILABLE, 1), False))

    def test_baseline_suppresses_new_listing_alerts(self):
        self.assertIsNone(diff_listing(None, self.listing(Availability.AVAILABLE), baseline=True))
        self.assertEqual(diff_listing(None, self.listing(Availability.AVAILABLE), baseline=False).kind, "release")

    def test_fingerprint_change(self):
        change = diff_listing({"status": "unknown", "detail": "fingerprint=a"},
                              self.listing(Availability.UNKNOWN, detail="fingerprint=b"), False)
        self.assertEqual(change.kind, "page_changed")


class MonitorFlowTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        cfg = Path(self.tmp.name) / "config.toml"
        cfg.write_text(CONFIG, encoding="utf-8")
        self.config = load_config(cfg)
        self.http = FakeHttp({
            "https://tixcraft.com/activity": fixture("tixcraft_activity.html"),
            "https://tixcraft.com/activity/game/26_kimjiwon": fixture("tixcraft_game_soldout.html"),
        })

    def tearDown(self):
        self.tmp.cleanup()

    def test_interval_floor(self):
        self.assertEqual(self.config.interval_seconds, MIN_INTERVAL_SECONDS)

    def test_sold_out_then_release_triggers_one_alert(self):
        notifier = RecordingNotifier()
        Monitor(self.config, notifier, self.http).run_once()
        self.assertEqual(len(notifier.sent), 1)
        self.assertIn("監測已啟動", notifier.sent[0][0])

        # Second process run (fresh Monitor, same state file) — still sold out: no alert.
        notifier = RecordingNotifier()
        Monitor(self.config, notifier, self.http).run_once()
        self.assertEqual(notifier.sent, [])

        # Tickets released.
        self.http.pages["https://tixcraft.com/activity/game/26_kimjiwon"] = fixture("tixcraft_game_available.html")
        changes = Monitor(self.config, notifier, self.http).run_once()
        releases = [c for c in changes if c.kind == "release"]
        self.assertEqual(len(releases), 1)
        self.assertEqual(len(notifier.sent), 1)
        self.assertTrue(notifier.sent[0][0].startswith("釋票"))
        self.assertEqual(notifier.sent[0][2], "https://tixcraft.com/ticket/area/26_kimjiwon/20345")

    def test_known_event_still_checked_when_delisted(self):
        Monitor(self.config, RecordingNotifier(), self.http).run_once()
        self.http.pages["https://tixcraft.com/activity"] = "<html></html>"
        self.http.requested.clear()
        Monitor(self.config, RecordingNotifier(), self.http).run_once()
        self.assertIn("https://tixcraft.com/activity/game/26_kimjiwon", self.http.requested)

    def test_new_event_alert_after_baseline(self):
        empty = FakeHttp({"https://tixcraft.com/activity": "<html></html>"})
        Monitor(self.config, RecordingNotifier(), empty).run_once()
        notifier = RecordingNotifier()
        Monitor(self.config, notifier, self.http).run_once()
        self.assertTrue(any(t.startswith("發現新活動") for t, _, _ in notifier.sent))


if __name__ == "__main__":
    unittest.main()
