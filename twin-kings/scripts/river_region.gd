class_name RiverRegion
extends RefCounted

const BACKGROUND: Texture2D = preload("res://assets/alignment-river.jpg")
const BOAT: Texture2D = preload("res://assets/river-boat.png")
const WISP: Texture2D = preload("res://assets/river-wisp.png")
const WISP_X := 430.0
const LEDGER_X := 830.0
const LANDING_X := 1182.0
const REACH := 92.0

var host
var challenge: AssemblyChallengeScreen
var wisp_image: TextureRect
var boat_image: TextureRect
var landing_marker: Button
var elapsed := 0.0

func _init(controller) -> void:
	host = controller
	challenge = AssemblyChallengeScreen.new(host)

func build() -> void:
	var world: TextureRect = host._image(host.scene_layer, BACKGROUND, Vector2.ZERO, Vector2(host.W, host.H), Control.MOUSE_FILTER_STOP)
	world.gui_input.connect(host._on_world_input)
	host._image(host.scene_layer, host.DUNGEON_SHADE, Vector2.ZERO, Vector2(host.W, host.H))
	host.world_ambience = host._add_atmosphere(host.scene_layer)
	boat_image = host._image(host.scene_layer, BOAT, Vector2(730, 512), Vector2(260, 88))
	boat_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	update_boat()
	wisp_image = host._image(host.scene_layer, WISP, Vector2(355, 352), Vector2(152, 83))
	wisp_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host.player = host._image(host.scene_layer, host.AREN, Vector2(host.player_x - 38, 471), Vector2(76, 178))
	host.player.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host.player.pivot_offset = Vector2(38, 89)
	_marker(402, 310, _walk_to_wisp)
	_marker(802, 365, _walk_to_ledger)
	landing_marker = _marker(1154, 320, _walk_to_landing)
	host._build_world_hud("ALIGNMENT RIVER", "CHAPTER 02   /   THE BROKEN LEDGER")
	host._update_hud()
	host._update_player_visual(false)

func _marker(x: float, y: float, callback: Callable) -> Button:
	var button: Button = host._button(host.scene_layer, "", x, y, 56, 49, callback, "plain", 10)
	host._image(button, host.MARKER, Vector2(12, 8), Vector2(32, 32))
	return button

func tick(delta: float) -> void:
	if bool(host.settings.get("reduced_motion", false)):
		return
	elapsed += delta
	if is_instance_valid(wisp_image):
		wisp_image.position.y = 352.0 + sin(elapsed * 1.6) * 4.0
	if is_instance_valid(boat_image) and bool(host.game.get("river_puzzle_solved", false)):
		boat_image.position.y = 512.0 + sin(elapsed * 1.2) * 2.0

func update_boat() -> void:
	if is_instance_valid(boat_image):
		boat_image.modulate = Color(1, 1, 1, 1) if bool(host.game.get("river_puzzle_solved", false)) else Color(0.7, 0.75, 0.7, 0.18)

func handle_world_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var point: Vector2 = event.position
		if point.x >= 320 and point.x <= 550 and point.y >= 280 and point.y <= 640:
			_walk_to_wisp()
		elif point.x >= 705 and point.x <= 1005 and point.y >= 295 and point.y <= 650:
			_walk_to_ledger()
		elif point.x >= 1070 and point.y >= 210 and point.y <= 650:
			_walk_to_landing()
		else:
			host.target_x = clampf(point.x, host.PLAYER_MIN, host.PLAYER_MAX)
			host.pending_action = ""

func _walk_to_wisp() -> void:
	_walk_to(WISP_X, "river_wisp")
func _walk_to_ledger() -> void:
	_walk_to(LEDGER_X, "river_ledger")
func _walk_to_landing() -> void:
	_walk_to(LANDING_X, "river_landing")
func _walk_to(x: float, action: String) -> void:
	if host.overlay_kind != "":
		return
	host.target_x = x
	host.pending_action = action

