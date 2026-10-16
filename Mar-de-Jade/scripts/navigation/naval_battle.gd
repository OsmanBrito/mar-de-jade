extends RefCounted
## Readable real-time naval encounter; UI pause never advances this simulation.
var player := Vector2(420,520)
var enemy := Vector2(960,390)
var heading := -0.35
var enemy_heading := 2.65
var velocity := Vector2.ZERO
var hull := 100.0
var enemy_hull := 100.0
var enemy_max := 100.0
var sails := 100.0
var guns := 100.0
var boss := false
var reinforced := false
var reloads := [0.0,0.0]
var target_part := "hull"
var clock := 0.0
var attack_clock := 2.0
var warning := 0.0
var aimed_at := Vector2.ZERO
var attack_kind := "volley"
var charge_direction := Vector2.ZERO
var charge_remaining := 0.0
var vulnerable := 0.0
var repair_clock := 0.0
var repaired := 0.0
var retreat := false
var state := "active"
var shots: Array = []
var splashes: Array = []
var note := "Apresenta um flanco ao inimigo. Q: bombordo · E: boreste. Espaço pausa para ordens."
var shot_serial := 0

func begin(is_boss: bool, condition: float, armour: bool) -> void:
	boss = is_boss; hull = condition; reinforced = armour
	enemy_max = 220 if boss else 100; enemy_hull = enemy_max
func side_available(side: int) -> bool:
	var delta := enemy-player
	if delta.length()>540: return false
	var side_dot := Vector2.from_angle(heading).cross(delta.normalized())
	return side_dot < -0.35 if side==0 else side_dot > 0.35
func fire(side: int) -> bool:
	if state!="active" or side not in [0,1]: return false
	if reloads[side]>0: note = "A bateria ainda está a recarregar."; return false
	if not side_available(side): note = "Apresenta esse lado ao alvo e aproxima-te até ao alcance da bateria."; return false
	reloads[side] = 3.8
	var damage := 25.0*(1.55 if vulnerable>0 else (0.68 if boss else 1.0))
	match target_part:
		"sails": sails = maxf(0,sails-damage*1.15); enemy_hull -= damage*0.2
		"guns": guns = maxf(0,guns-damage*1.3); enemy_hull -= damage*0.35
		_: enemy_hull -= damage
	shots.append({"from":player,"to":enemy,"life":0.4,"friendly":true})
	shot_serial += 1
	note = "Bordada! "+{"hull":"Casco atingido.","sails":"Velas atingidas: o alvo perde mobilidade.","guns":"Bateria atingida: o alvo perde poder de fogo."}[target_part]
	_check_result()
	return true
func repair(supplies: float) -> float:
	if state!="active" or repair_clock>0 or repaired>=30 or hull>=99: return 0
	if supplies<8: note = "São necessárias 8 provisões para o reparo de emergência."; return 0
	var amount := minf(18,minf(100-hull,30-repaired))
	hull += amount; repaired += amount; repair_clock = 4
	note = "Reparo de emergência: velocidade reduzida por quatro segundos."
	return 8
func helm(delta: float,rudder: float,sail_level: int) -> void:
	if state!="active": return
	var steerage := maxf(0.35 if sail_level>0 else 0,clampf(velocity.length()/30,0,1))
	heading += clampf(rudder,-1,1)*1.7*steerage*delta
	velocity = Vector2.from_angle(heading)*velocity.length()
	update(delta,Vector2.from_angle(heading)*[0.0,0.45,0.75,1.0][clampi(sail_level,0,3)])
func update(delta: float, direction: Vector2) -> void:
	if state!="active": return
	clock += delta
	for i in 2: reloads[i] = maxf(0,reloads[i]-delta)
	repair_clock = maxf(0,repair_clock-delta); vulnerable = maxf(0,vulnerable-delta)
	for shot in shots: shot.life -= delta
	shots = shots.filter(func(s): return s.life>0)
	for splash in splashes: splash.life -= delta
	splashes = splashes.filter(func(s): return s.life>0)
	velocity = velocity.move_toward(direction.limit_length()*132*(0.55 if repair_clock>0 else 1.0),delta*230)
	player += velocity*delta
	player = player.clamp(Vector2(95,190),Vector2(1345,710))
	if velocity.length()>1: heading = lerp_angle(heading,velocity.angle(),minf(1,delta*3.2))
	if retreat and player.distance_to(Vector2(115,680))<90 and clock>5:
		state = "fled"; return
	if charge_remaining>0:
		enemy += charge_direction*delta*310
		charge_remaining -= delta
		if enemy.distance_to(player)<65:
			hull -= 25*(0.75 if reinforced else 1.0); player -= charge_direction*40; charge_remaining = 0
		if charge_remaining<=0:
			vulnerable = 5; attack_clock = 4; note = "O Quebra-Mar passou! Flancos expostos por cinco segundos."
		enemy = enemy.clamp(Vector2(125,210),Vector2(1315,680))
	elif warning>0:
		warning -= delta
		if warning<=0:
			if attack_kind=="charge":
				charge_direction = (aimed_at-enemy).normalized(); charge_remaining = 1.8; enemy_heading = charge_direction.angle()
			else:
				splashes.append({"at":aimed_at,"life":0.9})
				shots.append({"from":enemy,"to":aimed_at,"life":0.3,"friendly":false})
				shot_serial += 1
				if player.distance_to(aimed_at)<85: hull -= (17 if boss else 13)*(0.45+0.55*guns/100.0)*(0.72 if reinforced else 1.0)
				attack_clock = 3.5 if boss else 4.5
	else:
		attack_clock -= delta
		var direction_to := player-enemy
		var goal := player+direction_to.normalized().orthogonal()*330
		var move := (goal-enemy).limit_length()*delta*(34 if boss else 47)*(0.3+0.7*sails/100.0)
		if move.length()>0.1: enemy_heading = lerp_angle(enemy_heading,move.angle(),delta*2)
		enemy = (enemy+move).clamp(Vector2(150,215),Vector2(1280,670))
		if attack_clock<=0:
			aimed_at = player+velocity*0.35; warning = 2.2 if boss else 1.8
			attack_kind = "charge" if boss and int(clock/6)%2==0 else "volley"
			note = "O Quebra-Mar baixa as velas: sai da linha da carga!" if attack_kind=="charge" else "Bordada anunciada: sai do círculo marcado na água."
	_check_result()
func _check_result() -> void:
	if hull<=0: hull = 0; state = "defeat"
	elif enemy_hull<=15 or sails<=0:
		enemy_hull = maxf(0,enemy_hull); state = "disabled"; note = "Alvo incapacitado. Podes abordar ou encerrar o encontro."
