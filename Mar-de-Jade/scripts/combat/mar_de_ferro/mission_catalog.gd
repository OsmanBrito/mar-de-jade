extends RefCounted
## Campaign-facing data. Maps and dialogue may consume these IDs without coupling to combat code.

const REGIONS := {
	"refuge":14,
	"cargo_deck":12, "cargo_shore":13,
	"mist_port": 0,
	"cove": 1,
	"lisbon": 2,
	"oporto": 3,
	"saint_roman": 4,
	"madeira": 5,
	"vigia": 6,
	"iron_tide": 7,
	"ceuta": 8, "coast":9, "storm":10, "home":11
}
const PLAYABLE_REGIONS := [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14]

const REGION_NAMES := {
	14:"Refúgio da Primeira Maré",
	12:"Rota de Porto Santo · Convés", 13:"Porto Santo · Ancoradouro oculto",
	0: "Porto da Bruma",
	1: "Enseada das Duas Escolas",
	2: "Lisboa · Ribeira das Naus",
	3: "Porto · Ribeira",
	4: "São Romão",
	5: "Madeira · Ponta do Sol",
	6: "Ilha da Vigia",
	7: "Nau de Esteban · Maré Partilhada", 11:"Ordem das Marés · Depois da tempestade",
	8: "Ceuta · Duas margens", 9:"Costa de Ceuta · O preço de acreditar", 10:"Mar aberto · Rumo à tempestade"
}

# Every persisted story switch belongs here. New acts add fields here, never ad-hoc
# keys in the map controller. `cove_choice` and `yusuf_outcome` are bounded values.
const FLAG_DEFAULTS := {
	"refuge_started":false,"refuge_from_home":false,"refuge_from_storm":false,
	"refuge_archive":false,"refuge_quarters":false,"refuge_trial":false,"refuge_legacy":false,
	"refuge_lessons":false,"refuge_people":false,"refuge_supplies":false,"refuge_threat":false,"refuge_training":false,
	"cargo_started":false, "cargo_boarding":false, "cargo_manifest":false, "cargo_witness":false,
	"cargo_signals":false, "cargo_weapon":false, "cargo_return":false, "cargo_done":false,
	"final_book":false, "final_rhythm":false, "final_esteban":false, "final_escape":false,
	"final_testimony":false, "final_wedding":false,
	"storm_entered":false, "storm_escort":false, "storm_reef":false, "storm_port":false,
	"storm_starboard":false, "storm_balanced":false, "storm_mate":false, "storm_resolved":false,
	"coast_entered":false, "coast_convoy":false, "coast_yusuf":false, "coast_resolved":false,
	"ceuta_entered":false, "ceuta_nadira":false, "ceuta_patrol":false,
	"ceuta_hostages":false, "ceuta_receipt":false, "ceuta_testimony":false,
	"ceuta_depot":false, "ceuta_resolved":false,
	"prologue":false, "training":false, "patrol":false, "secret":false,
	"chest":false, "gate":false, "boss":false, "manual":false, "bridge":false,
	"casa_docs":false, "casa_room":false, "casa_visited":false,
	"cove_entered":false, "cove_cache":false, "cove_trial":false,
	"cove_resolved":false, "armada_trust":false, "lastro_trust":false,
	"cove_manifest":false, "cove_departure_seen":false,
	"cove_choice":0, "cove_trial_stage":0,
	"lisbon_entered":false, "lisbon_samira":false, "lisbon_pursuit":false,
	"lisbon_ledger":false, "lisbon_fire":false, "lisbon_avelar":false,
	"lisbon_resolved":false, "lisbon_departure_seen":false,
	"oporto_entered":false, "leonor_met":false, "douro_blockade":false,
	"roman_entered":false, "roman_rescued":false, "roman_both_groups":false,
	"yusuf_outcome":"unresolved", "stronghold_route":"", "stronghold":false,
	"catarina_captured":false, "coastal_letters":false, "oporto_resolved":false,
	"madeira_entered":false, "vigia_entered":false, "rui_joined":false, "vigia_briefing":false,
	"vigia_sentinel":false, "vigia_water_a":0, "vigia_water_b":0, "vigia_water_c":0,
	"vigia_gate":false, "vigia_guard_defeated":false, "vigia_archive":false,
	"vigia_escape_stage":0, "rui_rescued":false, "martim_dead":false,
	"tide_call_awakened":false, "c05_resolved":false, "after_wave_seen":false,
	"iron_tide_entered":false, "final_boarding":false, "alvaro":false,
	"epilogue_seen":false
}

