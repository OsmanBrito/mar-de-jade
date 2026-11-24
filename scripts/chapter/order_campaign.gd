extends RefCounted
## Optional institutional arc. No autoload references during preload.
const Studies=preload("res://scripts/combat/order_studies.gd")
const Book=preload("res://scripts/chapter/order_techniques.gd")
const FIRST={"ES":"ES07","LA":"LA07","MC":"MC08","FO":"FO07","PU":"PU07"}
const ROWS={
	"grandmaster":{"at":Vector2(480,-555),"title":"Sala do Capítulo · Grão-Mestre"},
	"commander":{"at":Vector2(175,-520),"title":"Sala do Capítulo · Comendador da casa"},
	"order_ledger":{"at":Vector2(335,-690),"title":"Arquivo · Guia da carga da Ordem"}
}
const CITY_ROWS={
	"order_manifest":{"at":Vector2(1500,1050),"title":"Carga da Ordem · Manifesto do pontão"},
	"order_recipient":{"at":Vector2(360,995),"title":"Carga da Ordem · Ouvir a destinatária"}
}
static func rows(map) -> Dictionary:
	if map.has_meta("order_convent"):
		var result: Dictionary=ROWS.duplicate(true)
		var p=map.get_node_or_null("/root/ChapterProgress")
		if p!=null and p.completed:result.erase("grandmaster")
		return result
	return CITY_ROWS if map.has_meta("continuous_lisbon") and map.get("childhood")!=true else {}
static func ready(p) -> bool:
	if p.flags.get("order_intro_started",false):return p.flags.get("order_reported",false)
	return p.flags.get("order_reported",false) or p.flags.get("house_adult_done",false) or p.flags.get("patient_helped",false)
static func cargo_stage(p) -> String:
	if p.flags.get("order_cargo_done",false):return "done"
	if not p.flags.get("order_cargo_asked",false):return ""
	for flag in ["order_cargo_ledger","order_cargo_manifest","order_cargo_recipient"]:
		if not p.flags.get(flag,false):return flag.trim_prefix("order_cargo_")
	return "report"
static func objective(p) -> String:
	return {"":"Apresenta-te à liderança na Sala do Capítulo, pelo corredor da secretaria.","ledger":"Consulta a autorização de entrega no arquivo da Sala do Capítulo.","manifest":"Confere o manifesto no pontão nascente: quem autorizou mudar o destino da carga?","recipient":"Ouve a responsável da cozinha da Ribeira e recolhe o recibo da entrega urgente.","report":"Regressa à Sala do Capítulo: decide se é preciso enviar uma reposição à cozinha.","done":"A entrega urgente ficou documentada. Duas caixas chegaram à enfermaria; a cozinha não receberá uma reposição duplicada."}[cargo_stage(p)]
static func target(p) -> Dictionary:
	if p.choices.get("tracked_request","")=="ORDER-PRACTICE":return {"at":Vector2(-850,920),"city":false}
	var id: String={"":"grandmaster","ledger":"order_ledger","manifest":"order_manifest","recipient":"order_recipient","report":"grandmaster","done":"grandmaster"}[cargo_stage(p)]
	if id=="grandmaster" and p.completed:id="commander"
	return {"at":(CITY_ROWS if CITY_ROWS.has(id) else ROWS)[id].at,"city":CITY_ROWS.has(id)}
static func response(id: String,text: String,actions: Array=[]) -> Dictionary:
	return {"title":(CITY_ROWS if CITY_ROWS.has(id) else ROWS)[id].title,"text":text,"hub_id":id,"actions":actions}
static func extend(p,id: String,row: Dictionary,young: bool) -> Dictionary:
	if young:return row
	if id in ["services","registry","study"]:
		row.text+="\n\nPara treinares, procura o instrutor na armaria, no pátio sul. Podes combater e voltar ao teu serviço sem gastar provisões. A Sala do Capítulo fica a norte da secretaria."
		row.actions.append(["Indicar o caminho para o treino livre","order:training_track"])
		row.actions.append(["Consultar manuais da Ordem","order:catalog"])
		if cargo_stage(p) not in ["","done"]:row.actions.append(["Acompanhar a carga da Ordem","order:track"])
	if id=="armory":
		row.actions.append(["A medida do serviço · exercício orientado","order:trial"])
		row.actions.append(["Estudar um manual adquirido","order:lessons"])
	return row
