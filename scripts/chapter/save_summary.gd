extends RefCounted
## Describe the actual saved checkpoint, not unsaved live progress.
static func describe(data: Dictionary) -> String:
 var places: Dictionary={"childhood_home.tscn":"Casa da Ordem · infância","opening.tscn":"Acolhimento · infância","plaza.tscn":"Praça · infância","training.tscn":"Treino com Leonor","forest_hunt.tscn":"Floresta","promise.tscn":"A promessa","adult_opening.tscn":"Lisboa · fase adulta","chapter_flow.tscn":"Lisboa · fase adulta"}
 var where: String=places.get(str(data.get("entry_scene","")).get_file(),"Campanha")
 if str(data.get("entry_scene","")).get_file()=="chapter_flow.tscn":
  var scenes: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_01/chapter_flow.json")).scenes
  where=str(scenes[clampi(int(data.get("checkpoint",0)),0,scenes.size()-1)].title)
 var journey: Dictionary=data.get("journey",{})
 if not journey.is_empty():where+=" · "+{"square":"praça","cais":"Ribeira","room":"acolhimento","convent":"convento","deck":"convés"}.get(journey.get("area",""),"percurso")
 var hp: Dictionary=data.get("vitals",{})
 return "Progresso guardado: %s.\nCarteira pessoal: %d de ouro · Vida %d · Alento %d · Postura %d.\nEquipamento, aprendizados, pedidos e conversas regressam ao estado dessa gravação. %s"%[where,int(data.get("coins",0)),int(hp.get("hp",0)),int(hp.get("qi",0)),int(hp.get("posture",0)),"Retomas o local do percurso." if not journey.is_empty() else "Falas e combates recomeçam no início da etapa."]
static func chapter(p,path: String = "user://capitulo-01.json") -> String:
 var data: Variant
 if p.journey.get("kind","")=="port_visit":
  var parked=load("res://scripts/navigation/voyage_model.gd").new()
  if parked.load_from(preload("res://scripts/navigation/voyage_launch.gd").travel_path)!=OK:return "O ponto seguro da viagem não pôde ser consultado."
  if parked.campaign_state.get("run_id","")!=p.run_id:return "O ponto seguro pertence a outra campanha."
  return describe(parked.campaign_state)+"\nA visita e o navio são retomados juntos."
 if not FileAccess.file_exists(path):return "Ainda não há progresso guardado para consultar."
 data=JSON.parse_string(FileAccess.get_file_as_string(path))
 if not data is Dictionary:return "O progresso guardado não pôde ser consultado."
 var validator=load("res://scripts/chapter/chapter_progress.gd").new()
 var valid: bool=validator.restore(data,false)==OK;validator.free()
 return describe(data) if valid else "O progresso guardado não pôde ser validado."

static func voyage(path: String) -> String:
 var ship=load("res://scripts/navigation/voyage_model.gd").new()
 if ship.load_from(path)!=OK:return "Ainda não há um ponto seguro válido para consultar."
 return "Ponto seguro: casco %d%% · provisões %d%% · fundo de bordo %d de ouro.\n%s"%[roundi(ship.hull),roundi(ship.supplies),ship.coins,describe(ship.campaign_state) if not ship.campaign_state.is_empty() else "Viagem de teste, sem progresso terrestre associado."]
