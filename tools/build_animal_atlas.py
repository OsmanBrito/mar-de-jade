"""Rebuild atlas rectangles without rescaling or modifying the authored PNGs."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / "assets/art/forest"
SOURCES = {
    "wolf": ("wolf-poses-v2.png", (0, 512, 1024, 1536)),
    "bear": ("bear-poses-v3.png", (0, 480, 1024, 1536)),
    "deer": ("deer-poses-v2.png", (0, 512, 1024, 1536)),
}

def build():
    entries = {}
    for animal, (filename, columns) in SOURCES.items():
        path = FOLDER / filename
        image = Image.open(path).convert("RGBA")
        if image.size != (1536, 1024):
            raise ValueError(f"{filename}: expected authored 1536x1024 sheet")
        alpha = image.getchannel("A")
        frames = []
        for top, bottom in ((0, 512), (512, 1024)):
            for left, right in zip(columns, columns[1:]):
                region = alpha.crop((left, top, right, bottom))
                box = region.point(lambda value: 255 if value > 48 else 0).getbbox()
                if box is None:
                    raise ValueError(f"{filename}: empty pose")
                x, y, end_x, end_y = box
                if x == 0 or y == 0 or end_x == right-left or end_y == bottom-top:
                    raise ValueError(f"{filename}: pose touches cell boundary; review source layout")
                frames.append([left+x, top+y, end_x-x, end_y-y])
        entries[animal] = {
            "source": "res://" + path.relative_to(ROOT).as_posix(),
            "reference_height": frames[0][3],
            "frames": frames,
            "anchor": "bottom_center",
            "shared_scale": True,
        }
    destination = FOLDER / "animal-poses-v2.json"
    destination.write_text(json.dumps({"schema_version": 1, "entries": entries}, indent=2)+"\n", encoding="utf8")
    print(f"Validated 18 poses; wrote {destination}")

if __name__ == "__main__":
    build()