const LEADER_TOPICS={
	"duty":{"question":"O que esperais de mim?","text":"Grão-Mestre — Que voltes e me digas como correu, mesmo quando correr mal. O Tomé consegue ensinar-te muita coisa; não consegue estar sempre ao teu lado.\n\nQuando alguém no porto vir essa cruz, vai pedir-te ajuda. Se não souberes o que fazer, procura quem saiba. Foi para isso que fizemos esta casa."},
	"power":{"question":"Por que devo aprender a lutar?","text":"Grão-Mestre — Para voltares inteiro, antes de mais. E para trazeres os teus companheiros contigo. Há viagens em que uma boa vontade e uma conversa não chegam.\n\nMas treina aqui, enquanto podemos parar um golpe. No mar, a primeira vez que precisares da arma já é tarde para aprender."},
	"cargo":{"question":"O que aconteceu à carga?","text":"Grão-Mestre — A cozinha pediu uma reposição. Durante o socorro, parte da entrega mudou de destino; a guia ainda não foi corrigida.\n\nAntes de mandar sair mais mantimentos, preciso de saber quem recebeu a carga e quem autorizou a mudança. Confere a guia, o manifesto e o recibo."},
	"training":{"question":"Onde posso treinar?","text":"Grão-Mestre — Na armaria, no pátio sul. O instrutor empresta o material e dá-te um adversário. Podes entrar, experimentar o que Tomé te ensinou e sair quando quiseres.\n\nO treino livre não exige esta audiência. A avaliação para os estudos é um exercício à parte."}
}
static func leader_topics(p = null) -> Array:
	var result: Array=[]
	for key in LEADER_TOPICS:
		if key=="cargo" and p!=null and not p.flags.get("patient_helped",false):continue
		result.append([LEADER_TOPICS[key].question,"order:voice:"+key])
	return result
