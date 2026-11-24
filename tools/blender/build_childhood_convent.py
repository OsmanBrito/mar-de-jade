"""Build the playable childhood cloister and an articulated practice knight.

Run from the official repository with Blender --background --factory-startup
--python tools/blender/build_childhood_convent.py. Geometry and materials are
original; the campaign's illustrated actors remain separate in Godot.
"""
import bpy
import bmesh
import math
import random
from mathutils import Vector
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "art-source/blender/childhood-convent"
ASSETS = ROOT / "assets/models/childhood-convent"
SOURCE.mkdir(parents=True, exist_ok=True)
ASSETS.mkdir(parents=True, exist_ok=True)
(SOURCE / ".gdignore").write_text("", encoding="utf8")
random.seed(2410)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)


def material(name, color, metallic=0):
    value = bpy.data.materials.new(name)
    value.diffuse_color = (*color, 1)
    value.use_nodes = True
    shader = value.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Roughness"].default_value = .86
    shader.inputs["Metallic"].default_value = metallic
    return value


STONE = [material("Calcário_%d" % i, c) for i, c in enumerate([
    (.48, .49, .43), (.51, .51, .45), (.46, .47, .42), (.53, .52, .46)])]
TRIM = material("Cantaria clara", (.73, .70, .59))
WALL = material("Cal morna", (.65, .64, .55))
SHADE = material("Pedra antiga", (.43, .46, .39))
RED = material("Vermelhão da Ordem", (.53, .12, .09))
CLOTH = material("Linho cru", (.87, .82, .68))
WOOD = material("Castanho", (.27, .17, .09))
OAK = material("Madeira encerada", (.48, .32, .16))
FLOOR = [material("Soalho gasto_%d" % i, c) for i, c in enumerate([
    (.38, .27, .16), (.40, .29, .18), (.36, .25, .15), (.42, .30, .18)])]
LEAF = [material("Folhagem_%d" % i, c) for i, c in enumerate([
    (.20, .33, .20), (.30, .42, .24), (.41, .49, .28), (.52, .56, .32)])]
EARTH = material("Terra", (.22, .26, .16))
TILE = material("Telha", (.51, .23, .13))
TEAL = material("Manta verde", (.22, .39, .37))
WATER = material("Água do claustro", (.25, .48, .46))
METAL = material("Aço escurecido", (.34, .40, .42), .55)
GOLD = material("Latão", (.67, .47, .19), .65)
CLAY = material("Barro cozido", (.46, .26, .18))
BREAD = material("Pão", (.56, .38, .19))
MOSS = material("Musgo nas juntas", (.27, .34, .23))


def box(name, x, z, h, width, depth, height, mat, parent=None):
    # Author in the same X/Z plan as Godot; Blender's up-axis is Z.
    verts = [(sx*width/2, sy*depth/2, sz*height/2) for sz in [-1, 1] for sy in [-1, 1] for sx in [-1, 1]]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4), (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)])
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = (x, -z, h)
    obj.data.materials.append(mat)
    if parent:
        obj.parent = parent
    return obj


def cylinder(name, x, z, h, radius, depth, mat, vertices=12):
    mesh = bpy.data.meshes.new(name)
    verts = [(math.cos(i*math.tau/vertices)*radius, math.sin(i*math.tau/vertices)*radius, side*depth/2) for side in [-1, 1] for i in range(vertices)]
    faces = [tuple(reversed(range(vertices))), tuple(range(vertices, vertices*2))]
    faces += [(i, (i+1)%vertices, (i+1)%vertices+vertices, i+vertices) for i in range(vertices)]
    mesh.from_pydata(verts, [], faces)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = (x, -z, h)
    obj.data.materials.append(mat)
    return obj


