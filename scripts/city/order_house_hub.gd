extends Node2D
## A service hub: original activities and furniture, not a copy of a reference game's map.
const Actor = preload("res://scripts/chapter/actor_proxy.gd")
const Marker = preload("res://scripts/chapter/local_request_marker.gd")
const ROWS := {
 "services":{"at":Vector2(-245,435),"title":"Quadro de serviços da Ordem"},
 "registry":{"at":Vector2(230,75),"title":"Secretaria · Irmão escrivão"},
 "study":{"at":Vector2(330,-100),"title":"Estudo · Manuais de campo"},
 "armory":{"at":Vector2(-850,920),"title":"Armaria · Irmão instrutor"},
 "supplies":{"at":Vector2(470,655),"title":"Enfermaria · Mesa de cuidado"},
 "kitchen":{"at":Vector2(1360,95),"title":"Cozinha · Responsável das porções"},
 "preparation":{"at":Vector2(1190,115),"title":"Mesa de preparo · Separar porções"},
 "refectory":{"at":Vector2(880,105),"title":"Refeitório · Ajudante da vigília"},
 "belongings":{"at":Vector2(-600,700),"title":"Dormitório · Preparar a mochila"},
 "reflection":{"at":Vector2(-240,145),"title":"Capela · Compromisso de serviço"}
}
var world
var markers: Dictionary = {}
var workers: Array = []
var clock := 0.0
static func install(map) -> void:
 if map.has_node("OrderHouseHub"): return
 var hub := Node2D.new();hub.set_script(load("res://scripts/city/order_house_hub.gd"));hub.name="OrderHouseHub";hub.world=map;map.add_child(hub)
 for id in ROWS:
  var holder := Node2D.new();holder.position=ROWS[id].at;map.sorted_world.add_child(holder)
  var marker:=Marker.new();marker.caption=ROWS[id].title;marker.symbol="i";holder.add_child(marker);hub.markers[id]=marker
 hub.person("Irmão escrivão","order_brother",Vector2(165,65))
 hub.person("Irmão instrutor","order_instructor",Vector2(-940,915))
 hub.person("Cozinheira","order_cook",Vector2(1360,45))
 hub.person("Ajudante da vigília","order_server",Vector2(880,55))
 hub.worker("Irmão dos registos","order_brother",[Vector2(110,50),Vector2(135,-130)])
 hub.worker("Ajudante da cozinha","order_server",[Vector2(1160,-20),Vector2(1290,-95)])
 hub.worker("Arrumação da enfermaria","order_server",[Vector2(825,670),Vector2(835,520)])
 load("res://scripts/city/order_chapter_room.gd").install(map)
static func meal_stage(p) -> String:
 return "done" if p.flags.get("order_meal_done",false) else "prepared" if p.flags.get("order_meal_prepared",false) else "asked" if p.flags.get("order_meal_asked",false) else ""
static func meal_objective(p) -> String:
 return {"":"Fala com a responsável das porções, na cozinha, sobre o serviço da vigília.","asked":"Cozinha: separa quatro porções na mesa de preparo, entre a lareira e a passagem para o refeitório.","prepared":"Leva as quatro porções ao ajudante da vigília, no refeitório ao lado da cozinha.","done":"A vigília recebeu as quatro porções. A casa agradeceu com uma ração e 25 XP, uma única vez."}[meal_stage(p)]
static func meal_target(p) -> Vector2:
 return ROWS[{"":"kitchen","asked":"preparation","prepared":"refectory","done":"services"}[meal_stage(p)]].at
static func response(id: String,text: String,actions: Array = []) -> Dictionary:
 return {"title":ROWS[id].title,"text":text,"hub_id":id,"actions":actions}
static func talk(map,p,id: String) -> Dictionary:
 var Campaign=load("res://scripts/chapter/order_campaign.gd")
 if Campaign.rows(map).has(id):return Campaign.talk(map,p,id)
 return Campaign.extend(p,id,_house_talk(map,p,id),map.get("childhood")==true)