static func talk(map,p,id: String) -> Dictionary:
	var young: bool=map.get("childhood")==true
	if young:return response(id,"A casa guarda cartas, mapas e registos. Os serviços de viagem e os estudos de armas são recebidos na fase adulta.")
	if id in ["order_manifest","order_recipient"] and cargo_stage(p)=="":return response(id,"Se a casa te encarregar de conferir uma carga, os documentos e os destinatários podem esclarecer o percurso. A liderança da Ordem recebe os compromissos na Sala do Capítulo.")
	if id in ["grandmaster","commander"]:
		var greeting := "Grão-Mestre — Vieram duas cartas do porto esta manhã. Uma pede mantimentos; a outra, gente. Antes de responder, preciso de saber com quem posso contar."
		if id=="commander" or p.completed:greeting="Comendador — O Grão-Mestre está em viagem. Deixou-me os assuntos da casa; se tens um serviço por fechar, podemos tratá-lo aqui."
		if not p.flags.get("order_audience_done",false):
			var introduction: String="Carta de Duarte — É o aprendiz de Tomé. Recomendo que seja ouvido pelo primeiro serviço." if p.completed else "Duarte — É o aprendiz de Tomé. Trago-o para apresentar o primeiro serviço."
			return response(id,("Comendador" if id=="commander" else "Grão-Mestre")+" — Aproxima-te. O Tomé escreveu-me sobre ti.\n\n"+introduction+"\n\n"+("Então, conta-me como correu." if ready(p) else "Ajuda primeiro o Tomé e o Duarte. Quando terminares, volta cá; quero ouvir como correu."),([["Contar o primeiro serviço · O nome no livro","order:audience"]] if ready(p) else [])+leader_topics(p))
		var text := greeting+"\n\n"+objective(p)
		if cargo_stage(p)=="done": text+="\n\nGrão-Mestre — Já corrigi a guia. A cozinha tinha o que lhe era devido; a enfermaria recebeu a parte urgente. Evitaste mandar sair duas caixas de que precisamos aqui."
		var actions: Array=[]
		if cargo_stage(p)=="":
			if p.flags.get("patient_helped",false):actions.append(["Aceitar · A carga da Ordem","order:cargo_accept"])
			else:text="Grão-Mestre — Vai com o Duarte ao cais. Quando regressares, passa por cá; há sempre trabalho para quem conhece os dois lados da entrega."
		elif cargo_stage(p)=="report":
			actions.append(["Corrigir a guia: a entrega urgente está comprovada","order:cargo_report"])
			actions.append(["Enviar duas caixas de reposição à cozinha","order:cargo_replace"])
			actions.append(["Acusar a responsável da cozinha de desvio","order:cargo_accuse"])
		elif cargo_stage(p)!="done":actions.append(["Acompanhar investigação","order:track"])
		if not p.flags.get("order_trial_done",false):actions.append(["Perguntar pela avaliação de serviço","order:explain_trial"])
		else:text+="\n\nA medida do serviço está confirmada. O primeiro vale pode custear um estudo à tua escolha."
		if p.flags.get("embarked",false):text+="\n\nO teu lugar na viagem exige a mesma medida: confirmar carga, ouvir quem recebe e responder por quem segue contigo. A Ordem recebe o teu relato quando regressares."
		actions.append(["Indicar o caminho para o treino livre","order:training_track"])
		return response(id,text,actions+leader_topics(p))
	if id=="order_ledger":return response(id,"A guia manda doze caixas para a cozinha. Na margem, a autorização da casa: durante uma urgência, duas podem seguir para a enfermaria, com recibo. A cópia da cozinha ainda pede as doze. É preciso confirmar se a autorização foi usada.",[["Anotar a autorização e a guia por corrigir","order:ledger"]] if cargo_stage(p)!="" and cargo_stage(p)!="done" else [])
	if id=="order_manifest":return response(id,"Trabalhador — Descarreguei as doze. Mandaram duas para a enfermaria quando trouxeram o ferido; as outras dez foram para a cozinha. Assinei aqui a saída das duas, mas o recibo ficou com a responsável da cozinha.",[["Anotar a saída urgente e a assinatura","order:manifest"]] if cargo_stage(p)!="" and cargo_stage(p)!="done" else [])
	return response(id,"Responsável da cozinha — Pedi as duas porque a minha guia ainda dizia doze. Espera, tenho aqui o recibo da enfermaria, junto da nota do socorro. Ficámos com dez, como estava autorizado. Leva a cópia; já não preciso da reposição.",[["Recolher o recibo e confirmar que não há reposição","order:recipient"]] if cargo_stage(p)!="" and cargo_stage(p)!="done" else [])
static func purchased(p,id: String) -> bool:return p.flags.get("order_manual_"+id,false)
static func purchase_reason(p,id: String,voucher: bool) -> String:
	if not Studies.NAMES.has(id):return "Estudo desconhecido."
	if not p.flags.get("order_audience_done",false):return "Apresenta o primeiro relato à liderança para obter autorização."
	if p.flags.get("injured",false):return "O estudo espera pelo tratamento de Tomé."
	if p.skills.has(id) or purchased(p,id):return "Já conheces ou adquiriste este estudo."
	if not p.skills.has(FIRST[id.substr(0,2)]):return "Aprende com Tomé o fundamento deste manejo primeiro."
	if voucher and (not p.flags.get("order_trial_done",false) or p.flags.get("order_voucher_used",false)):return "O vale exige concluir a avaliação e só pode ser usado uma vez."
	if not Book.INTRO.has(id):
		var access: String=Book.reason(p,id)
		if not access.is_empty(): return access
	if voucher and Book.price(id)==0: return "Este ensinamento é gratuito; conserva o vale."
	if not voucher and p.coins<Book.price(id):return "Ouro insuficiente: este manual custa %d."%Book.price(id)
	return ""
