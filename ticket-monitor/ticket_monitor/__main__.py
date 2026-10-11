"""CLI: python -m ticket_monitor [--config config.toml] [--once | --discover-only]"""

from __future__ import annotations

import argparse
import logging
import sys

from . import notifiers
from .http import HttpClient
from .monitor import Monitor, load_config


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="ticket_monitor", description="監測售票網站釋票")
    parser.add_argument("--config", default="config.toml")
    parser.add_argument("--once", action="store_true", help="check once and exit (for cron / CI)")
    parser.add_argument("--discover-only", action="store_true", help="only list matching events on each site")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args(argv)

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )
    config = load_config(args.config)

    if args.discover_only:
        monitor = Monitor(config, notifiers.ConsoleNotifier(), HttpClient(config.min_host_interval_seconds))
        for target in config.targets:
            print(f"== {target.name}")
            for name in target.providers:
                try:
                    found = monitor._provider(name).discover(monitor.http, target.keywords)
                except Exception as exc:
                    print(f"  [{name}] 錯誤：{exc}")
                    continue
                print(f"  [{name}] 找到 {len(found)} 筆")
                for ev in found:
                    print(f"    - {ev.title}  {ev.url}")
        return 0

    monitor = Monitor(config, notifiers.from_env())
    if args.once:
        monitor.run_once()
    else:
        monitor.run_forever()
    return 0


if __name__ == "__main__":
    sys.exit(main())
