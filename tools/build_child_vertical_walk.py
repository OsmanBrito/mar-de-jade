"""Normalize the generated vertical walk with one scale and grounded anchors.

The raw atlas is preserved. No character parts are repainted or independently
rescaled. Each row supplies one half stride; Godot mirrors the complementary
half, so both legs really alternate instead of repeating the same leading foot.
"""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'assets/art/portugal-v2'
SIZE = 96


def build():
    raw = Image.open(ART / 'hero-child-vertical-walk-raw-v1.png').convert('RGBA')
    alpha = raw.getchannel('A')
    occupied = [y for y in range(raw.height)
                if sum(alpha.crop((0, y, raw.width, y + 1)).histogram()[129:]) > 10]
    rows = []
    for y in occupied:
        if not rows or y > rows[-1][1]:
            rows.append([y, y + 1])
        else:
            rows[-1][1] = y + 1
    assert len(rows) == 2, rows
    crops = []
    for top, bottom in rows:
        for column in range(4):
            # First four of eight generated slots form the usable half stride.
            cell = raw.crop((round(column * raw.width / 8), top,
                             round((column + 1) * raw.width / 8), bottom))
            box = cell.getchannel('A').point(lambda a: 255 if a > 8 else 0).getbbox()
            assert box is not None
            crops.append(cell.crop(box))
    scale = SIZE / max(max(c.size) for c in crops)
    atlas = Image.new('RGBA', (4 * SIZE, 2 * SIZE))
    for index, crop in enumerate(crops):
        resized = crop.resize((round(crop.width * scale), round(crop.height * scale)),
                              Image.Resampling.NEAREST)
        atlas.alpha_composite(resized, ((index % 4) * SIZE + (SIZE - resized.width) // 2,
                                       (index // 4) * SIZE + SIZE - resized.height))
    atlas.save(ART / 'hero-child-vertical-walk-v1.png')
    manifest = dict(source='res://assets/art/portugal-v2/hero-child-vertical-walk-v1.png',
                    frame_size=SIZE, reference_height=SIZE, columns=4, rows=2,
                    # Contact, loading, passing, opposite contact; complement
                    # the second half to avoid the raw generator's repeated leg.
                    sequence=[0, 1, 2, 3, 0, 1, 2, 3],
                    mirrored=[False, False, False, False, True, True, True, True],
                    rear_sequence=[0, 3, 1, 2, 0, 3, 1, 2],
                    rear_mirrored=[False, True, True, False, True, False, False, True])
    (ART / 'hero-child-vertical-walk-frames.json').write_text(
        json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print('Built grounded vertical walk: 8 phases per direction, one shared scale')


if __name__ == '__main__':
    build()
