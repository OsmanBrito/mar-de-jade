extends Node3D
## Small Blender-authored world, rendered at half resolution; UI stays native.
const Plan = preload("res://scripts/chapter/childhood_home_plan.gd")
const Library = preload("res://scripts/npcs/lisbon_npc_library.gd")
const SIDE_WALK: Texture2D = preload("res://assets/art/portugal-v2/hero-child-side-walk-v1.png")
const SIDE_CELL := 96.0
const VERTICAL_WALK: Texture2D = preload("res://assets/art/portugal-v2/hero-child-vertical-walk-v1.png")
const VERTICAL_PHASES := [0,1,2,3,0,1,2,3]
const VERTICAL_MIRRORED := [false,false,false,false,true,true,true,true]
const REAR_PHASES := [0,3,1,2,0,3,1,2]
const REAR_MIRRORED := [false,true,true,false,true,false,false,true]
const VERTICAL_CELL := 96.0
const STRIDE_LENGTH := 1.25
const WOOD_FLOOR := Rect2(-10.81,5.125,8.0,7.45)
var player: CharacterBody3D
var player_visual: Node3D
var camera: Camera3D
var navigation := AStarGrid2D.new()
var destination_path := PackedVector2Array()
var actors: Dictionary = {}
var sprites: Dictionary = {}
var animation_clock := 0.0
var enabled := true
var step_distance := 0.0
var steps: AudioStreamPlayer
var carried_bowl: MeshInstance3D
var waiting_bowl: Node3D
var target_tome := Vector2(-6.3,8.4)
var knight: Node3D
var water: MeshInstance3D
var camera_target := Vector3.ZERO
var blockers: Array = []
var cutaway_materials: Array[ShaderMaterial] = []
var last_facing := 0
var previous_physics_position := Vector3.ZERO
var current_physics_position := Vector3.ZERO
var visual_position := Vector3.ZERO
var environment_animators: Array[AnimationPlayer] = []

func _ready() -> void:
	var building: Node3D=load("res://assets/models/childhood-convent/convento.glb").instantiate()
	add_child(building);install_cutaway(building)
	for node in building.find_children("*","AnimationPlayer",true,false):
		environment_animators.append(node);play_loop(node)
	var atmosphere := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR; environment.background_color = Color("788779")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b5c4bf"); environment.ambient_light_energy = .38
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	atmosphere.environment = environment; add_child(atmosphere)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-54,-37,0)
	sun.light_color = Color("ffe8c3"); sun.light_energy = .65; sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 55; add_child(sun)
	player = CharacterBody3D.new(); player.name = "Child"; add_child(player)
	player.position = Vector3(Plan.SPAWN.x,floor_height(Plan.SPAWN),Plan.SPAWN.y)
	player_visual=Node3D.new();player_visual.name="Visual";player.add_child(player_visual)
	var shape := CollisionShape3D.new(); var capsule := CapsuleShape3D.new(); capsule.radius = .22; capsule.height = .9
	shape.shape = capsule; shape.position.y = .45; player.add_child(shape)
	actors.hero_child = player; sprites.hero_child = sprite("hero_child",player_visual,1.15)
	contact_shadow(player_visual,.25)
	add_actor("tome_young",Vector2(-6.3,8.4),1.65)
	add_actor("shelter_child",Vector2(-8.4,3.3),1.06)
	add_actor("worker",Vector2(1,-8.2),1.64)
	add_actor("leonor_child",Vector2(0,-8.9),1.18)
	add_actor("friar",Vector2(-8.8,-8.5),1.62,"tome_young")
	knight = load("res://assets/models/childhood-convent/cavaleiro.glb").instantiate()
	knight.position = Vector3(7.5,0,-1.4); knight.rotation.y = -.5; add_child(knight)
	for node in knight.find_children("*","AnimationPlayer",true,false):
		play_loop(node)
	for rect in Plan.obstacles(): solid(rect)
	# Walls separating the bedroom from the galleries have a real open doorway.
	for rect in [Rect2(-11.1,4.8,3.8,.35),Rect2(-5.25,4.8,2.65,.35)]:solid(rect)
	camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size = 15.8
	camera.near = 1.0; camera.far = 65; add_child(camera)
	camera_target = player.position+Vector3(0,.9,-.3); follow_camera(1,true)
	steps = AudioStreamPlayer.new(); steps.stream = load("res://assets/audio/chapter/foley/stone_step.wav")
	steps.bus = GamePreferences.effects_bus; steps.volume_db = -28; add_child(steps)
	carried_bowl = MeshInstance3D.new(); var bowl := CylinderMesh.new(); bowl.top_radius = .14; bowl.bottom_radius = .09; bowl.height = .10
	carried_bowl.mesh = bowl; carried_bowl.position = Vector3(.22,.55,.1); carried_bowl.hide(); player_visual.add_child(carried_bowl)
	var bowl_mat := StandardMaterial3D.new(); bowl_mat.albedo_color = Color("d7c8a0"); carried_bowl.material_override = bowl_mat
	waiting_bowl=Node3D.new();waiting_bowl.position=Vector3(Plan.PLACES.bowl.at.x,floor_height(Plan.PLACES.bowl.at),Plan.PLACES.bowl.at.y);add_child(waiting_bowl)
	var waiting_mesh:=MeshInstance3D.new();waiting_mesh.mesh=bowl;waiting_mesh.position.y=.07;waiting_mesh.material_override=bowl_mat;waiting_bowl.add_child(waiting_mesh)
	var inside:=MeshInstance3D.new();var hollow:=CylinderMesh.new();hollow.top_radius=.11;hollow.bottom_radius=.11;hollow.height=.004;inside.mesh=hollow;inside.position.y=.122
	var dark:=StandardMaterial3D.new();dark.albedo_color=Color("716148");inside.material_override=dark;waiting_bowl.add_child(inside)
	build_navigation()
	if DisplayServer.get_name()!="headless":
		var fountain:=AudioStreamPlayer3D.new();fountain.stream=load("res://assets/audio/chapter/foley/water.wav")
		fountain.position=Vector3(0,.7,-1);fountain.volume_db=-27;fountain.unit_size=4;fountain.max_distance=15
		fountain.bus=GamePreferences.effects_bus;add_child(fountain)
		fountain.finished.connect(fountain.play);fountain.play()
	reset_visual_motion()