# Tactical objectives are declared by content ID. The combat model reads only this
# dictionary; it no longer needs to know a district or character from the map.
# Optional detours never replace or fail the main mission. Paid on first victory.
const OPTIONAL_OBJECTIVES := {
	"lisbon_fire":{"title":"Cópia dos livros","cell":Vector2i(7,2),"deadline":4,"gold":45,"item":"qi","detail":"Recupera o maço antes de a fumaça o alcançar.","effect":"copy"},
	"douro_blockade":{"title":"Amarra de socorro","cell":Vector2i(5,7),"deadline":4,"gold":55,"item":"heal","detail":"Solta a amarra: recupera até 25 de integridade da barca.","effect":"repair"},
	"ceuta_depot":{"title":"Cortar as ordens","cell":Vector2i(7,2),"deadline":4,"gold":60,"item":"qi","detail":"Recolhe o selo de comando para retirar a protecção do chefe.","effect":"orders"}
}

const TACTICAL_OBJECTIVES := {
	"refuge_threat":{"kind":"protect","actor_id":2,"asset_cell":Vector2i(7,3),"hp":170,"max_hp":170,"title":"DEFENDE OS ENSINAMENTOS","detail":"Interrompe o incendiário e desfaz a ordem do sinaleiro.","action_name":"Queimar o arquivo","approach_name":"Alcançar o arquivo","damage":28,"damage_text":"Arquivo · integridade %d/%d"},
	"cargo_return":{"kind":"protect","actor_id":2,"asset_cell":Vector2i(7,3),"hp":150,"max_hp":150,"title":"SALVA OS DOCUMENTOS","detail":"Afasta o incendiário das cópias. O sinaleiro fortalece os seus aliados.","action_name":"Queimar as cópias","approach_name":"Alcançar os documentos","damage":25,"damage_text":"Documentos · integridade %d/%d"},
	"final_esteban":{"kind":"changing_deck", "actor_id":2, "deck_phase":1, "deck_cells":[], "title":"ESTEBAN · CONVÉS SOB TEMPESTADE", "detail":"O mastro e a carga alteram as passagens a cada fase. Sai das casas anunciadas e conserva as provas."},
	"coast_convoy":{"kind":"escort", "asset_cell":Vector2i(1,4), "exit":Vector2i(8,4), "hp":210, "max_hp":210, "progress":0, "title":"RETIRADA CIVIL", "detail":"Abre a passagem para o batel de Nadira.", "siege_ids":[2,5], "siege_damage":25, "asset_name":"BATEL DOS REFUGIADOS"},
	"coast_yusuf":{"kind":"duel_rescue", "actor_id":2, "title":"CONFRONTA YUSUF", "detail":"Quebra o confronto para que Yusuf veja quem ordenou a represália.", "rescue":{"kind":"protect", "actor_id":3, "asset_cell":Vector2i(7,3), "hp":150, "max_hp":150, "title":"PROTEGE A RETIRADA", "detail":"Yusuf abriu a passagem. Impede o incendiário de alcançar as famílias.", "asset_kind":"civilians", "action_name":"Incendiar a retirada", "approach_name":"Aproximar-se das famílias", "damage":25, "damage_text":"Retirada em perigo · segurança %d/%d"}},
	"ceuta_depot": {
		"kind":"protect", "actor_id":2, "asset_cell":Vector2i(7,3), "hp":125, "max_hp":125,
		"title":"PROTEGE O REGISTO DE PAGAMENTOS", "detail":"Interrompe o incendiário antes que destrua as contas das duas margens.",
		"action_name":"Queimar os registos", "approach_name":"Aproximar-se dos registos",
		"damage":25, "damage_text":"Registos em perigo · integridade %d/%d"
	},
	"douro_blockade": {
		"kind":"escort", "asset_cell":Vector2i(1,4), "exit":Vector2i(8,4), "hp":180, "max_hp":180,
		"progress":0, "title":"ESCOLTA NO DOURO", "detail":"Protege a barca civil até à margem leste; o avanço pára sob ameaça.",
		"siege_ids":[2,5], "siege_damage":30, "asset_name":"BARCA CIVIL"
	},
	"lisbon_pursuit": {
		"kind":"capture", "actor_id":2, "exit":Vector2i(8,3), "escaped":false,
		"title":"CAPTURA O MENSAGEIRO", "detail":"Derrota, quebra ou atordoa antes da fuga.",
		"flee_name":"Desaparecer entre os cais", "move_name":"Correr para a saída",
		"escaped_text":"O mensageiro desaparece com o selo entre os cais.",
		"near_exit_text":"O mensageiro alcança a saída. Impede-o antes do próximo turno!"
	},
	"lisbon_fire": {
		"kind":"protect", "actor_id":2, "asset_cell":Vector2i(7,3), "hp":100, "max_hp":100,
		"title":"PROTEGE OS LIVROS", "detail":"Neutraliza o incendiário antes que as provas ardam.",
		"action_name":"Atear fogo aos livros", "approach_name":"Aproximar-se dos livros",
		"damage":34, "damage_text":"Os livros ardem · integridade %d/%d"
	}
}

