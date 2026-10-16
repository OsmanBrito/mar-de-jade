extends SceneTree
const Rules=preload("res://scripts/combat/mar_de_ferro/tactics.gd")
var count:=0
var failures:=0

func check(ok: bool, message: String) -> void:
	count+=1
	if not ok: failures+=1; push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var b=Rules.new()
	var attack: Dictionary={"kind":"attack","targets":[0],"target":0,"cells":[Vector2i(5,3)],"name":"Teste","power":24,"posture":16}
	for face in [0,1,2]:
		b.start("boss"); b.current_id=2; b.heroes[0].cell=Vector2i(5,3); b.heroes[0].face=face
		var preview: Dictionary=b.defense_preview(2,0,attack,2)
		var hp: int=b.heroes[0].hp
		b.resolve_enemy(attack,{0:2})
		check(hp-b.heroes[0].hp==preview.damage,"Defesa coincide com previsão em cada orientação")
		check(b.counters==(1 if face==0 else 0),"Contra-ataque só pela frente")
		check(preview.damage>0 if face==2 else preview.damage==0,"Perfeito pelas costas só reduz dano")
	b.start("training"); b.obstacles.clear(); b.current_id=0
	b.heroes[0].cell=Vector2i(3,3); b.heroes[1].cell=Vector2i(3,4); b.enemies[0].cell=Vector2i(4,4)
	check(b.valid_attack(4,b.heroes[1].cell),"Duarte pode proteger Inês")
	check(not b.valid_attack(4,b.enemies[0].cell),"Protecção não aceita inimigo")
	b.perform(4,b.heroes[1].cell,1)
	check(b.heroes[0].cover_target==1 and b.heroes[0].qi==9,"Protecção gasta alento e regista aliada")
	b.current_id=2; attack.targets=[1]; attack.target=1
	var before_ines: int=b.heroes[1].hp
	var before_duarte: int=b.heroes[0].hp
	var p: Dictionary=b.defense_preview(2,1,attack,0)
	b.resolve_enemy(attack,{1:0})
	check(before_ines-b.heroes[1].hp==p.cover.remaining and before_duarte-b.heroes[0].hp==p.cover.damage,"Protecção divide dano 50%/25%")
	check(p.cover.remaining==int(ceil(p.damage*0.5)) and p.cover.damage==int(ceil(p.damage*0.25)),"Protecção prevista coincide com execução")
	check(b.heroes[0].cover_target==-1,"Protecção consumida uma vez")
	b.heroes[0].cover_target=1; b.heroes[0].cell=Vector2i(0,0)
	check(b.cover_info(1,24).id==-1,"Protecção falha fora de alcance")
	b.heroes[0].cell=Vector2i(3,2); b.obstacles.append(Vector2i(3,3))
	check(b.cover_info(1,24).id==-1,"Obstáculo impede protecção")
	b.start("training"); b.obstacles.clear(); b.current_id=0
	b.heroes[0].cell=Vector2i(4,3); b.heroes[1].cell=Vector2i(4,4); b.enemies[0].cell=Vector2i(5,3)
	b.perform(1,Vector2i(5,3),1)
	check(b.enemies[0].opening==2,"Varrimento de Duarte abre alvo")
	b.current_id=1; b.heroes[1].cell=Vector2i(5,4)
	p=b.predict(1,2,2,1)
	check(p.combo,"Estocada de Inês reconhece abertura")
	var hp: int=b.enemies[0].hp
	var result: Dictionary=b.perform(2,Vector2i(5,3),1)
	check(hp-b.enemies[0].hp==p.damage and b.enemies[0].opening==0,"Combo previsto aplicado e abertura consumida")
	check(result.text.contains("ABERTURA CONSUMIDA"),"Combo tem feedback próprio")

	print("COMBAT_REFERENCE: %d assertions, %d failures"%[count,failures])
	quit(0 if failures==0 else 1)

