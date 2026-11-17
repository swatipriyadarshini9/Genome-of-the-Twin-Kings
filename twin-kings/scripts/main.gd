extends Control

# Playable vertical slice. World art and interface are separate from puzzle
# rules and the save model so each can evolve independently.
const TITLE_FONT: Font = preload("res://assets/fonts/Cinzel.ttf")
const BODY_FONT: Font = preload("res://assets/fonts/CormorantGaramond-Regular.ttf")
const ITALIC_FONT: Font = preload("res://assets/fonts/CormorantGaramond-Italic.ttf")
const UI_FONT: Font = preload("res://assets/fonts/DMSans.ttf")
const KINGDOM: Texture2D = preload("res://assets/kingdom.jpg")
const DUNGEON: Texture2D = preload("res://assets/dungeon.jpg")
const MENU_SHADE: Texture2D = preload("res://assets/menu-shade.png")
const DUNGEON_SHADE: Texture2D = preload("res://assets/dungeon-shade.png")
const AREN: Texture2D = preload("res://assets/aren.png")
const HELIX: Texture2D = preload("res://assets/helix.svg")
const MARKER: Texture2D = preload("res://assets/marker.svg")
const ATMOSPHERE = preload("res://scripts/atmosphere.gd")
const TRANSITION = preload("res://scripts/dna_transition.gd")
const FOREST_REGION = preload("res://scripts/forest_region.gd")
const RIVER_REGION = preload("res://scripts/river_region.gd")
const SWAMP_REGION = preload("res://scripts/swamp_region.gd")
const MISSING_REGION = preload("res://scripts/missing_data_region.gd")
const FINAL_REGION = preload("res://scripts/final_trial_region.gd")
const JOURNAL = preload("res://scripts/evidence_journal.gd")

const W := 1366.0
const H := 768.0
const IVORY := Color("e9e2d0")
const MUTED := Color("a6a89f")
const GOLD := Color("c6a976")
const BRIGHT_GOLD := Color("e2c594")
const TEAL := Color("7bbdb3")
const DIM_LINE := Color(0.67, 0.57, 0.40, 0.34)
const TERMINAL_X := 808.0
const GATE_X := 1182.0
const PLAYER_MIN := 102.0
const PLAYER_MAX := 1235.0
const SPEED := 260.0

var scene_layer: Control
var modal_layer: Control
var current_screen := "menu"
var overlay_kind := ""
var return_from_modal := "menu"
var settings: Dictionary = {}
var game: Dictionary = {}
var saved_game: Dictionary = {}
var forest_region: ForestRegion
var river_region: RiverRegion
var swamp_region: SwampRegion
var missing_region: MissingDataRegion
var final_region: FinalTrialRegion
var journal: EvidenceJournal

var player: TextureRect
var world_ambience: Control
var objective_title: Label
var objective_detail: Label
var evidence_label: Label
var xp_label: Label
var interact_button: Button
var prompt_label: Label
var controls_tip: Label
var gate_marker: Button
var puzzle_counter: Label
var puzzle_feedback: Label
var puzzle_hint: Label
var puzzle_selected: Array[int] = []
var is_hint_visible := false
var current_codex_page := 0

var player_x := 270.0
var target_x := -1.0
var pending_action := ""
var held_left := false
var held_right := false
var walk_time := 0.0
var save_timer := 0.0
var position_dirty := false
var facing_right := true

func _ready() -> void:
	settings = SaveData.load_settings()
	journal = JOURNAL.new(self)
	scene_layer = Control.new()
	scene_layer.name = "SceneLayer"
	scene_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scene_layer)
	modal_layer = Control.new()
	modal_layer.name = "ModalLayer"
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal_layer)
	_show_menu()

# ---------------------------------------------------------------------------
# UI building blocks
# ---------------------------------------------------------------------------
func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _clear_modal() -> void:
	_clear_children(modal_layer)
	overlay_kind = ""
	held_left = false
	held_right = false

func _image(parent: Node, texture: Texture2D, pos: Vector2, dimensions: Vector2, mouse: int = Control.MOUSE_FILTER_IGNORE) -> TextureRect:
	var image := TextureRect.new()
	image.position = pos
	image.size = dimensions
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.mouse_filter = mouse
	parent.add_child(image)
	return image

func _label(parent: Node, text: String, x: float, y: float, width: float, height: float, font: Font, font_size: int, color: Color = IVORY, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	# Set autowrap before text/size: otherwise Label's initial minimum width is
	# the entire unwrapped string and Godot will refuse the requested width.
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	# Godot's default extra line spacing can hide a final wrapped line in a
	# fixed-height game HUD. Zero keeps two-line descriptions within their box.
	label.add_theme_constant_override("line_spacing", 0)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = Vector2(x, y)
	# Large display fonts need at least one full font-height or Godot's
	# clipping can hide the line entirely, even if the glyphs look smaller.
	label.size = Vector2(width, maxf(height, font.get_height(font_size) + 2.0))
	parent.add_child(label)
	return label

func _line(parent: Node, x: float, y: float, width: float, color: Color = DIM_LINE, height: float = 1.0) -> ColorRect:
	var line := ColorRect.new()
	line.position = Vector2(x, y)
	line.size = Vector2(width, height)
	line.color = color
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)
	return line

func _style(bg: Color, border: Color = Color(0, 0, 0, 0), border_width: int = 0, radius: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style

func _panel(parent: Node, x: float, y: float, width: float, height: float, bg: Color, border: Color = DIM_LINE, border_width: int = 1) -> Panel:
	var panel := Panel.new()
	panel.position = Vector2(x, y)
	panel.size = Vector2(width, height)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(bg, border, border_width, 2))
	parent.add_child(panel)
	return panel

