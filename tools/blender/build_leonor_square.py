"""Author the public Leonor duel and its animated square in Blender.

Run with Blender --background --python tools/blender/build_leonor_square.py.
The original illustrated characters are kept as editable cutouts in a 3D set.
No external model, generator, add-on, or paid service is required.
"""
import bpy
import json
import math
import random
import sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "art-source/blender/leonor-praca"
RENDER = ROOT / ".qa-runtime/leonor-blender/frames"
OUT.mkdir(parents=True, exist_ok=True)
RENDER.mkdir(parents=True, exist_ok=True)
random.seed(23)
FPS, END = 24, 384
TILT = math.radians(61)
NPC = json.loads((ROOT / "assets/art/npcs/lisbon/frames.json").read_text(encoding="utf8"))["entries"]
COMBAT = json.loads((ROOT / "assets/art/combat/portugal/frames.json").read_text(encoding="utf8"))["entries"]
NPC["duarte"] = json.loads((ROOT / "assets/art/npcs/lisbon/duarte-order-frames.json").read_text(encoding="utf8"))
hero = json.loads((ROOT / "assets/art/portugal-v2/frames.json").read_text(encoding="utf8"))["hero"]
NPC["hero_adult"] = dict(hero, source=hero["path"], reference_height=295)

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for data in list(bpy.data.collections):
    if data.name != "Collection":
        bpy.data.collections.remove(data)
BASE = bpy.data.collections.get("Collection")
BASE.name = "00 — Direção e câmeras"
GROUP = BASE


def collection(name):
    global GROUP
    GROUP = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(GROUP)
    return GROUP


def move_group(obj):
    for group in list(obj.users_collection):
        group.objects.unlink(obj)
    GROUP.objects.link(obj)
    return obj


def empty(name, loc=(0, 0, 0), parent=None):
    obj = bpy.data.objects.new(name, None)
    GROUP.objects.link(obj)
    obj.location = loc
    obj.empty_display_size = .15
    obj.parent = parent
    return obj


def mat(name, color, rough=.7, metal=0):
    obj = bpy.data.materials.new(name)
    obj.diffuse_color = (*color, 1)
    obj.use_nodes = True
    bs = obj.node_tree.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = (*color, 1)
    bs.inputs["Roughness"].default_value = rough
    bs.inputs["Metallic"].default_value = metal
    return obj


def textured(name, color, scale=5, bump=.06):
    obj = mat(name, color)
    nodes, links = obj.node_tree.nodes, obj.node_tree.links
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = scale
    noise.inputs["Detail"].default_value = 4
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (*[v * .72 for v in color], 1)
    ramp.color_ramp.elements[1].color = (*[min(v * 1.14, 1) for v in color], 1)
    links.new(noise.outputs["Fac"], ramp.inputs[0])
    links.new(ramp.outputs[0], nodes.get("Principled BSDF").inputs["Base Color"])
    normal = nodes.new("ShaderNodeBump")
    normal.inputs["Strength"].default_value = .25
    normal.inputs["Distance"].default_value = bump
    links.new(noise.outputs["Fac"], normal.inputs["Height"])
    links.new(normal.outputs["Normal"], nodes.get("Principled BSDF").inputs["Normal"])
    return obj


def mesh(name, verts, faces, material, parent=None):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    GROUP.objects.link(obj)
    if material:
        obj.data.materials.append(material)
    obj.parent = parent
    return obj