func play_loop(animator: AnimationPlayer) -> void:
	for clip in animator.get_animation_list():
		if clip=="RESET":continue
		animator.get_animation(clip).loop_mode=Animation.LOOP_LINEAR;animator.play(clip);break

func add_actor(id: String, point: Vector2, height: float, art_id: String = "") -> void:
	var node := Node3D.new(); node.position = Vector3(point.x,0,point.y); add_child(node)
	node.position.y=floor_height(point)
	actors[id] = node; sprites[id] = sprite(id if art_id.is_empty() else art_id,node,height)
	contact_shadow(node,.28 if height>1.3 else .23)

func contact_shadow(parent: Node3D, radius: float) -> void:
	var node:=MeshInstance3D.new();var disk:=CylinderMesh.new()
	disk.top_radius=radius;disk.bottom_radius=radius;disk.height=.008;disk.radial_segments=16;node.mesh=disk
	var material:=StandardMaterial3D.new();material.albedo_color=Color(.10,.15,.13,.22)
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	node.material_override=material;node.position.y=.015;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(node)

func sprite(id: String, parent: Node3D, height: float) -> Sprite3D:
	var value := Sprite3D.new(); value.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	value.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD; value.alpha_scissor_threshold = .12
	value.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	value.no_depth_test = false; value.shaded = false
	value.set_meta("identity",id); value.set_meta("height",height)
	parent.add_child(value); set_frame(value,0,0); return value

