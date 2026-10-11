"""JSON-file state so releases are detected across runs (including cron/CI runs)."""

from __future__ import annotations

import json
import os
import tempfile
from pathlib import Path


class StateStore:
    def __init__(self, path: str | Path) -> None:
        self.path = Path(path)
        self.data: dict = {"events": {}, "listings": {}}
        self.is_new = True
        if self.path.exists():
            try:
                self.data = json.loads(self.path.read_text(encoding="utf-8"))
                self.data.setdefault("events", {})
                self.data.setdefault("listings", {})
                self.is_new = False
            except (OSError, json.JSONDecodeError):
                pass

    @property
    def events(self) -> dict:
        return self.data["events"]

    @property
    def listings(self) -> dict:
        return self.data["listings"]

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        fd, tmp = tempfile.mkstemp(dir=self.path.parent, prefix=".state-")
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump(self.data, fh, ensure_ascii=False, indent=2, sort_keys=True)
        os.replace(tmp, self.path)
        self.is_new = False