static func _house_talk(map,p,id: String) -> Dictionary:
 if not ROWS.has(id): return {}
 var child: bool = map.get("childhood")==true
 match id:
  "services","registry":
   var text := "A casa de Lisboa reparte o trabalho entre acolhimento, estudo, preparo e cuidado. A secretaria regista compromissos; cada responsável confirma o resultado do seu serviço.\n\n"+meal_objective(p)
   var options := [["Consultar missão e pedidos","requests"]]
   if not child and meal_stage(p)=="":options.append(["Oferecer ajuda nas porções da vigília","meal_accept"])
   if not child and meal_stage(p) in ["asked","prepared"]:options.append(["Acompanhar as porções da vigília","meal_track"])
   return response(id,text,options)
  "study":return response(id,"Consulta aqui o repertório da Ordem: técnicas são ações de combate; passivas dão efeitos enquanto equipadas.\n\nEm Técnicas podes comprar ou aprender um manual e depois prepará-lo. Tens seis vagas de técnicas e quatro de passivas por pessoa. O domínio cresce com a prática.",[["Técnicas · aprender e preparar","techniques"],["Passivas · consultar e equipar","passives"],["Evolução · atributos e cultivo","repertoire"]] if not child else [])
  "armory":return response(id,"Aqui conferem-se empunhaduras, proteção e equipamento antes dos exercícios. As armas da prática são emprestadas. Podes treinar o manejo equipado sem gastar os suprimentos pessoais; terminar ou sair devolve-te à casa, sem avançar a história nem premiar repetição.",[["Conferir equipamento","equipment"],["Praticar com o manejo equipado","practice"]] if not child else [])
  "supplies":return response(id,"Ligaduras, água e panos usados ficam separados. A mesa serve para conferir a reserva: uma ligadura recupera vida quando usada, a água recupera alento. Ferimentos da história continuam a exigir tratamento de Tomé.\n\nConferir material não consome itens nem cura à distância.",[["Conferir a sacola","inventory"]] if not child else [])
  "kitchen":
   var text := "A vigília fica de serviço enquanto os outros comem. Precisamos de quatro porções: duas para a portaria e duas para a enfermaria. A mesa junto à passagem tem pão e recipientes; prepara o conjunto e entrega-o ao ajudante no refeitório. É uma ajuda opcional."
   if meal_stage(p)!="":text=meal_objective(p)
   return response(id,text,[["Aceitar o serviço das quatro porções","meal_accept"]] if not child and meal_stage(p)=="" else [["Acompanhar este serviço","meal_track"]] if not child and meal_stage(p)!="done" else [])
  "preparation":
   if not child and meal_stage(p)=="asked":return response(id,"A folha da cozinha indica duas porções para a portaria e duas para a enfermaria. Quantas vais separar para a vigília?",[["Separar quatro porções e cobrir a travessa","meal_prepare"],["Separar só duas porções","meal_short"]])
   return response(id,meal_objective(p) if meal_stage(p)!="" else "Pão e recipientes separados por serviço. A responsável da cozinha explica o que precisa ser preparado; não retires mantimentos sem combinar a entrega.")
  "refectory":
   if not child and meal_stage(p)=="prepared":return response(id,"A travessa veio coberta? Quatro porções chegam para as duas pessoas da portaria e as duas da enfermaria. Confirma a entrega e eu distribuo-as.",[["Entregar as quatro porções à vigília","meal_finish"]])
   return response(id,"As porções chegaram e a vigília já pode comer. A ração de agradecimento ficou na tua sacola; não é preciso repetir o serviço." if meal_stage(p)=="done" else "As mesas recebem quem terminou o serviço. Se queres ajudar a vigília, combina as porções com a responsável da cozinha.")
  "belongings":return response(id,"A arrumação fica junto às camas e armários; o corredor central deve permanecer livre. Podes conferir o que levas contigo e mudar a preparação em segurança. Esta é a tua mesma sacola, não um segundo inventário.",[["Organizar mochila e equipamento","equipment"]] if not child else [])
  "reflection":
   if p.flags.get("order_reflection_done",false):return response(id,"O compromisso ficou no teu caderno: aprender sem prometer o que não sabes fazer e confirmar o serviço com quem dele depende. Recolher-te não recupera recursos nem concede poder por repetição.",[["Rever o caderno","requests"]])
   return response(id,"A capela é um lugar de pausa. A cruz da casa lembra o serviço que liga o acolhimento ao porto. Queres registar um propósito para o que vem a seguir?",[["Registar: aprender e responder pelo meu serviço","reflect"]] if not child else [])
 return {}
