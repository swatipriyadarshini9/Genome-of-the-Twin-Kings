class_name ForestRegion
extends RefCounted

const FOREST: Texture2D = preload("res://assets/sequence-forest.jpg")
const SAGE: Texture2D = preload("res://assets/sage.png")
const SPRITE: Texture2D = preload("res://assets/snp-sprite.png")
const SAGE_X := 435.0
const ARCHIVE_X := 858.0
const EXIT_X := 1182.0
const REACH := 92.0

var host
var challenge: ForestChallengeScreen
var sprite_image: TextureRect
var archive_marker: Button
var exit_marker: Button
var elapsed := 0.0

func _init(controller) -> void:
	host = controller
	challenge = ForestChallengeScreen.new(host)

func build() -> void:
	var world: TextureRect = host._image(host.scene_layer, FOREST, Vector2.ZERO, Vector2(host.W, host.H), Control.MOUSE_FILTER_STOP)
	world.gui_input.connect(host._on_world_input)
	host._image(host.scene_layer, host.DUNGEON_SHADE, Vector2.ZERO, Vector2(host.W, host.H))
	host.world_ambience = host._add_atmosphere(host.scene_layer)
	var sage: TextureRect = host._image(host.scene_layer, SAGE, Vector2(SAGE_X - 44, 469), Vector2(88, 180))
	sage.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite_image = host._image(host.scene_layer, SPRITE, Vector2(800, 328), Vector2(116, 116))
	sprite_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host.player = host._image(host.scene_layer, host.AREN, Vector2(host.player_x - 38, 471), Vector2(76, 178))
	host.player.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host.player.pivot_offset = Vector2(38, 89)
	_marker(407, 390, _walk_to_sage)
	archive_marker = _marker(830, 294, _walk_to_archive)
	exit_marker = _marker(1154, 321, _walk_to_exit)
	host._build_world_hud("SEQUENCE FOREST", "CHAPTER 01   /   THE SCATTERED SURVEY")
	host._update_hud()
	host._update_player_visual(false)

func _marker(x: float, y: float, callback: Callable) -> Button:
	var button: Button = host._button(host.scene_layer, "", x, y, 56, 49, callback, "plain", 10)
	host._image(button, host.MARKER, Vector2(12, 8), Vector2(32, 32))
	return button

func tick(delta: float) -> void:
	if is_instance_valid(sprite_image) and not bool(host.settings.get("reduced_motion", false)):
		elapsed += delta
		sprite_image.position.y = 328.0 + sin(elapsed * 1.7) * 5.0

func handle_world_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var point: Vector2 = event.position
		if point.x >= 325 and point.x <= 540 and point.y >= 330 and point.y <= 650:
			_walk_to_sage()
		elif point.x >= 735 and point.x <= 1004 and point.y >= 265 and point.y <= 650:
			_walk_to_archive()
		elif point.x >= 1070 and point.y >= 210 and point.y <= 650:
			_walk_to_exit()
		else:
			host.target_x = clampf(point.x, host.PLAYER_MIN, host.PLAYER_MAX)
			host.pending_action = ""

func _walk_to_sage() -> void:
	_walk_to(SAGE_X, "sage")
func _walk_to_archive() -> void:
	_walk_to(ARCHIVE_X, "forest_archive")
func _walk_to_exit() -> void:
	_walk_to(EXIT_X, "forest_exit")
func _walk_to(x: float, action: String) -> void:
	if host.overlay_kind != "":
		return
	host.target_x = x
	host.pending_action = action

func update_objective() -> void:
	var solved := bool(host.game.get("forest_puzzle_solved", false))
	var complete := bool(host.game.get("forest_complete", false))
	if complete:
		host.objective_title.text = "Forest chapter complete"
		host.objective_detail.text = "Approach the arch to continue."
	else:
		host.objective_title.text = "Reach the forest arch" if solved else "Untangle the survey"
		host.objective_detail.text = "The path through the forest is clear." if solved else "Find the sprite by the archive."
	if is_instance_valid(exit_marker):
		exit_marker.modulate = Color(1, 1, 1, 1) if solved else Color(1, 1, 1, 0.45)

func update_prompt() -> void:
	var near_sage: bool = absf(host.player_x - SAGE_X) <= REACH
	var near_archive: bool = absf(host.player_x - ARCHIVE_X) <= REACH
	var near_exit: bool = absf(host.player_x - EXIT_X) <= REACH
	host.interact_button.disabled = not (near_sage or near_archive or near_exit)
	if near_sage:
		host.prompt_label.text = "E  /  SPEAK WITH THE GENOME SAGE"
		host.interact_button.text = "E     SPEAK TO SAGE"
	elif near_archive:
		host.prompt_label.text = "E  /  INSPECT THE SPRITE'S SURVEY"
		host.interact_button.text = "E     INSPECT SURVEY"
	elif near_exit:
		host.prompt_label.text = "E  /  EXAMINE THE FOREST ARCH"
		host.interact_button.text = "E     EXAMINE ARCH"
	else:
		host.prompt_label.text = ""
		host.interact_button.text = "E     INTERACT"

func interact() -> void:
	if absf(host.player_x - SAGE_X) <= REACH:
		show_sage()
	elif absf(host.player_x - ARCHIVE_X) <= REACH:
		if bool(host.game.get("forest_puzzle_solved", false)):
			challenge.show_success()
		else:
			challenge.show()
	elif absf(host.player_x - EXIT_X) <= REACH:
		if bool(host.game.get("forest_puzzle_solved", false)):
			host.game["forest_complete"] = true
			host._save_game()
			host._update_hud()
			show_complete()
		else:
			show_blocked_path()