static func buy(p,id: String,voucher: bool) -> String:
	var reason:=purchase_reason(p,id,voucher)
	if not reason.is_empty():return reason
	if voucher:p.flags.order_voucher_used=true
	else:p.coins-=Book.price(id)
	p.flags["order_manual_"+id]=true
	return "Manual adquirido: "+Studies.NAMES[id]+". Abre Técnicas na mochila para aprender numa pausa segura. O repertório atual foi preservado."
static func study_reason(p,id: String) -> String:
	if not Studies.NAMES.has(id) or not purchased(p,id):return "Adquire este manual na secretaria primeiro."
	if p.skills.has(id):return "Esta técnica já foi aprendida."
	if not p.flags.get("order_trial_done",false):return "Conclui A medida do serviço com o instrutor antes de estudar."
	if p.flags.get("injured",false) or not p.skills.has(FIRST[id.substr(0,2)]):return "O estudo exige recuperação e fundamento deste manejo."
	if not Book.INTRO.has(id): return Book.reason(p,id)
	return ""
static func study(p,id: String) -> String:
	var reason := study_reason(p,id)
	if not reason.is_empty():return reason
	var Dev=load("res://scripts/chapter/character_development.gd")
	var slots: Array=Dev.member(p).active_skills.duplicate()
	p.learn(id);Dev.member(p).active_skills=slots
	return "Lição concluída: "+Studies.NAMES[id]+". Prepara-a em Técnicas, numa das seis vagas. Aprender não aumenta o patamar de cultivo."
static func acquire_reason(p,id: String,voucher: bool) -> String:
	var reason := purchase_reason(p,id,voucher)
	if not reason.is_empty(): return reason
	if not p.flags.get("order_trial_done",false): return "Conclui a avaliação com o instrutor para aprender esta técnica."
	return ""
static func acquire(p,id: String,voucher: bool) -> String:
	var reason := acquire_reason(p,id,voucher)
	if not reason.is_empty(): return reason
	buy(p,id,voucher)
	study(p,id)
	return "Técnica aprendida: "+Studies.NAMES[id]+". Podes prepará-la aqui."
static func finish_trial(p) -> void:
	if not p.flags.get("order_audience_done",false) or p.flags.get("order_trial_done",false):return
	p.flags.order_trial_done=true;p.award_development("order:trial",25)
static func show(d,station: String,text: String,actions: Array=[],title := "Estudos autorizados da Ordem") -> void:
	d.routes.inspect({"title":title,"text":text,"hub_id":station,"actions":actions})
static func catalog(d,station: String,lessons := false) -> void:
	if d.has_meta("order_confirmation"):d.remove_meta("order_confirmation")
	d._menu("Técnicas")