static func act(d,id: String,code: String) -> void:
 if code.begins_with("order:"):load("res://scripts/chapter/order_campaign.gd").act(d,id,code);return
 var p = d.get_node("/root/ChapterProgress")
 if d.paused or d.phase!="order_inspection" or not d.routes.active or d.routes.area()!="convent" or not ROWS.has(id) or not d.routes.near(ROWS[id].at):return
 var offered: Array = talk(d.world,p,id).get("actions",[])
 if not offered.any(func(a):return a[1]==code):return
 var menus := {"requests":"Pedidos","techniques":"Técnicas","passives":"Passivas","repertoire":"Evolução","equipment":"Equipamento","inventory":"Inventário"}
 if menus.has(code):d._menu(menus[code]);return
 if code=="practice":d.begin_order_practice();return
 var message := ""
 match code:
  "meal_accept":
   if meal_stage(p)!="":return
   p.flags.order_meal_asked=true;p.choices.tracked_request="ORDER-MEAL"
   message="Serviço aceite. A cozinha fica a nascente do refeitório. Separa quatro porções na mesa de preparo; o indicador acompanha a próxima ação."
  "meal_track":p.choices.tracked_request="ORDER-MEAL";message=meal_objective(p)
  "meal_short":message="Duas porções cobrem só a portaria. São duas pessoas na portaria e duas na enfermaria: confere o total antes de levar a travessa."
  "meal_prepare":
   p.flags.order_meal_prepared=true
   message="Quatro porções separadas e a travessa coberta. O ajudante da vigília espera no refeitório ao lado; não precisas voltar à secretaria para entregar."
  "meal_finish":
   if meal_stage(p)!="prepared":return
   p.flags.order_meal_done=true
   p.inventory["PT-C02"]=mini(999,int(p.inventory.get("PT-C02",0))+1)
   p.award_development("order:meal",25)
   if p.choices.get("tracked_request","")=="ORDER-MEAL":p.choices.erase("tracked_request")
   message="Entrega confirmada: quatro porções para a vigília. Recebeste uma ração e 25 XP pelo serviço. O ajudante vai distribuir a comida; a obrigação terminou."
  "reflect":p.flags.order_reflection_done=true;message="Registaste o propósito no caderno. A aprendizagem e o serviço continuam fora da capela, nas decisões que tomares."
 if message.is_empty():return
 if p.auto_save:p.save_to()
 d.routes.inspect(response(id,message,talk(d.world,p,id).get("actions",[])))
static func journal(p) -> Array:
 var result: Array=[]
 if meal_stage(p)!="":result.append({"id":"order:meal","title":"Ordem · A mesa de quem fica","text":meal_objective(p)})
 if p.flags.get("order_reflection_done",false):result.append({"id":"order:reflection","title":"Um propósito de serviço","text":"Aprender sem prometer o que ainda não sabes fazer e confirmar o trabalho com quem dele depende."})
 return result
func person(label: String,id: String,at: Vector2) -> Node2D:
 var actor:=Actor.new();actor.name=label;actor.npc_id=id;actor.position=at;world.sorted_world.add_child(actor)
 return actor
func worker(label: String,id: String,route: Array) -> void:
 var actor=person(label,id,route[0]);workers.append({"actor":actor,"route":route,"leg":1,"wait":1.5})
func _process(delta: float) -> void:
 if not is_instance_valid(world.player) or not world.player.enabled:return
 clock+=delta
 var p=get_node("/root/ChapterProgress")
 for id in markers:
  var marker=markers[id]
  var active: bool = (id=="preparation" and meal_stage(p)=="asked") or (id=="refectory" and meal_stage(p)=="prepared")
  marker.symbol="!" if active else "✓" if id in ["kitchen","refectory"] and meal_stage(p)=="done" else "i"
  marker.highlighted=world.player.position.distance_to(ROWS[id].at)<60
 for job in workers:
  var actor=job.actor
  if world.player.position.distance_to(actor.position)<65:actor.walking=false;continue
  if job.wait>0:job.wait-=delta;actor.walking=false;continue
  var target: Vector2=job.route[job.leg]
  var next: Vector2=actor.position.move_toward(target,35*delta)
  if world.point_clear(next) and world.segment_clear(actor.position,next):
   var direction: Vector2=next-actor.position
   actor.facing=(1 if direction.x<0 else 3) if absf(direction.x)>absf(direction.y) else (2 if direction.y<0 else 0)
   actor.position=next;actor.walking=true;actor.frame_time+=delta*6
  else:actor.walking=false
  if actor.position.distance_to(target)<3:job.leg=1-job.leg;job.wait=2.5
