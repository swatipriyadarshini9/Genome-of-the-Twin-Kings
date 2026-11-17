class_name AssemblyChallengeScreen
extends RefCounted

# The screen is currently laid out for four short reads; the assembly rules and
# the source reads themselves live outside the presentation code.
const TRIAL: AssemblyTrial = preload("res://data/trials/river_assembly.tres")
const QUEST: QuestDefinition = preload("res://data/quests/river_assembly.tres")
const LETTERS := ["A", "B", "C", "D"]

var host
var order: Array[int] = []
var read_buttons: Array[Button] = []
var board_layer: Control
var feedback: Label

func _init(controller) -> void:
	host = controller

func show() -> void:
	host._clear_modal()
	host.overlay_kind = "river_puzzle"
	order.clear()
	read_buttons.clear()
	host._dim_screen(0.86)
	host._modal_frame(106, 54, 1154, 660)
	host._label(host.modal_layer, "ALIGNMENT RIVER   /   THE BROKEN LEDGER", 147, 80, 700, 20, host.UI_FONT, 10, host.TEAL)
	host._label(host.modal_layer, "Build a path from fragments.", 147, 110, 900, 52, host.TITLE_FONT, 29, host.IVORY)
	host._label(host.modal_layer, "Choose all four reads in order. Each join needs at least 3 matching bases: the end of one read to the start of the next.", 148, 169, 1020, 45, host.BODY_FONT, 20, Color("c8d0c6"))
	host._close_button(1196, 69)
	host._line(host.modal_layer, 147, 222, 1072, host.DIM_LINE)
	host._label(host.modal_layer, "AVAILABLE READS  /  ALL SHOWN 5' TO 3'", 148, 235, 700, 20, host.UI_FONT, 10, host.GOLD)
	for i in range(TRIAL.reads.size()):
		var button: Button = host._button(host.modal_layer, "%s      %s" % [LETTERS[i], TRIAL.reads[i]], 147 + i * 268, 263, 253, 58, _choose.bind(i), "outline", 14)
		read_buttons.append(button)
	host._label(host.modal_layer, "YOUR ORDER  /  USE EACH READ ONCE", 148, 336, 700, 20, host.UI_FONT, 10, host.GOLD)
	host._panel(host.modal_layer, 147, 361, 1072, 68, Color("182622"), Color(0.42, 0.59, 0.53, 0.25), 1)
	host._label(host.modal_layer, "CONTIG PREVIEW  /  SHARED BASES COUNTED ONCE", 148, 446, 720, 20, host.UI_FONT, 10, host.TEAL)
	host._panel(host.modal_layer, 147, 472, 1072, 67, Color("182622"), Color(0.42, 0.59, 0.53, 0.25), 1)
	board_layer = Control.new()
	board_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.modal_layer.add_child(board_layer)
	feedback = host._label(host.modal_layer, "Select a read to begin. Use Undo if you need a different starting point.", 148, 548, 950, 52, host.BODY_FONT, 18, host.MUTED)
	host._line(host.modal_layer, 147, 614, 1072, host.DIM_LINE)
	host._button(host.modal_layer, "NEED A HINT?", 147, 633, 180, 45, _hint, "outline", 10)
	host._button(host.modal_layer, "UNDO", 339, 633, 130, 45, _undo, "outline", 10)
	host._button(host.modal_layer, "CLEAR", 481, 633, 130, 45, _clear, "outline", 10)
	host._button(host.modal_layer, "BUILD THE BOAT   →", 917, 633, 302, 45, _check, "primary", 10)
	_refresh_board()

