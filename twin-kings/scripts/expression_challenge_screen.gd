class_name ExpressionChallengeScreen
extends RefCounted

# This layout is designed for four short samples and three CPM choices.
# The sample data, validation and calculations are independent of the UI.
const TRIAL: ExpressionTrial = preload("res://data/trials/swamp_expression.tres")
const QUEST: QuestDefinition = preload("res://data/quests/swamp_assay.tres")

var host
var selected: Array[int] = []
var selected_option := -1
var sample_buttons: Array[Button] = []
var option_buttons: Array[Button] = []
var counter: Label
var feedback: Label

func _init(controller) -> void:
	host = controller

func show() -> void:
	host._clear_modal()
	host.overlay_kind = "swamp_puzzle"
	selected.clear()
	selected_option = -1
	sample_buttons.clear()
	option_buttons.clear()
	host._dim_screen(0.86)
	host._modal_frame(106, 54, 1154, 660)
	host._label(host.modal_layer, "EXPRESSION SWAMP   /   THE MARSH ASSAY", 147, 80, 700, 20, host.UI_FONT, 10, host.TEAL)
	host._label(host.modal_layer, "Find a signal in the noise.", 147, 110, 900, 52, host.TITLE_FONT, 29, host.IVORY)
	host._label(host.modal_layer, "Choose a QC-passing control and case from the same batch. Then compare the target counts per million mapped reads.", 148, 168, 1020, 45, host.BODY_FONT, 20, Color("c8d0c6"))
	host._close_button(1196, 69)
	host._line(host.modal_layer, 147, 222, 1072, host.DIM_LINE)
	host._label(host.modal_layer, "STEP 1  /  SELECT TWO SAMPLES", 148, 230, 500, 20, host.UI_FONT, 10, host.GOLD)
	counter = host._label(host.modal_layer, "0 / 2 SELECTED", 925, 230, 280, 20, host.UI_FONT, 10, host.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	host._label(host.modal_layer, "SAMPLE", 174, 251, 210, 21, host.UI_FONT, 10, host.MUTED)
	host._label(host.modal_layer, "BATCH", 402, 251, 110, 21, host.UI_FONT, 10, host.MUTED)
	host._label(host.modal_layer, "QUALITY CHECK", 524, 251, 195, 21, host.UI_FONT, 10, host.MUTED)
	host._label(host.modal_layer, "MAPPED READS", 750, 251, 170, 21, host.UI_FONT, 10, host.MUTED)
	host._label(host.modal_layer, "TARGET COUNT", 974, 251, 160, 21, host.UI_FONT, 10, host.MUTED)
	for i in range(TRIAL.samples.size()):
		var sample := TRIAL.samples[i] as ExpressionSample
		var y := 275.0 + i * 46.0
		host._panel(host.modal_layer, 147, y, 1072, 42, Color("182622"), Color(0.42, 0.59, 0.53, 0.25), 1)
		var button: Button = host._button(host.modal_layer, "%s    /    %s" % [sample.id, sample.condition.to_upper()], 157, y + 3, 222, 36, _choose_sample.bind(i), "outline", 12)
		button.toggle_mode = true
		sample_buttons.append(button)
		host._label(host.modal_layer, sample.batch, 402, y + 5, 100, 32, host.UI_FONT, 13, host.IVORY)
		host._label(host.modal_layer, sample.qc_note, 524, y + 5, 210, 32, host.UI_FONT, 11, host.TEAL if sample.qc_pass else Color("e6a49a"))
		host._label(host.modal_layer, "%.0f MILLION" % (float(sample.mapped_reads) / 1000000.0), 750, y + 5, 190, 32, host.UI_FONT, 12, host.IVORY)
		host._label(host.modal_layer, "%d" % sample.target_count, 974, y + 5, 140, 32, host.UI_FONT, 13, host.IVORY)
	host._label(host.modal_layer, "STEP 2  /  CHOOSE COUNTS PER MILLION: CONTROL / CASE", 148, 468, 900, 20, host.UI_FONT, 10, host.TEAL)
	for i in range(TRIAL.options.size()):
		var value: Vector2 = TRIAL.options[i]
		var button: Button = host._button(host.modal_layer, "%d  /  %d CPM" % [int(value.x), int(value.y)], 147 + i * 357, 493, 342, 44, _choose_option.bind(i), "outline", 12)
		button.toggle_mode = true
		option_buttons.append(button)
	feedback = host._label(host.modal_layer, "Check quality and batch before comparing the counts.", 148, 543, 1030, 58, host.BODY_FONT, 18, host.MUTED)
	host._line(host.modal_layer, 147, 614, 1072, host.DIM_LINE)
	host._button(host.modal_layer, "NEED A HINT?", 147, 633, 180, 45, _hint, "outline", 10)
	host._button(host.modal_layer, "CLEAR", 339, 633, 130, 45, _clear, "outline", 10)
	host._button(host.modal_layer, "CHECK THE ASSAY   →", 917, 633, 302, 45, _check, "primary", 10)
	_refresh()

func _refresh() -> void:
	for i in range(sample_buttons.size()):
		sample_buttons[i].set_pressed_no_signal(selected.has(i))
	for i in range(option_buttons.size()):
		option_buttons[i].set_pressed_no_signal(i == selected_option)
	counter.text = "%d / 2 SELECTED" % selected.size()

func _choose_sample(index: int) -> void:
	if index < 0 or index >= TRIAL.samples.size():
		return
	if selected.has(index):
		selected.erase(index)
	elif selected.size() < 2:
		selected.append(index)
	else:
		feedback.text = "Two samples are selected. Click one again to remove it."
		feedback.add_theme_color_override("font_color", host.MUTED)
		_refresh()
		return
	feedback.text = "Check quality and batch before comparing the counts."
	feedback.add_theme_color_override("font_color", host.MUTED)
	_refresh()

func _choose_option(index: int) -> void:
	if index < 0 or index >= TRIAL.options.size():
		return
	selected_option = index
	feedback.text = "CPM compares the target counts after accounting for mapped-library size."
	feedback.add_theme_color_override("font_color", host.MUTED)
	_refresh()

func _hint() -> void:
	feedback.text = "CPM = target count / mapped reads in millions. Use a passing control and case from the same batch."
	feedback.add_theme_color_override("font_color", host.TEAL)

func _clear() -> void:
	selected.clear()
	selected_option = -1
	feedback.text = "Start again. Click two sample names, then one CPM answer."
	feedback.add_theme_color_override("font_color", host.MUTED)
	_refresh()

func _check() -> void:
	var pair := TRIAL.review_pair(selected)
	if not pair.get("ok", false):
		match String(pair.get("error", "")):
			"choose_two":
				feedback.text = "Select exactly two samples: one control and one case."
			"failed_qc":
				feedback.text = "A selected sample failed the provided quality check. Choose passing samples."
			"need_control_and_case":
				feedback.text = "Compare one control with one case, not two from the same condition."
			"different_batch":
				feedback.text = "Different batches could confound the comparison. Find a passing pair from the same batch."
			_:
				feedback.text = "That pair cannot be compared in this assay. Check the samples and try again."
		feedback.add_theme_color_override("font_color", Color("e6a49a"))
		return
	if selected_option < 0:
		feedback.text = "Now choose the control and case counts per million."
		feedback.add_theme_color_override("font_color", Color("e6a49a"))
		return
	if not TRIAL.grade(selected, selected_option):
		feedback.text = "Check library size: divide each target count by its mapped reads in millions."
		feedback.add_theme_color_override("font_color", Color("e6a49a"))
		return
	host.game["swamp_puzzle_solved"] = true
	host._save_game()
	host._update_hud()
	if host.swamp_region != null:
		host.swamp_region.update_kraken()
	show_success(true)

func show_success(newly_recovered: bool = false) -> void:
	host._clear_modal()
	host.overlay_kind = "swamp_success"
	host._dim_screen(0.84)
	host._modal_frame(307, 118, 752, 532)
	host._image(host.modal_layer, host.HELIX, Vector2(643, 147), Vector2(80, 80))
	host._label(host.modal_layer, "EVIDENCE RECOVERED" if newly_recovered else "EVIDENCE ALREADY RECOVERED", 405, 231, 556, 22, host.UI_FONT, 10, host.TEAL, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "The noise falls quiet.", 357, 264, 652, 52, host.TITLE_FONT, 27, host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "The passing same-batch pair has 30 CPM each, although the raw target counts were 60 and 120.", 396, 331, 574, 72, host.BODY_FONT, 22, Color("cbd2c8"), HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "One pair cannot establish equal expression. Replication, quality checks and careful analysis still matter.", 396, 418, 574, 68, host.ITALIC_FONT, 20, Color("aac5b8"), HORIZONTAL_ALIGNMENT_CENTER)
	host._line(host.modal_layer, 401, 508, 565, host.DIM_LINE)
	var reward_text := "+ 1 DATA FRAGMENT       •       + %d XP" % QUEST.evidence.xp if newly_recovered else "FRAGMENT ALREADY RECOVERED       •       NO ADDITIONAL XP"
	host._label(host.modal_layer, reward_text, 413, 522, 540, 23, host.UI_FONT, 11, host.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	host._button(host.modal_layer, "RETURN TO THE SWAMP   →", 501, 558, 365, 48, host._clear_modal, "primary", 11)
