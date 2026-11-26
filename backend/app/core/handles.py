import re
import unicodedata
from typing import Protocol


class HandleSubject(Protocol):
    first_name: str | None
    last_name: str | None


class HandlePolicy(Protocol):
    def generate(self, subject: HandleSubject) -> str: ...

    def validate(self, handle: str) -> bool: ...


class DevelopmentHandlePolicy:
    pattern = re.compile(r"^[a-z][a-z0-9_]{3,31}$")

    @staticmethod
    def _normalize(value: str | None) -> str:
        value = unicodedata.normalize("NFKD", value or "user")
        value = value.encode("ascii", "ignore").decode().lower()
        return re.sub(r"[^a-z0-9]+", "_", value).strip("_") or "user"

    def generate(self, subject: HandleSubject) -> str:
        base = f"{self._normalize(subject.first_name)}_{self._normalize(subject.last_name)}"
        base = base[:32].rstrip("_")
        if len(base) < 4:
            base = (base + "_user")[:4]
        return base

    def validate(self, handle: str) -> bool:
        return bool(self.pattern.fullmatch(handle))


handle_policy: HandlePolicy = DevelopmentHandlePolicy()