func _refresh_board() -> void:
	host._clear_children(board_layer)
	for i in range(read_buttons.size()):
		read_buttons[i].disabled = order.has(i)
	for slot in range(TRIAL.reads.size()):
		var label_text := "%d     —" % (slot + 1)
		var colour: Color = host.MUTED
		if slot < order.size():
			var idx: int = order[slot]
			label_text = "%d     %s  /  %s" % [slot + 1, LETTERS[idx], TRIAL.reads[idx]]
			colour = host.IVORY
		host._label(board_layer, label_text, 158 + slot * 263, 370, 235, 50, host.UI_FONT, 12, colour, HORIZONTAL_ALIGNMENT_CENTER)
		if slot < TRIAL.reads.size() - 1:
			host._label(board_layer, "→", 388 + slot * 263, 371, 35, 47, host.UI_FONT, 16, host.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	if order.is_empty():
		host._label(board_layer, "Your assembled sequence will appear here.", 170, 480, 700, 47, host.ITALIC_FONT, 18, host.MUTED)
		return
	var result := TRIAL.assemble(order, false)
	if not result.get("ok", false):
		return
	var contig: String = result["contig"]
	for i in range(contig.length()):
		var x := 169.0 + i * 38.0
		host._panel(board_layer, x, 485, 32, 40, Color("263c36"), Color(0.45, 0.62, 0.55, 0.29), 1)
		host._label(board_layer, contig[i], x, 485, 32, 40, host.UI_FONT, 14, host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	var joins: PackedInt32Array = result["joins"]
	var detail := "1 READ  /  NO JOIN YET"
	if not joins.is_empty():
		detail = "%d READS  /  LAST JOIN: %d BASES" % [order.size(), joins[joins.size() - 1]]
	host._label(board_layer, detail, 875, 486, 318, 38, host.UI_FONT, 10, host.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)

func _choose(index: int) -> void:
	if index < 0 or index >= TRIAL.reads.size() or order.has(index):
		return
	if not order.is_empty():
		var overlap := ReadAssembly.longest_overlap(TRIAL.reads[order[order.size() - 1]], TRIAL.reads[index])
		if overlap < TRIAL.min_overlap:
			feedback.text = "The river stirs: that join has fewer than %d matching bases. Try another read or use Undo." % TRIAL.min_overlap
			feedback.add_theme_color_override("font_color", Color("e6a49a"))
			return
		feedback.text = "%d shared bases join these reads; the overlap appears only once in the contig." % overlap
		feedback.add_theme_color_override("font_color", host.TEAL)
	else:
		feedback.text = "A starting read is in place. Compare its ending with the start of another read."
		feedback.add_theme_color_override("font_color", host.MUTED)
	order.append(index)
	_refresh_board()

func _hint() -> void:
	feedback.text = "Start with a read that has no matching predecessor. Then match its last 3 bases to the next read's first 3."
	feedback.add_theme_color_override("font_color", host.TEAL)

func _undo() -> void:
	if order.is_empty():
		feedback.text = "There are no reads to undo yet."
	else:
		order.pop_back()
		feedback.text = "The last read was removed. You can choose a different path."
	feedback.add_theme_color_override("font_color", host.MUTED)
	_refresh_board()

func _clear() -> void:
	order.clear()
	feedback.text = "Start again with any read. Use each fragment once."
	feedback.add_theme_color_override("font_color", host.MUTED)
	_refresh_board()

func _check() -> void:
	if not TRIAL.grade(order):
		feedback.text = "Use all four reads with at least 3 matching bases at every join."
		feedback.add_theme_color_override("font_color", Color("e6a49a"))
		return
	host.game["river_puzzle_solved"] = true
	host._save_game()
	host._update_hud()
	if host.river_region != null:
		host.river_region.update_boat()
	show_success(true)

func show_success(newly_recovered: bool = false) -> void:
	host._clear_modal()
	host.overlay_kind = "river_success"
	host._dim_screen(0.84)
	host._modal_frame(307, 118, 752, 532)
	host._image(host.modal_layer, host.HELIX, Vector2(643, 147), Vector2(80, 80))
	host._label(host.modal_layer, "EVIDENCE RECOVERED" if newly_recovered else "EVIDENCE ALREADY RECOVERED", 405, 231, 556, 22, host.UI_FONT, 10, host.TEAL, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "One continuous thread.", 357, 264, 652, 52, host.TITLE_FONT, 27, host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "The reads join into a contig. As the ledger is restored, the river's broken boat takes shape.", 396, 331, 574, 72, host.BODY_FONT, 22, Color("cbd2c8"), HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "Real assemblies must account for errors, repeats and missing coverage; an overlap alone may not be unique.", 396, 418, 574, 68, host.ITALIC_FONT, 20, Color("aac5b8"), HORIZONTAL_ALIGNMENT_CENTER)
	host._line(host.modal_layer, 401, 508, 565, host.DIM_LINE)
	var reward_text := "+ 1 DATA FRAGMENT       •       + %d XP" % QUEST.evidence.xp if newly_recovered else "FRAGMENT ALREADY RECOVERED       •       NO ADDITIONAL XP"
	host._label(host.modal_layer, reward_text, 413, 522, 540, 23, host.UI_FONT, 11, host.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	host._button(host.modal_layer, "RETURN TO THE RIVER   →", 501, 558, 365, 48, host._clear_modal, "primary", 11)
