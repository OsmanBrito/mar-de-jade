extends RefCounted
const Madeira=preload("res://scripts/combat/mar_de_ferro/madeira_world.gd")
## Optional legacy and reopening, separate from mandatory campaign resolution.
const Motifs=preload("res://scripts/combat/mar_de_ferro/maritime_motifs.gd")
const SPAWN=Vector2(170,600)
const PORTALS={5:Madeira.REFUGE,10:Vector2(620,590),11:Vector2(350,430)}
const SITES={"refuge_archive":Vector2(470,430),"refuge_quarters":Vector2(760,570),"refuge_trial":Vector2(1190,430),"refuge_legacy":Vector2(1190,430),"refuge_lessons":Vector2(470,430),"refuge_people":Vector2(760,570),"refuge_supplies":Vector2(940,600),"refuge_threat":Vector2(1190,580),"refuge_wait":Vector2(760,430),"refuge_training":Vector2(760,430)}
const SOLIDS=[Rect2(350,250,240,115),Rect2(640,270,220,90),Rect2(1060,245,240,100)]

const LABELS={"refuge_depart":"Interpretar a rota oculta da Ordem","refuge_exit":"Regressar à viagem","refuge_archive":"Abrir o arquivo","refuge_quarters":"Examinar os aposentos","refuge_trial":"Prova da Rosa · nível 17 recomendado","refuge_legacy":"Recolher o Selo da Primeira Maré","refuge_lessons":"Recuperar os ensinamentos","refuge_people":"Convidar os primeiros aprendizes","refuge_supplies":"Reunir materiais · 120 ouro","refuge_threat":"Defender o arquivo da Ordem","refuge_wait":"Combinar a primeira aula","refuge_training":"Realizar o primeiro treino","albergaria":"Descansar · 35 ouro","regional_shop":"Provisões"}
const DIALOGUES={
	"refuge_defended":[["ines","Os ensinamentos estão a salvo. Já temos as cópias, os materiais e quem queira aprender."],["duarte","E um pátio para os receber. Este lugar pode voltar a ter vida."],["guide","Arquivo defendido. A preparação de Reabrir a Ordem está concluída; falta realizar a primeira aula."]],
	"refuge_wait":[["ines","O arquivo está seguro, mas não quero chamar as famílias enquanto os homens de Esteban ainda as puderem ameaçar."],["duarte","O piloto fica a guardar o refúgio. Concluímos a viagem, entregamos as provas e voltamos para ensinar."]],
	"refuge_depart":[["ines","A marca nas cópias da Vigia também estava nas ruínas da Ordem. Agora a Rosa revela a passagem que faltava."],["duarte","Não se vê passagem nenhuma daqui. Aproxima a Rosa outra vez; eu seguro a carta."],["guide","Refúgio da Primeira Maré · opcional. Prova difícil, recomendada a partir do nível 17. O batel conserva a rota de regresso."]],
	"refuge_archive":[["ines","Olha os nomes: pilotos, curadores... E aqui, um mestre de armas. Quero levar estes exercícios para a escola."],["duarte","Esta página tem os cantos gastos. Alguém a leu muitas vezes. Começamos por ela?"],["guide","Arquivo registado. Nos aposentos há o testemunho de quem guardou este lugar."]],
	"refuge_quarters":[["ines","A carta ficou por enviar. Diz que ainda esperavam a última embarcação... Depois a tinta acaba."],["duarte","Queres levar a carta? A Beatriz talvez reconheça o nome."],
			["ines", "Quero. Com cuidado, que o papel desfaz-se nas pontas."],
			["duarte", "Uso uma das tábuas da caixa. Ajuda-me a passá-la por baixo."],["guide","A Rosa responde à carta. No arsenal, duas memórias sustentam um eco: não são pessoas trazidas de volta à vida."]],
	"refuge_trial":[["guide","O Eco da Primeira Maré recebe menos 40% de dano de vida enquanto restar uma das duas memórias. Derrota ambas, quebra a postura do eco ou aplica Exposto para abrir a defesa. A pressão de postura não é reduzida pelo véu."],["ines","Eu vou aos apoios. Consegues tirar-me esse eco da frente?"],["duarte","Consigo. Mas olha para o chão antes de avançares."]],
	"refuge_legacy":[["guide","Duarte e Inês encontram o Selo da Primeira Maré. A Rosa reconhece a escolha dos dois; o sinal da Ordem passa a acompanhá-los."],["ines","Já não me lembrava de ver este sinal tão nítido. Quero mostrá-lo aos alunos, quando voltarmos a ensinar."],["duarte","Levamos isto para a tua sala. Há-de servir a alguém, em vez de ficar aqui a apanhar humidade."],
			["ines", "Deixa-me ver o teu ombro. A insígnia ficou torcida."],
			["duarte", "Estava a tentar ver a tua."],
			["", "Inês endireita a insígnia. Depois passa os dedos pelo próprio manto, demorando-se na marca da Ordem."],
			["ines", "Passei tanto tempo a procurá-la em papel queimado. É estranho tê-la aqui."],
			["duarte", "Fica-te bem."],
			["ines", "Ainda me estou a habituar. Vamos devagar até ao barco?"],["guide","Legado recebido: duas armas, dois trajes e dois acessórios. A apresentação da dupla muda permanentemente agora; os atributos só mudam se equipares os itens. Nova missão: Reabrir a Ordem."]],
	"refuge_lessons":[["ines","Começamos por estes exercícios: cair sem se ferir, sair de um cerco, proteger a retirada de outra pessoa."],["duarte","Põe aí uma página em branco. Também quero escrever o que correu mal connosco."],["guide","Ensinamentos copiados e preparados para o primeiro treino."]],
	"refuge_people":[["guide","O piloto faz chegar o convite a duas famílias que procuram um lugar para aprender. Os futuros aprendizes aceitam reunir-se quando a rota estiver segura."],["ines","Diz-lhes que podem vir ver a sala primeiro. Não precisam de prometer nada por aceitarem o convite."],["duarte","E quem quiser só aprender a nadar, pode? Eu começava por aí."],
			["ines", "Pode. Mas és tu que organizas essa aula. Eu já tenho as mãos cheias com a sala."],
			["duarte", "Está bem. E se só aparecer uma pessoa?"],
			["ines", "Ensinamos uma pessoa."]],
	"refuge_threat":[["ines","Vieram destruir as cópias e assustar quem aceitou o convite."],["duarte","Não lhes dou a porta. Leva as cópias para dentro, Inês."],["guide","Protege o arquivo. Interrompe o incendiário e desfaz as ordens do sinaleiro. Podes retirar-te e preparar outra tentativa."]],
	"refuge_training":[["guide","Com as provas entregues e a conspiração desfeita, chega o dia combinado. As portas da Ordem recebem os primeiros aprendizes."],["ines","Antes de levantarem as armas, olhem à volta. Precisam de espaço para se mexer sem magoar o colega."],["duarte","Eu e a Inês mostramos primeiro. Devagar, Inês. Ainda estão a aprender... e eu já não caio com tanta graça."],["guide","Reabrir a Ordem · concluída. O primeiro treino dá continuidade ao sonho de Inês. O refúgio permanece aberto."]]
}
static func available(region: int,f: Dictionary) -> bool:
	return PORTALS.has(region) and (f.get("tide_call_awakened",false) or f.get("final_escape",false)) and (region!=10 or f.get("storm_resolved",false))
