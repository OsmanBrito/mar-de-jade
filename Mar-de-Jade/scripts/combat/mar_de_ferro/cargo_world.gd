extends RefCounted
const Madeira=preload("res://scripts/combat/mar_de_ferro/madeira_world.gd")
## Optional maritime slice. Existing illustrated environments are reused intentionally.
## This optional voyage retains its existing deck and collision layout.
const DECK_SOLIDS:=[Rect2(300,270,210,120),Rect2(720,315,25,155),Rect2(1040,530,80,70)]
const SHORE=preload("res://scripts/combat/mar_de_ferro/coast_world.gd")
const PORT := Madeira.CARGO
const SPAWN := Vector2(190,580)
const CAPTAIN := Vector2(560,430)
const ROUTE := Vector2(1320,550)
const MANIFEST := Vector2(550,430)
const WITNESS := Vector2(800,580)
const SIGNALS := Vector2(1320,430)
const LABELS := {
	"cargo_depart":"Rota opcional · A carga que não chegou",
	"cargo_home":"Regressar à Madeira", "cargo_boarding":"Repelir a abordagem",
	"cargo_land":"Desembarcar em Porto Santo", "cargo_back":"Voltar ao convés",
	"cargo_manifest":"Examinar os selos da carga", "cargo_witness":"Ouvir a testemunha",
	"cargo_signals":"Recuperar os mantimentos", "cargo_weapon":"Recolher a alabarda e as cópias",
	"cargo_return":"Defender os documentos no regresso", "cargo_done":"Entregar a carga ao piloto",
	"cargo_captain":"Consultar a rota", "albergaria":"Descansar · 35 ouro"
}
const DIALOGUES := {
	"cargo_depart":[["guide","Madeira — Porto Santo. A carga que não chegou · aventura opcional, recomendada a partir do nível 8. Podes interromper a viagem e regressar à Madeira."],["ines","Os recibos dizem que os mantimentos chegaram. O piloto diz que o cais continua vazio."],["duarte","Vamos ver esse cais. Se a farinha chegou, há-de haver alguém que a tenha carregado."]],
	"cargo_boarding":[["ines","Olha o homem na retaguarda. Os outros só avançam quando ele dá o sinal. Consegues tirá-lo dali?"],["duarte","Eu abro espaço no convés. Fica de olho nos ganchos."],["guide","Sinaleiro: prepara a ordem durante um turno. Quebrar, atordoar ou deslocar interrompe-a. Abordador: guarda, cobertura ou defesa perfeita impedem o puxão."]],
	"cargo_manifest":[["ines","Dois selos sobre a mesma cera. Alguém mudou o destino depois da partida."],["duarte","E o saco está remendado por dentro. Transferiram a carga aqui."],["guide","Indício registado: os mantimentos foram desviados para o ancoradouro. Procura quem viu o transbordo."]],
	"cargo_witness":[["guide","A barqueira aponta para o cais oriental. Homens armados pagaram pelo silêncio e levaram farinha e cartas para o armazém."],["ines","Pode esperar junto ao batel. Vamos buscar as cartas. O seu nome não vai para os registos que levarmos."],["guide","Testemunho registado. O acesso aos guardas do ancoradouro está identificado."]],
	"cargo_signals":[["ines","Lá está ele a chamar o besteiro para junto do guarda. Não os deixes juntar-se."],["duarte","Se vierem juntos, consigo apanhá-los com a alabarda. Dá-me espaço."]],
	"cargo_weapon":[["guide","Entre os volumes recuperados está a Alabarda das amarras. O contrapeso permite recuperar o passo depois de um puxão."],["duarte","O contrapeso puxa-me de volta ao sítio. Espera, deixa-me experimentar outra vez. Isto dava jeito no convés."],["ines","Experimenta longe das folhas. Encontrei as contas; o intermediário usava os mesmos sinais dos homens de Esteban."],["guide","Arma recebida. Equipa-a no menu Equipamento: um puxão real concede 1 movimento e recupera 1 alento, uma vez por turno. Há uma última batalha no regresso."]],
	"cargo_return":[["ines","Querem queimar as cópias. Vou cortar o caminho do incendiário."],["duarte","Deixa-me os homens das amarras. Quando tiveres as folhas, chama-me; levo-as para o batel."],["guide","Protege os documentos até vencer. Podes provocar, quebrar ou eliminar o incendiário; derrota ou retirada permitem tentar novamente."]],
	"cargo_done":[["guide","O piloto confere os mantimentos e entrega as cópias a dois destinatários diferentes. A testemunha não é identificada."],["ines","Quero ensinar os alunos a conferir recibos também. O meu pai ia gostar disso."],["duarte","E a pesar os sacos. Estes chegaram com menos farinha do que deviam."],
			["ines", "Então vamos dizer-lhe. Não quero entregar uma conta que já sei estar errada."],
			["duarte", "Eu peso. Tu escreves. Depois comemos alguma coisa que não tenha passado o dia num saco."],
			["ines", "Se encontrares, guarda-me metade."],["guide","A carga que não chegou · concluída. A rota permanece acessível; a aventura não bloqueia a história principal."]]
}
static func objective(f: Dictionary) -> String:
	if not f.cargo_boarding: return "Afasta os abordadores do convés"
	if not f.cargo_manifest: return "Desembarca e examina os selos junto ao armazém"
	if not f.cargo_witness: return "Ouve a barqueira junto ao ancoradouro"
	if not f.cargo_signals: return "Recupera os mantimentos no cais oriental"
	if not f.cargo_weapon: return "Recolhe a alabarda e as cópias no cais oriental"
	if not f.cargo_return: return "Volta ao convés e defende os documentos no regresso"
	if not f.cargo_done: return "Entrega os mantimentos ao piloto no convés"
	return "Carga entregue · regressa à Madeira quando quiseres"