def arch(name, x, z, width=2.7, height=3.7, depth=.5, along_x=True, base=0):
    """Actual open arch: individual voussoirs, never an opaque painted doorway."""
    radius = width / 2
    spring = height - radius
    for side in [-1, 1]:
        px, pz = (x + side * (radius + .16), z) if along_x else (x, z + side * (radius + .16))
        box(name + " pilar", px, pz, base+spring / 2, .34 if along_x else depth, depth if along_x else .34, spring, TRIM)
        box(name + " base", px, pz, base+.13, .58, .58, .26, TRIM)
        box(name + " capitel", px, pz, base+spring - .08, .52, .62, .24, TRIM)
    for i in range(13):
        a, b = i * math.pi / 13, (i + 1) * math.pi / 13
        verts = []
        for face in [-depth / 2, depth / 2]:
            for r, t in [(radius, a), (radius, b), (radius + .34, b), (radius + .34, a)]:
                horizontal, up = math.cos(t) * r, base+spring + math.sin(t) * r
                verts.append((x + horizontal, -z + face, up) if along_x else (x + face, -z + horizontal, up))
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(verts, [], [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)])
        obj = bpy.data.objects.new(name + " aduela", mesh)
        bpy.context.collection.objects.link(obj)
        obj.data.materials.append(TRIM if i % 3 else STONE[1])


def cross(name, x, z, h, scale=1):
    box(name, x, z, h, .18 * scale, .055, .93 * scale, RED)
    box(name, x, z-.01, h+.12*scale, .67 * scale, .055, .18 * scale, RED)
    for dx, dz in [(-.29, .12), (.29, .12), (0, .43), (0, -.43)]:
        box(name, x+dx*scale, z-.012, h+dz*scale, .23*scale, .06, .23*scale, RED)


def rounded_box(name, x, z, h, width, depth, height, mat, bevel=.035):
    obj = box(name, x, z, h, width, depth, height, mat)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bevel, segments=1, affect='EDGES')
    bm.to_mesh(obj.data)
    bm.free()
    return obj


def branch(name, a, b, radius, mat):
    a, b = Vector(a), Vector(b)
    obj = cylinder(name, 0, 0, 0, radius, (b-a).length, mat, 8)
    obj.location = (a+b)/2
    obj.rotation_euler = (b-a).to_track_quat('Z', 'Y').to_euler()
    return obj


def foliage(name, x, z, h, radius, mat, stretch=(1, 1, 1)):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=radius)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = (x, -z, h)
    obj.scale = stretch
    mesh.materials.append(mat)
    return obj