func update_objective() -> void:
	var solved := bool(host.game.get("river_puzzle_solved", false))
	if bool(host.game.get("river_complete", false)):
		host.objective_title.text = "River chapter complete"
		host.objective_detail.text = "Approach the landing to continue."
	elif solved:
		host.objective_title.text = "Launch the skiff"
		host.objective_detail.text = "Reach the eastern landing."
	else:
		host.objective_title.text = "Rebuild the skiff"
		host.objective_detail.text = "Find the ledger by the jetty."
	if is_instance_valid(landing_marker):
		landing_marker.modulate = Color(1, 1, 1, 1) if solved else Color(1, 1, 1, 0.45)

func update_prompt() -> void:
	var near_wisp: bool = absf(host.player_x - WISP_X) <= REACH
	var near_ledger: bool = absf(host.player_x - LEDGER_X) <= REACH
	var near_landing: bool = absf(host.player_x - LANDING_X) <= REACH
	host.interact_button.disabled = not (near_wisp or near_ledger or near_landing)
	if near_wisp:
		host.prompt_label.text = "E  /  SPEAK WITH THE RIVER WISP"
		host.interact_button.text = "E     SPEAK TO WISP"
	elif near_ledger:
		host.prompt_label.text = "E  /  EXAMINE THE BROKEN LEDGER"
		host.interact_button.text = "E     EXAMINE LEDGER"
	elif near_landing:
		host.prompt_label.text = "E  /  APPROACH THE EASTERN LANDING"
		host.interact_button.text = "E     LAUNCH SKIFF" if bool(host.game.get("river_puzzle_solved", false)) else "E     EXAMINE LANDING"
	else:
		host.prompt_label.text = ""
		host.interact_button.text = "E     INTERACT"

func interact() -> void:
	if absf(host.player_x - WISP_X) <= REACH:
		show_wisp()
	elif absf(host.player_x - LEDGER_X) <= REACH:
		if bool(host.game.get("river_puzzle_solved", false)):
			challenge.show_success()
		else:
			challenge.show()
	elif absf(host.player_x - LANDING_X) <= REACH:
		if bool(host.game.get("river_puzzle_solved", false)):
			_begin_crossing()
		else:
			show_blocked_landing()

func show_intro() -> void:
	host._clear_modal()
	host.overlay_kind = "river_intro"
	host._dim_screen(0.76)
	host._modal_frame(262, 143, 842, 476)
	host._label(host.modal_layer, "CHAPTER 02   /   ALIGNMENT RIVER", 309, 179, 500, 20, host.UI_FONT, 10, host.TEAL)
	host._line(host.modal_layer, 309, 218, 748, host.DIM_LINE)
	host._label(host.modal_layer, "The river keeps its secrets.", 307, 238, 725, 66, host.TITLE_FONT, 32, host.IVORY)
	host._label(host.modal_layer, "What was scattered can be joined again.", 309, 314, 695, 42, host.ITALIC_FONT, 25, host.BRIGHT_GOLD)
	host._label(host.modal_layer, "The crossing is broken, and an old ledger lies in fragments. Follow the river wisp to the jetty; join the reads to restore a boat and recover another clue.", 309, 367, 693, 80, host.BODY_FONT, 23, Color("c8cbc0"))
	host._line(host.modal_layer, 309, 476, 748, host.DIM_LINE)
	host._label(host.modal_layer, "THE BROKEN RIVER LEDGER", 309, 503, 410, 20, host.UI_FONT, 10, host.MUTED)
	host._button(host.modal_layer, "ENTER THE RIVER   →", 783, 502, 271, 51, dismiss_intro, "primary", 11)

func dismiss_intro() -> void:
	host.game["river_intro_seen"] = true
	host._save_game()
	host._clear_modal()

func show_wisp() -> void:
	host._clear_modal()
	host.overlay_kind = "river_wisp"
	host._dim_screen(0.72)
	host._modal_frame(307, 167, 752, 434)
	host._label(host.modal_layer, "THE RIVER WISP  /  A SCRIPTED GUIDE", 350, 199, 620, 20, host.UI_FONT, 10, host.TEAL)
	host._label(host.modal_layer, "Let the ends find each other.", 350, 231, 635, 51, host.TITLE_FONT, 26, host.IVORY)
	var speech := "The ledger's reads all face the same way. Match the end of one read to the beginning of the next; count the shared bases only once."
	if bool(host.game.get("river_puzzle_solved", false)):
		speech = "A single path for this little puzzle. In real data, repeats and errors can make several paths look convincing. Keep that uncertainty."
	host._label(host.modal_layer, "“" + speech + "”", 350, 302, 635, 103, host.BODY_FONT, 23, Color("ccd4c9"))
	host._line(host.modal_layer, 350, 435, 664, host.DIM_LINE)
	host._button(host.modal_layer, "READ ABOUT OVERLAPS", 350, 465, 250, 47, _open_overlap_codex, "outline", 10)
	host._button(host.modal_layer, "CONTINUE   →", 690, 465, 324, 47, host._clear_modal, "primary", 11)
	host._close_button(997, 183)