func _button(parent: Node, text: String, x: float, y: float, width: float, height: float, callback: Callable, kind: String = "outline", font_size: int = 12) -> Button:
	var b := Button.new()
	b.text = text
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.position = Vector2(x, y)
	b.size = Vector2(width, height)
	b.add_theme_font_override("font", UI_FONT)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", IVORY)
	b.add_theme_color_override("font_hover_color", Color("fff5de"))
	b.add_theme_color_override("font_pressed_color", Color("101914"))
	b.add_theme_color_override("font_hover_pressed_color", Color("101914"))
	b.add_theme_color_override("font_disabled_color", Color(0.60, 0.61, 0.57, 0.50))
	var normal: StyleBoxFlat
	var hover: StyleBoxFlat
	var down: StyleBoxFlat
	match kind:
		"primary":
			normal = _style(Color("c8aa76"), Color("dbc394"), 1, 2)
			hover = _style(Color("e1c48f"), Color("f2dbad"), 1, 2)
			down = _style(Color("af8f5e"), Color("e5cca0"), 1, 2)
			b.add_theme_color_override("font_color", Color("151b17"))
			b.add_theme_color_override("font_hover_color", Color("101713"))
		"plain":
			normal = _style(Color(0, 0, 0, 0))
			hover = _style(Color(0.75, 0.67, 0.50, 0.08))
			down = _style(Color(0.75, 0.67, 0.50, 0.18))
			b.add_theme_color_override("font_pressed_color", BRIGHT_GOLD)
		"base":
			normal = _style(Color("202d2c"), Color(0.46, 0.61, 0.56, 0.28), 1, 2)
			hover = _style(Color("324944"), Color(0.54, 0.75, 0.69, 0.7), 1, 2)
			down = _style(Color("94c6b8"), Color("bde5d7"), 1, 2)
			normal.content_margin_left = 0
			normal.content_margin_right = 0
			hover.content_margin_left = 0
			hover.content_margin_right = 0
			down.content_margin_left = 0
			down.content_margin_right = 0
		_:
			normal = _style(Color(0.04, 0.07, 0.065, 0.80), Color(0.65, 0.57, 0.42, 0.46), 1, 2)
			hover = _style(Color(0.13, 0.17, 0.15, 0.96), Color(0.84, 0.72, 0.53, 0.8), 1, 2)
			down = _style(Color("c8aa76"), Color("e5cca0"), 1, 2)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("hover_pressed", down)
	b.add_theme_stylebox_override("disabled", _style(Color(0.04, 0.06, 0.055, 0.47), Color(0.40, 0.39, 0.34, 0.3), 1, 2))
	var focus := _style(Color(0, 0, 0, 0), Color(0.89, 0.77, 0.56, 0.85), 1, 2)
	focus.expand_margin_left = 3
	focus.expand_margin_right = 3
	focus.expand_margin_top = 3
	focus.expand_margin_bottom = 3
	b.add_theme_stylebox_override("focus", focus)
	if callback.is_valid():
		b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _dim_screen(opacity: float = 0.79) -> void:
	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(W, H)
	dim.color = Color(0.008, 0.017, 0.016, opacity)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_layer.add_child(dim)

func _modal_frame(x: float, y: float, width: float, height: float) -> void:
	_panel(modal_layer, x, y, width, height, Color("111b19"), Color(0.72, 0.63, 0.47, 0.66), 1)
	# A second hairline gives the window a little of an illuminated-manuscript feel.
	_panel(modal_layer, x + 6, y + 6, width - 12, height - 12, Color(0, 0, 0, 0), Color(0.70, 0.62, 0.46, 0.16), 1)

func _close_button(x: float, y: float, callback: Callable = _clear_modal) -> void:
	_button(modal_layer, "×", x, y, 42, 42, callback, "plain", 22)

func _add_atmosphere(parent: Node) -> Control:
	var fx: Control = ATMOSPHERE.new()
	fx.reduced_motion = bool(settings.get("reduced_motion", false))
	parent.add_child(fx)
	return fx

