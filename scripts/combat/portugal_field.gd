extends RefCounted
## Contextual ground markings, using the same path, cost and target queries as confirmation.
const Board = preload("res://scripts/combat/portugal_board.gd")
const JADE := Color("78c5af")
const GOLD := Color("e2b66c")
const RED := Color("df8370")
const PAPER := Color("eddfbb")
const INK := Color("102c37")
const NEIGHBOURS := [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]

func snapshot(view) -> Dictionary:
	var model = view.model
	var origin: Vector2i = model.current().cell
	var focus: Vector2i = view.preview_cell()
	var state := {"phase":view.phase,"origin":origin,"focus":focus,"reachable":{},"range":{},"targets":[],"area":[],"path":[],"cost":0,"budget":model.current().moves,"valid":false,"reason":"","feedback":{},"threats":[]}
	if view.is_player() and view.phase=="move":
		state.reachable = view.cached_reachable.get("costs",{})
		if model.inside(focus):
			state.path = model.path_to(model.current_id,focus)
			state.valid = not state.path.is_empty()
			if state.path.is_empty() and focus!=origin and model.passable(focus,model.current_id):
				state.path = model.path_to(model.current_id,focus,model.SIZE.x*model.SIZE.y)
			state.cost = state.path.size()
			if focus==origin: state.reason = "Já estás nesta casa."
			elif model.obstacles.has(focus): state.reason = "Um banco bloqueia esta casa."
			elif model.unit_at(focus,model.current_id)>=0: state.reason = "Esta casa está ocupada."
			elif not state.valid: state.reason = "Movimento insuficiente." if not state.path.is_empty() else "Não há caminho até esta casa."
	elif view.is_player() and view.phase=="aim":
		var definition: Dictionary = model.skill_def(model.current_id,view.selected_skill)
		if not definition.is_empty():
			for y in model.SIZE.y:
				for x in model.SIZE.x:
					var cell := Vector2i(x,y)
					if definition.shape=="self":
						if cell==origin: state.range[cell] = true
					elif model.distance(origin,cell)<=model.aim_range(model.current_id,view.selected_skill):
						if definition.shape!="line" or cell.x==origin.x or cell.y==origin.y: state.range[cell] = true
					if view.valid_target_cell(cell): state.targets.append(cell)
			if model.inside(focus):
				state.valid = view.valid_target_cell(focus)
				state.feedback = model.aim_feedback(model.current_id,view.selected_skill,focus)
				state.reason = model.attack_reason(view.selected_skill,focus)
				state.reason = state.reason.replace("Selecciona Inês para a proteger.","Escolhe "+model.units[0].name+" para proteger.")
				if not state.feedback.is_empty(): state.reason = state.feedback.label
				# Do not promise damage for a target rejected by a maneuver's extra constraints.
				if state.valid: state.area = model.area(model.current_id,view.selected_skill,focus)
	if view.phase in ["telegraph","timing_defend","timing_volley"]: state.threats = view.plan.get("cells",[])
	return state

func outline(canvas: Node2D,cell: Vector2i,colour: Color,width := 1.5,inset := 2.0,offset := Vector2.ZERO) -> void:
	var points := Board.polygon(cell,inset)
	for i in points.size(): points[i] += offset
	points.append(points[0])
	canvas.draw_polyline(points,Color(INK,colour.a*0.8),width+2,true)
	canvas.draw_polyline(points,colour,width,true)

func corners(canvas: Node2D,cell: Vector2i,colour: Color,width := 2.0) -> void:
	var points := Board.polygon(cell,1)
	for i in 4:
		var corner := PackedVector2Array([points[i].lerp(points[posmod(i-1,4)],0.27),points[i],points[i].lerp(points[(i+1)%4],0.27)])
		canvas.draw_polyline(corner,Color(INK,0.85),width+2,true)
		canvas.draw_polyline(corner,colour,width,true)

func contour(canvas: Node2D,cells: Dictionary,colour: Color,dashed: bool = false) -> void:
	for cell in cells:
		var points := Board.polygon(cell,0)
		for edge in 4:
			if cells.has(cell+NEIGHBOURS[edge]): continue
			canvas.draw_line(points[edge],points[(edge+1)%4],Color(INK,0.65),3.5,true)
			if dashed: canvas.draw_dashed_line(points[edge],points[(edge+1)%4],colour,1.6,5,true,true)
			else: canvas.draw_line(points[edge],points[(edge+1)%4],colour,1.6,true)