# Reusable mission vocabulary; implemented rules consume the encounter definitions above.
# multi_interact and phase_unlock remain available for later map-specific missions.
const OBJECTIVE_TEMPLATES := {
	"escort": {"kind":"escort", "requires":"asset_id, exit, hp, max_hp", "wins":"asset reaches exit", "fails":"asset hp reaches zero"},
	"multi_interact": {"kind":"multi_interact", "requires":"sites, hold_turns", "wins":"all sites completed", "fails":"all protected zones lost"},
	"capture": {"kind":"capture", "requires":"actor_id, exit", "wins":"target defeated, broken or stunned", "fails":"target escapes"},
	"phase_unlock": {"kind":"phase_unlock", "requires":"key_actor, interact_cell, boss_id", "wins":"boss defeated after unlock", "fails":"party defeated"}
}

static func defaults() -> Dictionary:
	return FLAG_DEFAULTS.duplicate(true)

static func normalized_flags(raw: Variant) -> Dictionary:
	if not raw is Dictionary: return defaults()
	var result := defaults()
	for key in FLAG_DEFAULTS:
		if not raw.has(key): continue
		if key=="cove_trial_stage":
			if raw[key] is int or raw[key] is float: result[key]=clampi(int(raw[key]),0,4)
		elif key=="cove_choice":
			if raw[key] is int or raw[key] is float: result[key]=clampi(int(raw[key]),0,2)
		elif key in ["vigia_water_a","vigia_water_b","vigia_water_c"]:
			if raw[key] is int or raw[key] is float: result[key]=posmod(int(raw[key]),4)
		elif key=="vigia_escape_stage":
			if raw[key] is int or raw[key] is float: result[key]=clampi(int(raw[key]),0,3)
		elif key=="yusuf_outcome":
			if raw[key] in ["unresolved","ignored","proof","force"]: result[key]=raw[key]
		elif key=="stronghold_route":
			if raw[key] in ["","armada","lastro"]: result[key]=raw[key]
		elif raw[key] is bool:
			result[key]=raw[key]
	# Reaching Lisbon on an older save proves the former cove exit was completed.
	if result.lisbon_entered:
		result.cove_manifest=true
		result.cove_departure_seen=true
	if result.cove_trial: result.cove_trial_stage=4
	return result

static func valid_flags(raw: Variant) -> bool:
	if not raw is Dictionary: return false
	for key in FLAG_DEFAULTS:
		# These flags were added after saves existed. Missing values migrate to defaults.
		if not raw.has(key):
			if key.begins_with("refuge_") or key.begins_with("cargo_") or key.begins_with("ceuta_") or key.begins_with("coast_") or key.begins_with("storm_") or key.begins_with("final_"): continue
			if key in ["casa_docs","casa_room","cove_manifest","cove_departure_seen","cove_trial_stage","lisbon_departure_seen","madeira_entered","vigia_entered","rui_joined","vigia_briefing","vigia_sentinel","vigia_water_a","vigia_water_b","vigia_water_c","vigia_gate","vigia_guard_defeated","vigia_archive","vigia_escape_stage","rui_rescued","martim_dead","tide_call_awakened","c05_resolved","after_wave_seen"]: continue
			return false
		var value=raw[key]
		if key=="cove_trial_stage":
			if not (value is int or value is float) or int(value)!=value or value<0 or value>4: return false
		elif key=="cove_choice":
			if not (value is int or value is float) or int(value)!=value or value<0 or value>2: return false
		elif key in ["vigia_water_a","vigia_water_b","vigia_water_c"]:
			if not (value is int or value is float) or int(value)!=value or value<0 or value>3: return false
		elif key=="vigia_escape_stage":
			if not (value is int or value is float) or int(value)!=value or value<0 or value>3: return false
		elif key=="yusuf_outcome":
			if value not in ["unresolved","ignored","proof","force"]: return false
		elif key=="stronghold_route":
			if value not in ["","armada","lastro"]: return false
		elif not value is bool:
			return false
	return true