# ---------------------------------------------------------------------------
# Main menu and navigation
# ---------------------------------------------------------------------------
func _show_menu() -> void:
	current_screen = "menu"
	_clear_modal()
	_clear_children(scene_layer)
	saved_game = SaveData.load_game()
	_image(scene_layer, KINGDOM, Vector2.ZERO, Vector2(W, H))
	_image(scene_layer, MENU_SHADE, Vector2.ZERO, Vector2(W, H))
	world_ambience = _add_atmosphere(scene_layer)
	_image(scene_layer, HELIX, Vector2(70, 34), Vector2(46, 46))
	_label(scene_layer, "THE CHRONICLES OF HELIX", 128, 38, 300, 25, UI_FONT, 11, BRIGHT_GOLD)
	_label(scene_layer, "A STORY OF BLOOD & TRUTH", 128, 60, 300, 17, UI_FONT, 9, MUTED)
	_label(scene_layer, "A NARRATIVE BIOINFORMATICS RPG", 96, 138, 410, 22, UI_FONT, 11, GOLD)
	_label(scene_layer, "GENOME", 91, 171, 510, 79, TITLE_FONT, 67, IVORY)
	_label(scene_layer, "OF THE", 97, 242, 170, 25, UI_FONT, 11, GOLD)
	_line(scene_layer, 153, 254, 52, Color(0.78, 0.66, 0.47, 0.7))
	_label(scene_layer, "TWIN KINGS", 91, 264, 540, 76, TITLE_FONT, 51, IVORY)
	_line(scene_layer, 97, 350, 56, GOLD)
	_label(scene_layer, "One crown. Two brothers.\nOnly the evidence can reveal the truth.", 96, 364, 480, 66, ITALIC_FONT, 25, Color("d5d2c3"))
	_button(scene_layer, "START GAME                         →", 96, 458, 300, 51, _on_new_game, "primary", 12)
	var cont := _button(scene_layer, "CONTINUE                              →", 96, 518, 300, 48, _on_continue, "outline", 12)
	cont.disabled = saved_game.is_empty()
	if saved_game.is_empty():
		if _has_save_file():
			_label(scene_layer, "SAVE UNREADABLE  /  STARTING OVER CREATES A NEW SAVE", 110, 566, 430, 18, UI_FONT, 9, Color("e6a49a"))
		else:
			_label(scene_layer, "NO SAVED JOURNEY YET", 110, 566, 250, 18, UI_FONT, 9, Color(0.67, 0.67, 0.61, 0.68))
	else:
		_label(scene_layer, "YOUR JOURNEY IS SAVED ON THIS DEVICE", 110, 566, 300, 18, UI_FONT, 9, Color(0.70, 0.73, 0.67, 0.75))
	_button(scene_layer, "BIOINFORMATICS CODEX", 96, 595, 260, 37, _open_codex_from_menu, "plain", 11)
	_button(scene_layer, "SETTINGS", 96, 637, 110, 34, _open_settings_from_menu, "plain", 11)
	_button(scene_layer, "CREDITS", 208, 637, 110, 34, _show_credits, "plain", 11)
	_line(scene_layer, 70, 707, 1226, Color(0.74, 0.65, 0.49, 0.25))
	_label(scene_layer, "PROLOGUE  /  THE FALSE KING", 72, 715, 350, 20, UI_FONT, 9, Color(0.79, 0.78, 0.70, 0.76))
	_label(scene_layer, "A KINGDOM BUILT ON A LIE.", 1010, 715, 286, 20, UI_FONT, 9, Color(0.79, 0.78, 0.70, 0.76), HORIZONTAL_ALIGNMENT_RIGHT)
	_label(scene_layer, "THE KINGDOM OF HELIX", 1050, 46, 246, 20, UI_FONT, 10, Color(0.85, 0.80, 0.67, 0.8), HORIZONTAL_ALIGNMENT_RIGHT)
	_image(scene_layer, MARKER, Vector2(1240, 593), Vector2(20, 20))
	_label(scene_layer, "THE TRUTH AWAITS", 1045, 625, 250, 19, UI_FONT, 9, BRIGHT_GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	_label(scene_layer, "Some secrets are written in blood.", 975, 645, 320, 28, ITALIC_FONT, 19, IVORY, HORIZONTAL_ALIGNMENT_RIGHT)

func _has_save_file() -> bool:
	return FileAccess.file_exists(SaveData.GAME_PATH) or FileAccess.file_exists(SaveData.V5_GAME_PATH) or FileAccess.file_exists(SaveData.V4_GAME_PATH) or FileAccess.file_exists(SaveData.V3_GAME_PATH) or FileAccess.file_exists(SaveData.V2_GAME_PATH) or FileAccess.file_exists(SaveData.LEGACY_GAME_PATH)

func _on_new_game() -> void:
	var existing := SaveData.load_game()
	if not existing.is_empty() or _has_save_file():
		_show_new_game_confirmation(existing.is_empty())
		return
	_begin_new_game()

func _show_new_game_confirmation(unreadable: bool = false) -> void:
	_clear_modal()
	overlay_kind = "confirm"
	_dim_screen()
	_modal_frame(400, 236, 566, 296)
	_label(modal_layer, "A NEW JOURNEY", 440, 271, 440, 22, UI_FONT, 10, GOLD)
	_label(modal_layer, "Begin again?", 440, 300, 450, 52, TITLE_FONT, 31, IVORY)
	var warning := "The existing save cannot be read. Starting over creates a new active save." if unreadable else "Starting a new game replaces the journey saved on this device."
	_label(modal_layer, warning, 440, 359, 470, 63, BODY_FONT, 21, MUTED)
	_button(modal_layer, "CANCEL", 440, 445, 180, 45, _clear_modal, "outline", 11)
	_button(modal_layer, "START OVER  →", 638, 445, 270, 45, _begin_new_game, "primary", 11)
	_close_button(901, 259)

func _begin_new_game() -> void:
	game = SaveData.new_game()
	player_x = float(game["player_x"])
	_save_game()
	_transition_to_game()

func _on_continue() -> void:
	game = SaveData.load_game()
	if game.is_empty():
		_show_menu()
		return
	player_x = float(game.get("player_x", 270.0))
	_transition_to_game()

func _transition_to_game() -> void:
	_clear_modal()
	overlay_kind = "transition"
	if bool(settings.get("reduced_motion", false)):
		_build_game()
		_on_transition_finished()
		return
	var transition: Control = TRANSITION.new()
	modal_layer.add_child(transition)
	transition.midpoint.connect(_build_game)
	transition.finished.connect(_on_transition_finished)

func _on_transition_finished() -> void:
	_clear_modal()
	if _in_final():
		if not bool(game.get("final_intro_seen", false)) and final_region != null:
			final_region.show_intro()
	elif _in_missing():
		if not bool(game.get("missing_intro_seen", false)) and missing_region != null:
			missing_region.show_intro()
	elif _in_swamp():
		if not bool(game.get("swamp_intro_seen", false)) and swamp_region != null:
			swamp_region.show_intro()
	elif _in_river():
		if not bool(game.get("river_intro_seen", false)) and river_region != null:
			river_region.show_intro()
	elif _in_forest():
		if not bool(game.get("forest_intro_seen", false)) and forest_region != null:
			forest_region.show_intro()
	elif not bool(game.get("intro_seen", false)):
		_show_intro()

func _in_forest() -> bool:
	return game.get("region", "dungeon") == "forest"

func _in_river() -> bool:
	return game.get("region", "dungeon") == "river"

func _in_swamp() -> bool:
	return game.get("region", "dungeon") == "swamp"

func _in_missing() -> bool:
	return game.get("region", "dungeon") == "missing"

func _in_final() -> bool:
	return game.get("region", "dungeon") == "final"

# ---------------------------------------------------------------------------
# The 2D first room
# ---------------------------------------------------------------------------
func _build_game() -> void:
	current_screen = "game"
	_clear_children(scene_layer)
	target_x = -1.0
	pending_action = ""
	held_left = false
	held_right = false
	forest_region = null
	river_region = null
	swamp_region = null
	missing_region = null
	final_region = null
	if _in_forest():
		forest_region = FOREST_REGION.new(self)
		forest_region.build()
		return
	if _in_river():
		river_region = RIVER_REGION.new(self)
		river_region.build()
		return
	if _in_swamp():
		swamp_region = SWAMP_REGION.new(self)
		swamp_region.build()
		return
	if _in_missing():
		missing_region = MISSING_REGION.new(self)
		missing_region.build()
		return
	if _in_final():
		final_region = FINAL_REGION.new(self)
		final_region.build()
		return
	var world := _image(scene_layer, DUNGEON, Vector2.ZERO, Vector2(W, H), Control.MOUSE_FILTER_STOP)
	world.gui_input.connect(_on_world_input)
	_image(scene_layer, DUNGEON_SHADE, Vector2.ZERO, Vector2(W, H))
	world_ambience = _add_atmosphere(scene_layer)
	# Floor shadow and character are separate from the background to allow movement.
	var shadow := ColorRect.new()
	shadow.color = Color(0.0, 0.0, 0.0, 0.0)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_layer.add_child(shadow)
	player = _image(scene_layer, AREN, Vector2(player_x - 38, 471), Vector2(76, 178))
	player.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player.pivot_offset = Vector2(38, 89)
	# Clickable markers also walk Aren over to the corresponding object.
	var terminal_marker := _button(scene_layer, "", 782, 338, 56, 49, _walk_to_terminal, "plain", 10)
	_image(terminal_marker, MARKER, Vector2(12, 8), Vector2(32, 32))
	gate_marker = _button(scene_layer, "", 1150, 339, 56, 49, _walk_to_gate, "plain", 10)
	_image(gate_marker, MARKER, Vector2(12, 8), Vector2(32, 32))
	_build_world_hud("THE DUNGEON OF FALSE ANNOTATIONS", "PROLOGUE   /   THE FALSE KING")
	_update_hud()
	_update_player_visual(false)

func _build_world_hud(location_title: String, chapter_label: String) -> void:
	# Shared by all regions; the quest data supplies evidence and XP totals.
	_image(scene_layer, HELIX, Vector2(27, 20), Vector2(41, 41))
	_label(scene_layer, location_title, 78, 22, 520, 22, UI_FONT, 11, IVORY)
	_label(scene_layer, chapter_label, 78, 44, 410, 17, UI_FONT, 9, GOLD)
	evidence_label = _label(scene_layer, "EVIDENCE  0 / 5", 685, 30, 145, 22, UI_FONT, 10, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	xp_label = _label(scene_layer, "0 XP", 837, 30, 70, 22, UI_FONT, 10, IVORY, HORIZONTAL_ALIGNMENT_RIGHT)
	_button(scene_layer, "JOURNAL", 918, 23, 100, 35, _open_journal_from_game, "outline", 10)
	_button(scene_layer, "CODEX", 1027, 23, 100, 35, _open_codex_from_game, "outline", 10)
	_button(scene_layer, "MENU", 1136, 23, 100, 35, _show_pause, "outline", 10)
	_panel(scene_layer, 30, 104, 334, 145, Color(0.035, 0.065, 0.06, 0.90), Color(0.71, 0.62, 0.47, 0.45), 1)
	_image(scene_layer, MARKER, Vector2(49, 120), Vector2(14, 14))
	_label(scene_layer, "CURRENT OBJECTIVE", 72, 119, 247, 18, UI_FONT, 10, GOLD)
	objective_title = _label(scene_layer, "", 49, 145, 290, 30, TITLE_FONT, 17, IVORY)
	objective_detail = _label(scene_layer, "", 49, 181, 285, 50, BODY_FONT, 19, Color("c1c4b9"))
	prompt_label = _label(scene_layer, "", 450, 663, 465, 28, UI_FONT, 10, BRIGHT_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	controls_tip = _label(scene_layer, "MOVE: A / D OR ARROWS  •  CLICK A MARKER  •  J: JOURNAL", 37, 733, 630, 18, UI_FONT, 9, Color(0.83, 0.82, 0.74, 0.82))
	var left := _button(scene_layer, "←", 34, 677, 48, 42, Callable(), "outline", 20)
	var right := _button(scene_layer, "→", 88, 677, 48, 42, Callable(), "outline", 20)
	left.button_down.connect(_press_left)
	left.button_up.connect(_release_left)
	right.button_down.connect(_press_right)
	right.button_up.connect(_release_right)
	interact_button = _button(scene_layer, "E     INTERACT", 1106, 677, 224, 44, _interact, "outline", 11)

func _show_intro() -> void:
	_clear_modal()
	overlay_kind = "intro"
	_dim_screen(0.76)
	_modal_frame(262, 143, 842, 476)
	_label(modal_layer, "PROLOGUE   /   THE FALSE KING", 309, 179, 420, 20, UI_FONT, 10, GOLD)
	_line(modal_layer, 309, 218, 748, DIM_LINE)
	_label(modal_layer, "You are not the villain.", 307, 238, 725, 66, TITLE_FONT, 34, IVORY)
	_label(modal_layer, "Your twin wears your face. Now he wears your crown.", 309, 314, 695, 42, ITALIC_FONT, 25, BRIGHT_GOLD)
	_label(modal_layer, "The kingdom believes his lie. You, Aren, were left to rot beneath the castle. But even the most carefully buried truth leaves a trace.", 309, 367, 693, 80, BODY_FONT, 24, Color("c8cbc0"))
	_line(modal_layer, 309, 476, 748, DIM_LINE)
	_label(modal_layer, "THE DUNGEON OF FALSE ANNOTATIONS", 309, 503, 400, 20, UI_FONT, 10, MUTED)
	_button(modal_layer, "ENTER THE DUNGEON   →", 783, 502, 271, 51, _dismiss_intro, "primary", 11)

func _dismiss_intro() -> void:
	game["intro_seen"] = true
	_save_game()
	_clear_modal()

func _press_left() -> void:
	held_left = true
	target_x = -1.0
	pending_action = ""
func _release_left() -> void:
	held_left = false
func _press_right() -> void:
	held_right = true
	target_x = -1.0
	pending_action = ""
func _release_right() -> void:
	held_right = false

func _on_world_input(event: InputEvent) -> void:
	if current_screen != "game" or overlay_kind != "":
		return
	if _in_forest() and forest_region != null:
		forest_region.handle_world_click(event)
		return
	if _in_river() and river_region != null:
		river_region.handle_world_click(event)
		return
	if _in_swamp() and swamp_region != null:
		swamp_region.handle_world_click(event)
		return
	if _in_missing() and missing_region != null:
		missing_region.handle_world_click(event)
		return
	if _in_final() and final_region != null:
		final_region.handle_world_click(event)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var point: Vector2 = event.position
		if point.x >= 680 and point.x <= 1000 and point.y >= 280 and point.y <= 635:
			_walk_to_terminal()
		elif point.x >= 1070 and point.y >= 210 and point.y <= 650:
			_walk_to_gate()
		else:
			target_x = clampf(point.x, PLAYER_MIN, PLAYER_MAX)
			pending_action = ""

func _walk_to_terminal() -> void:
	if overlay_kind != "":
		return
	target_x = TERMINAL_X
	pending_action = "terminal"

func _walk_to_gate() -> void:
	if overlay_kind != "":
		return
	target_x = GATE_X
	pending_action = "gate"

func _process(delta: float) -> void:
	if current_screen != "game" or overlay_kind != "" or not is_instance_valid(player):
		return
	if _in_forest() and forest_region != null:
		forest_region.tick(delta)
	elif _in_river() and river_region != null:
		river_region.tick(delta)
	elif _in_swamp() and swamp_region != null:
		swamp_region.tick(delta)
	elif _in_missing() and missing_region != null:
		missing_region.tick(delta)
	elif _in_final() and final_region != null:
		final_region.tick(delta)
	var direction := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or held_left:
		direction -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or held_right:
		direction += 1.0
	var old_x := player_x
	if direction != 0.0:
		target_x = -1.0
		pending_action = ""
		player_x = clampf(player_x + direction * SPEED * delta, PLAYER_MIN, PLAYER_MAX)
		facing_right = direction > 0.0
	elif target_x >= 0.0:
		facing_right = target_x >= player_x
		player_x = move_toward(player_x, target_x, SPEED * delta)
		if absf(player_x - target_x) < 0.5:
			target_x = -1.0
			var action := pending_action
			pending_action = ""
			if action != "":
				_interact()
	var moving := absf(player_x - old_x) > 0.01
	if moving:
		walk_time += delta * 11.0
		position_dirty = true
	_update_player_visual(moving)
	_update_prompt()
	if position_dirty:
		save_timer += delta
		if save_timer > 2.0:
			_save_game()
			position_dirty = false
			save_timer = 0.0

func _update_player_visual(moving: bool) -> void:
	if not is_instance_valid(player):
		return
	var bob := 0.0
	if moving and not bool(settings.get("reduced_motion", false)):
		bob = absf(sin(walk_time)) * 2.8
	player.position = Vector2(player_x - 38, 471 - bob)
	player.scale.x = 1.0 if facing_right else -1.0

func _update_hud() -> void:
	if not is_instance_valid(objective_title):
		return
	evidence_label.text = "EVIDENCE  %d / %d" % [GameProgress.collected_count(game), GameProgress.QUESTS.size()]
	xp_label.text = "%d XP" % GameProgress.total_xp(game)
	controls_tip.visible = bool(settings.get("show_hints", true))
	if _in_forest() and forest_region != null:
		forest_region.update_objective()
	elif _in_river() and river_region != null:
		river_region.update_objective()
	elif _in_swamp() and swamp_region != null:
		swamp_region.update_objective()
	elif _in_missing() and missing_region != null:
		missing_region.update_objective()
	elif _in_final() and final_region != null:
		final_region.update_objective()
	else:
		var solved := bool(game.get("puzzle_solved", false))
		objective_title.text = "Reach the gate" if solved else "Investigate the terminal"
		objective_detail.text = "The gate is unlocked. Escape." if solved else "Search the terminal for a clue."
		if is_instance_valid(gate_marker):
			gate_marker.modulate = Color(1, 1, 1, 1) if solved else Color(1, 1, 1, 0.45)
	_update_prompt()

func _update_prompt() -> void:
	if not is_instance_valid(interact_button):
		return
	if _in_forest() and forest_region != null:
		forest_region.update_prompt()
		return
	if _in_river() and river_region != null:
		river_region.update_prompt()
		return
	if _in_swamp() and swamp_region != null:
		swamp_region.update_prompt()
		return
	if _in_missing() and missing_region != null:
		missing_region.update_prompt()
		return
	if _in_final() and final_region != null:
		final_region.update_prompt()
		return
	var near_terminal := absf(player_x - TERMINAL_X) <= 102.0
	var near_gate := absf(player_x - GATE_X) <= 100.0
	interact_button.disabled = not (near_terminal or near_gate)
	if near_terminal:
		prompt_label.text = "E  /  EXAMINE THE ANCIENT TERMINAL"
		interact_button.text = "E     EXAMINE TERMINAL"
	elif near_gate:
		prompt_label.text = "E  /  EXAMINE THE GATE"
		interact_button.text = "E     EXAMINE GATE"
	else:
		prompt_label.text = ""
		interact_button.text = "E     INTERACT"

func _interact() -> void:
	if current_screen != "game" or overlay_kind != "":
		return
	held_left = false
	held_right = false
	if _in_forest() and forest_region != null:
		forest_region.interact()
		return
	if _in_river() and river_region != null:
		river_region.interact()
		return
	if _in_swamp() and swamp_region != null:
		swamp_region.interact()
		return
	if _in_missing() and missing_region != null:
		missing_region.interact()
		return
	if _in_final() and final_region != null:
		final_region.interact()
		return
	if absf(player_x - TERMINAL_X) <= 102.0:
		if bool(game.get("puzzle_solved", false)):
			_show_puzzle_success()
		else:
			_show_puzzle()
	elif absf(player_x - GATE_X) <= 100.0:
		if bool(game.get("puzzle_solved", false)):
			game["chapter_complete"] = true
			_save_game()
			_show_chapter_complete()
		else:
			_show_locked_gate()

func _show_locked_gate() -> void:
	_clear_modal()
	overlay_kind = "gate_locked"
	_dim_screen(0.67)
	_modal_frame(429, 253, 508, 260)
	_label(modal_layer, "THE IRON GATE", 468, 287, 420, 21, UI_FONT, 10, GOLD)
	_label(modal_layer, "The seal holds.", 468, 321, 420, 44, TITLE_FONT, 27, IVORY)
	_label(modal_layer, "The terminal's record may be the key to opening it.", 468, 374, 420, 47, BODY_FONT, 22, MUTED)
	_button(modal_layer, "RETURN TO THE DUNGEON", 468, 446, 315, 42, _clear_modal, "outline", 10)
	_close_button(872, 270)

func _save_game() -> void:
	if game.is_empty():
		return
	game["player_x"] = player_x
	SaveData.save_game(game)

func _show_pause() -> void:
	_save_game()
	_clear_modal()
	overlay_kind = "pause"
	_dim_screen(0.78)
	_modal_frame(441, 134, 484, 498)
	_label(modal_layer, "THE JOURNEY PAUSED", 485, 175, 390, 20, UI_FONT, 10, GOLD)
	_label(modal_layer, "Take a moment.", 485, 205, 400, 49, TITLE_FONT, 27, IVORY)
	_line(modal_layer, 485, 273, 396, DIM_LINE)
	_button(modal_layer, "RESUME JOURNEY", 485, 294, 396, 44, _clear_modal, "primary", 11)
	_button(modal_layer, "EVIDENCE JOURNAL", 485, 347, 396, 40, _open_journal_from_pause, "outline", 11)
	_button(modal_layer, "BIOINFORMATICS CODEX", 485, 396, 396, 40, _open_codex_from_pause, "outline", 11)
	_button(modal_layer, "SETTINGS", 485, 445, 396, 40, _open_settings_from_pause, "outline", 11)
	_button(modal_layer, "SAVE & RETURN TO TITLE", 485, 494, 396, 40, _save_and_menu, "outline", 11)
	_label(modal_layer, "Your progress is saved on this device.", 485, 548, 396, 24, BODY_FONT, 18, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_close_button(861, 149)

func _save_and_menu() -> void:
	_save_game()
	_show_menu()

# ---------------------------------------------------------------------------
# First puzzle: equal-length sequence comparison
# ---------------------------------------------------------------------------
func _show_puzzle() -> void:
	_clear_modal()
	overlay_kind = "puzzle"
	puzzle_selected.clear()
	is_hint_visible = false
	_dim_screen(0.85)
	_modal_frame(111, 56, 1144, 656)
	_label(modal_layer, "ANCIENT TERMINAL   /   EVIDENCE 01", 151, 82, 650, 20, UI_FONT, 10, TEAL)
	_label(modal_layer, "The records don't agree.", 150, 114, 750, 53, TITLE_FONT, 31, IVORY)
	_label(modal_layer, "Select the TWO prison-record bases that differ from the reference.", 151, 173, 742, 56, BODY_FONT, 21, Color("c5cbc1"))
	_close_button(1190, 72)
	_line(modal_layer, 151, 245, 1063, DIM_LINE)
	_label(modal_layer, "POSITION  /  1-BASED", 152, 265, 330, 18, UI_FONT, 9, MUTED)
	var start_x := 153.0
	var cell_width := 31.0
	var step := 36.0
	for i in range(SequencePuzzle.REFERENCE.length()):
		_label(modal_layer, str(i + 1), start_x + i * step, 288, cell_width, 18, UI_FONT, 9, Color(0.72, 0.75, 0.69, 0.75), HORIZONTAL_ALIGNMENT_CENTER)
	_label(modal_layer, "REFERENCE", 153, 314, 210, 17, UI_FONT, 10, GOLD)
	for i in range(SequencePuzzle.REFERENCE.length()):
		_panel(modal_layer, start_x + i * step, 339, cell_width, 39, Color("182522"), Color(0.63, 0.63, 0.52, 0.24), 1)
		_label(modal_layer, SequencePuzzle.REFERENCE[i], start_x + i * step, 339, cell_width, 39, UI_FONT, 16, Color("d9ded1"), HORIZONTAL_ALIGNMENT_CENTER)
	_label(modal_layer, "PRISON RECORD    /    SELECT THE DIFFERENCES", 153, 400, 580, 19, UI_FONT, 10, TEAL)
	for i in range(SequencePuzzle.PRISON_RECORD.length()):
		var base := _button(modal_layer, SequencePuzzle.PRISON_RECORD[i], start_x + i * step, 428, cell_width, 42, Callable(), "base", 16)
		base.toggle_mode = true
		base.toggled.connect(_on_base_toggled.bind(i + 1))
	puzzle_counter = _label(modal_layer, "0 / 2 DIFFERENCES SELECTED", 153, 486, 430, 22, UI_FONT, 10, MUTED)
	puzzle_feedback = _label(modal_layer, "", 153, 516, 650, 44, BODY_FONT, 19, Color("e4a59b"))
	# A small teaching card makes the investigation understandable without outside knowledge.
	_panel(modal_layer, 847, 268, 354, 270, Color("192826"), Color(0.41, 0.61, 0.56, 0.3), 1)
	_label(modal_layer, "FROM THE CODEX", 872, 286, 290, 20, UI_FONT, 10, TEAL)
	_label(modal_layer, "What am I looking for?", 872, 319, 300, 40, TITLE_FONT, 16, IVORY)
	_label(modal_layer, "A substitution is a change in one DNA base. Compare each column, not the whole sequence at once.", 872, 365, 293, 87, BODY_FONT, 19, Color("c5d2c8"))
	_line(modal_layer, 872, 461, 298, Color(0.47, 0.65, 0.59, 0.32))
	puzzle_hint = _label(modal_layer, "Need a nudge? Ask for a hint below.", 872, 471, 286, 49, BODY_FONT, 18, MUTED)
	_line(modal_layer, 151, 577, 1063, DIM_LINE)
	_button(modal_layer, "NEED A HINT?", 151, 608, 184, 49, _reveal_hint, "outline", 11)
	_button(modal_layer, "CHECK MY EVIDENCE   →", 934, 608, 267, 49, _check_puzzle, "primary", 11)
	_label(modal_layer, "Select a base again to unselect it.", 352, 614, 330, 31, ITALIC_FONT, 18, MUTED)

func _on_base_toggled(pressed: bool, position: int) -> void:
	if pressed and not puzzle_selected.has(position):
		puzzle_selected.append(position)
	elif not pressed:
		puzzle_selected.erase(position)
	puzzle_counter.text = "%d / 2 DIFFERENCES SELECTED" % puzzle_selected.size()
	puzzle_feedback.text = ""

func _reveal_hint() -> void:
	is_hint_visible = true
	puzzle_hint.text = "One difference is in positions 1–9; the other is in positions 10–18."

func _check_puzzle() -> void:
	if SequencePuzzle.is_correct(puzzle_selected):
		game["puzzle_solved"] = true
		_save_game()
		_update_hud()
		_show_puzzle_success(true)
	else:
		puzzle_feedback.text = "Not quite. Compare each column again; check for extra or missing selections."

func _show_puzzle_success(newly_recovered: bool = false) -> void:
	_clear_modal()
	overlay_kind = "success"
	_dim_screen(0.82)
	_modal_frame(327, 128, 712, 512)
	_image(modal_layer, HELIX, Vector2(643, 157), Vector2(80, 80))
	_label(modal_layer, "EVIDENCE RECOVERED" if newly_recovered else "EVIDENCE ALREADY RECOVERED", 425, 241, 516, 22, UI_FONT, 10, TEAL, HORIZONTAL_ALIGNMENT_CENTER)
	_label(modal_layer, "A pattern emerges.", 382, 271, 602, 54, TITLE_FONT, 29, IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	_label(modal_layer, "You found two differences: position 6 (A → T) and position 12 (C → T). The terminal releases the gate.", 405, 339, 555, 70, BODY_FONT, 22, Color("cbd2c8"), HORIZONTAL_ALIGNMENT_CENTER)
	_label(modal_layer, "A mismatch may be a variant or an error—it is not proof of identity on its own. Keep the original data and verify it.", 405, 418, 555, 70, ITALIC_FONT, 20, Color("aac5b8"), HORIZONTAL_ALIGNMENT_CENTER)
	_line(modal_layer, 401, 506, 565, DIM_LINE)
	var xp: int = GameProgress.QUESTS[0].evidence.xp
	var reward_text := "+ 1 DATA FRAGMENT       •       + %d XP" % xp if newly_recovered else "FRAGMENT ALREADY RECOVERED       •       NO ADDITIONAL XP"
	_label(modal_layer, reward_text, 413, 519, 540, 23, UI_FONT, 11, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_button(modal_layer, "RETURN TO THE DUNGEON   →", 501, 555, 365, 48, _clear_modal, "primary", 11)

func _show_chapter_complete() -> void:
	_clear_modal()
	overlay_kind = "complete"
	_dim_screen(0.83)
	_modal_frame(290, 99, 786, 570)
	_label(modal_layer, "PROLOGUE COMPLETE", 358, 143, 650, 24, UI_FONT, 11, TEAL, HORIZONTAL_ALIGNMENT_CENTER)
	_label(modal_layer, "A door opens.\nA question remains.", 356, 183, 654, 100, TITLE_FONT, 32, IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	_line(modal_layer, 480, 302, 406, DIM_LINE)
	_label(modal_layer, "You recovered the first data fragment. But a difference between two records is only the beginning of a case.", 395, 322, 576, 70, BODY_FONT, 23, Color("cbd0c5"), HORIZONTAL_ALIGNMENT_CENTER)
	_label(modal_layer, "NEXT IN THE STORY", 397, 416, 572, 20, UI_FONT, 10, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_label(modal_layer, "Sequence Forest", 397, 442, 572, 38, TITLE_FONT, 22, IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	_label(modal_layer, "A new trail opens beyond the prison.", 397, 485, 572, 26, ITALIC_FONT, 19, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_button(modal_layer, "REVISIT THE DUNGEON", 375, 546, 280, 49, _clear_modal, "outline", 10)
	_button(modal_layer, "ENTER SEQUENCE FOREST   →", 669, 546, 322, 49, _enter_forest, "primary", 11)

func _enter_forest() -> void:
	if not bool(game.get("chapter_complete", false)):
		return
	game["region"] = "forest"
	player_x = SaveData.FOREST_START_X
	_save_game()
	_transition_to_game()

func _enter_river() -> void:
	if not bool(game.get("forest_complete", false)):
		return
	game["region"] = "river"
	player_x = SaveData.RIVER_START_X
	_save_game()
	_transition_to_game()

func _enter_swamp() -> void:
	if not bool(game.get("river_complete", false)):
		return
	game["region"] = "swamp"
	player_x = SaveData.SWAMP_START_X
	_save_game()
	_transition_to_game()

func _enter_missing() -> void:
	if not bool(game.get("swamp_complete", false)):
		return
	game["region"] = "missing"
	player_x = SaveData.MISSING_START_X
	_save_game()
	_transition_to_game()

func _enter_final() -> void:
	if not bool(game.get("missing_complete", false)):
		return
	game["region"] = "final"
	player_x = SaveData.FINAL_START_X
	_save_game()
	_transition_to_game()

# ---------------------------------------------------------------------------
# Codex, journal, settings, and credits
# ---------------------------------------------------------------------------
func _open_journal_from_game() -> void:
	return_from_modal = "game"
	journal.show(0)

func _open_journal_from_pause() -> void:
	return_from_modal = "pause"
	journal.show(0)

func _open_codex_from_menu() -> void:
	return_from_modal = "menu"
	_show_codex(0)
func _open_codex_from_game() -> void:
	return_from_modal = "game"
	_show_codex(0)
func _open_codex_from_pause() -> void:
	return_from_modal = "pause"
	_show_codex(0)

func _show_codex(page: int = 0) -> void:
	_clear_modal()
	overlay_kind = "codex"
	current_codex_page = clampi(page, 0, 8)
	_dim_screen(0.86)
	_modal_frame(166, 71, 1034, 626)
	_label(modal_layer, "A FIELD GUIDE TO TRUTH", 209, 100, 500, 20, UI_FONT, 10, TEAL)
	_label(modal_layer, "Bioinformatics Codex", 208, 129, 680, 53, TITLE_FONT, 30, IVORY)
	_label(modal_layer, "Knowledge is the first piece of evidence.", 210, 184, 610, 28, ITALIC_FONT, 20, MUTED)
	_close_button(1134, 88, _return_to_previous)
	_line(modal_layer, 210, 225, 948, DIM_LINE)
	var tabs := ["01     THE DNA ALPHABET", "02     READING A SEQUENCE", "03     VARIANTS & ERRORS", "04     TWINS & EVIDENCE", "05     INSERTIONS & DELETIONS", "06     READ OVERLAPS", "07     RNA-SEQ & NOISE", "08     CALLS & COVERAGE", "09     CUSTODY & REVIEW"]
	for i in range(tabs.size()):
		var tab := _button(modal_layer, tabs[i], 210, 247 + i * 38, 274, 35, _show_codex.bind(i), "plain", 10)
		tab.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if i == current_codex_page:
			tab.add_theme_color_override("font_color", BRIGHT_GOLD)
			_line(modal_layer, 210, 249 + i * 38, 3, GOLD, 32)
	_line(modal_layer, 500, 252, 1, Color(0.67, 0.57, 0.40, 0.22), 325)
	var titles := ["The DNA alphabet", "Reading a sequence", "A difference is a clue", "Twins & evidence", "Gaps in an alignment", "From reads to contigs", "A signal in the noise", "When a site is missing", "A traceable record"]
	var eyebrows := ["01   /   THE BASICS", "02   /   ALIGNMENT", "03   /   INTERPRETATION", "04   /   SCIENTIFIC INTEGRITY", "05   /   INSERTIONS & DELETIONS", "06   /   GENOME ASSEMBLY", "07   /   RNA-SEQ", "08   /   VARIANT EVIDENCE", "09   /   CUSTODY & REVIEW"]
	var bodies := [
		"DNA can be represented as a sequence of four bases: A, C, G and T. In double-stranded DNA, A pairs with T, and C pairs with G.",
		"A sequence is normally written from its 5′ end to its 3′ end. When two equal-length sequences are already aligned, compare their bases column by column. Positions here start at 1.",
		"A mismatch is an observed difference between records. It might reflect a real variant, a sequencing error, or another issue. A substitution changes one base into another.",
		"Identical twins share most inherited DNA, but changes can arise in some cells. Mismatches alone do not prove identity or tampering; verify samples independently.",
		"A gap in the reference indicates an insertion in the sample. A gap in the sample indicates a deletion relative to the reference. A dash is not a DNA base.",
		"Reads are short sequences. Matching ends can join them into a longer contig. Real data may contain errors, repeats and more than one plausible assembly.",
		"RNA-seq counts depend on library size. Check quality and batch design before comparing. CPM rescales counts, but cannot replace replication or a statistical model.",
		"Variant calling examines reads aligned to a reference. Low coverage may require no call. A candidate is not confirmed: check quality, mapping, strand bias and independent evidence.",
		"Chain of custody records who handled a sample, when and how. Repeating a reading from one aliquot cannot undo labeling errors shared by both runs. Seek independent evidence."
	]
	var examples := [
		"BASE PAIRS    A — T       C — G",
		"POSITION         1   2   3   4\nREFERENCE      A   C   G   T\nSAMPLE             A   C   A   T",
		"OBSERVATION ≠ CONCLUSION\nCompare. Check quality. Replicate.",
		"GOOD EVIDENCE IS TRACEABLE\nRecord the source, method and limitations.",
		"INSERTION     REF  A – C    /    SAMPLE  A T C\nDELETION       REF  A T C    /    SAMPLE  A – C",
		"ATGCCG  +  CCGTTA  →  ATGCCGTTA\nTHE SHARED CCG IS COUNTED ONCE",
		"CPM = TARGET COUNT / MAPPED READS IN MILLIONS\n60 / 2M = 30 CPM     120 / 4M = 30 CPM",
		"TOY RULE: KEEP Q ≥ 30; DEPTH ≥ 4\n2 / 4 PASSING READS SUPPORT G AT SITE 112",
		"PRESERVE ORIGINALS  /  DOCUMENT CUSTODY\nA REPEAT IS NOT AN INDEPENDENT SAMPLE"
	]
	_label(modal_layer, eyebrows[current_codex_page], 538, 249, 530, 20, UI_FONT, 10, GOLD)
	_label(modal_layer, titles[current_codex_page], 538, 281, 558, 45, TITLE_FONT, 23, IVORY)
	_label(modal_layer, bodies[current_codex_page], 538, 338, 578, 120, BODY_FONT, 22, Color("c9cfc4"))
	_panel(modal_layer, 538, 472, 582, 92, Color("192926"), Color(0.43, 0.62, 0.56, 0.28), 1)
	_label(modal_layer, examples[current_codex_page], 558, 484, 544, 68, UI_FONT, 12, Color("b7d7c7"))
	_line(modal_layer, 210, 603, 948, DIM_LINE)
	_label(modal_layer, "THE CODEX WILL GROW AS THE KINGDOM OPENS.", 212, 622, 600, 24, UI_FONT, 9, MUTED)
	_button(modal_layer, "BACK", 1018, 615, 140, 40, _return_to_previous, "outline", 10)

func _open_settings_from_menu() -> void:
	return_from_modal = "menu"
	_show_settings()
func _open_settings_from_pause() -> void:
	return_from_modal = "pause"
	_show_settings()

func _show_settings() -> void:
	_clear_modal()
	overlay_kind = "settings"
	_dim_screen(0.86)
	_modal_frame(276, 99, 814, 570)
	_label(modal_layer, "MAKE THE JOURNEY YOURS", 320, 131, 600, 20, UI_FONT, 10, GOLD)
	_label(modal_layer, "Settings", 320, 163, 600, 50, TITLE_FONT, 30, IVORY)
	_close_button(1028, 112, _return_to_previous)
	_line(modal_layer, 320, 231, 726, DIM_LINE)
	_label(modal_layer, "DISPLAY & ACCESSIBILITY", 320, 252, 500, 22, UI_FONT, 10, TEAL)
	_label(modal_layer, "Reduced motion", 320, 293, 440, 29, TITLE_FONT, 17, IVORY)
	_label(modal_layer, "Skip the DNA transition and ambient movement.", 320, 324, 500, 29, BODY_FONT, 19, MUTED)
	var reduced := bool(settings.get("reduced_motion", false))
	_button(modal_layer, "ON" if reduced else "OFF", 920, 302, 125, 43, _toggle_motion, "primary" if reduced else "outline", 11)
	_line(modal_layer, 320, 369, 726, Color(0.67, 0.57, 0.40, 0.21))
	_label(modal_layer, "Movement hints", 320, 386, 440, 29, TITLE_FONT, 17, IVORY)
	_label(modal_layer, "Show the control reminder while exploring.", 320, 417, 500, 29, BODY_FONT, 19, MUTED)
	var hints := bool(settings.get("show_hints", true))
	_button(modal_layer, "ON" if hints else "OFF", 920, 395, 125, 43, _toggle_hints, "primary" if hints else "outline", 11)
	_line(modal_layer, 320, 462, 726, Color(0.67, 0.57, 0.40, 0.21))
	_label(modal_layer, "LOCAL SAVE", 320, 485, 340, 22, UI_FONT, 10, TEAL)
	_label(modal_layer, "Progress and settings are stored on this device. This prototype has no audio yet.", 320, 511, 650, 56, BODY_FONT, 19, MUTED)
	_button(modal_layer, "BACK", 883, 593, 162, 42, _return_to_previous, "outline", 10)

func _toggle_motion() -> void:
	settings["reduced_motion"] = not bool(settings.get("reduced_motion", false))
	SaveData.save_settings(settings)
	if is_instance_valid(world_ambience):
		world_ambience.reduced_motion = settings["reduced_motion"]
	_show_settings()

func _toggle_hints() -> void:
	settings["show_hints"] = not bool(settings.get("show_hints", true))
	SaveData.save_settings(settings)
	if current_screen == "game":
		_update_hud()
	_show_settings()

func _return_to_previous() -> void:
	if return_from_modal == "pause":
		_show_pause()
	elif return_from_modal == "final_review" and final_region != null:
		final_region.challenge.show_review()
	elif return_from_modal == "final_profile" and final_region != null:
		final_region.challenge.show_profile()
	else:
		_clear_modal()

func _show_credits() -> void:
	_clear_modal()
	overlay_kind = "credits"
	_dim_screen(0.86)
	_modal_frame(312, 118, 742, 532)
	_label(modal_layer, "THE CHRONICLES OF HELIX", 356, 151, 600, 20, UI_FONT, 10, GOLD)
	_label(modal_layer, "Credits", 356, 184, 600, 48, TITLE_FONT, 30, IVORY)
	_close_button(990, 131)
	_line(modal_layer, 356, 245, 654, DIM_LINE)
	_label(modal_layer, "GENOME OF THE TWIN KINGS", 356, 267, 600, 23, UI_FONT, 11, TEAL)
	_label(modal_layer, "A playable prologue and five chapters, inspired by the project README. Built with Godot 4.", 356, 301, 628, 64, BODY_FONT, 21, Color("cbd0c5"))
	_label(modal_layer, "ART & TYPE", 356, 388, 600, 20, UI_FONT, 10, GOLD)
	_label(modal_layer, "Original concept artwork was AI-generated for this prototype. Typefaces: Cinzel, Cormorant Garamond and DM Sans, used under the SIL Open Font License.", 356, 418, 625, 80, BODY_FONT, 20, MUTED)
	_line(modal_layer, 356, 525, 654, DIM_LINE)
	_button(modal_layer, "BACK TO THE TITLE", 356, 550, 250, 45, _clear_modal, "outline", 10)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		match overlay_kind:
			"":
				if current_screen == "game":
					_show_pause()
			"intro":
				_dismiss_intro()
			"forest_intro":
				if forest_region != null:
					forest_region.dismiss_intro()
			"river_intro":
				if river_region != null:
					river_region.dismiss_intro()
			"swamp_intro":
				if swamp_region != null:
					swamp_region.dismiss_intro()
			"missing_intro":
				if missing_region != null:
					missing_region.dismiss_intro()
			"final_intro":
				if final_region != null:
					final_region.dismiss_intro()
			"codex", "settings", "journal":
				_return_to_previous()
			"transition", "river_crossing":
				pass
			_:
				_clear_modal()
		get_viewport().set_input_as_handled()
	elif current_screen == "game" and overlay_kind == "" and (event.keycode == KEY_E or event.keycode == KEY_SPACE):
		_interact()
		get_viewport().set_input_as_handled()
	elif current_screen == "game" and overlay_kind == "" and event.keycode == KEY_J:
		_open_journal_from_game()
		get_viewport().set_input_as_handled()
