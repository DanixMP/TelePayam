from pathlib import Path
from uuid import NAMESPACE_URL, uuid5

ASSET_DIR = Path(__file__).with_name("assets")


def asset_id(name: str):
    return uuid5(NAMESPACE_URL, f"university-messenger:campus-notes:v1:{name}")


PACK_ID = asset_id("pack")
STICKER_ART = {"plane.png": "✈️", "book.png": "📖", "done.png": "✅", "star.png": "⭐"}
GIF_ART = ("flight.gif", "sparkle.gif")
FEATURED_GIFS = tuple(asset_id(name) for name in GIF_ART)
BUNDLED_FILES = {asset_id(name): ASSET_DIR / name for name in (*STICKER_ART, *GIF_ART)}
