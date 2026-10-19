extends RefCounted
## Re-readable facts are gated by witnessed milestones, never by future objectives.
static func context(index:int) -> String:
	if index==6:return "Demonstração pública"
	if index in [7,8]:return "Avaliação reservada"
	if index in [9,10,11]:return "Depois do confronto"
	if index==12:return "Cuidados no acolhimento"
	if index in [13,14]:return "Recuperação e aprendizagem"
	if index in [15,16]:return "Missão da Ordem"
	return "Presente"
static func task(id:String,step:int) -> String:
	match id:
		"lever":return "Assenta a alavanca no apoio; Duarte segura a carga." if step==0 else "Apoio firme. Aproxima-te de Duarte e confirma a elevação conjunta; não puxes pelo braço do trabalhador."
		"meal":return "Recebe duas porções e água na cozinha da Ordem." if step==0 else "Leva as porções ao refeitório e aproxima-te da mesa de Leonor."
		"recovery_water":return "Bebe a água sentado. O cuidado e o repouso continuam; beber não encerra a recuperação."
		"recovery_walk":return "Caminha devagar até ao primeiro apoio." if step==0 else "Volta até Tomé. A confirmação da recuperação vem depois desta caminhada."
		"blue_rope":return "Recolhe a ponta azul; a branca pertence a Beatriz." if step==0 else "Leva a ponta azul até Duarte para concluírem a primeira manobra."
	return ""
static func notes(p) -> Array:
	var rows:Array=[]
	if p.flags.get("delivery_finished",false):rows.append({"id":"story:delivery","title":"A farinha chegou à cozinha","text":"Entregaste a farinha seca, separada do peixe. A entrega à cozinha precede o compromisso com Duarte no pátio."})
	if p.flags.get("cargo_freed",false):rows.append({"id":"story:rescue","title":"A carga e o apoio","text":"Assentaste a alavanca e levantaste a madeira com Duarte. O braço foi libertado; o atendimento do ferimento depende de Tomé, pano e água limpa."})
	if p.flags.get("green_sight",false):rows.append({"id":"story:perception","title":"Uma percepção no ferimento","text":"Percebeste uma pulsação sob o ferimento. Não fechaste a ferida nem curaste o trabalhador: foi necessário buscar Tomé, pano e água limpa."})
	if p.flags.get("patient_helped",false):rows.append({"id":"story:care","title":"O socorro foi concluído","text":"Tomé prestou o atendimento comum. A passagem ficou livre e o trabalhador saiu acompanhado; a refeição no refeitório veio depois do socorro."})
	if p.flags.get("city_leonor_demonstrated",false):rows.append({"id":"story:public","title":"A demonstração e o mestre da praça","text":"Na demonstração pública, o mestre desarmou o combatente e foi depois desarmado por Leonor. Assististe à troca de golpes; não estavas a ser avaliado naquele confronto. Na praça tratam-no por mestre."})
	if p.flags.get("duel_lost",false):rows.append({"id":"story:duel","title":"A avaliação terminou","text":"Leonor venceu o confronto reservado. O confronto terminou junto do banco; o resultado não apaga a preparação nem os trabalhos que já concluíste."})
	if p.flags.get("leonor_departed",false):rows.append({"id":"story:promise","title":"Dez anos, no mesmo banco","text":"Combinaste reencontrar Leonor neste dia, daqui a dez anos. Ela partiu; a viagem e o trabalho até lá serão teus."})
	if p.flags.get("assisted_return",false):rows.append({"id":"story:help","title":"O regresso acompanhado","text":"Duarte ficou contigo e Tomé veio ajudar no regresso ao acolhimento. O repouso e o cuidado precedem a volta aos exercícios."})
	if p.flags.get("recovered",false):rows.append({"id":"story:recovery","title":"Voltar a aprender com Tomé","text":"O cuidado, o repouso e a caminhada vieram antes de voltar ao pátio. Estás pronto para retomar a aprendizagem com Tomé; a recuperação não ensina técnicas automaticamente."})
	if p.flags.get("packed",false):rows.append({"id":"story:mission","title":"Uma missão antes da ambição","text":("Subiste à Botafogo como aprendiz sob Rodrigo, acompanhado por Duarte." if p.completed else "Duarte foi nomeado para a missão da Ordem e propôs levar-te como aprendiz. Falta apresentar-te ao capitão Rodrigo.")+" Madeira é a primeira escala para mantimentos; depois seguem para Duas Águas, na busca pela caravela desaparecida."})
	return rows
