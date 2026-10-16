extends RefCounted
const CIVILIAN_KINDS := ["merchant","worker","civilian","sailor","rui","samira","beatriz","tome","leonor","mafalda","duarte_home","ines_home"]
## Approved illustrated actor catalogue. Visual identity is independent of combat rules.
const KINDS := ["duarte","ines","bruma_guard","martim","esteban","nadira","yusuf","samira","rui","beatriz","tome","afonso","avelar","leonor","mafalda","catarina","mestre","guardiao","guard","rogue","boss","defender","archer","archer_woman","duelist","pikeman","bombard","medic","merchant","worker","civilian","sailor","duarte_home","ines_home"]
const UNARMED := ["merchant","worker","civilian","sailor","rui","samira","beatriz","tome","leonor","mafalda","duarte_home","ines_home"]
const NAMED_COMBAT := {"Mestre de Ferro":"mestre","Afonso Lastro":"afonso","Rui de Avelar":"avelar","Catarina":"catarina","Guardião da Rosa":"guardiao","Yusuf ibn Rami":"yusuf","Esteban de Alarcón":"esteban"}

# Source-slot remnants surround the hero action poses. Restrict their atlas
# sampling window without rewriting the approved PNGs or rescaling the body.
# Bounds measured with tools/audit_hero_fragments.gd, with a 6px edge allowance.
const FRAME_WINDOWS := {
	"duarte": {3:Rect2(64,69,130,162),4:Rect2(55,59,147,167),5:Rect2(86,62,109,172)},
	"ines": {3:Rect2(60,77,136,166),4:Rect2(53,71,152,171),5:Rect2(85,64,116,174)}
}


