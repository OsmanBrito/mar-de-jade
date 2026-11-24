"""Validate the saved Blender artifact, including the actual disarm state."""
import bpy
import json
from pathlib import Path

root = Path(__file__).resolve().parents[2]
scene = bpy.context.scene
checks = 0


def check(condition, message):
    global checks
    assert condition, message
    checks += 1


check(scene.render.fps == 24, "24 fps")
check(scene.frame_start == 1 and scene.frame_end == 384, "16-second range")
check((scene.render.resolution_x, scene.render.resolution_y) == (1280, 720), "HD frame")
check(scene.camera is not None, "Active camera")
check(len(scene.timeline_markers) == 12, "Named choreography beats")
check(all(image.packed_file for image in bpy.data.images if image.source == "FILE"), "All original images packed")
weapon = bpy.data.objects["Mestre / instrumento na mão"]
drop = bpy.data.objects["Instrumento desarmado / queda e ressalto"]
leonor = bpy.data.objects["Leonor / instrumento na mão"]
art = json.loads((root / "assets/art/combat/portugal/frames.json").read_text(encoding="utf8"))["entries"]["leonor"]
for frame, released in [(115, False), (240, False), (241, True), (274, True), (384, True)]:
    scene.frame_set(frame)
    check(all(obj.hide_render == released for obj in weapon.children_recursive), f"Held weapon state at {frame}")
    check(all(obj.hide_render != released for obj in drop.children_recursive), f"Dropped weapon state at {frame}")
    check(not any(obj.hide_render for obj in leonor.children_recursive), f"Leonor remains armed at {frame}")
    visible = [obj for obj in bpy.data.objects if obj.name.startswith("Leonor / 0") and not obj.hide_render]
    check(len(visible) == 1, f"Exactly one Leonor pose at {frame}")
scene.frame_set(384)
check(abs(drop.location.z - .045) < .001, "Weapon settles on paving")
check((bpy.data.objects["LEONOR / movimento principal"].location - bpy.data.objects["MESTRE / Grande Guerreiro"].location).length > 1.5, "Separate final feet")
timeline = json.loads((root / "art-source/blender/leonor-praca/timeline.json").read_text(encoding="utf8"))
check([item["frame"] for item in timeline["beats"]] == sorted(item["frame"] for item in timeline["beats"]), "Chronological exported beats")
for frame in range(1, 385):
    scene.frame_set(frame)
    visible = [obj for obj in bpy.data.objects if obj.name.startswith("Leonor / 0") and not obj.hide_render]
    pose = int(visible[0].name.split(" / ")[1].split(" ")[0])
    px, py = art["pivots"][pose]
    gx, gy = art["grips"][pose]
    factor = 1.82 / art["reference_height"]
    check(abs(leonor.location.x + (gx - px) * factor) < .0001 and abs(leonor.location.y - (py - gy) * factor) < .0001, f"Hilt stays in painted hand at {frame}")
print("LEONOR_BLENDER_VALIDATED", checks, flush=True)
