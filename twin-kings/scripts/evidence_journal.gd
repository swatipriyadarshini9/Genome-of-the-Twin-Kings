class_name EvidenceJournal
extends RefCounted

# The journal reads authored evidence resources and never invents conclusions
# from the mere presence of a saved flag.
var host
var current_page := 0

func _init(controller) -> void:
	host = controller

func show(page: int = 0) -> void:
	host._clear_modal()
	host.overlay_kind = "journal"
	current_page = clampi(page, 0, GameProgress.QUESTS.size() - 1)
	host._dim_screen(0.86)
	host._modal_frame(166, 71, 1034, 626)
	host._label(host.modal_layer, "THE RECORD  /  SOURCES & LIMITATIONS", 209, 100, 600, 20, host.UI_FONT, 10, host.TEAL)
	host._label(host.modal_layer, "Evidence Journal", 208, 129, 680, 53, host.TITLE_FONT, 30, host.IVORY)
	var count := GameProgress.collected_count(host.game)
	host._label(host.modal_layer, "%d / %d EVIDENCE ENTRIES RECORDED" % [count, GameProgress.QUESTS.size()], 210, 184, 610, 28, host.UI_FONT, 10, host.GOLD)
	host._close_button(1134, 88, host._return_to_previous)
	host._line(host.modal_layer, 210, 225, 948, host.DIM_LINE)
	for i in range(GameProgress.QUESTS.size()):
		var quest: QuestDefinition = GameProgress.QUESTS[i]
		var unlocked := GameProgress.is_collected(host.game, quest)
		var tab_text := "%02d     %s" % [i + 1, quest.evidence.title.to_upper() if unlocked else "UNDISCOVERED"]
		var tab: Button = host._button(host.modal_layer, tab_text, 210, 247 + i * 59, 275, 47, show.bind(i), "plain", 10)
		tab.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if i == current_page:
			tab.add_theme_color_override("font_color", host.BRIGHT_GOLD)
			host._line(host.modal_layer, 210, 251 + i * 59, 3, host.GOLD, 38)
	host._line(host.modal_layer, 500, 252, 1, Color(0.67, 0.57, 0.40, 0.22), 302)
	var selected: QuestDefinition = GameProgress.QUESTS[current_page]
	var collected := GameProgress.is_collected(host.game, selected)
	if collected:
		var evidence: EvidenceEntry = selected.evidence
		host._label(host.modal_layer, "ENTRY %02d  /  RECORDED" % (current_page + 1), 538, 249, 530, 20, host.UI_FONT, 10, host.TEAL)
		host._label(host.modal_layer, evidence.title, 538, 278, 570, 47, host.TITLE_FONT, 23, host.IVORY)
		host._label(host.modal_layer, "SOURCE", 538, 337, 250, 20, host.UI_FONT, 10, host.GOLD)
		host._label(host.modal_layer, evidence.source, 538, 358, 570, 35, host.BODY_FONT, 19, Color("cad3c9"))
		host._label(host.modal_layer, "OBSERVATION", 538, 406, 250, 20, host.UI_FONT, 10, host.GOLD)
		host._label(host.modal_layer, evidence.observation, 538, 429, 574, 63, host.BODY_FONT, 19, Color("cad3c9"))
		host._panel(host.modal_layer, 538, 504, 582, 73, Color("192926"), Color(0.43, 0.62, 0.56, 0.28), 1)
		host._label(host.modal_layer, "LIMITATION   /   " + evidence.limitation, 558, 510, 544, 60, host.BODY_FONT, 17, Color("b7d7c7"))
	else:
		host._label(host.modal_layer, "ENTRY %02d  /  UNDISCOVERED" % (current_page + 1), 538, 249, 530, 20, host.UI_FONT, 10, host.GOLD)
		host._label(host.modal_layer, "An empty page.", 538, 285, 558, 45, host.TITLE_FONT, 23, host.IVORY)
		host._label(host.modal_layer, "Continue investigating. New evidence will be recorded here with its source and limitations.", 538, 349, 570, 90, host.BODY_FONT, 22, Color("c9cfc4"))
		host._panel(host.modal_layer, 538, 472, 582, 92, Color("192926"), Color(0.43, 0.62, 0.56, 0.28), 1)
		host._label(host.modal_layer, "EVIDENCE IS MORE THAN AN ANSWER.\nKeep the observation, source and uncertainty together.", 558, 484, 544, 68, host.UI_FONT, 12, Color("b7d7c7"))
	host._line(host.modal_layer, 210, 603, 948, host.DIM_LINE)
	host._label(host.modal_layer, "A STRONG CASE CAN BE CHECKED AND REPRODUCED.", 212, 622, 600, 24, host.UI_FONT, 9, host.MUTED)
	host._button(host.modal_layer, "BACK", 1018, 615, 140, 40, host._return_to_previous, "outline", 10)