static func act(d,station: String,code: String) -> void:
	var p=d.get_node("/root/ChapterProgress")
	if d.paused or d.phase!="order_inspection" or not d.routes.active or d.world.get("childhood")==true:return
	var all_rows: Dictionary=load("res://scripts/city/house_life.gd").rows(d.world)
	if not all_rows.has(station) or not d.routes.near(all_rows[station].at):return
	var leader: bool=station in ["grandmaster","commander"]
	var shop: bool=station in ["registry","study"]
	var message := ""
	if code=="order:training_track" and (leader or station in ["services","registry","study"]):
		p.choices.tracked_request="ORDER-PRACTICE"
		d.routes.save();d.routes.resume()
		return
	if code.begins_with("order:voice:") and leader:
		var topic := code.trim_prefix("order:voice:")
		if not LEADER_TOPICS.has(topic): return
		if topic=="cargo" and not p.flags.get("patient_helped",false):return
		var speech: String=LEADER_TOPICS[topic].text
		if station=="commander": speech=speech.replace("Grão-Mestre —","Comendador —")
		show(d,station,speech,[["Voltar à audiência","order:back"]]+leader_topics(p),"Grão-Mestre · Sala do Capítulo" if station=="grandmaster" else "Comendador · Sala do Capítulo")
		return
	if code=="order:back":d.routes.inspect(load("res://scripts/city/order_house_hub.gd").talk(d.world,p,station));return
	if code=="order:catalog" and station in ["registry","study","services"]:catalog(d,station);return
	if code=="order:lessons" and station=="armory":catalog(d,station,true);return
	if code.begins_with("order:view:") and station in ["registry","study","services"]:
		var id:=code.trim_prefix("order:view:")
		if not Studies.NAMES.has(id):return
		var actions: Array=[]
		if not p.skills.has(id) and not purchased(p,id):
			if shop:actions.append(["Aprender gratuitamente" if Book.price(id)==0 else "Comprar por %d ouro · confirmar"%Book.price(id),"order:confirm:"+id])
			if shop and p.flags.get("order_trial_done",false) and not p.flags.get("order_voucher_used",false):actions.append(["Usar o vale · confirmar","order:free:"+id])
			var reason:=purchase_reason(p,id,false)
			if not reason.is_empty():message="\n\n"+reason
		else:message="\n\nJá conheces esta técnica." if p.skills.has(id) else "\n\nManual adquirido. Aprende na página Técnicas da mochila."
		actions.append(["Voltar aos manuais","order:catalog"])
		show(d,station,Studies.TEXT[id]+"\n\nAlento: %d · Manejo: %s · Requisito: fundamento de Tomé e avaliação de serviço para estudar."%[Studies.COSTS[id],id.substr(0,2)]+message,actions,Studies.NAMES[id]);return
	if (code.begins_with("order:confirm:") or code.begins_with("order:free:")) and shop:
		var id: String=code.get_slice(":",2);var voucher:=code.begins_with("order:free:")
		message=purchase_reason(p,id,voucher)
		if message.is_empty():
			d.set_meta("order_confirmation",{"id":id,"station":station,"voucher":voucher})
			show(d,station,"Confirmar aquisição de %s por %s? O manual fica registado; poderás aprender a técnica na página Técnicas da mochila."%[Studies.NAMES[id],"um vale" if voucher else "%d ouro"%Book.price(id)],[["Confirmar aquisição","order:purchase:"+id],["Cancelar · voltar ao catálogo","order:catalog"]]);return
	elif code.begins_with("order:purchase:") and shop:
		var id:=code.trim_prefix("order:purchase:");var quote: Dictionary=d.get_meta("order_confirmation",{})
		if quote.get("id","")!=id or quote.get("station","")!=station:return
		d.remove_meta("order_confirmation");message=buy(p,id,quote.voucher)
	elif code.begins_with("order:learn:") and station=="armory":message=study(p,code.trim_prefix("order:learn:"))
	elif code=="order:audience" and leader and ready(p) and not p.flags.get("order_audience_done",false):
		p.flags.order_audience_done=true;message="Grão-Mestre — O Duarte recomenda-te. Pelo que me contas, fez bem. Vou deixar o teu nome na secretaria; podes consultar os manuais. Antes de os estudares, faz o exercício com o instrutor da armaria. O Tomé continua a acompanhar-te.\n\nE tenho um assunto para ti, se quiseres: a cozinha pediu uma reposição depois do socorro. Preciso que confirmes a entrega antes de mandar sair mais carga."
		if not p.flags.get("patient_helped",false):message=message.get_slice("\n\n",0)+"\n\nVai com o Duarte ao cais. Quando regressares, passa por cá."
		if p.choices.get("tracked_request","")=="ORDER-AUDIENCE":p.choices.erase("tracked_request")
	elif code=="order:cargo_accept" and leader and p.flags.get("order_audience_done",false) and p.flags.get("patient_helped",false) and cargo_stage(p)=="":
		p.flags.order_cargo_asked=true;p.choices.tracked_request="ORDER-CARGO";message="Antes de repor a carga, confirma a entrega urgente. A autorização está no arquivo; o trabalhador do pontão tem o manifesto e a cozinha guarda o recibo. Podes recolhê-los pela ordem que te der jeito."
	elif code=="order:track" and cargo_stage(p) not in ["","done"]:p.choices.tracked_request="ORDER-CARGO";message=objective(p)
	elif code in ["order:ledger","order:manifest","order:recipient"] and cargo_stage(p) not in ["","done"]:
		var key:=code.trim_prefix("order:")
		if {"ledger":"order_ledger","manifest":"order_manifest","recipient":"order_recipient"}[key]!=station:return
		p.flags["order_cargo_"+key]=true;message="Evidência anotada. "+objective(p)
	elif code=="order:cargo_report" and leader and cargo_stage(p)=="report":
		p.flags.order_cargo_done=true;p.coins=mini(1000000,p.coins+40);p.award_development("order:cargo",25)
		if p.choices.get("tracked_request","")=="ORDER-CARGO":p.choices.erase("tracked_request")
		message="Grão-Mestre — A autorização, o manifesto e o recibo conferem. Corrigimos a guia e cancelamos a reposição. As duas caixas ficam disponíveis para o próximo serviço.\n\nServiço concluído · 40 de ouro e 25 XP."
	elif code=="order:cargo_replace" and leader and cargo_stage(p)=="report":message="Grão-Mestre — A responsável retirou o pedido quando encontrou o recibo. Enviar mais duas seria pagar a mesma necessidade duas vezes. Confere a autorização e apresenta outra conclusão."
	elif code=="order:cargo_accuse" and leader and cargo_stage(p)=="report":message="Grão-Mestre — O manifesto e o recibo confirmam a entrega urgente. A responsável mostrou-te o documento e retirou o pedido de reposição. Que prova tens de um desvio? Revê o relato."
	elif code=="order:explain_trial" and leader:message="Procura o irmão instrutor na armaria. Alcança a casa de proteção, acerta um golpe e responde de frente com execução Boa ou Perfeita. O exercício usa recursos emprestados e pode ser repetido sem taxa; só a primeira conclusão concede vale e 25 XP."
	elif code=="order:trial" and station=="armory":
		if not p.flags.get("order_audience_done",false):message="Apresenta-te à liderança na Sala do Capítulo primeiro."
		else:d.begin_order_trial();return
	if message.is_empty():return
	if station=="commander":message=message.replace("Grão-Mestre —","Comendador —")
	d.routes.save()
	var options: Array=[["Voltar ao posto","order:back"]]
	if code.begins_with("order:voice:") and leader:
		var topic := code.trim_prefix("order:voice:")
		if not LEADER_TOPICS.has(topic): return
		var speech: String=LEADER_TOPICS[topic].text
		if station=="commander": speech=speech.replace("Grão-Mestre —","Comendador —")
		show(d,station,speech,[["Voltar à audiência","order:back"]]+leader_topics(),"Grão-Mestre · Sala do Capítulo" if station=="grandmaster" else "Comendador · Sala do Capítulo")
		return
	if code=="order:back":return
	show(d,station,message,options,str(all_rows[station].title))
