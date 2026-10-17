@tool
extends RefCounted
## Iris anchors measured in the original atlases. No eye is drawn through hair/back views.
const JADE := Color("4d8460")
const ANCHORS := {
	"walk":[[[254,48],[269,48]],[[496,48],[509,48]],[[745,48],[758,48]],[[999,48],[1012,48]],[[240,358]],[[485,359]],[[732,359]],[[982,359]],[],[],[],[],[[291,977]],[[541,980]],[[781,978]],[[1035,978]]],
	"child":[[[220,69],[242,69]],[[458,71],[479,71]],[[694,72],[715,72]],[[930,69],[951,69]],[[204,351]],[[435,352]],[[674,351]],[[910,350]],[],[],[],[],[[245,925]],[[480,926]],[[716,927]],[[951,926]],[[194,1213],[216,1213]],[[448,1220],[470,1220]],[[679,1216]],[[920,1229]]],
	"story":[[[362,150],[398,150]],[[876,252],[910,252]],[[368,730]],[[837,840]]],
	"combat":[[[265,64],[278,64]],[[643,65],[656,65]],[[1015,64],[1028,64]],[[264,490],[277,490]],[[678,488],[691,488]],[[1044,490],[1057,490]],[[251,882],[264,884]],[],[]],
	"combat_child":[[[274,105],[299,103]],[[658,113],[681,111]],[[1063,112],[1083,110]],[[275,508],[297,506]],[[668,513],[689,511]],[[1064,513],[1088,511]],[[263,895],[285,889]],[],[]]
}
static func draw(canvas: CanvasItem,key: String,index: int,rect: Array,pivot: Array,factor: float,glow: bool = false) -> void:
	if not ANCHORS.has(key) or index<0 or index>=ANCHORS[key].size(): return
	for anchor in ANCHORS[key][index]:
		var point := Vector2(anchor[0]-rect[0]-pivot[0],anchor[1]-rect[1]-pivot[1])*factor
		var radius := maxf(0.52,2.5*factor)
		canvas.draw_circle(point,radius,JADE)
		canvas.draw_circle(point+Vector2(0.12,0),radius*0.35,Color("132c26"))
		if glow:
			canvas.draw_circle(point,radius*2.8,Color(0.4,0.9,0.6,0.18))
			canvas.draw_circle(point,radius*1.35,Color("90d99a"))
