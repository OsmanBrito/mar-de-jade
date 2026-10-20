extends RefCounted
const Items=preload("res://scripts/chapter/player_items.gd")
const UNARMED="unarmed"
const FIRST={"ES":"PT-W01","LA":"PT-W02","MC":"PT-W03","FO":"PT-W04"}
const TIPS={"ES":"Equilibrada · alcance 1","LA":"Mantém distância · alcance 2","MC":"Golpes fortes · alcance 1","FO":"Ataca à distância · exige linha livre","PU":"Luta sem arma · alcance 1"}
static func current(p) -> String:
 var id:String=p.equipment.get("weapon","")
 return Items.items()[id].name if not id.is_empty() else "Desarmado" if p.style=="PU" else "Ainda sem arma própria"
static func reason(p,id:String)->String:
 if not p is Node and not p.has("tested_styles"):return "Esta viagem não tem a preparação de campanha para trocar armas."
 if id!=UNARMED:return Items.equip_reason(p,id)
 if not p.flags.get("recovered",false) or p.flags.get("injured",false):return "Espera pela recuperação com Tomé."
 if not p.tested_styles.has("PU"):return "Experimenta lutar desarmado com Tomé primeiro."
 return ""
static func rows(p)->Array:
 var result:Array=[]
 for style in Items.STYLES:
  if style=="PU":result.append({"id":UNARMED,"style":style,"name":"Desarmado","owned":true,"active":p.style=="PU" and not p.equipment.has("weapon")})
  var found:=false
  for id in Items.items():
   var item:Dictionary=Items.items()[id]
   if item.slot!="weapon" or item.get("style","")!=style or int(p.inventory.get(id,0))<1:continue
   found=true;result.append({"id":id,"style":style,"name":item.name,"owned":true,"active":p.equipment.get("weapon","")==id})
  if not found and FIRST.has(style):
   var id:String=FIRST[style]
   result.append({"id":id,"style":style,"name":Items.items()[id].name,"owned":false,"active":false})
 return result
static func choose(p,id:String)->String:
 var blocked:=reason(p,id)
 if not blocked.is_empty():return blocked
 if id!=UNARMED:return Items.equip(p,id)
 if p.equipment.has("weapon"):return Items.unequip(p,"weapon")
 p.style="PU";Items.clamp_vitals(p)
 return Items.persist(p,"O herói está a lutar desarmado.")
