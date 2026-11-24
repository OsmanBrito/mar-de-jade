extends CanvasLayer
signal chosen(style:String)
signal practice_requested
const Items=preload("res://scripts/chapter/player_items.gd")
const Rules=preload("res://scripts/combat/campaign_rules.gd")
const Choices=preload("res://scripts/chapter/weapon_choices.gd")
const FIRST={"ES":"PT-W01","LA":"PT-W02","MC":"PT-W03","FO":"PT-W04","PU":"PT-W05"}
var screen:Control
var grid:GridContainer
var cards:Dictionary={}
var preview:Label
var primary:Button
var selected:=""
func _ready():
 layer=22;process_mode=Node.PROCESS_MODE_ALWAYS
func close():
 if is_instance_valid(screen):screen.hide()
func open(options:Array):
 if is_instance_valid(screen):screen.free()
 selected="";cards.clear()
 screen=Control.new();screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(screen)
 screen.theme=preload("res://scripts/ui/presentation.gd").theme()
 var shade:=ColorRect.new();shade.color=Color(0.015,.035,.04,.88);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);screen.add_child(shade)
 var panel:=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.offset_left=32;panel.offset_right=-32;panel.offset_top=24;panel.offset_bottom=-24;screen.add_child(panel)
 panel.add_theme_stylebox_override("panel",preload("res://scripts/ui/presentation.gd").panel(Color("132c30"),Color("b39b65")))
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true;panel.add_child(scroll)
 var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",16);scroll.add_child(box)
 text(box,"Tomé · Escolhe a tua arma",26,Color("e6cb8d"))
 text(box,"Escolhe a arma do herói e confirma para continuar a missão.",18)
 text(box,"Tomé oferece a primeira arma e ensina o seu fundamento. Não precisas fazer testes de combate.",17)
 grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);box.add_child(grid)
 for option in options:
  var style:String=option.style
  var card:=Button.new();card.text=Items.STYLES[style]+"\n"+Choices.TIPS[style]
  card.icon=load(Items.items()[FIRST[style]].icon);card.expand_icon=true;card.add_theme_constant_override("icon_max_width",62)
  card.custom_minimum_size=Vector2(0,100);card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  card.add_theme_font_size_override("font_size",GamePreferences.font_size(18));card.pressed.connect(select.bind(style));grid.add_child(card);cards[style]=card
 preview=text(box,"Seleciona uma arma para continuar.",21,Color("e6cb8d"))
 primary=Button.new();primary.text="Escolhe uma arma acima";primary.custom_minimum_size.y=54;primary.add_theme_font_size_override("font_size",GamePreferences.font_size(20));primary.disabled=true;box.add_child(primary)
 primary.pressed.connect(func():if not selected.is_empty():chosen.emit(selected))
 var practice:=Button.new();practice.text="Opcional · comparar armas em prática livre";practice.custom_minimum_size.y=42;practice.pressed.connect(func():practice_requested.emit());box.add_child(practice)
 text(box,"Os treinos não gastam os teus suprimentos. Esc / Start abre a pausa.",16)
 if not cards.is_empty():cards.values()[0].grab_focus()
func text(parent:Node,value:String,size:int,color:Color=Color("e8dfc8"))->Label:
 var label:=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",GamePreferences.font_size(size));label.add_theme_color_override("font_color",color);parent.add_child(label);return label
func select(style:String):
 selected=style
 for id in cards:cards[id].modulate=Color("e6cb8d") if id==style else Color.WHITE
 preview.text="Escolha: "+Items.STYLES[style]+" · "+Choices.TIPS[style]
 if style=="FO":preview.text+="\nTomé ensina Disparo de Medida, Tiro Preparado, Guarda do Cano e Tiro de Passagem."
 primary.text="Escolher "+Items.STYLES[style]+" como arma do herói"
 primary.disabled=false;primary.grab_focus()