static func walkable(region: int, p: Vector2) -> bool:
	if region!=12: return SHORE.walkable(p)
	if not Rect2(100,250,1360,390).has_point(p): return false
	for area in DECK_SOLIDS:
		if area.has_point(p): return false
	return true
static func nearby(region: int, p: Vector2, f: Dictionary) -> String:
	if region==12:
		if p.distance_to(SPAWN)<45: return "cargo_home"
		if p.distance_to(Vector2(330,430))<45: return "albergaria"
		if p.distance_to(CAPTAIN)<48: return "cargo_done" if f.cargo_return and not f.cargo_done else "cargo_captain"
		if p.distance_to(Vector2(820,430))<50 and not f.cargo_boarding: return "cargo_boarding"
		if p.distance_to(ROUTE)<50 and f.cargo_boarding:
			return "cargo_return" if f.cargo_weapon and not f.cargo_return else "cargo_land"
	else:
		if p.distance_to(SHORE.SPAWN)<50: return "cargo_back"
		if p.distance_to(MANIFEST)<48 and not f.cargo_manifest: return "cargo_manifest"
		if p.distance_to(WITNESS)<48 and f.cargo_manifest and not f.cargo_witness: return "cargo_witness"
		if p.distance_to(SIGNALS)<50 and f.cargo_witness:
			if not f.cargo_signals: return "cargo_signals"
			if not f.cargo_weapon: return "cargo_weapon"
	return ""
static func enter(host, region: int) -> void:
	host.region=region
	host.player=SPAWN if region==12 else (SHORE.SPAWN if region==13 else PORT)
	host.follower=host.player+Vector2(-28,14); host.camera=Madeira.camera_target(host.player) if host.region==5 else Vector2.ZERO
	host.jump_clock=-1; host.state="world"; host.save_game(false)
static func interact(host, id: String) -> void:
	match id:
		"cargo_home": enter(host,5)
		"cargo_back": enter(host,12)
		"cargo_land": enter(host,13)
		"cargo_captain": host.show_dialog("A CARGA QUE NÃO CHEGOU",[objective(host.flags)])
		_:
			if DIALOGUES.has(id): host.show_dialog("A CARGA QUE NÃO CHEGOU",[],id)
static func finish(host, id: String) -> void:
	match id:
		"cargo_depart": host.flags.cargo_started=true; enter(host,12)
		"cargo_boarding", "cargo_signals", "cargo_return": host.begin_battle(id)
		"cargo_manifest", "cargo_witness": host.flags[id]=true; host.save_game(false)
		"cargo_weapon", "cargo_done":
			host.flags[id]=true; host.reward_message=host.progress.reward(id)
			host.save_game(false); host.notify_player(host.reward_message)
static func draw(host, art, t: float, f: Dictionary) -> void:
	art.regional.begin(host,host.region); host.draw_set_transform(-host.camera.round())
	art.regional.draw(12 if host.region==12 else 9,t,f)
	if host.region==12:
		art.actor(CAPTAIN,"sailor",t); art.actor(Vector2(330,430),"civilian",t)
		host.world_marker(SPAWN-Vector2(0,45),"MADEIRA · REGRESSAR",host.MUTED)
		host.world_marker(CAPTAIN-Vector2(0,48),"PILOTO · CARGA",host.JADE)
		host.world_marker(Vector2(330,385),"DESCANSO",host.JADE)
		if not f.cargo_boarding:
			art.actor(Vector2(820,430),"pikeman",t)
			host.world_marker(Vector2(820,380),"ABORDADORES",host.GOLD)
		if f.cargo_boarding: host.world_marker(ROUTE-Vector2(0,50),"DEFENDER AS CÓPIAS" if f.cargo_weapon and not f.cargo_return else "PORTO SANTO · DESEMBARCAR",host.GOLD)
	else:
		host.world_marker(SHORE.SPAWN-Vector2(0,45),"CONVÉS · REGRESSAR",host.MUTED)
		host.world_marker(MANIFEST-Vector2(0,48),"SELOS DA CARGA",host.JADE if f.cargo_manifest else host.GOLD)
		art.actor(WITNESS,"civilian",t); host.world_marker(WITNESS-Vector2(0,45),"BARQUEIRA",host.GOLD)
		if not f.cargo_signals: art.actor(SIGNALS,"medic",t)
		host.world_marker(SIGNALS-Vector2(0,50),"MANTIMENTOS E CARTAS",host.JADE if f.cargo_weapon else host.GOLD)
	if host.follower.y<host.player.y: host.draw_world_hero(host.follower,"ines",true)
	host.draw_world_hero(host.player,"duarte")
	if host.follower.y>=host.player.y: host.draw_world_hero(host.follower,"ines",true)
	art.regional.flush(); host.draw_set_transform(Vector2.ZERO)
	host.draw_exploration_hud("A CARGA QUE NÃO CHEGOU · CONVÉS" if host.region==12 else "PORTO SANTO · ANCORADOURO OCULTO")
	if not host.interaction.is_empty() and host.state=="world": host.draw_interaction_prompt(host.interaction,LABELS)