func set_frame(value: Sprite3D, facing: int, frame: int) -> void:
	var id: String = value.get_meta("identity")
	if id=="hero_child" and facing in [1,3] and frame>0:
		var phase:=clampi(frame-1,0,7)
		var index:=200+(8 if facing==1 else 0)+phase
		if int(value.get_meta("frame",-1))==index:return
		value.set_meta("frame",index)
		var atlas:=AtlasTexture.new();atlas.atlas=SIDE_WALK
		atlas.region=Rect2(phase*SIDE_CELL,0,SIDE_CELL,SIDE_CELL)
		value.texture=atlas;value.pixel_size=float(value.get_meta("height"))/SIDE_CELL
		value.offset=Vector2(0,SIDE_CELL*.5);value.flip_h=facing==1
		return
	if id=="hero_child" and facing in [0,2] and frame>0:
		var phase:=clampi(frame-1,0,7)
		var index:=100+(8 if facing==2 else 0)+phase
		if int(value.get_meta("frame",-1))==index:return
		value.set_meta("frame",index)
		var atlas:=AtlasTexture.new();atlas.atlas=VERTICAL_WALK
		var column:int=REAR_PHASES[phase] if facing==2 else VERTICAL_PHASES[phase]
		atlas.region=Rect2(column*VERTICAL_CELL,VERTICAL_CELL if facing==2 else 0,VERTICAL_CELL,VERTICAL_CELL)
		value.texture=atlas;value.pixel_size=float(value.get_meta("height"))/VERTICAL_CELL
		value.offset=Vector2(0,VERTICAL_CELL*.5);value.flip_h=REAR_MIRRORED[phase] if facing==2 else VERTICAL_MIRRORED[phase]
		return
	var entry: Dictionary = Library.data()[id]
	var index := facing*4+frame
	if int(value.get_meta("frame",-1))==index:return
	value.set_meta("frame",index)
	var r: Array = entry.frames[index]; var pivot: Array = entry.pivots[index]
	var atlas := AtlasTexture.new(); atlas.atlas = load(entry.source); atlas.region = Rect2(r[0],r[1],r[2],r[3])
	value.texture = atlas
	value.pixel_size = float(value.get_meta("height"))/float(entry.reference_height)
	# Per-frame feet anchors, not bounding-box centres, prevent floating while walking.
	value.flip_h = bool(entry.west_flip) if facing==1 else bool(entry.get("east_flip",false)) if facing==3 else false
	value.offset = Vector2((float(r[2])*.5-float(pivot[0]))*(-1 if value.flip_h else 1),float(pivot[1])-float(r[3])*.5)

func install_cutaway(building: Node3D) -> void:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
uniform vec4 stone_color : source_color;
uniform float metalness = 0.0;
uniform vec3 child_at;
uniform vec3 camera_at;
uniform vec3 interest_at;
uniform float interest_weight = 0.0;
varying vec3 world_at;
void vertex(){ world_at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
 ALBEDO=stone_color.rgb; ROUGHNESS=0.86; METALLIC=metalness;
 vec3 eye=normalize(camera_at-child_at);
 vec3 relative=world_at-child_at;
 float along=dot(relative,eye);
 float radius=length(relative-along*eye);
 vec3 interest_eye=normalize(camera_at-interest_at);
 vec3 interest_relative=world_at-interest_at;
 float interest_along=dot(interest_relative,interest_eye);
 float interest_radius=length(interest_relative-interest_along*interest_eye);
 float cut_radius=along>0.35?radius:100.0;
 if(interest_weight>0.01 && interest_along>0.35){cut_radius=min(cut_radius,interest_radius+(1.0-interest_weight)*3.0);}
 float grain=fract(sin(dot(floor(FRAGCOORD.xy),vec2(12.9898,78.233)))*43758.5453);
 if(world_at.y>0.26 && cut_radius<0.95 && grain>smoothstep(0.68,0.95,cut_radius)){discard;}
}
"""
	for mesh in building.find_children("*","MeshInstance3D",true,false):
		var original: StandardMaterial3D=mesh.get_active_material(0)
		if original==null:continue
		# Woven crosses have two material surfaces and animated morphs. A global
		# override would paint both cloth and cross the same colour.
		if mesh.get_blend_shape_count()>0:
			for surface in mesh.mesh.get_surface_count():
				var cloth:StandardMaterial3D=mesh.get_active_material(surface)
				if cloth!=null:cloth.cull_mode=BaseMaterial3D.CULL_DISABLED
			continue
		if original.resource_name.begins_with("Água"):
			water=mesh
			var water_shader:=Shader.new()
			water_shader.code="""shader_type spatial;