static func cosmetic(f: Dictionary,kind: String) -> bool:
	return f.get("refuge_legacy",false) and kind in ["duarte","ines"]
static func objective(f: Dictionary) -> String:
	if not f.refuge_archive: return "Explora o arquivo do refúgio"
	if not f.refuge_quarters: return "Lê a carta nos aposentos"
	if not f.refuge_trial: return "Enfrenta a prova da Rosa no arsenal · nível 17 recomendado"
	if not f.refuge_legacy: return "Recolhe o Selo da Primeira Maré no arsenal"
	if not f.refuge_lessons: return "Reabrir a Ordem · copia os ensinamentos do arquivo"
	if not f.refuge_people: return "Reabrir a Ordem · convida os aprendizes nos aposentos"
	if not f.refuge_supplies: return "Reabrir a Ordem · reúne materiais no cais (120 ouro)"
	if not f.refuge_threat: return "Reabrir a Ordem · defende o arquivo no cais oriental"
	if f.refuge_training: return "Ordem reaberta · o refúgio continua disponível"
	if not f.final_testimony: return "Arquivo salvo · volta ao batel e continua a viagem"
	if not f.refuge_training: return "Reabrir a Ordem · realiza o primeiro treino no pátio"
	return "Ordem reaberta · o refúgio continua disponível"