func draw_ground(view,state: Dictionary) -> void:
	var canvas: Node2D = view.host
	var model = view.model
	if view.phase=="move":
		for cell in state.reachable:
			canvas.draw_colored_polygon(Board.polygon(cell,1),Color(JADE,0.11))
			if cell!=state.origin: canvas.draw_circle(Board.screen(cell),1.4,Color(JADE,0.65))
		contour(canvas,state.reachable,Color(JADE,0.9))
		var last := Board.screen(state.origin)
		for i in state.path.size():
			var point := Board.screen(state.path[i])
			var colour: Color = JADE if i<state.budget else RED
			canvas.draw_line(last,point,INK,4.5,true)
			if i<state.budget: canvas.draw_line(last,point,colour,2,true)
			else: canvas.draw_dashed_line(last,point,colour,2,4,true,true)
			last = point
		# Draw labels after every segment, so the next segment cannot cross a number.
		for i in state.path.size():
			var point := Board.screen(state.path[i])
			var colour: Color = JADE if i<state.budget else RED
			canvas.draw_circle(point,7,INK); canvas.draw_arc(point,7,0,TAU,16,colour,1.2,true)
			view.host.centered(str(i+1),point.y+3,9,PAPER,point.x)
		if model.inside(state.focus):
			corners(canvas,state.focus,PAPER if state.valid else RED)
	elif view.phase=="aim":
		contour(canvas,state.range,Color("b3d9df"),true)
		for cell in state.range:
			if model.obstacles.has(cell) or cell==state.origin: continue
			canvas.draw_circle(Board.screen(cell),1.2,Color(PAPER,0.38))
		for cell in state.targets:
			canvas.draw_colored_polygon(Board.polygon(cell,3),Color(GOLD,0.10))
			corners(canvas,cell,Color(GOLD,0.8),1.4)
		for cell in state.area:
			canvas.draw_colored_polygon(Board.polygon(cell,2),Color(GOLD,0.15))
			outline(canvas,cell,GOLD,2.1)
		if model.inside(state.focus): corners(canvas,state.focus,GOLD if state.valid else RED,2.3)
		if not state.feedback.is_empty():
			var point := Board.screen(state.feedback.cell)
			canvas.draw_dashed_line(Board.screen(state.origin),point,Color(RED,0.8),1.4,5,true,true)
	# Mark blocked seats while deciding, preserving their artwork and depth.
	if view.phase in ["move","aim"]:
		for cell in model.obstacles: outline(canvas,cell,Color(RED,0.5),1.0,3)
	for cell in state.threats:
		canvas.draw_colored_polygon(Board.polygon(cell,2),Color(RED,0.14))
		outline(canvas,cell,RED,1.6)
		var points := Board.polygon(cell,4)
		for i in range(1,4): canvas.draw_line(points[0].lerp(points[3],i/4.0),points[1].lerp(points[2],i/4.0),Color(RED,0.65),1,true)
	for hero in model.heroes:
		if hero.hp>0 and model.cover_info(hero.id,4).id>=0:
			var protector: int = model.cover_info(hero.id,4).id
			canvas.draw_dashed_line(Board.screen(model.units[protector].cell),Board.screen(hero.cell),JADE,1.8,5,true,true)
	if view.is_player() and view.phase=="facing":
		var step: Vector2 = Board.screen(state.origin+model.DIRECTIONS[view.facing])-Board.screen(state.origin)
		var direction := step.normalized()
		var point := Board.screen(state.origin)
		canvas.draw_colored_polygon(PackedVector2Array([point+direction*8,point+direction*32+direction.orthogonal()*11,point+direction*32-direction.orthogonal()*11]),Color(GOLD,0.20))
	# Current actor uses a complete jade diamond; targets use gold corner brackets.
	var offset: Vector2 = view.unit_position(model.current_id)-Board.screen(state.origin) if view.phase=="walk" and view.walk_actor==model.current_id else Vector2.ZERO
	outline(canvas,state.origin,JADE if view.is_player() else RED,1.7,2,offset)

func draw_annotations(view,state: Dictionary) -> void:
	var canvas: Node2D = view.host
	if view.phase in ["move","aim"]:
		for cell in view.model.obstacles:
			var point := Board.screen(cell)+Vector2(0,9)
			var focused: bool = state.focus==cell or state.feedback.get("cell",Vector2i(-1,-1))==cell
			var ink := RED if focused else Color(PAPER,0.75)
			canvas.draw_line(point-Vector2(3,3),point+Vector2(3,3),INK,3.5,true)
			canvas.draw_line(point+Vector2(-3,3),point+Vector2(3,-3),INK,3.5,true)
			canvas.draw_line(point-Vector2(3,3),point+Vector2(3,3),ink,1.5,true)
			canvas.draw_line(point+Vector2(-3,3),point+Vector2(3,-3),ink,1.5,true)
	if view.phase=="aim" and not state.feedback.is_empty(): corners(canvas,state.feedback.cell,RED,2.0)
	if not view.is_player() or view.phase not in ["choose","move","aim","facing"]: return
	var label := "G · mover     1 / 2 · ações     T · orientar e terminar"
	if view.phase=="move": label = "Verde · destinos acessíveis     Números · custo do percurso     × · obstáculo"
	elif view.phase=="aim": label = "Tracejado · alcance máximo     Cantos dourados · alvo válido     × · obstáculo"
	elif view.phase=="facing": label = "Q / E · orientar     Enter / A · terminar o turno"
	if view.phase=="aim" and view.model.skill_def(view.model.current_id,view.selected_skill).shape=="self": label = "Próprio personagem · Enter / A confirma a técnica"
	canvas.draw_rect(Rect2(252,392,687,15),Color(INK,0.90))
	view.host.text_at(label,Vector2(263,403),9,PAPER)