static func notes(p) -> Array:
	var result: Array=[]
	if p.flags.get("order_audience_done",false):result.append({"id":"order:audience","title":"O nome no livro","text":"A liderança recebeu o primeiro relato e autorizou os estudos. Continuas aprendiz de Tomé."})
	if cargo_stage(p)!="":result.append({"id":"order:cargo","title":"A carga da Ordem","text":objective(p)})
	if p.flags.get("order_trial_done",false):result.append({"id":"order:trial","title":"A medida do serviço","text":"Exercício de posição, ataque e resposta concluído. Vale usado." if p.flags.get("order_voucher_used",false) else "Exercício concluído. Um vale de estudo está disponível na secretaria."})
	return result
static func valid_state(data: Dictionary) -> bool:
	var f: Dictionary=data.flags
	if f.get("order_trial_done",false) and not f.get("order_audience_done",false):return false
	if f.get("order_voucher_used",false) and not f.get("order_trial_done",false):return false
	if f.get("order_cargo_done",false):
		for id in ["order_cargo_asked","order_cargo_ledger","order_cargo_manifest","order_cargo_recipient","order_audience_done"]:
			if not f.get(id,false):return false
	for id in Studies.NAMES:
		if f.get("order_manual_"+id,false) and not f.get("order_audience_done",false):return false
	return true
