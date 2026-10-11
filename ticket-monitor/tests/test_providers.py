import unittest
from pathlib import Path

from ticket_monitor.models import Availability, EventRef, Listing
from ticket_monitor.providers import base, generic, kktix, tixcraft

FIXTURES = Path(__file__).parent / "fixtures"
KEYWORDS = ["金智媛", "KIM JI WON", "김지원", "WONEDERLAND"]
KJW = EventRef("tixcraft", "26_kimjiwon", "金智媛 WONEDERLAND", "https://tixcraft.com/activity/detail/26_kimjiwon")


def fixture(name: str) -> str:
    return (FIXTURES / name).read_text(encoding="utf-8")


class BaseHelpersTests(unittest.TestCase):
    def test_matches_any_ignores_case_and_spaces(self):
        self.assertTrue(base.matches_any("2026 Kim Ji Won Fanmeeting", ["KIMJIWON"]))
        self.assertTrue(base.matches_any("金智媛 見面會", ["金智媛"]))
        self.assertFalse(base.matches_any("Other Band", KEYWORDS))

    def test_classify_prefers_sold_out(self):
        self.assertEqual(base.classify("立即訂購 / 選購一空"), Availability.SOLD_OUT)
        self.assertEqual(base.classify("立即訂購"), Availability.AVAILABLE)
        self.assertEqual(base.classify("販售時間 2026/09/27 13:00"), Availability.NOT_ON_SALE)
        self.assertEqual(base.classify("購買須知"), Availability.UNKNOWN)


class TixcraftParserTests(unittest.TestCase):
    def test_discovers_only_matching_events(self):
        events = tixcraft.parse_activity_list(fixture("tixcraft_activity.html"), KEYWORDS)
        self.assertEqual([e.event_id for e in events], ["26_kimjiwon"])
        self.assertEqual(events[0].url, "https://tixcraft.com/activity/detail/26_kimjiwon")
        self.assertIn("WONEDERLAND", events[0].title)

    def test_sold_out_session(self):
        [session] = tixcraft.parse_game_list(fixture("tixcraft_game_soldout.html"), KJW)
        self.assertEqual(session.status, Availability.SOLD_OUT)
        self.assertIn("2026/11/08", session.title)

    def test_available_session_links_to_area_page(self):
        [session] = tixcraft.parse_game_list(fixture("tixcraft_game_available.html"), KJW)
        self.assertEqual(session.status, Availability.AVAILABLE)
        self.assertEqual(session.url, "https://tixcraft.com/ticket/area/26_kimjiwon/20345")
        self.assertEqual(session.key, "26_kimjiwon:2026/11/08 (日) 18:00")

    def test_area_remaining_counts(self):
        session = Listing("tixcraft", "26_kimjiwon:20345", "KJW", "u", Availability.AVAILABLE)
        areas = {a.key.split(":")[-1]: a for a in tixcraft.parse_area_list(fixture("tixcraft_area.html"), session)}
        self.assertEqual(areas["特A區 5800"].remaining, 2)
        self.assertEqual(areas["特A區 5800"].status, Availability.AVAILABLE)
        self.assertEqual(areas["A區 4980"].status, Availability.SOLD_OUT)
        self.assertEqual(areas["A區 4980"].remaining, 0)
        self.assertIsNone(areas["B區 4980"].remaining)


class KktixParserTests(unittest.TestCase):
    def test_search(self):
        [ev] = kktix.parse_search(fixture("kktix_search.html"), KEYWORDS)
        self.assertEqual(ev.event_id, "kjw-wonederland-tpe")

    def test_register_info_inventory(self):
        ev = EventRef("kktix", "slug", "KJW", "https://x.kktix.cc/events/slug")
        data = {
            "tickets": [{"id": 1, "name": "VIP"}, {"id": 2, "name": "一般"}],
            "inventory": {"ticketInventory": {"1": 0, "2": 5}},
        }
        listings = {l.key: l for l in kktix.parse_register_info(data, ev)}
        self.assertEqual(listings["slug:1"].status, Availability.SOLD_OUT)
        self.assertEqual(listings["slug:2"].remaining, 5)

    def test_register_info_tolerates_unknown_shape(self):
        self.assertEqual(kktix.parse_register_info({"unexpected": True}, KJW), [])


class GenericTests(unittest.TestCase):
    def test_links_and_patterns(self):
        html = '<a href="/e/1">金智媛 見面會</a><a href="/e/2">別的活動</a><script>金智媛</script>'
        [ev] = generic.parse_links(html, "https://ticket.example.com/", KEYWORDS, "ibon")
        self.assertEqual(ev.url, "https://ticket.example.com/e/1")
        text = generic.page_text("<main>A區 已售完</main><script>立即購買</script>")
        self.assertEqual(generic.classify_with(text, ["立即購買"], ["已售完"]), Availability.SOLD_OUT)


if __name__ == "__main__":
    unittest.main()