func show_intro() -> void:
	host._clear_modal()
	host.overlay_kind = "forest_intro"
	host._dim_screen(0.76)
	host._modal_frame(262, 143, 842, 476)
	host._label(host.modal_layer, "CHAPTER 01   /   SEQUENCE FOREST", 309, 179, 500, 20, host.UI_FONT, 10, host.TEAL)
	host._line(host.modal_layer, 309, 218, 748, host.DIM_LINE)
	host._label(host.modal_layer, "The forest remembers.", 307, 238, 725, 66, host.TITLE_FONT, 34, host.IVORY)
	host._label(host.modal_layer, "Every living thing carries a record.", 309, 314, 695, 42, host.ITALIC_FONT, 25, host.BRIGHT_GOLD)
	host._label(host.modal_layer, "Beyond the prison lies an old forest archive. A wary sage watches as a sprite tangles the survey's labels. Find what changed, and the path ahead may open.", 309, 367, 693, 80, host.BODY_FONT, 23, Color("c8cbc0"))
	host._line(host.modal_layer, 309, 476, 748, host.DIM_LINE)
	host._label(host.modal_layer, "THE SPRITE'S SCATTERED SURVEY", 309, 503, 410, 20, host.UI_FONT, 10, host.MUTED)
	host._button(host.modal_layer, "ENTER THE FOREST   →", 783, 502, 271, 51, dismiss_intro, "primary", 11)

func dismiss_intro() -> void:
	host.game["forest_intro_seen"] = true
	host._save_game()
	host._clear_modal()

func show_sage() -> void:
	host._clear_modal()
	host.overlay_kind = "sage"
	host._dim_screen(0.72)
	host._modal_frame(307, 167, 752, 434)
	host._label(host.modal_layer, "THE GENOME SAGE  /  A SCRIPTED GUIDE", 350, 199, 620, 20, host.UI_FONT, 10, host.TEAL)
	host._label(host.modal_layer, "Look between the letters.", 350, 231, 635, 51, host.TITLE_FONT, 27, host.IVORY)
	var speech := "The sprite has mixed up the survey. A dash is a gap, not a DNA base. Compare the sample with its reference, one column at a time."
	if bool(host.game.get("forest_puzzle_solved", false)):
		speech = "Well done. Keep the source with the observation, and remember: an apparent change still needs to be checked."
	host._label(host.modal_layer, "“" + speech + "”", 350, 302, 635, 103, host.BODY_FONT, 23, Color("ccd4c9"))
	host._line(host.modal_layer, 350, 435, 664, host.DIM_LINE)
	host._button(host.modal_layer, "READ ABOUT GAPS", 350, 465, 250, 47, _open_gap_codex, "outline", 10)
	host._button(host.modal_layer, "CONTINUE   →", 690, 465, 324, 47, host._clear_modal, "primary", 11)
	host._close_button(997, 183)

func _open_gap_codex() -> void:
	host.return_from_modal = "game"
	host._show_codex(4)

func show_blocked_path() -> void:
	host._clear_modal()
	host.overlay_kind = "forest_blocked"
	host._dim_screen(0.72)
	host._modal_frame(411, 244, 544, 280)
	host._label(host.modal_layer, "THE FOREST ARCH", 452, 277, 450, 20, host.UI_FONT, 10, host.GOLD)
	host._label(host.modal_layer, "The path is veiled.", 452, 308, 460, 46, host.TITLE_FONT, 25, host.IVORY)
	host._label(host.modal_layer, "The sprite guards a survey near the old archive. Perhaps it can be persuaded with careful analysis.", 452, 365, 450, 70, host.BODY_FONT, 20, host.MUTED)
	host._button(host.modal_layer, "RETURN TO THE FOREST", 452, 460, 280, 42, host._clear_modal, "outline", 10)
	host._close_button(886, 261)

func show_complete() -> void:
	host._clear_modal()
	host.overlay_kind = "forest_complete"
	host._dim_screen(0.84)
	host._modal_frame(290, 99, 786, 570)
	host._label(host.modal_layer, "CHAPTER 01 COMPLETE", 358, 143, 650, 24, host.UI_FONT, 11, host.TEAL, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "One path.\nTwo pieces of evidence.", 356, 183, 654, 100, host.TITLE_FONT, 30, host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	host._line(host.modal_layer, 480, 302, 406, host.DIM_LINE)
	host._label(host.modal_layer, "The archive has yielded another clue. A convincing case still needs its sources, limitations and independent checks.", 395, 322, 576, 75, host.BODY_FONT, 22, Color("cbd0c5"), HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "NEXT IN THE STORY", 397, 416, 572, 20, host.UI_FONT, 10, host.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "Alignment River", 397, 442, 572, 38, host.TITLE_FONT, 22, host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "A new crossing awaits beyond the trees.", 397, 485, 572, 26, host.ITALIC_FONT, 19, host.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	host._button(host.modal_layer, "REVISIT THE FOREST", 375, 546, 280, 49, host._clear_modal, "outline", 10)
	host._button(host.modal_layer, "ENTER ALIGNMENT RIVER   →", 669, 546, 322, 49, host._enter_river, "primary", 11)