varying vec3 world_at;
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float ring=sin(length(world_at.xz-vec2(0.0,-1.0))*32.0-TIME*2.5);
 ALBEDO=mix(vec3(0.14,0.30,0.28),vec3(0.32,0.49,0.44),smoothstep(0.75,1.0,ring)*0.55);
 ROUGHNESS=0.28;SPECULAR=0.35;
}
"""
			var water_material:=ShaderMaterial.new();water_material.shader=water_shader;mesh.material_override=water_material
			continue
		var material:=ShaderMaterial.new();material.shader=shader
		material.set_shader_parameter("stone_color",original.albedo_color)
		material.set_shader_parameter("metalness",original.metallic)
		mesh.material_override=material;cutaway_materials.append(material)

func solid(rect: Rect2) -> void:
	blockers.append(rect)
	var node := StaticBody3D.new(); var collision := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(rect.size.x,3,rect.size.y); collision.shape = box
	node.position = Vector3(rect.get_center().x,1.5,rect.get_center().y); node.add_child(collision); add_child(node)

func point() -> Vector2:return Vector2(player.position.x,player.position.z)

func floor_height(at: Vector2) -> float:
	return .072 if WOOD_FLOOR.has_point(at) else .002

func clear(p: Vector2) -> bool:
	if not Plan.clear(p):return false
	for rect in blockers:
		if rect.grow(.23).has_point(p):return false
	return true

func segment_clear(a: Vector2,b: Vector2) -> bool:
	var count := maxi(1,ceili(a.distance_to(b)/.1))
	for i in range(count+1):
		if not clear(a.lerp(b,float(i)/count)):return false
	return true

func build_navigation() -> void:
	navigation.region = Rect2i(0,0,100,100); navigation.cell_size = Vector2(.25,.25); navigation.offset = Vector2(-12,-12)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES; navigation.update()
	for y in 100:
		for x in 100:
			var id := Vector2i(x,y); navigation.set_point_solid(id,not clear(navigation.get_point_position(id)))

func nearest(p: Vector2) -> Vector2i:
	var base := Vector2i(((p-navigation.offset)/.25).round())
	var result := Vector2i(-1,-1); var best := INF
	for y in range(-3,4):
		for x in range(-3,4):
			var id := base+Vector2i(x,y)
			if not navigation.region.has_point(id) or navigation.is_point_solid(id):continue
			var at := navigation.get_point_position(id)
			if p.distance_to(at)<best and segment_clear(p,at):result=id;best=p.distance_to(at)
	return result

func walk_to(p: Vector2) -> bool:
	if not enabled or not clear(p):return false
	var start := nearest(point()); var finish := nearest(p)
	if start.x<0 or finish.x<0:return false
	var grid_path:=navigation.get_point_path(start,finish)
	if grid_path.is_empty():return false
	grid_path.append(p)
	# Walk directly across clear stretches instead of pausing on every grid cell.
	destination_path.clear()
	var cursor:=point();var index:=0
	while index<grid_path.size():
		var farthest:=index
		for candidate in range(index,grid_path.size()):
			if segment_clear(cursor,grid_path[candidate]):farthest=candidate
			else:break
		destination_path.append(grid_path[farthest]);cursor=grid_path[farthest];index=farthest+1
	return true

func stop() -> void:
	destination_path.clear();player.velocity=Vector3.ZERO;animation_clock=0;set_frame(sprites.hero_child,last_facing,0)
	reset_visual_motion()

func reset_visual_motion() -> void:
	player.position.y=floor_height(point())
	previous_physics_position=player.position;current_physics_position=player.position;visual_position=player.position
	player_visual.position=Vector3.ZERO

func motion_facing(motion: Vector2, previous: int) -> int:
	# The four-direction atlas needs a small dead band near diagonal headings.
	if absf(motion.x)>absf(motion.y)*1.15:return 3 if motion.x>0 else 1
	if absf(motion.y)>absf(motion.x)*1.15:return 0 if motion.y>0 else 2
	if previous in [1,3]:return 3 if motion.x>0 else 1
	return 0 if motion.y>0 else 2

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):return
	if player.position.distance_to(current_physics_position)>.001:reset_visual_motion()
	previous_physics_position=player.position
	var direction := Input.get_vector("move_left","move_right","move_up","move_down") if enabled else Vector2.ZERO
	if direction.length()>.1:destination_path.clear()
	elif enabled and not destination_path.is_empty():
		while not destination_path.is_empty() and point().distance_to(destination_path[0])<.035:
			destination_path.remove_at(0)
		if not destination_path.is_empty():direction=point().direction_to(destination_path[0])
	var speed := 4.2 if Input.is_action_pressed("run") else 2.9
	if not destination_path.is_empty():speed=minf(speed,point().distance_to(destination_path[0])/delta)
	var proposed := direction*speed*delta
	if not clear(point()+proposed):
		if clear(point()+Vector2(proposed.x,0)):direction.y=0
		elif clear(point()+Vector2(0,proposed.y)):direction.x=0
		else:direction=Vector2.ZERO
	var before := player.position
	player.velocity = Vector3(direction.x,0,direction.y)*speed;player.move_and_slide()
	player.position.y=floor_height(point());current_physics_position=player.position
	var motion:=Vector2(player.position.x-before.x,player.position.z-before.z)
	var travelled:=motion.length()
	step_distance += travelled
	if step_distance>.6:
		step_distance=fmod(step_distance,.6)
		if DisplayServer.get_name()!="headless":steps.play()
	if travelled>.0001:
		animation_clock=fposmod(animation_clock+travelled/STRIDE_LENGTH,1.0)
		last_facing=motion_facing(motion,last_facing)
		var frame:int=1+int(animation_clock*8)
		set_frame(sprites.hero_child,last_facing,frame)
	else:animation_clock=0;set_frame(sprites.hero_child,last_facing,0)
	var tome: Node3D = actors.tome_young
	var tome_at := Vector2(tome.position.x,tome.position.z)
	if tome_at.distance_to(target_tome)>.05:
		var at := tome_at.move_toward(target_tome,delta*1.5);tome.position=Vector3(at.x,floor_height(at),at.y)
		set_frame(sprites.tome_young,3,1+int(fmod(Time.get_ticks_msec()*.006,3)))
	else:set_frame(sprites.tome_young,0,0)

func _process(delta: float) -> void:
	if not is_instance_valid(camera) or not is_instance_valid(player_visual):return
	# Only this new scene interpolates its presentation; campaign physics is unchanged.
	if player.position.distance_to(current_physics_position)>.001:reset_visual_motion()
	visual_position=previous_physics_position.lerp(current_physics_position,clampf(Engine.get_physics_interpolation_fraction(),0,1))
	player_visual.position=visual_position-player.position
	follow_camera(delta)

func follow_camera(delta: float, snap: bool = false) -> void:
	if snap:reset_visual_motion()
	var reveal:=smoothstep(3.8,8.5,-visual_position.z)
	var target := visual_position+Vector3(0,.8+reveal*1.3,-.4-reveal*1.1)
	# Tight near the bed; the courtyard's scale is discovered by moving through it.
	target.x=clampf(target.x,-5.8,7.0); target.z=clampf(target.z,-9.2,8.8)
	camera_target=target if snap else camera_target.lerp(target,1-exp(-delta*4))
	camera.position=camera_target+Vector3(0,17,21);camera.look_at(camera_target)
	camera.size=lerpf(camera.size,11.3 if player.position.z>4.7 else lerpf(13.2,16.0,reveal),1.0 if snap else 1-exp(-delta*2))
	# Keep the person the child is approaching readable through the same arch.
	# Otherwise the player was visible but Leonor's head remained behind stone.
	var interest:=visual_position+Vector3(0,.7,0)
	var interest_weight:=0.0;var nearest_actor:=3.0
	for id in actors:
		if id=="hero_child":continue
		var actor:Node3D=actors[id]
		var distance:float=point().distance_to(Vector2(actor.position.x,actor.position.z))
		if distance<nearest_actor:
			nearest_actor=distance;interest=actor.position+Vector3(0,float(sprites[id].get_meta("height"))*.6,0)
			interest_weight=1.0-smoothstep(1.3,3.0,distance)
	for material in cutaway_materials:
		material.set_shader_parameter("child_at",visual_position+Vector3(0,.7,0))
		material.set_shader_parameter("camera_at",camera.position)
		material.set_shader_parameter("interest_at",interest)
		material.set_shader_parameter("interest_weight",interest_weight)