def banner(name, x, z, h, width, height):
    """A single cloth mesh, two wind morphs, and a coloured woven cross.

    glTF keeps the morph animation and the two material slots intact; these
    meshes must not be joined into the static material batches below.
    """
    cols, rows = 10, 16
    verts, faces = [], []
    for row in range(rows+1):
        t = row/rows
        for column in range(cols+1):
            u = column/cols
            verts.append(((u-.5)*width, .025*math.sin(u*math.tau)*t, (.5-t)*height))
    for row in range(rows):
        for column in range(cols):
            i = row*(cols+1)+column
            faces.append((i, i+1, i+cols+2, i+cols+1))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(CLOTH)
    mesh.materials.append(RED)
    uv = mesh.uv_layers.new(name='Cloth UV')
    for polygon in mesh.polygons:
        for loop_index in polygon.loop_indices:
            vertex = mesh.loops[loop_index].vertex_index
            uv.data[loop_index].uv = ((vertex % (cols+1))/cols, 1-(vertex//(cols+1))/rows)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = (x, -z, h)
    for row in range(rows):
        for column in range(cols):
            stem = column in [4,5] and 3 <= row <= 12
            arm = 1 <= column <= 8 and row in [6,7]
            tips = (column in [1,8] and 5 <= row <= 8) or (3 <= column <= 6 and row in [3,12])
            mesh.polygons[row*cols+column].material_index = int(stem or arm or tips)
    obj.shape_key_add(name='Basis')
    for sign, key_name in [(1,'Brisa de fora'),(-1,'Brisa do claustro')]:
        key = obj.shape_key_add(name=key_name)
        for i, vert in enumerate(verts):
            t = (i//(cols+1))/rows
            u = (i%(cols+1))/cols
            key.data[i].co.y += sign*(.12*math.sin(t*3+u*2)+.025*math.cos(u*5))*t
            key.data[i].co.z += .04*math.sin(u*5+t*2)*t
        for frame, value in [(1,0),(25,1 if sign>0 else 0),(49,0),(73,1 if sign<0 else 0),(97,0)]:
            key.value = value
            key.keyframe_insert('value', frame=frame)
    return obj


# The map is compact: bedroom, surrounding galleries, garden, practice bay.
# Keep its upper face below the paving, including after glTF float conversion.
# Coplanar foundation/paving faces were alternating in the depth buffer.
box("Fundação", 0, 0, -.47, 25, 26, .7, SHADE)
box("Terreno para além dos muros", 0, -3, -1.3, 68, 64, .5, EARTH)
for iz in range(50):
    for ix in range(40):
        x = -11.8 + ix * .61 + (.3 if iz % 2 else 0)
        z = -11.7 + iz * .49
        if x > 12 or z > 12.7:
            continue
        box("Laje", x, z, -.035, .602, .482, .07, random.choice(STONE))

# High rear wall and modest upper gallery, with the central gate visibly open.
for x, width in [(-7.4, 7.2), (7.4, 7.2)]:
    box("Ala norte", x, -10.9, 3.1, width, 1, 6.2, WALL)
    box("Cornija norte", x, -10.9, 6.25, width+.3, 1.25, .22, TRIM)
    for wx in [x-2.2, x, x+2.2]:
        box("Janela escura", wx, -10.36, 4.4, .95, .06, 1.4, SHADE)
        arch("Janela", wx, -10.3, .82, 1.65, .15, base=3.65)
        box("Peitoril", wx, -10.24, 3.62, 1.3, .25, .16, TRIM)
        for offset in [-.25, 0, .25]:
            box("Ferro da janela", wx+offset, -10.21, 4.3, .035, .04, 1.3, METAL)
    for j in range(int(width/.3)):
        roof = box("Telha da ala", x-width/2+j*.3, -10.8, 6.52, .28, 2.1, .17, TILE)
        roof.rotation_euler.x = math.radians(9)
arch("Porta para Lisboa", 0, -10.7, 5.3, 5.5, 1)
box("Corpo da portaria", 0, -10.9, 6.35, 5.9, 1.2, 1.25, WALL)
box("Remate da portaria", 0, -10.9, 7.05, 6.2, 1.4, .22, TRIM)
banner("Estandarte da portaria", 0, -10.12, 6.3, .9, 1.15)
box("Verga do estandarte", 0, -10.14, 6.91, 1.2, .11, .1, WOOD)

# A tower and a Romanesque rose give the skyline one recognisable silhouette.
box("Torre da casa", -8.7, -12.2, 4.0, 2.8, 2.6, 8, WALL)
box("Cinta da torre", -8.7, -12.2, 6.1, 3.05, 2.8, .22, TRIM)
box("Sombra do campanário", -8.7, -10.86, 8, 1.15, .06, 1.85, WOOD)
arch("Arco do sino", -8.7, -10.79, 1.12, 2.1, .3, base=7.02)
box("Coroamento da torre", -8.7, -12.2, 9.45, 3.1, 2.9, .28, TRIM)
cylinder("Sino", -8.7, -10.63, 7.75, .30, .42, GOLD)
box("Badalo", -8.7, -10.63, 7.48, .06, .06, .2, METAL)
for dx in [-1.05,0,1.05]:
    box("Merlão da torre", -8.7+dx, -10.94, 9.8, .48, .44, .58, TRIM)
for i in range(16):
    angle = i*math.tau/16
    petal = rounded_box("Rosácea da portaria", math.cos(angle)*.65, -10.19,
                        6.1+math.sin(angle)*.65, .16, .12, .29, SHADE, .02)
    petal.rotation_euler.y = -angle

# Open cloister arches give a procession of framed views, not a giant empty room.
for x in [-7.6, -4.6, 4.6, 7.6]:
    arch("Galeria norte", x, -5.5, 2.55, 3.5, .45)
arch("Arco maior do claustro", 0, -5.5, 5.75, 4.2, .55)
for x in [-6.3,6.3]:
    box("Entablamento norte", x, -5.5, 3.83, 6.1, .75, .45, WALL)
    box("Cornija do claustro", x, -5.5, 4.08, 6.5, .95, .15, TRIM)
box("Entablamento do arco maior", 0, -5.5, 4.66, 6.45, .75, .25, WALL)
box("Cornija do arco maior", 0, -5.5, 4.86, 6.7, .95, .15, TRIM)
for z in [-3.7, -.6, 2.5]:
    arch("Galeria poente", -6.2, z, 2.65, 3.5, .45, False)
    arch("Galeria nascente", 6.2, z, 2.65, 3.5, .45, False)
for x in [-6.2, 6.2]:
    box("Cornija lateral", x, -.6, 3.85, .7, 9.3, .4, WALL)
    box("Friso lateral", x, -.6, 3.52, .78, 9.3, .12, SHADE)
    for z in [-4.6,-2.8,-1,.8,2.6,4.1]:
        beam = box("Cachorro de madeira", x, z, 3.35, .95, .16, .20, WOOD)
        beam.rotation_euler.y = math.radians(12)
for x in [-8.9,-5.9,-2.9,0,2.9,5.9,8.9]:
    box("Friso da galeria", x, -5.19, 3.7, 1.85, .08, .12, SHADE)

# Repairs and worn borders break the repeated paving without raising the floor.
for x, z in [(-10,-3),(-7.9,-8.8),(6.7,-7.8),(9.9,3.5)]:
    for i in range(5):
        box("Musgo ao abrigo do muro", x+i*.15, z+random.uniform(-.12,.12), .003,
            .12, random.uniform(.04,.12), .004, MOSS)

# A garden separates circulation from a focal point; low beds preserve visibility.
for x in [-2.5, 2.5]:
    for z in [-2.5, .5]:
        box("Canteiro", x, z, .10, 3.5, 2.3, .20, TRIM)
        box("Terra dos canteiros", x, z, .22, 3.25, 2.05, .15, EARTH)
        for i in range(11):
            bx, bz = x+random.uniform(-1.4, 1.4), z+random.uniform(-.8, .8)
            mesh = bpy.data.meshes.new("Arbusto")
            bm = bmesh.new()
            bmesh.ops.create_icosphere(bm, subdivisions=1, radius=random.uniform(.22, .4))
            bm.to_mesh(mesh)
            bm.free()
            shrub = bpy.data.objects.new("Arbusto", mesh)
            bpy.context.collection.objects.link(shrub)
            shrub.location = (bx, -bz, .42)
            mesh.materials.append(random.choice(LEAF))
cylinder("Fonte base", 0, -1, .19, 1.05, .38, TRIM, 16)
cylinder("Água", 0, -1, .39, .88, .03, WATER, 16)
cylinder("Fonte coluna", 0, -1, .78, .18, .84, STONE[1])
cylinder("Fonte taça", 0, -1, 1.20, .52, .16, TRIM)
for side in [-1,1]:
    box("Bica", side*.43, -1, 1.17, .22, .16, .10, SHADE)
    cylinder("Fio de água", side*.49, -1, .80, .018, .64, WATER, 6)
# One old olive tree occupies an existing blocked garden bed, never the path.
branch("Oliveira tronco", (-2.5,2.5,.3), (-2.4,2.4,1.9), .15, WOOD)
for dx,dz in [(-.65,.25),(.65,-.25),(.15,.6)]:
    branch("Oliveira ramo", (-2.4,2.4,1.5), (-2.4+dx,2.4+dz,2.55), .065, WOOD)
    foliage("Oliveira copa", -2.4+dx, -2.4-dz, 2.65, .75, LEAF[1], (1,1,.65))

# West enclosure and a quiet chapel: the player sees the place through the arches.
box("Muro poente", -11.8, -2.5, 2.7, .55, 16.7, 5.4, WALL)
box("Rodapé poente", -11.48, -2.5, .35, .18, 16.7, .7, SHADE)
for z in [-8, -3, 2]:
    box("Contraforte poente", -11.45, z, 1.9, .7, .75, 3.8, TRIM)
box("Mesa da capela", -9, -6.8, .53, 2.5, .85, 1.06, TRIM)
for x in [-9.7, -8.3]:
    cylinder("Vela", x, -6.8, 1.2, .06, .3, CLOTH)
cross("Memória templária", -9, -10.28, 2.5, 1.1)
for x in [-10,-8]:
    box("Cantaria do memorial", x, -10.24, 1.6, .18, .18, 2.8, TRIM)
box("Lintel do memorial", -9, -10.22, 3.1, 2.3, .22, .26, TRIM)
for i in range(5):
    box("Inscrição gasta", -9, -10.17, 1.8-i*.12, .85-i*.07, .025, .025, SHADE)

# Bedroom with a cutaway front, correctly sized furniture and its own warm palette.
for i in range(25):
    x = -10.65+i*.32
    box("Soalho do dormitório", x, 8.85, .035, .314, 7.45, .07, FLOOR[i%4])
    for z in [6.1+(i%3)*.58,9.4+(i%4)*.45]:
        box("Junta do soalho", x, z, .072, .30, .009, .003, WOOD)
        for dx in [-.1,.1]:
            cylinder("Cavilha do soalho", x+dx, z+.06, .074, .009, .003, WOOD, 6)
box("Tapete junto da mesa", -4.9, 9.55, .08, 3.8, 2.7, .025, CLOTH)
box("Centro do tapete", -4.9, 9.55, .095, 3.45, 2.35, .015, TEAL)
for x in [-6.55,-3.25]:
    box("Borda do tapete", x, 9.55, .106, .04, 2.35, .01, OAK)
box("Parede do dormitório", -10.9, 8.7, 1.65, .45, 7.7, 3.3, WALL)
box("Rodapé do dormitório", -10.64, 8.7, .2, .09, 7.5, .3, WOOD)
for z in [5.45,8.6,12.1]:
    box("Viga do dormitório", -10.57, z, 1.7, .2, .18, 3.4, WOOD)
box("Arca da roupa", -3.55, 6.05, .42, 1.4, .85, .84, WOOD)
box("Tampa da arca", -3.55, 6.05, .87, 1.48, .92, .12, OAK)
for x in [-4.03,-3.07]:
    box("Ferragem da arca", x, 6.5, .46, .09, .035, .78, METAL)
box("Prateleira", -10.55, 9.05, 1.65, .45, 1.45, .12, OAK)
for z in [8.6,8.85,9.1,9.35]:
    box("Livro gasto", -10.55, z, 1.9, .35, .16, .42, TEAL if z>9 else RED)
for x, width in [(-9.1, 3.9), (-3.6, 2.1)]:
    box("Parede de saída", x, 5.0, 1.65, width, .3, 3.3, WALL)
arch("Passagem do dormitório", -6.3, 5, 1.9, 3, .4)
for x, z in [(-9.3, 7), (-9.3, 10.6)]:
    box("Cama", x, z, .38, 1.3, 2.5, .5, WOOD)
    box("Colchão", x, z, .68, 1.24, 2.35, .17, CLOTH)
    box("Manta", x, z+.37, .79, 1.27, 1.45, .09, TEAL)
    box("Almofada", x, z-.78, .82, .8, .43, .14, CLOTH)
    for dz in [-1.2, 1.2]:
        box("Cabeceira", x, z+dz, .7, 1.45, .12, 1.15, OAK)
    for dx in [-.4,0,.4]:
        box("Dobra da manta", x+dx, z+.44, .845, .035, 1.28, .035, LEAF[0])
    rounded_box("Roupa dobrada aos pés", x+.15, z+1, .9, .67, .35, .14, CLOTH)
box("Mesa de refeição", -4.2, 9.5, .86, 1.8, 1.1, .16, OAK)
for x in [-4.9, -3.5]:
    for z in [9.13, 9.87]:
        box("Pé da mesa", x, z, .42, .12, .12, .84, WOOD)
for x in [-5.5, -2.9]:
    box("Banco", x, 9.5, .44, .6, .8, .18, OAK)
    for z in [9.22, 9.78]:
        box("Pé do banco", x, z, .2, .12, .12, .4, WOOD)
cylinder("Tigela", -4.5, 9.45, .98, .16, .13, CLOTH)
cylinder("Caneca", -3.85, 9.5, 1.02, .09, .2, OAK)
rounded_box("Tábua do pão", -4.15, 9.42, .965, .45, .38, .04, WOOD, .015)
rounded_box("Pão partido", -4.13, 9.42, 1.05, .27, .23, .16, BREAD, .055)
cylinder("Jarro de água", -3.65, 9.2, 1.13, .13, .38, CLAY)
cylinder("Boca do jarro", -3.65, 9.2, 1.33, .08, .08, CLAY)
for z in [6.1,6.45,6.8]:
    cylinder("Gancho na parede", -10.57, z, 1.5, .035, .18, WOOD, 6)
    rounded_box("Capa de trabalho", -10.42, z, 1.07, .09, .26, .72, TEAL if z<6.5 else CLOTH)

# Departure is visible work, with packs and barrels instead of quest signs.
for i in range(8):
    x, z = 3.2+(i%4)*.85, -8.7+(i//4)*.9
    box("Caixa de viagem", x, z, .32, .7, .7, .64, OAK)
    for dz in [-.24, .24]:
        box("Travessa da caixa", x, z+dz, .66, .76, .07, .05, WOOD)
for x in [-4.5, -3.5, -2.5]:
    cylinder("Barrica", x, -8.9, .57, .43, 1.14, OAK)
    for h in [.18, .9]:
        cylinder("Aro da barrica", x, -8.9, h, .447, .055, METAL)

# Training bay and standard, scaled to humans and seen from the child's gallery.
box("Muro do pátio", 11.8, -1.6, 1.9, .5, 16.5, 3.8, WALL)
for z in [-8, -3, 2]:
    box("Contraforte do pátio", 11.45, z, 1.5, .7, .7, 3, TRIM)
box("Instrumentos de treino", 10.7, .7, .85, .12, 2.4, .12, WOOD)
for z in [-.1, .4, .9, 1.4]:
    box("Vara de treino", 10.55, z, 1.05, .055, .055, 2.1, OAK)
cylinder("Alvo base", 9, -1, .16, .45, .32, WOOD)
box("Alvo tronco", 9, -1, .9, .33, .4, 1.5, OAK)
box("Alvo braços", 9, -1, 1.2, 1.2, .15, .15, WOOD)
box("Haste do estandarte", 10.8, -4, 2.3, .09, .09, 4.6, WOOD)
banner("Estandarte do pátio", 10.3, -3.95, 3.5, .95, 1.55)
box("Travessa do estandarte", 10.3, -4, 4.32, 1.2, .1, .1, WOOD)

# Inaccessible surroundings support the framed view instead of ending in void.
for x,z in [(-15,-7),(-14,4),(15,-9),(16,4),(-6,-17),(8,-18)]:
    branch("Cipreste tronco", (x,-z,-.8), (x,-z,2.8), .14, WOOD)
    foliage("Cipreste", x, z, 3, 1.3, LEAF[0], (.65,.65,2.2))
for x,z in [(-18,-17),(-12,-21),(12,-20),(19,-16)]:
    box("Casa ao longe", x, z, .9, 4, 3.6, 3.5, WALL)
    for side in [-1,1]:
        roof = box("Telhado ao longe", x+side*1.05, z, 3.05, 2.4, 4.0, .18, TILE)
        roof.rotation_euler.y = side*math.radians(25)

# Save the editable environment, then batch static geometry by material for Godot.
bpy.context.scene.frame_start, bpy.context.scene.frame_end = 1, 97
bpy.context.scene.render.fps = 24
bpy.context.scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "convento-infancia.blend"), compress=True)
for mat in list(bpy.data.materials):
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH" and o.data.materials and o.data.materials[0] == mat and not o.data.shape_keys]
    if not meshes:
        continue
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    meshes[0].name = mat.name
bpy.context.scene.frame_start, bpy.context.scene.frame_end = 1, 97
bpy.context.scene.render.fps = 24
bpy.context.scene.frame_set(1)
bpy.ops.export_scene.gltf(filepath=str(ASSETS / "convento.glb"), export_format="GLB", export_animations=True, export_animation_mode="SCENE", export_anim_scene_split_object=False, export_frame_range=True, export_cameras=False, export_lights=False)

# A reusable articulated knight: real pivoted limbs and authored keyframes.
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
root = bpy.data.objects.new("Cavaleiro", None)
bpy.context.collection.objects.link(root)


def part(name, loc, dimensions, mat, parent=root):
    obj = rounded_box(name, 0, 0, 0, *dimensions, mat, bevel=min(.04,min(dimensions)*.12))
    obj.parent = parent
    obj.location = loc
    return obj


part("Botas", (-.16, 0, .14), (.22, .42, .28), WOOD)
part("Botas", (.16, 0, .14), (.22, .42, .28), WOOD)
part("Perna", (-.15, 0, .46), (.22, .24, .52), METAL)
part("Perna", (.15, 0, .46), (.22, .24, .52), METAL)
torso = part("Tabardo", (0, 0, 1.08), (.69, .4, .85), CLOTH)
part("Cinto", (0, -.01, .88), (.72, .44, .09), WOOD)
part("Cruz vertical", (0, -.213, 1.2), (.08, .025, .37), RED)
part("Cruz horizontal", (0, -.22, 1.25), (.3, .025, .08), RED)
cylinder("Elmo", 0, 0, 1.7, .25, .39, METAL)
helmet = bpy.data.objects["Elmo"]
helmet.parent = root
part("Viseira", (0, -.24, 1.72), (.32, .04, .045), WOOD)
for side in [-1, 1]:
    shoulder = bpy.data.objects.new("Braço_E" if side < 0 else "Braço_D", None)
    bpy.context.collection.objects.link(shoulder)
    shoulder.parent = root
    shoulder.location = (side*.44, 0, 1.36)
    part("Manga", (0, 0, -.15), (.24, .3, .35), CLOTH, shoulder)
    elbow = bpy.data.objects.new("Cotovelo_E" if side < 0 else "Cotovelo_D", None)
    bpy.context.collection.objects.link(elbow)
    elbow.parent = shoulder
    elbow.location = (0,0,-.32)
    part("Antebraço", (0,0,-.13), (.19,.25,.29), METAL, elbow)
    part("Manopla", (0, -.04, -.32), (.2, .26, .19), METAL, elbow)
    if side > 0:
        part("Espada de treino", (0, -.1, -.81), (.075, .09, .92), OAK, elbow)
        part("Guarda da espada", (0, -.1, -.42), (.38, .1, .07), WOOD, elbow)
    for frame, angle in [(1, -.25), (16, -.5), (27, -2.05 if side > 0 else -.8), (33, .35), (48, -.25)]:
        shoulder.rotation_euler.x = angle
        shoulder.rotation_euler.y = side * (.15 if frame != 27 else -.3)
        shoulder.keyframe_insert("rotation_euler", frame=frame)
        elbow.rotation_euler.x = -.22 if frame in [1,48] else -.65 if frame==16 else -1.1 if frame==27 else -.08
        elbow.keyframe_insert("rotation_euler", frame=frame)
for frame, angle in [(1, -.1), (16, -.25), (27, -.4), (33, .32), (48, -.1)]:
    root.rotation_euler.z = angle
    root.keyframe_insert("rotation_euler", frame=frame)
scene = bpy.context.scene
scene.frame_start, scene.frame_end, scene.render.fps = 1, 48, 24
scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "cavaleiro-treino.blend"), compress=True)
bpy.ops.export_scene.gltf(filepath=str(ASSETS / "cavaleiro.glb"), export_format="GLB", export_animations=True, export_animation_mode="SCENE", export_anim_scene_split_object=False, export_frame_range=True, export_cameras=False, export_lights=False)
print("CHILDHOOD_CONVENT_BUILT", ASSETS, flush=True)