static func return_region(f: Dictionary) -> int:
	return 11 if f.refuge_from_home else (10 if f.refuge_from_storm else 5)
static func next_step(f: Dictionary) -> String:
	if f.refuge_training: return "A primeira aula foi realizada. A Ordem está reaberta e o refúgio permanece acessível."
	if f.final_testimony: return "As provas já foram entregues. Realiza o primeiro treino no pátio central do refúgio, onde os aprendizes já esperam."
	if return_region(f)==11: return "Sai pelo batel, entrega o livro e as cópias na Ordem das Marés e regressa a este pátio para a primeira aula."
	var destination: String="Mar Aberto" if return_region(f)==10 else "Madeira"
	return "O batel regressa a %s. Continua a história até entregar as provas na Ordem das Marés; depois regressa a este pátio para a primeira aula."%destination
static func walkable(p: Vector2) -> bool:
	return Rect2(100,370,1330,280).has_point(p) and not SOLIDS.any(func(r): return r.has_point(p))
static func permitted(id: String,f: Dictionary) -> bool:
	match id:
		"refuge_archive": return not f.refuge_archive
		"refuge_quarters": return f.refuge_archive and not f.refuge_quarters
		"refuge_trial": return f.refuge_quarters and not f.refuge_trial
		"refuge_legacy": return f.refuge_trial and not f.refuge_legacy
		"refuge_lessons": return f.refuge_legacy and not f.refuge_lessons
		"refuge_people": return f.refuge_lessons and not f.refuge_people
		"refuge_supplies": return f.refuge_people and not f.refuge_supplies
		"refuge_threat": return f.refuge_supplies and not f.refuge_threat
		"refuge_wait": return f.refuge_threat and not f.final_testimony and not f.refuge_training
		"refuge_training": return f.refuge_threat and f.final_testimony and not f.refuge_training
	return false
static func nearby(p: Vector2,f: Dictionary) -> String:
	if p.distance_to(SPAWN)<42: return "refuge_exit"
	if p.distance_to(Vector2(300,560))<38: return "albergaria"
	if p.distance_to(Vector2(450,600))<38: return "regional_shop"
	for id in SITES:
		if permitted(id,f) and p.distance_to(SITES[id])<42: return id
	return ""
static func travel(host, destination: int) -> void:
	host.region=destination; host.player=SPAWN if destination==14 else PORTALS[destination]
	host.follower=host.player+Vector2(-28,14); host.camera=Madeira.camera_target(host.player) if host.region==5 else Vector2.ZERO
	if destination==11:
		var home=preload("res://scripts/combat/mar_de_ferro/order_world.gd")
		host.player=home.restore_position(host.player); host.follower=home.restore_position(host.follower)
		host.camera=home.camera_target(host.player)
	host.jump_clock=-1; host.state="world"; host.save_game(false)
static func interact(host,id: String) -> void:
	if id=="refuge_exit":
		travel(host,return_region(host.flags)); return
	if id=="refuge_depart":
		if available(host.region,host.flags): host.show_dialog("REFÚGIO DA PRIMEIRA MARÉ",[],id)
		return
	if host.region!=14 or not permitted(id,host.flags): return
	if id=="refuge_supplies":
		if host.progress.data.gold<120: host.notify_player("Faltam materiais · precisas de 120 ouro."); return
		host.progress.data.gold-=120; host.flags.refuge_supplies=true
		host.save_game(false); host.notify_player("Materiais reunidos. Defende agora o arquivo no cais oriental."); return
	if DIALOGUES.has(id): host.show_dialog("REABRIR A ORDEM" if host.flags.refuge_legacy else "REFÚGIO DA PRIMEIRA MARÉ",[],id)