func _open_overlap_codex() -> void:
	host.return_from_modal = "game"
	host._show_codex(5)

func show_blocked_landing() -> void:
	host._clear_modal()
	host.overlay_kind = "river_blocked"
	host._dim_screen(0.72)
	host._modal_frame(411, 244, 544, 280)
	host._label(host.modal_layer, "THE EASTERN LANDING", 452, 277, 450, 20, host.UI_FONT, 10, host.GOLD)
	host._label(host.modal_layer, "The current is too strong.", 452, 308, 460, 46, host.TITLE_FONT, 24, host.IVORY)
	host._label(host.modal_layer, "The broken ledger by the jetty may hold the pattern needed to restore the skiff.", 452, 365, 450, 70, host.BODY_FONT, 20, host.MUTED)
	host._button(host.modal_layer, "RETURN TO THE RIVER", 452, 460, 280, 42, host._clear_modal, "outline", 10)
	host._close_button(886, 261)

func _begin_crossing() -> void:
	if bool(host.game.get("river_complete", false)):
		show_complete()
		return
	host.game["river_complete"] = true
	host._save_game()
	host._update_hud()
	if bool(host.settings.get("reduced_motion", false)):
		show_complete()
		return
	host._clear_modal()
	host.overlay_kind = "river_crossing"
	host._dim_screen(0.86)
	host._modal_frame(262, 143, 842, 476)
	host._label(host.modal_layer, "THE CROSSING", 309, 179, 748, 20, host.UI_FONT, 10, host.TEAL, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "The current carries you onward.", 309, 234, 748, 60, host.TITLE_FONT, 28, host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "The restored skiff follows the river toward the next shore.", 309, 307, 748, 48, host.ITALIC_FONT, 22, host.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	host._line(host.modal_layer, 364, 472, 638, Color(0.42, 0.67, 0.61, 0.45), 2)
	var sailing_boat: TextureRect = host._image(host.modal_layer, BOAT, Vector2(365, 402), Vector2(205, 68))
	sailing_boat.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tween: Tween = host.create_tween()
	tween.tween_property(sailing_boat, "position:x", 798.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(0.25)
	tween.finished.connect(show_complete)

func show_complete() -> void:
	host._clear_modal()
	host.overlay_kind = "river_complete"
	host._dim_screen(0.84)
	host._modal_frame(290, 99, 786, 570)
	host._label(host.modal_layer, "CHAPTER 02 COMPLETE", 358, 143, 650, 24, host.UI_FONT, 11, host.TEAL, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "A crossing made.\nA stronger trail.", 356, 183, 654, 100, host.TITLE_FONT, 30, host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	host._line(host.modal_layer, 480, 302, 406, host.DIM_LINE)
	host._label(host.modal_layer, "Three fragments now travel with Aren. Each observation needs context before it can become part of a convincing case.", 395, 322, 576, 75, host.BODY_FONT, 22, Color("cbd0c5"), HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "NEXT IN THE STORY", 397, 416, 572, 20, host.UI_FONT, 10, host.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "Expression Swamp", 397, 442, 572, 38, host.TITLE_FONT, 22, host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "A path through noisy waters awaits.", 397, 485, 572, 26, host.ITALIC_FONT, 19, host.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	host._button(host.modal_layer, "REVISIT THE RIVER", 375, 546, 280, 49, host._clear_modal, "outline", 10)
	host._button(host.modal_layer, "ENTER EXPRESSION SWAMP   →", 669, 546, 322, 49, host._enter_swamp, "primary", 11)
