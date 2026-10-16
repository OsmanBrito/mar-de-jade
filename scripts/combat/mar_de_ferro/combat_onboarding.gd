extends RefCounted
## Contextual first-battle lessons. A card pauses presentation, never changes rules.

const CARDS := {
	"welcome": {"title":"A tua primeira batalha", "cue":"G · Mover", "lines":[
		"Derrota os dois assaltantes. A ordem no topo mostra quem joga a seguir; agora controlas %HERÓI%.",
		"Clica numa casa verde ou prime G e usa as setas. Enter ou duplo clique confirma o caminho.",
		"Mover gasta casas, mas não gasta a acção. Podes mover antes e depois de atacar."]},
	"undo": {"title":"Podes refazer o caminho", "cue":"Z · Desfazer movimento", "lines":[
		"Experimenta Z ou o botão Desfazer: voltas à posição e orientação anteriores e recuperas as casas gastas.",
		"Cada pressão desfaz um deslocamento. Executar uma técnica ou terminar o turno confirma os movimentos anteriores.",
		"Agora podes desfazer ou continuar a partir desta posição."]},
	"actions": {"title":"Escolhe e confirma o alvo", "cue":"1–9 · Comandos   |   Tab · Alvos", "lines":[
		"Os números nos ícones escolhem ataques e técnicas. Lê o alcance, o custo de alento e a previsão antes de confirmar.",
		"Clica no alvo ou usa Tab para alternar os alvos válidos. Enter confirma; Esc ou botão direito volta atrás.",
		"Tens uma acção principal por turno. Quando aprenderes apoios rápidos, podes usar também um por turno."]},
	"attack": {"title":"Acerta o golpe perfeito", "cue":"ESPAÇO / SPACE · Prime no dourado", "lines":[
		"Quando fechares esta explicação, o cursor começa a percorrer a barra. Prime Espaço uma vez quando passar na zona dourada.",
		"Dourado é Perfeito; verde é Bom. Um erro mantém o ataque, mas perde o bónus do timing.",
		"O perfeito aumenta o dano e a pressão de postura. Não precisas de acertar sempre para vencer."]},
	"resources": {"title":"Vida, alento e postura", "cue":"8 · Respirar   |   9 · Itens", "lines":[
		"Vida mantém o herói em combate. Alento paga técnicas; o ataque básico e Respirar ajudam a recuperá-lo.",
		"A postura é a barra dourada. Quebrar a postura de um adversário faz perder um turno; protege também a tua.",
		"Respirar e usar itens gastam a acção principal. Na bolsa, Infusão cura e Tónico recupera alento; confirma um aliado vivo ao alcance."]},
	"facing": {"title":"Termina com a guarda certa", "cue":"Q / E · Virar   |   Enter · Terminar", "lines":[
		"Ainda podes gastar as casas restantes antes de terminar. Esc volta à escolha; Z pode desfazer movimentos ainda não confirmados.",
		"Vira a guarda para a ameaça: Q/E roda a seta, ou clica na direcção desejada. Enter termina o turno.",
		"Flancos e costas deixam-te mais vulnerável. A posição final prepara a tua defesa."]},
	"defense": {"title":"Defende e contra-ataca", "cue":"ESPAÇO / SPACE · Defesa perfeita", "lines":[
		"O inimigo vai atacar. Quando fechares esta explicação, prime Espaço quando o cursor passar no dourado.",
		"Um perfeito pela frente apara e contra-ataca automaticamente se o inimigo estiver adjacente. Não há outra tecla para responder.",
		"Pelo flanco podes aparar; pelas costas não há perfeito. Certos golpes pedem vários tempos: prime Espaço uma vez em cada tempo indicado."]},
	"duo": {"title":"Duas armas, uma equipa", "cue":"Duarte · Quebra   |   Inês · Flanco", "lines":[
		"Agora controlas %HERÓI%. Cada herói tem as suas casas de movimento e a sua acção.",
		"Duarte pressiona a postura e a sua Varredura cria Abertura. Inês pode aproveitá-la com a Estocada do cabo.",
		"Procura flancos e costas, e usa obstáculos para cortar linhas de tiro. H abre a ajuda; no futuro, sai das casas de golpes anunciados."]}
}

var enabled:=false
var seen: Dictionary={}
var active:=""
var first_actor:=-1

func reset(available: bool, actor: int) -> void:
	enabled=available; seen.clear(); active=""; first_actor=actor

func present(topic: String) -> void:
	if not enabled or not active.is_empty() or seen.has(topic) or not CARDS.has(topic): return
	seen[topic]=true; active=topic

func dismiss() -> void:
	active=""

func skip() -> void:
	enabled=false; active=""