static func objective_for(encounter: String) -> Dictionary:
	return TACTICAL_OBJECTIVES.get(encounter,{}).duplicate(true)

static func region_name(id: int) -> String:
	return REGION_NAMES.get(id,"Costa desconhecida")

static func porto_ready(flags: Dictionary) -> bool:
	for flag in ["cove_manifest","lisbon_samira","lisbon_pursuit","lisbon_ledger","lisbon_fire","lisbon_avelar","lisbon_resolved","lisbon_departure_seen"]:
		if not flags.get(flag,false): return false
	return bool(flags.get("armada_trust",false)) != bool(flags.get("lastro_trust",false))

static func main_objective(region: int, flags: Dictionary, quest: int) -> String:
	if region==14: return preload("res://scripts/combat/mar_de_ferro/refuge_world.gd").objective(flags)
	if region in [12,13]: return preload("res://scripts/combat/mar_de_ferro/cargo_world.gd").objective(flags)
	match region:
		REGIONS.home:
			if not flags.final_testimony: return "Entrega o livro e as cópias na Ordem das Marés"
			if not flags.final_wedding: return "Partilha com Inês a primeira manhã depois da vitória"
			if not flags.epilogue_seen: return "Ouve a história de Rui, cinco anos depois"
			return "Viagem concluída · a Ordem voltou a ter futuro"
		REGIONS.storm:
			if not flags.storm_escort: return "Afasta a escolta de Esteban do convés"
			if not flags.storm_balanced: return "Ajusta a vela e o lastro; confirma a estabilidade no leme"
			if not flags.storm_mate: return "Enfrenta o imediato junto à proa"
			if not flags.storm_resolved: return "Encontra Inês junto à cabine e fala do futuro"
			return "Segue pela proa para abordar a nau de Esteban"
		REGIONS.coast:
			if not flags.coast_convoy: return "Escolta as famílias no ancoradouro da costa"
			if not flags.coast_yusuf: return "Encontra Yusuf na passagem do sinal"
			if not flags.coast_resolved: return "Volta a Nadira no abrigo e confirma a retirada"
			return "Embarca no ancoradouro para a travessia oceânica"
		REGIONS.ceuta:
			if not flags.ceuta_nadira: return "Encontra Nadira no pátio do cais oriental"
			if not flags.ceuta_patrol: return "Abre a passagem junto à porta da costa"
			if not flags.ceuta_hostages: return "Liberta os reféns no pátio das cordas"
			if not flags.ceuta_testimony: return "Ouve o testemunho dos sobreviventes junto a Nadira"
			if not flags.ceuta_receipt: return "Compara o recibo na banca de Samira"
			if not flags.ceuta_depot: return "Protege os registos no entreposto oriental"
			if not flags.ceuta_resolved: return "Leva as contas a Nadira e estabelece os termos da travessia"
			return "Segue pela estrada oriental para defender a costa"
		REGIONS.lisbon:
			if not flags.lisbon_samira: return "Leva o rol da Enseada a Samira, junto aos barcos de carreira"
			if not flags.lisbon_pursuit: return "Intercepta o mensageiro das bandeiras falsas"
			if not flags.lisbon_ledger: return "Procura o armazém marcado com meia lua"
			if not flags.lisbon_fire: return "Protege os livros do incêndio"
			if not flags.lisbon_avelar: return "Confronta Rui de Avelar no terreiro"
			if flags.get("lisbon_departure_seen",false): return "Embarca no cais norte para a Ribeira do Porto"
			return "Lisboa concluída · próxima escala: Ribeira do Porto"
		REGIONS.cove:
			if not flags.cove_resolved and flags.cove_choice==2: return "Volta a Afonso · prova %d/4 do Lastro"%clampi(int(flags.get("cove_trial_stage",0))+1,1,4)
			if not flags.cove_resolved: return "Fala com Afonso e decide o destino da enseada"
			if not flags.cove_manifest: return "Lê o rol de cargas junto ao batel · arca opcional na varanda" if not flags.cove_cache else "Lê o rol de cargas junto ao batel"
			return "Embarca no cais oriental para Lisboa · arca opcional na varanda" if not flags.cove_cache and not flags.cove_departure_seen else "Embarca no cais oriental para Lisboa"
		REGIONS.oporto:
			if not flags.leonor_met: return "Encontra Leonor na Ribeira do Porto"
			if not flags.douro_blockade: return "Protege a embarcação de civis no bloqueio do Douro"
			if not flags.roman_entered: return "Parte com Mafalda para São Romão"
			if not flags.roman_both_groups: return "Liberta os dois grupos de moradores em São Romão"
			if not flags.oporto_resolved: return "Confronta Catarina na torre e leva-a a julgamento"
			return "Porto concluído · consulta a rota para Madeira"
		REGIONS.saint_roman:
			if not flags.roman_rescued: return "Defende os moradores junto à capela"
			if not flags.roman_both_groups: return "Liberta os moradores na casa do moinho"
			if not flags.stronghold: return "Confronta Catarina na torre de São Romão"
			if not flags.oporto_resolved: return "Reúne as cópias e garante o julgamento de Catarina"
			return "São Romão protegida · regressa à Ribeira do Porto"
		REGIONS.madeira:
			if not flags.madeira_entered: return "Fala com Martim e conhece Rui da Costa no acampamento"
			if not flags.vigia_briefing: return "Fala com Rui da Costa e prepara a travessia para a Ilha da Vigia"
			if not flags.c05_resolved: return "Explora a Ilha da Vigia e recupera o arquivo da Rosa de Sal"
			if not flags.after_wave_seen: return "Fala com Rui no acampamento e prepara a próxima viagem"
			return "Capítulo concluído · a próxima rota segue para Ceuta"
		REGIONS.vigia:
			if int(flags.vigia_escape_stage)==2: return "Segue com Rui até ao batel na praia"
			if int(flags.vigia_escape_stage)==1: return "Liberta Rui no armazém e leva-o até ao batel"
			if not flags.vigia_sentinel: return "Vence a sentinela e abre caminho pela galeria exterior"
			if not flags.vigia_gate: return "Alinha os canais: I ↓, II ↑, III ←"
			if not flags.vigia_guard_defeated: return "Enfrenta o guardião do arquivo"
			if not flags.vigia_archive: return "Recolhe a Rosa de Sal e copia o arquivo"
			if int(flags.vigia_escape_stage)<2: return "Resgata Rui e alcança o batel antes da explosão"
			return "Foge da Ilha da Vigia"
		REGIONS.iron_tide:
			if not flags.final_boarding: return "Abre a passagem até à cabine das ordens"
			if not flags.final_book: return "Recupera o livro de bordo antes de enfrentar Esteban"
			if not flags.final_rhythm: return "Encontra Inês e dá ritmo ao Chamado da Maré"
			if not flags.final_esteban: return "Enfrenta Esteban sem abandonar as provas e a tripulação"
			return "Recupera a Rosa e protege a retirada junto à proa"
	if quest==0: return "Fala com Beatriz sobre o selo encontrado na nau"
	if quest==1: return "Recupera a encomenda a leste da ponte"
	if quest==2: return "Leva a encomenda e o selo a Beatriz"
	if not flags.training: return "Treina com o discípulo do cais"
	if not flags.bridge: return "Salta a ponte partida para leste"
	if not flags.patrol: return "Vence a patrulha da névoa"
	if not flags.boss: return "Enfrenta o Mestre de Ferro"
	if not flags.casa_visited: return "Explora as ruínas da Ordem das Marés com Inês"
	if flags.boss and not flags.cove_entered: return "Embarca no batel do cais para descobrir a enseada"
	return "Prova concluída · explora os segredos do porto"

