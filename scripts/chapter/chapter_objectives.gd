extends RefCounted
const TRAVEL := "Madeira é a primeira escala: preparar mantimentos e seguir para Duas Águas, onde uma caravela desapareceu. Vais como aprendiz sob Rodrigo; Duarte segue contigo."
static func current(director) -> String:
	if director.routes!=null and director.routes.active: return director.routes.objective()
	if director.completed: return TRAVEL+" A Botafogo já largou; inicia a navegação."
	if director.phase=="task": return director.current_event.get("caption","Conclui a ação indicada no cenário.")
	if director.phase=="delivery_choice": return "Conclui a entrega prometida: farinha seca para a cozinha, separada do peixe. Depois regressa ao pátio com Duarte."
	if director.phase in ["styles","styles_result","practice_retry"]: return "Pátio de Tomé: compara armas emprestadas, aprende um fundamento e prepara até quatro passivas por pessoa. Podes sair dos exercícios para trocar de manejo."
	if director.scene_index==5 and director.harbor.active: return "A refeição terminou. Podes concluir os pedidos de Lisboa antes de regressar ao abrigo com Duarte. Amanhã há uma avaliação na praça; o embarque só vem depois da recuperação e dos treinos."
	if director.scene_index in [3,15] and director.harbor.active:
		return ("Explora Lisboa, conversa com os moradores e conclui pedidos. Duarte espera para seguir à refeição." if director.scene_index==3 else "Conclui os assuntos de Lisboa e compra o que precisares. Procura Duarte no pontão quando estiveres pronto.\n"+TRAVEL)
	if director.scene_index<=2: return "Ajuda no trabalho do cais e procura tratamento comum com Tomé. A visão percebe o sofrimento; o atendimento depende das pessoas."
	if director.scene_index<=5: return "Partilha o trabalho e a refeição. Leonor marcou uma avaliação para a manhã seguinte. Usa os intervalos seguros para conhecer Lisboa."
	if director.scene_index<=8: return "Observa a demonstração e participa da avaliação de Leonor. Experimenta mover, atacar e responder ao golpe: a diferença de experiência conduz à derrota, e a história continua."
	if director.scene_index<=12: return "Aceita o auxílio de Duarte e Tomé. Bebe a água, recupera e só então regressa à prática."
	if director.scene_index==13: return "Retoma o pátio com Tomé, compara os cinco manejos e escolhe a arma inicial. Aprender e equipar passivas são ações separadas."
	return TRAVEL