static func finish(host,id: String) -> void:
	if id=="refuge_depart":
		if not available(host.region,host.flags): return
		host.flags.refuge_from_home=host.region==11; host.flags.refuge_from_storm=host.region==10
		host.flags.refuge_started=true; travel(host,14); return
	if host.region!=14 or not permitted(id,host.flags): return
	if id=="refuge_wait": return # A reminder, never a new saved quest flag.
	if id in ["refuge_trial","refuge_threat"]: host.begin_battle(id); return
	host.flags[id]=true
	if id=="refuge_legacy":
		host.reward_message=host.progress.reward(id)
		host.art.order_legacy=true
		host.begin_order_reveal()
	elif id=="refuge_training": host.reward_message=host.progress.reward(id)
	host.save_game(false)
static func portal(host) -> void:
	if not available(host.region,host.flags): return
	host.world_marker(PORTALS[host.region]-Vector2(0,46),"REFÚGIO · PRIMEIRA AULA" if permitted("refuge_training",host.flags) else "REFÚGIO · ROTA OPCIONAL",host.JADE)
static func draw(host,art,t: float,f: Dictionary) -> void:
	art.regional.begin(host,14); host.draw_set_transform(-host.camera.round())
	var r=art.regional
	r.landscape.draw(14,t,650,Color("b5c3b7"))
	for i in SOLIDS.size(): r.house(SOLIDS[i],i,"chapel" if i==2 else "")
	Motifs.rose(host,Vector2(760,536),103,Color(0.85,0.84,0.67,0.42))
	r.props([Vector2(950,560),Vector2(1000,565)],"crate",Vector2(38,34))
	art.actor(Vector2(300,560),"sailor",t); art.actor(Vector2(450,600),"merchant",t)
	var waiting: bool=permitted("refuge_wait",f)
	host.world_marker(SPAWN-Vector2(0,45),"BATEL · CONTINUAR A VIAGEM" if waiting else "BATEL · REGRESSAR",host.JADE if waiting else host.MUTED)
	host.world_marker(Vector2(300,515),"DESCANSO",host.JADE)
	host.world_marker(Vector2(450,555),"PROVISÕES",host.GOLD)
	host.world_marker(Vector2(465,290),"ARQUIVO",host.PAPER)
	host.world_marker(Vector2(755,300),"APOSENTOS",host.PAPER)
	host.world_marker(Vector2(1180,285),"ARSENAL · A ROSA",host.GOLD)
	for id in SITES:
		if permitted(id,f): host.world_marker(SITES[id]-Vector2(0,34),LABELS[id],host.JADE)
	if f.refuge_threat:
		r.sprite("order-bench",Vector2(660,502),Vector2(86,47))
		r.sprite("order-bench",Vector2(860,502),Vector2(86,47))
		if waiting: art.actor(Vector2(800,450),"sailor",t)
	if f.refuge_training or permitted("refuge_training",f):
		art.actor(Vector2(690,465),"civilian",t); art.actor(Vector2(835,465),"civilian",t)
	if not f.refuge_trial and f.refuge_quarters: art.actor(SITES.refuge_trial,"guardiao",t,false,false,2.2,false,"",0.0,Color(0.66,0.93,0.88,0.80))
	host.draw_world_hero(host.follower,"ines",true); host.draw_world_hero(host.player,"duarte")
	r.flush(); host.draw_set_transform(Vector2.ZERO)
	host.draw_exploration_hud("REFÚGIO DA PRIMEIRA MARÉ")
	if not host.interaction.is_empty() and host.state=="world": host.draw_interaction_prompt(host.interaction,LABELS)

