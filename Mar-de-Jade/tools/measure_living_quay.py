"""Measure atlas frames/strip bounds without modifying any generated pixels."""
import json
from pathlib import Path
from PIL import Image
import numpy as np

def largest_component(mask):
    # Connected row runs keep measurement fast without an extra image-processing dependency.
    parents, runs, previous = [], [], []
    def find(i):
        while parents[i] != i:
            parents[i] = parents[parents[i]]
            i = parents[i]
        return i
    for y, row in enumerate(mask):
        changes = np.diff(np.r_[False, row, False].astype(np.int8))
        current = []
        for start, end in zip(np.where(changes == 1)[0], np.where(changes == -1)[0]):
            index = len(parents); parents.append(index)
            runs.append((y, int(start), int(end)))
            for a, b, old in previous:
                if a < end and b > start:
                    parents[find(old)] = find(index)
            current.append((start, end, index))
        previous = current
    areas = {}
    for i, (_, a, b) in enumerate(runs):
        group = find(i); areas[group] = areas.get(group, 0) + b-a
    main = max(areas, key=areas.get)
    result = np.zeros_like(mask)
    for i, (y, a, b) in enumerate(runs):
        if find(i) == main: result[y, a:b] = True
    return result

root = Path(__file__).resolve().parents[1]
path = root / "assets/art/living-quay/frames.json"
data = json.loads(path.read_text())
data["details"] = {"path": "res://assets/art/living-quay/street-props-v1.png",
                   "frames": [[60, 0, 650, 510], [875, 0, 515, 490], [60, 515, 715, 475], [805, 480, 700, 530]]}
for key in ["buildings", "details"]:
    alpha = np.asarray(Image.open(root / data[key]["path"].removeprefix("res://")).getchannel("A"))
    data[key]["strips"] = []
    for x, y, w, h in data[key]["frames"]:
        body = largest_component(alpha[y:y+h, x:x+w] > 100)
        strips = []
        for column in range(0, w, 12):
            width = min(12, w-column)
            rows = np.where(body[:, column:column+width].any(axis=1))[0]
            if not rows.size:
                continue
            top, bottom = max(0, int(rows.min())-2), min(h, int(rows.max())+3)
            strips.append([column, top, width, bottom-top])
        data[key]["strips"].append(strips)
path.write_text(json.dumps(data, indent=2))
print("Measured building/detail strip bounds; original PNGs preserved.")
