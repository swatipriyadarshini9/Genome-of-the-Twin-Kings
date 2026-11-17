class_name ForestChallengeScreen
extends RefCounted

const TRIAL: VariantTrial = preload("res://data/trials/forest_variants.tres")
const QUEST: QuestDefinition = preload("res://data/quests/forest_investigation.tres")
const OPTIONS := ["substitution", "insertion", "deletion"]
var host
var answers: Array[String] = []
var option_buttons: Array = []
var row_status: Array[Label] = []
var feedback: Label
var counter: Label

func _init(controller) -> void:
	host = controller

func show() -> void:
	host._clear_modal()
	host.overlay_kind = "forest_puzzle"
	answers.clear()
	option_buttons.clear()
	row_status.clear()
	for _item in TRIAL.cases:
		answers.append("")
	host._dim_screen(0.86)
	host._modal_frame(106, 54, 1154, 660)
	host._label(host.modal_layer, "SEQUENCE FOREST   /   THE SPRITE'S FIELD TRIAL", 147, 80, 700, 20, host.UI_FONT, 10, host.TEAL)
	host._label(host.modal_layer, "What changed in the sequence?", 147, 110, 900, 52, host.TITLE_FONT, 29, host.IVORY)
	host._label(host.modal_layer, "Classify each sample relative to its reference. A dash marks a gap in the alignment.", 148, 169, 1010, 39, host.BODY_FONT, 21, Color("c8d0c6"))
	host._close_button(1196, 69)
	host._line(host.modal_layer, 147, 222, 1072, host.DIM_LINE)
	host._label(host.modal_layer, "ALIGNED FIELD SAMPLES", 160, 235, 390, 20, host.UI_FONT, 10, host.GOLD)
	host._label(host.modal_layer, "SELECT ONE CLASSIFICATION FOR EACH ROW", 641, 235, 520, 20, host.UI_FONT, 10, host.GOLD)
	for i in range(TRIAL.cases.size()):
		var item := TRIAL.cases[i] as VariantCase
		var y := 263.0 + i * 92.0
		host._panel(host.modal_layer, 147, y, 1072, 82, Color("182622"), Color(0.42, 0.59, 0.53, 0.25), 1)
		host._label(host.modal_layer, "%02d" % (i + 1), 163, y + 20, 43, 39, host.TITLE_FONT, 20, host.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		host._label(host.modal_layer, "REF", 218, y + 12, 73, 20, host.UI_FONT, 9, host.MUTED)
		host._label(host.modal_layer, "SAMPLE", 218, y + 46, 73, 20, host.UI_FONT, 9, host.TEAL)
		for n in range(item.reference.length()):
			_draw_base(item.reference[n], 295 + n * 34, y + 9, false)
			_draw_base(item.sample[n], 295 + n * 34, y + 43, true)
		var buttons: Array[Button] = []
		for j in range(OPTIONS.size()):
			var option_text: String = String(OPTIONS[j]).to_upper()
			var button: Button = host._button(host.modal_layer, option_text, 585 + j * 172, y + 19, 165, 43, Callable(), "outline", 10)
			button.toggle_mode = true
			button.pressed.connect(_choose.bind(i, j))
			buttons.append(button)
		option_buttons.append(buttons)
		var status: Label = host._label(host.modal_layer, "", 1108, y + 28, 98, 24, host.UI_FONT, 9, Color("e6a49a"), HORIZONTAL_ALIGNMENT_CENTER)
		row_status.append(status)
	counter = host._label(host.modal_layer, "0 / %d CLASSIFIED" % TRIAL.cases.size(), 150, 553, 290, 21, host.UI_FONT, 10, host.MUTED)
	feedback = host._label(host.modal_layer, "Compare the bases column by column.", 148, 574, 730, 34, host.BODY_FONT, 18, host.MUTED)
	host._line(host.modal_layer, 147, 614, 1072, host.DIM_LINE)
	host._button(host.modal_layer, "NEED A HINT?", 147, 633, 180, 45, _hint, "outline", 10)
	host._button(host.modal_layer, "CHECK CLASSIFICATIONS   →", 917, 633, 302, 45, _check, "primary", 10)

func _draw_base(base: String, x: float, y: float, sample: bool) -> void:
	var gap := base == "-"
	var fill := Color("263c36") if sample else Color("202e29")
	host._panel(host.modal_layer, x, y, 29, 28, fill, Color(0.45, 0.62, 0.55, 0.29), 1)
	host._label(host.modal_layer, "–" if gap else base, x, y, 29, 28, host.UI_FONT, 13, host.TEAL if gap else host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)

func _choose(row: int, option: int) -> void:
	answers[row] = OPTIONS[option]
	for i in range(OPTIONS.size()):
		var b: Button = option_buttons[row][i]
		b.set_pressed_no_signal(i == option)
	row_status[row].text = ""
	var selected := 0
	for value in answers:
		if value != "":
			selected += 1
	counter.text = "%d / %d CLASSIFIED" % [selected, answers.size()]
	feedback.text = "Compare the bases column by column."
	feedback.add_theme_color_override("font_color", host.MUTED)

func _hint() -> void:
	feedback.text = "Changed letter: substitution. Gap in reference: insertion. Gap in sample: deletion."
	feedback.add_theme_color_override("font_color", host.TEAL)

func _check() -> void:
	if answers.has(""):
		feedback.text = "Choose a classification for every observation first."
		feedback.add_theme_color_override("font_color", Color("e6a49a"))
		return
	if TRIAL.grade(answers):
		host.game["forest_puzzle_solved"] = true
		host._save_game()
		host._update_hud()
		show_success(true)
		return
	feedback.text = "Not quite. Revisit the observations marked REVIEW."
	feedback.add_theme_color_override("font_color", Color("e6a49a"))
	for i in range(TRIAL.cases.size()):
		var item := TRIAL.cases[i] as VariantCase
		if answers[i] != VariantClassifier.classify(item.reference, item.sample):
			row_status[i].text = "REVIEW"
		else:
			row_status[i].text = ""

func show_success(newly_recovered: bool = false) -> void:
	host._clear_modal()
	host.overlay_kind = "forest_success"
	host._dim_screen(0.84)
	host._modal_frame(307, 118, 752, 532)
	host._image(host.modal_layer, host.HELIX, Vector2(643, 147), Vector2(80, 80))
	host._label(host.modal_layer, "EVIDENCE RECOVERED" if newly_recovered else "EVIDENCE ALREADY RECOVERED", 405, 231, 556, 22, host.UI_FONT, 10, host.TEAL, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "The pattern takes shape.", 357, 264, 652, 52, host.TITLE_FONT, 27, host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "The sprite releases the survey: a substitution, an insertion and a deletion, each relative to its reference.", 396, 331, 574, 72, host.BODY_FONT, 22, Color("cbd2c8"), HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "These simplified alignments are clues, not proof. Real variants require quality checks and independent evidence.", 396, 418, 574, 68, host.ITALIC_FONT, 20, Color("aac5b8"), HORIZONTAL_ALIGNMENT_CENTER)
	host._line(host.modal_layer, 401, 508, 565, host.DIM_LINE)
	var reward_text := "+ 1 DATA FRAGMENT       •       + %d XP" % QUEST.evidence.xp if newly_recovered else "FRAGMENT ALREADY RECOVERED       •       NO ADDITIONAL XP"
	host._label(host.modal_layer, reward_text, 413, 522, 540, 23, host.UI_FONT, 11, host.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	host._button(host.modal_layer, "RETURN TO THE FOREST   →", 501, 558, 365, 48, host._clear_modal, "primary", 11)