def box(name, loc, size, material, bevel=.025, parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = move_group(bpy.context.object)
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    obj.parent = parent
    if bevel:
        mod = obj.modifiers.new("Arestas gastas", "BEVEL")
        mod.width, mod.segments = bevel, 2
        obj.modifiers.new("Normais", "WEIGHTED_NORMAL")
    return obj


def cylinder(name, loc, radius, depth, material, vertices=20):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    obj = move_group(bpy.context.object)
    obj.name = name
    obj.data.materials.append(material)
    mod = obj.modifiers.new("Arestas", "BEVEL")
    mod.width, mod.segments = .015, 2
    return obj


def key(obj, frame, loc=None, rot=None, scale=None):
    if loc is not None:
        obj.location = loc
        obj.keyframe_insert("location", frame=frame)
    if rot is not None:
        obj.rotation_euler = rot
        obj.keyframe_insert("rotation_euler", frame=frame)
    if scale is not None:
        obj.scale = scale
        obj.keyframe_insert("scale", frame=frame)


def planar_key(obj, frame, x, y, angle=0):
    key(obj, frame, (x, y, obj.location.z), (0, 0, math.radians(angle)))


def curve(name, points, radius, material, parent=None):
    data = bpy.data.curves.new(name, "CURVE")
    data.dimensions = "3D"
    data.bevel_depth, data.bevel_resolution = radius, 2
    poly = data.splines.new("POLY")
    poly.points.add(len(points) - 1)
    for p, xyz in zip(poly.points, points):
        p.co = (*xyz, 1)
    obj = bpy.data.objects.new(name, data)
    GROUP.objects.link(obj)
    obj.data.materials.append(material)
    obj.parent = parent
    return obj


STONE = textured("Calcário • veio e desgaste", (.57, .49, .35), 24, .045)
PLASTER = textured("Cal quente • irregularidade fina", (.77, .72, .57), 11, .025)
PEACH = textured("Cal ocre rosada", (.64, .39, .26), 15, .03)
WOOD = textured("Carvalho escurecido", (.18, .105, .055), 6, .025)
TEAL = textured("Madeira verde • portas e venezianas", (.085, .22, .19), 7, .02)
ROOF = textured("Barro cozido", (.43, .14, .065), 20, .02)
GOLD = mat("Latão envelhecido", (.47, .32, .12), .45, .55)
LINEN = textured("Linho cru", (.65, .61, .47), 60, .012)
DARK = mat("Interior das aberturas", (.055, .063, .051))
PRACTICE = textured("Freixo • instrumentos de treino", (.48, .29, .115), 14, .01)

collection("01 — Praça / piso e cantarias")
paving = mat("Calçada de calcário / junta e relevo", (.57, .53, .43))
nodes, links = paving.node_tree.nodes, paving.node_tree.links
tex = nodes.new("ShaderNodeTexCoord")
brick = nodes.new("ShaderNodeTexBrick")
brick.inputs["Scale"].default_value = 1.9
brick.inputs["Mortar Size"].default_value = .012
brick.inputs["Mortar Smooth"].default_value = .012
brick.inputs["Brick Width"].default_value = .72
brick.inputs["Row Height"].default_value = .42
brick.inputs["Color1"].default_value = (.60, .55, .44, 1)
brick.inputs["Color2"].default_value = (.43, .41, .33, 1)
brick.inputs["Mortar"].default_value = (.27, .27, .22, 1)
links.new(tex.outputs["Object"], brick.inputs["Vector"])
links.new(brick.outputs["Color"], nodes.get("Principled BSDF").inputs["Base Color"])
bump = nodes.new("ShaderNodeBump")
bump.inputs["Strength"].default_value = .38
bump.inputs["Distance"].default_value = .035
links.new(brick.outputs["Fac"], bump.inputs["Height"])
links.new(bump.outputs[0], nodes.get("Principled BSDF").inputs["Normal"])
box("Praça / calçada contínua", (0, 2, -.15), (31, 25, .3), paving, .04)
for y in [5.15, 5.5, 5.85]:
    box("Degrau do adro", (-5.8, y, (y - 5) * .23), (13, .4, .16), STONE)
for x in [-12.2, -11.9, 11.9, 12.2]:
    box("Faixa de cantaria", (x, 2, .012), (.22, 24, .025), STONE, 0)


def arch(x, y, width=1.55, height=3.15):
    radius = width * .5
    spring = height - radius
    for side in [-1, 1]:
        box("Pilar da arcada", (x + side * (radius + .19), y, spring * .5), (.38, .55, spring), STONE)
        box("Base do pilar", (x + side * (radius + .19), y, .17), (.52, .7, .26), STONE)
        box("Imposta", (x + side * (radius + .19), y, spring), (.52, .72, .16), STONE)
    for i in range(13):
        a, b = i * math.pi / 13, (i + 1) * math.pi / 13
        verts = []
        for dy in [-.29, .29]:
            for r, t in [(radius, a), (radius + .32, a), (radius + .32, b), (radius, b)]:
                verts.append((x + r * math.cos(t), y + dy, spring + r * math.sin(t)))
        mesh("Aduela • arco de pedra", verts, [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (3, 2, 6, 7)], STONE)


def roof(name, x, y, width, depth, z):
    rise = depth * .29
    verts = [(x - width / 2, y - depth / 2, z), (x + width / 2, y - depth / 2, z),
             (x - width / 2, y, z + rise), (x + width / 2, y, z + rise),
             (x - width / 2, y + depth / 2, z), (x + width / 2, y + depth / 2, z)]
    mesh(name, verts, [(0, 1, 3, 2), (2, 3, 5, 4)], ROOF)
    # Individually shaped roof ridges: consistent real-world scale.
    for i in range(int(width / .22) + 1):
        xx = x - width / 2 + i * .22
        curve("Capa de telha", [(xx, y - depth / 2 - .07, z + .025), (xx, y, z + rise + .025),
                                  (xx, y + depth / 2 + .07, z + .025)], .034, ROOF)
    curve("Cumeeira", [(x - width / 2 - .1, y, z + rise), (x + width / 2 + .1, y, z + rise)], .11, ROOF)


def window(x, y, z, width=.66, height=1.05):
    box("Ombreira da janela", (x, y, z), (width + .25, .20, height + .26), STONE)
    box("Vão escuro", (x, y - .12, z), (width, .04, height), DARK, .01)
    for side in [-1, 1]:
        shutter = box("Portada verde", (x + side * width * .54, y - .28, z), (width * .45, .07, height), TEAL, .015)
        shutter.rotation_euler.z = side * .23
        for dz in [-height * .35, height * .35]:
            box("Travessa da portada", (x + side * width * .54, y - .33, z + dz), (width * .42, .055, .06), WOOD, .008)
    box("Peitoril", (x, y - .22, z - height * .5 - .09), (width + .4, .44, .13), STONE)


collection("02 — Convento / arcadas e telhados")
for x in [-10.8, -8.75, -6.7, -4.65, -2.6, -.55]:
    arch(x, 6.1)
box("Parede alta do convento", (-5.7, 6.15, 4.6), (13.1, .52, 2.65), PLASTER)
box("Cornija", (-5.7, 5.98, 5.91), (13.5, .75, .16), STONE)
box("Parede interior do claustro", (-5.7, 9.1, 2.8), (13, .5, 5.6), PLASTER)
box("Piso sombreado do claustro", (-5.7, 7.6, .18), (13.6, 3.4, .25), STONE)
for x in [-10.8, -8.1, -5.4, -2.7, 0]:
    window(x, 5.83, 4.6, .7, 1.02)
roof("Cobertura do convento", -5.7, 7.5, 14, 4, 6)
for x in [-10, -6.5, -3, .5]:
    box("Porta do claustro", (x, 8.82, 1.25), (1.2, .12, 2.3), WOOD)
    for i in range(5):
        box("Tábua da porta", (x - .48 + i * .24, 8.74, 1.25), (.014, .018, 2.2), DARK, 0)

collection("03 — Casas / travessa e vista do Tejo")
for x, y, width, depth, height, material in [(7.8, 7.8, 5, 4, 5.7, PLASTER), (12.6, 9.1, 4.4, 4, 6.3, PEACH), (13.9, 2.5, 3.7, 5.5, 5.4, PLASTER)]:
    box("Casa da praça", (x, y, height * .5), (width, depth, height), material)
    box("Soco de pedra", (x, y - depth * .5 - .03, .27), (width, .2, .54), STONE)
    roof("Telhado da travessa", x, y, width + .55, depth + .5, height)
    front = y - depth * .5
    for xx in [x - width * .25, x + width * .25]:
        window(xx, front - .12, height - 1.2)
    box("Portal de pedra", (x, front - .09, 1.18), (1.55, .25, 2.37), STONE)
    box("Porta de entrada", (x, front - .24, 1.10), (1.12, .08, 2.15), TEAL)
    for xx in [x - .4, x - .2, x, x + .2, x + .4]:
        box("Junta da porta", (xx, front - .29, 1.1), (.014, .01, 2.05), WOOD, 0)
    cylinder("Argola de ferro", (x + .32, front - .34, 1.05), .045, .025, GOLD)
    box("Travessa de madeira", (x, front - .14, height * .52), (width, .13, .14), WOOD)

# Tejo glimpsed through the open descending street.
watermat = mat("Tejo • ondulação jade", (.09, .27, .25), .27, .35)
nodes, links = watermat.node_tree.nodes, watermat.node_tree.links
coords = nodes.new("ShaderNodeTexCoord")
mapping = nodes.new("ShaderNodeMapping")
noise = nodes.new("ShaderNodeTexNoise")
noise.inputs["Scale"].default_value = 6
noise.inputs["Roughness"].default_value = .6
normal = nodes.new("ShaderNodeBump")
normal.inputs["Strength"].default_value, normal.inputs["Distance"].default_value = .34, .15
links.new(coords.outputs["Generated"], mapping.inputs["Vector"])
links.new(mapping.outputs[0], noise.inputs[0])
links.new(noise.outputs["Fac"], normal.inputs["Height"])
links.new(normal.outputs[0], nodes.get("Principled BSDF").inputs["Normal"])
mapping.inputs["Location"].default_value = (0, 0, 0)
mapping.inputs["Location"].keyframe_insert("default_value", frame=1)
mapping.inputs["Location"].default_value = (.8, .3, 0)
mapping.inputs["Location"].keyframe_insert("default_value", frame=END)
box("Água contínua do Tejo", (0, 30, -.25), (100, 30, .15), watermat, 0)
for xx in range(-24, 25, 3):
    box("Margem distante", (xx, 45, random.uniform(.0, .4)), (3.2, 2, 1.2), STONE, .08)
for xx, yy in [(3, 22), (-4, 28)]:
    cylinder("Mastro no Tejo", (xx, yy, 1.9), .025, 3.4, WOOD, 8)
    mesh("Vela latina distante", [(xx, yy, 3.3), (xx + 1.9, yy, 1), (xx + .05, yy, .95)], [(0, 1, 2)], LINEN)
    box("Casco distante", (xx + .5, yy, .15), (2.6, .5, .25), WOOD)

collection("04 — Banco / oliveira / vida do local")
for xx in [-5.2, -3.9]:
    box("Pé do banco", (xx, -.3, .29), (.18, .6, .58), STONE)
for yy in [-.52, -.28, -.04]:
    box("Assento do banco", (-4.55, yy, .6), (1.9, .2, .1), WOOD)
for z in [.92, 1.16]:
    box("Encosto do banco", (-4.55, .12, z), (1.9, .1, .18), WOOD)
for xx in [-5.3, -3.8]:
    box("Suporte do encosto", (xx, .15, .86), (.09, .1, .7), WOOD)

LEAF = [mat("Oliveira / folha %d" % i, c) for i, c in enumerate([(.23, .31, .14), (.34, .38, .20), (.40, .44, .26), (.19, .27, .15)])]
tree = empty("Oliveira / tronco e copa", (-6.2, .8, 0))
curve("Tronco retorcido", [(0, 0, .05), (.12, .02, .8), (-.05, .1, 1.5), (.2, .1, 2.35), (.05, .12, 3.2)], .16, WOOD, tree)
for branch in range(8):
    angle = branch * math.tau / 8
    end = (math.cos(angle) * 1.3, math.sin(angle) * 1, 2.8 + random.random() * .7)
    curve("Ramo da oliveira", [(.06, .1, 1.8), (end[0] * .55, end[1] * .55, 2.5), end], .055, WOOD, tree)
    verts, faces = [], []
    for i in range(130):
        p = Vector(end) + Vector((random.gauss(0, .48), random.gauss(0, .4), random.gauss(0, .3)))
        ang = random.random() * math.tau
        u = Vector((math.cos(ang), math.sin(ang), random.uniform(-.2, .2))) * .13
        v = Vector((-math.sin(ang), math.cos(ang), .25)) * .033
        base = len(verts)
        verts.extend([p - u, p + v, p + u, p - v])
        faces.append(tuple(base + j for j in range(4)))
    leaves = mesh("Folhas / movimento de brisa", verts, faces, LEAF[branch % 4], tree)
    for frame in range(1, END + 20, 24):
        key(leaves, frame, rot=(.018 * math.sin(frame * .04 + branch), .022 * math.cos(frame * .05 + branch), .01 * math.sin(frame * .07)))

for xx, yy in [(-8.3, 4.3), (9.1, 4), (5.4, 5), (-11.6, 4.1)]:
    cylinder("Vaso de terracota", (xx, yy, .32), .27, .6, ROOF)
    cylinder("Aro do vaso", (xx, yy, .61), .3, .09, ROOF)
    for j in range(9):
        a = j * math.tau / 9
        curve("Alecrim do adro", [(xx, yy, .64), (xx + math.cos(a) * .16, yy + math.sin(a) * .16, 1)], .019, LEAF[j % 4])


def banner(x, y, z, width, height):
    pole = curve("Haste de estandarte", [(x, y, z), (x + width, y, z)], .028, GOLD)
    verts, faces = [], []
    cols, rows = 8, 12
    for row in range(rows + 1):
        for col in range(cols + 1):
            u, v = col / cols, row / rows
            verts.append((x + u * width, y + math.sin(u * 12) * v * .07, z - v * height))
    for row in range(rows):
        for col in range(cols):
            a = row * (cols + 1) + col
            faces.append((a, a + 1, a + cols + 2, a + cols + 1))
    obj = mesh("Estandarte / linho ao vento", verts, faces, TEAL)
    obj.shape_key_add(name="Repouso")
    wave = obj.shape_key_add(name="Brisa")
    for i, point in enumerate(wave.data):
        v = (i // (cols + 1)) / rows
        u = (i % (cols + 1)) / cols
        point.co.y += math.sin(u * 9 + v * 7) * v * .28
        point.co.z += math.sin(u * 8) * v * .06
    for frame in range(1, END + 20, 20):
        wave.value = .5 + .45 * math.sin(frame * .055 + x)
        wave.keyframe_insert("value", frame=frame)
    # Simple applied heraldic stripe; independent from any unapproved coat of arms.
    return obj

banner(-9.7, 5.7, 4, .72, 1.5)
banner(-1.6, 5.7, 4, .72, 1.5)

# The cutouts use original high-resolution images; alpha and color stay intact.
SPRITE_MATS = {}


def sprite_mat(source):
    if source in SPRITE_MATS:
        return SPRITE_MATS[source]
    image = bpy.data.images.load(str(ROOT / source.replace("res://", "")), check_existing=True)
    image.alpha_mode = "STRAIGHT"
    obj = bpy.data.materials.new(Path(source).stem + " / arte original")
    obj.use_nodes = True
    nodes, links = obj.node_tree.nodes, obj.node_tree.links
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    tex = nodes.new("ShaderNodeTexImage")
    tex.image, tex.interpolation = image, "Linear"
    diffuse = nodes.new("ShaderNodeEmission")
    diffuse.inputs["Strength"].default_value = .78
    transparent = nodes.new("ShaderNodeBsdfTransparent")
    mix = nodes.new("ShaderNodeMixShader")
    links.new(tex.outputs["Color"], diffuse.inputs["Color"])
    links.new(tex.outputs["Alpha"], mix.inputs[0])
    links.new(transparent.outputs[0], mix.inputs[1])
    links.new(diffuse.outputs[0], mix.inputs[2])
    links.new(mix.outputs[0], output.inputs["Surface"])
    try:
        obj.surface_render_method = "BLENDED"
    except (TypeError, AttributeError):
        pass
    obj.use_transparency_overlap = False
    SPRITE_MATS[source] = (obj, image)
    return obj, image


def cutout(name, entry, frame, parent, height=1.8, flip=False, polygon=None, pivot=None, depth=0):
    rect = entry["frames"][frame]
    px, py = pivot if pivot else entry["pivots"][frame]
    factor = height / entry["reference_height"]
    sx, sy, width, h = rect
    points = polygon or [(0, 0), (width, 0), (width, h), (0, h)]
    side = -1 if flip else 1
    verts = [((x - px) * factor * side, (py - y) * factor, depth) for x, y in points]
    material, image = sprite_mat(entry["source"])
    obj = mesh(name, verts, [tuple(range(len(points)))], material, parent)
    uv = obj.data.uv_layers.new()
    for face in obj.data.polygons:
        for index in face.loop_indices:
            v = obj.data.loops[index].vertex_index
            x, y = points[v]
            uv.data[index].uv = ((sx + x) / image.size[0], 1 - (sy + y) / image.size[1])
    return obj


SHADOW = mat("Sombra de contato suave", (.055, .07, .045))
shadow_nodes = SHADOW.node_tree.nodes
shadow_links = SHADOW.node_tree.links
shadow_nodes.clear()
output = shadow_nodes.new("ShaderNodeOutputMaterial")
transparent = shadow_nodes.new("ShaderNodeBsdfTransparent")
dark = shadow_nodes.new("ShaderNodeEmission")
dark.inputs["Color"].default_value = (.045, .05, .035, 1)
mix = shadow_nodes.new("ShaderNodeMixShader")
tex = shadow_nodes.new("ShaderNodeTexCoord")
distance = shadow_nodes.new("ShaderNodeVectorMath")
distance.operation = "DISTANCE"
distance.inputs[1].default_value = (.5, .5, 0)
shadow_links.new(tex.outputs["UV"], distance.inputs[0])
ramp = shadow_nodes.new("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].position = .05
ramp.color_ramp.elements[0].color = (.34, .34, .34, 1)
ramp.color_ramp.elements[1].position = .5
ramp.color_ramp.elements[1].color = (0, 0, 0, 1)
shadow_links.new(distance.outputs["Value"], ramp.inputs[0])
shadow_links.new(ramp.outputs[0], mix.inputs[0])
shadow_links.new(transparent.outputs[0], mix.inputs[1])
shadow_links.new(dark.outputs[0], mix.inputs[2])
shadow_links.new(mix.outputs[0], output.inputs[0])
SHADOW.surface_render_method = "BLENDED"


def shadow(parent, radius=.6):
    obj = mesh("Sombra / contato dos pés", [(-radius, -.22, .012), (radius, -.22, .012), (radius, .22, .012), (-radius, .22, .012)], [(0, 1, 2, 3)], SHADOW, parent)
    uv = obj.data.uv_layers.new()
    for i, xy in enumerate([(0, 0), (1, 0), (1, 1), (0, 1)]):
        uv.data[i].uv = xy
    return obj


def billboard_root(name, loc):
    root = empty(name, loc)
    carrier = empty(name + " / plano ilustrado", parent=root)
    carrier.rotation_euler.x = TILT
    shadow(root)
    return root, carrier


collection("05 — Público / herói e Duarte")
for i, (who, frame, x, y) in enumerate([
    ("worker", 0, -3.5, 2.5), ("dock_woman", 0, -1.8, 3.3),
    ("observer", 0, .1, 3.6), ("family", 0, 2.1, 3.1),
    ("worker", 4, 3.3, 1.4), ("attendant", 0, -4.3, 1.4),
    ("duarte", 8, -2.6, -2.2), ("hero_adult", 8, -1.6, -2.5)]):
    if who not in NPC:
        who = "hero" if "hero" in NPC else "worker"
    root, carrier = billboard_root("Público %02d / %s" % (i, who), (x, y, .015))
    entry = NPC[who]
    cutout("Corpo ilustrado", entry, frame, carrier, 1.75)
    for f in range(1, END + 20, 24):
        key(carrier, f, scale=(1, 1 + .003 * math.sin(f * .07 + i), 1))
    # A small collective recoil follows the disarm, then each returns to rest.
    if i < 6:
        for f, dy in [(235, 0), (246, .12), (266, .04), (296, 0)]:
            key(root, f, (x, y + dy, .015))

collection("06 — Leonor / poses e instrumento")
leonor, lc = billboard_root("LEONOR / movimento principal", (3.1, -.2, .015))
le = COMBAT["leonor"]
lposes = [cutout("Leonor / %02d %s" % (i, name), le, i, lc, 1.82, True) for i, name in enumerate(["guarda", "passo A", "passo B", "preparação", "extensão", "retorno", "desvio", "ferida — não usada", "joelho — não usado"])]


def practice(name, parent, length=.91):
    handle = empty(name, parent=parent)
    box("Lâmina arredondada de freixo", (length * .5, 0, 0), (length, .043, .035), PRACTICE, .018, handle)
    box("Guarda do instrumento", (.015, 0, .004), (.055, .23, .05), WOOD, .018, handle)
    box("Punho", (-.10, 0, 0), (.19, .045, .045), WOOD, .015, handle)
    return handle


lweapon = practice("Leonor / instrumento na mão", lc, 1.04)


def leonor_pose(frame, pose, angle):
    for i, obj in enumerate(lposes):
        obj.hide_render = i != pose
        obj.hide_viewport = i != pose
        obj.keyframe_insert("hide_render", frame=frame)
        obj.keyframe_insert("hide_viewport", frame=frame)
    px, py = le["pivots"][pose]
    gx, gy = le["grips"][pose]
    factor = 1.82 / le["reference_height"]
    bpy.context.preferences.edit.keyframe_new_interpolation_type = "CONSTANT"
    key(lweapon, frame, (-(gx - px) * factor, (py - gy) * factor, .035))
    bpy.context.preferences.edit.keyframe_new_interpolation_type = "BEZIER"
    key(lweapon, frame, rot=(0, 0, math.radians(angle)))


# Six held poses, with actual walking only during entry. No hurt/kneel for Leonor.
lkeys = [(1, 0, 145), (36, 0, 145), (43, 1, 145), (49, 2, 145), (55, 1, 145), (61, 2, 145),
         (67, 0, 150), (109, 0, 150), (115, 6, 132), (123, 6, 161), (136, 0, 150),
         (211, 0, 150), (229, 6, 135), (236, 5, 184), (244, 4, 180), (252, 4, 180),
         (274, 4, 180), (307, 4, 180), (339, 4, 180), (355, 5, 155), (372, 0, 145), (384, 0, 145)]
for frame, pose, angle in lkeys:
    leonor_pose(frame, pose, angle)
# Blender inherits interpolation from neighboring keys on an existing channel.
# Anchor changes must step on the same frame as the illustrated pose changes;
# otherwise the wooden hilt drifts between two different painted hands.
for layer in lweapon.animation_data.action.layers:
    for strip in layer.strips:
        for bag in strip.channelbags:
            for channel in bag.fcurves:
                if channel.data_path == "location":
                    for point_key in channel.keyframe_points:
                        point_key.interpolation = "CONSTANT"
for frame, x, y in [(1, 3.1, -.2), (36, 3.1, -.2), (67, 1.13, -.2), (106, 1.13, -.2),
                    (118, 1.18, -.11), (133, 1.13, -.2), (218, 1.13, -.2),
                    (234, 1.21, -.02), (244, .74, -.12), (258, .8, -.12), (339, .8, -.12), (372, 1, -.12), (384, 1, -.12)]:
    key(leonor, frame, (x, y, .015))
for frame in range(1, END + 10, 12):
    key(lc, frame, scale=(1, 1 + .0015 * math.sin(frame * .05), 1))

collection("07 — Mestre / marionete articulada")
master, mc = billboard_root("MESTRE / Grande Guerreiro", (-1.65, -.2, .015))
me = NPC["master"]
fac = 1.92 / me["reference_height"]
mpivot = (65.43, 291)


def point(x, y, depth=0):
    return ((x - mpivot[0]) * fac, (mpivot[1] - y) * fac, depth)


def part(name, polygon, pivot, parent=mc, parent_pivot=mpivot, depth=.0):
    root = empty(name + " / controle", ((pivot[0] - parent_pivot[0]) * fac, (parent_pivot[1] - pivot[1]) * fac, depth), parent)
    cutout(name, me, 0, root, 1.92, polygon=polygon, pivot=pivot)
    return root


# Overlapping garment pieces keep the original painting instead of stretching it.
legs = []
for name, hip, knee, poly1, poly2 in [
    ("perna esquerda", (48, 168), (41, 232), [(25, 155), (66, 155), (63, 218), (51, 241), (27, 237)], [(27, 218), (57, 222), (57, 279), (52, 302), (4, 302), (6, 282), (24, 260)]),
    ("perna direita", (81, 168), (88, 232), [(63, 155), (105, 155), (105, 232), (76, 240), (67, 217)], [(76, 221), (107, 217), (109, 267), (126, 282), (127, 302), (78, 302), (77, 279)])]:
    upper = part(name + " / coxa", poly1, hip, depth=-.006)
    lower = part(name + " / bota", poly2, knee, upper, hip, .001)
    legs.append((upper, lower))
left_upper = part("braço livre", [(19, 58), (40, 58), (44, 88), (29, 127), (9, 124), (10, 88)], (31, 66), depth=-.002)
left_lower = part("antebraço livre", [(10, 110), (30, 111), (32, 151), (34, 174), (14, 178), (9, 150)], (20, 116), left_upper, (31, 66), .002)
torso = part("tronco / colete", [(36, 49), (88, 49), (99, 78), (95, 141), (105, 177), (72, 183), (63, 159), (55, 183), (26, 176), (35, 135), (28, 75)], (65, 162), depth=.004)
head = part("cabeça", [(32, 0), (96, 0), (101, 42), (86, 64), (42, 64), (28, 43)], (65, 54), depth=.007)
arm = part("braço armado", [(87, 56), (108, 61), (121, 111), (116, 129), (99, 126), (90, 102)], (97, 67), depth=.009)
forearm = part("antebraço armado", [(100, 109), (121, 110), (124, 157), (121, 176), (102, 177), (98, 154)], (111, 119), arm, (97, 67), .003)
mweapon = practice("Mestre / instrumento na mão", forearm, 1.03)
mweapon.location = ((114 - 111) * fac, (119 - 165) * fac, .03)
mweapon.rotation_euler.z = math.radians(77)

# Arms lift in a real joint hierarchy. The first contact is short; the second
# attempt overcommits and opens the fingers to the disarm.
for frame, a, b, left, tilt, blade in [(1, 0, 0, 0, 0, 77), (60, 20, 45, -8, 0, 55), (92, 30, 56, -10, 0, 58),
    (106, 52, 32, -15, -1, 50), (115, 60, 20, -22, -2, 35), (121, 58, 24, -22, -1, 65),
    (135, 38, 57, -10, 0, 55), (168, 24, 52, -7, 0, 55),
    (197, 144, 66, -25, -3, 100), (216, 148, 64, -25, -3, 100), (233, 90, 0, -15, -4, 3),
    (239, 82, 4, -15, -3, 36), (247, 65, 5, -10, 1, 40), (272, 26, 5, -9, 1, 40),
    (294, 20, 9, -8, 1, 40), (321, 24, 6, -7, 1, 40), (345, 21, 6, -6, 0, 40), (384, 9, 5, -4, 0, 40)]:
    key(arm, frame, rot=(0, 0, math.radians(a)))
    key(forearm, frame, rot=(0, 0, math.radians(b)))
    key(left_upper, frame, rot=(0, 0, math.radians(left)))
    key(head, frame, rot=(0, 0, math.radians(tilt)))
    key(torso, frame, rot=(0, 0, math.radians(tilt * .6)))
    key(mweapon, frame, rot=(0, 0, math.radians(blade - a - b)))
for frame, x, y in [(1, -1.65, -.2), (68, -1.65, -.2), (104, -1.38, -.2), (116, -.75, -.2),
                    (124, -.75, -.2), (165, -1.6, -.2), (214, -1.6, -.2), (234, -.66, -.2),
                    (244, -.66, -.2), (265, -.97, -.15), (384, -.97, -.15)]:
    key(master, frame, (x, y, .015))
for frame, value in [(1, 0), (68, 0), (89, 12), (105, -10), (116, 0), (135, -13), (152, 10), (165, 0),
                     (214, 0), (225, 14), (234, 0), (254, -8), (265, 0), (384, 0)]:
    for i, (upper, lower) in enumerate(legs):
        sign = -1 if i == 0 else 1
        key(upper, frame, rot=(0, 0, math.radians(value * sign)))
        key(lower, frame, rot=(0, 0, math.radians(-value * sign * .55)))
# Trembling hand remains visible after Leonor has already stopped moving.
for frame in range(286, 339, 3):
    key(forearm, frame, rot=(0, 0, math.radians(7 + math.sin(frame * 1.7) * 2.0)))
for obj in [mweapon] + list(mweapon.children_recursive):
    for f, hidden in [(1, False), (241, True)]:
        obj.hide_render = hidden
        obj.hide_viewport = hidden
        obj.keyframe_insert("hide_render", frame=f)
        obj.keyframe_insert("hide_viewport", frame=f)

# Dropped weapon is independent so the fingers can release it without a jump.
drop = practice("Instrumento desarmado / queda e ressalto", None, 1.03)
bpy.context.scene.frame_set(240)
bpy.context.view_layer.update()
release_loc = tuple(mweapon.matrix_world.translation)
release_rot = tuple(mweapon.matrix_world.to_euler())
for f, loc, rot in [(1, release_loc, release_rot),
    (241, release_loc, release_rot), (249, (1.2, -.6, 1.8), (1.2, .7, 1.7)),
    (263, (2.25, -1.15, .09), (0, 0, 3.9)), (268, (2.4, -1.17, .23), (.1, .15, 4.1)),
    (277, (2.5, -1.18, .045), (0, 0, 4.22)), (384, (2.5, -1.18, .045), (0, 0, 4.22))]:
    key(drop, f, loc, rot)
for f, hidden in [(1, True), (240, True), (241, False)]:
    for obj in [drop] + list(drop.children_recursive):
        obj.hide_render = hidden
        obj.hide_viewport = hidden
        obj.keyframe_insert("hide_render", frame=f)
        obj.keyframe_insert("hide_viewport", frame=f)

collection("08 — Aves / ar e movimentos do ambiente")
PIGEON = mat("Pombos / cinza azulado", (.19, .23, .22))
for i, (x, y) in enumerate([(-5, 3.8), (4.6, 3.6), (5, 3.2)]):
    bird = empty("Pombo / percurso %d" % i, (x, y, .11))
    body = mesh("Corpo do pombo", [(-.11, 0, 0), (0, -.07, -.03), (.14, 0, .07), (0, .07, -.03), (0, 0, .12)], [(0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4)], PIGEON, bird)
    wings = []
    for side in [-1, 1]:
        wing = mesh("Asa", [(0, 0, .03), (-.1, side * .29, 0), (.11, side * .2, .03)], [(0, 1, 2)], PIGEON, bird)
        wings.append(wing)
    for frame, z, offset in [(1, .11, 0), (235, .11, 0), (249, .6, .3), (275, 2.4, 1.9), (310, 5.5, 4.2), (384, 8, 7)]:
        key(bird, frame, (x + offset, y + offset * .7, z))
    for f in range(237, END + 4, 3):
        for side, wing in zip([-1, 1], wings):
            key(wing, f, rot=(side * .9 * math.sin(f * .6), 0, 0))

collection("09 — Luz / câmera / montagem")
world = bpy.data.worlds.new("Manhã do Tejo")
bpy.context.scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (.45, .58, .64, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = .45
sun_data = bpy.data.lights.new("Sol da manhã", "SUN")
sun_data.energy, sun_data.angle = 2.1, math.radians(9)
sun_data.color = (1, .84, .64)
sun = bpy.data.objects.new("Sol da manhã", sun_data)
GROUP.objects.link(sun)
sun.rotation_euler = (math.radians(29), math.radians(-24), math.radians(-37))
area_data = bpy.data.lights.new("Luz do céu / preenchimento", "AREA")
area_data.energy, area_data.shape, area_data.size = 1300, "DISK", 12
area = bpy.data.objects.new("Luz do céu / preenchimento", area_data)
GROUP.objects.link(area)
area.location = (0, -5, 12)

camera_data = bpy.data.cameras.new("Praça / plano contínuo")
camera = bpy.data.objects.new("Praça / plano contínuo", camera_data)
GROUP.objects.link(camera)
bpy.context.scene.camera = camera
camera_data.type = "ORTHO"
direction = Vector((0, -math.sin(TILT), math.cos(TILT)))
target = Vector((0, .6, .9))
camera.location = target + direction * 25
camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
for frame, size, tx, ty, tz in [(1, 23, 0, 4.2, 1.8), (42, 23, 0, 4.2, 1.8), (78, 10.3, .1, .2, .9),
                           (165, 10.3, .1, .2, .9), (213, 9.4, -.05, -.1, .9), (275, 9.4, -.05, -.1, .9),
                           (339, 8.9, -.05, -.1, .9), (384, 10, -.05, -.1, .9)]:
    target = Vector((tx, ty, tz))
    key(camera, frame, target + direction * 25)
    camera_data.ortho_scale = size
    camera_data.keyframe_insert("ortho_scale", frame=frame)

scene = bpy.context.scene
scene.frame_start, scene.frame_end = 1, END
scene.render.fps = FPS
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x, scene.render.resolution_y = 1280, 720
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGB"
scene.render.filepath = str(RENDER / "praca_")
scene.render.film_transparent = False
scene.view_settings.view_transform = "AgX"
scene.view_settings.look = "AgX - Medium High Contrast"
scene.render.image_settings.color_depth = "8"
try:
    scene.eevee.taa_render_samples = 16
except AttributeError:
    pass
scene.render.use_file_extension = True
scene.render.fps_base = 1
for frame, name in [(1, "Praça / manhã"), (43, "Leonor entra"), (106, "Primeira investida"),
                    (115, "Desvio curto"), (165, "Mestre recompõe a guarda"), (216, "Segunda técnica"),
                    (241, "Desarme"), (263, "Instrumento toca a pedra"), (274, "Ponta junto ao peito"),
                    (295, "Outra vez."), (326, "A tua mão."), (355, "Fim do confronto")]:
    scene.timeline_markers.new(name, frame=frame)

notes = bpy.data.texts.new("LEIA-ME • Leonor / praça")
notes.write("""MAR DE JADE — LEONOR / DEMONSTRAÇÃO PÚBLICA
Blender 5.2.2 LTS · 24 fps · 384 quadros / 16 segundos · 1280 × 720

Cena híbrida: cenário 3D novo e personagens ilustrados originais do projeto.
Coleções separam cenário, público, Leonor, articulações do mestre e montagem.
Os marcadores da timeline identificam todos os momentos da coreografia.
Leonor usa instrumentos de madeira e vence com dois movimentos curtos.
A figura denominada Grande Guerreiro corresponde ao mestre visitante anônimo
do roteiro C01-M03/S01; não altera seu nome nas falas da campanha.

Todas as imagens usadas estão empacotadas neste arquivo.
O roteiro de autoria está em tools/blender/build_leonor_square.py.
O vídeo é uma cena de apresentação do encontro, sem alterar os saves.
""")

# Useful opening view in the editor; no external cache needed to scrub animation.
scene.frame_set(274)
for area_ui in bpy.context.screen.areas:
    if area_ui.type == "VIEW_3D":
        area_ui.spaces.active.region_3d.view_perspective = "CAMERA"
        area_ui.spaces.active.shading.type = "MATERIAL"
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "leonor-praca.blend"), compress=True)
(OUT / "timeline.json").write_text(json.dumps({
    "fps": FPS, "frames": END, "duration_seconds": END / FPS,
    "source": "docs/narrativa/C01-portugal-aprovado.md#c01-m03",
    "beats": [{"frame": m.frame, "time": (m.frame - 1) / FPS, "label": m.name} for m in scene.timeline_markers]
}, ensure_ascii=False, indent=2), encoding="utf8")
print("LEONOR_BLEND_SAVED", str(OUT / "leonor-praca.blend"), flush=True)
if "--render" in sys.argv:
    scene.frame_set(1)
    bpy.ops.render.render(animation=True)
elif "--preview" in sys.argv:
    for frame in [1, 115, 241, 274]:
        scene.frame_set(frame)
        scene.render.filepath = str(ROOT / ".qa-runtime/leonor-blender" / ("preview-%03d.png" % frame))
        bpy.ops.render.render(write_still=True)
