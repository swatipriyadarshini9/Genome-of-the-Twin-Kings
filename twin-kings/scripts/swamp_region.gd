class_name SwampRegion
extends RefCounted

const BACKGROUND: Texture2D = preload("res://assets/expression-swamp.jpg")
const KRAKEN: Texture2D = preload("res://assets/swamp-kraken.png")
const KRAKEN_X := 430.0
const ASSAY_X := 950.0
const ARCH_X := 1182.0
const REACH := 92.0

var host
var challenge: ExpressionChallengeScreen
var kraken_image: TextureRect
var arch_marker: Button
var elapsed := 0.0

func _init(controller) -> void:
	host = controller
	challenge = ExpressionChallengeScreen.new(host)

func build() -> void:
	var world: TextureRect = host._image(host.scene_layer, BACKGROUND, Vector2.ZERO, Vector2(host.W, host.H), Control.MOUSE_FILTER_STOP)
	world.gui_input.connect(host._on_world_input)
	host._image(host.scene_layer, host.DUNGEON_SHADE, Vector2.ZERO, Vector2(host.W, host.H))
	host.world_ambience = host._add_atmosphere(host.scene_layer)
	kraken_image = host._image(host.scene_layer, KRAKEN, Vector2(310, 340), Vector2(280, 130))
	kraken_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	update_kraken()
	host.player = host._image(host.scene_layer, host.AREN, Vector2(host.player_x - 38, 471), Vector2(76, 178))
	host.player.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host.player.pivot_offset = Vector2(38, 89)
	_marker(402, 302, _walk_to_kraken)
	_marker(922, 368, _walk_to_assay)
	arch_marker = _marker(1154, 292, _walk_to_arch)
	host._build_world_hud("EXPRESSION SWAMP", "CHAPTER 03   /   THE MARSH ASSAY")
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
	if is_instance_valid(kraken_image):
		kraken_image.position.y = 340.0 + sin(elapsed * 1.35) * 4.0

func update_kraken() -> void:
	if is_instance_valid(kraken_image):
		kraken_image.modulate = Color(0.82, 1.0, 0.91, 0.74) if bool(host.game.get("swamp_puzzle_solved", false)) else Color.WHITE

func handle_world_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var point: Vector2 = event.position
		if point.x >= 310 and point.x <= 600 and point.y >= 275 and point.y <= 640:
			_walk_to_kraken()
		elif point.x >= 795 and point.x <= 1055 and point.y >= 300 and point.y <= 650:
			_walk_to_assay()
		elif point.x >= 1070 and point.y >= 210 and point.y <= 650:
			_walk_to_arch()
		else:
			host.target_x = clampf(point.x, host.PLAYER_MIN, host.PLAYER_MAX)
			host.pending_action = ""

func _walk_to_kraken() -> void:
	_walk_to(KRAKEN_X, "swamp_kraken")
func _walk_to_assay() -> void:
	_walk_to(ASSAY_X, "swamp_assay")
func _walk_to_arch() -> void:
	_walk_to(ARCH_X, "swamp_arch")
func _walk_to(x: float, action: String) -> void:
	if host.overlay_kind != "":
		return
	host.target_x = x
	host.pending_action = action

func update_objective() -> void:
	var solved := bool(host.game.get("swamp_puzzle_solved", false))
	if bool(host.game.get("swamp_complete", false)):
		host.objective_title.text = "Swamp chapter complete"
		host.objective_detail.text = "Approach the arch to continue."
	elif solved:
		host.objective_title.text = "Reach the marsh arch"
		host.objective_detail.text = "The water is calm. Go east."
	else:
		host.objective_title.text = "Untangle the noise"
		host.objective_detail.text = "Investigate the marsh assay."
	if is_instance_valid(arch_marker):
		arch_marker.modulate = Color(1, 1, 1, 1) if solved else Color(1, 1, 1, 0.45)

func update_prompt() -> void:
	var near_kraken: bool = absf(host.player_x - KRAKEN_X) <= REACH
	var near_assay: bool = absf(host.player_x - ASSAY_X) <= REACH
	var near_arch: bool = absf(host.player_x - ARCH_X) <= REACH
	host.interact_button.disabled = not (near_kraken or near_assay or near_arch)
	if near_kraken:
		host.prompt_label.text = "E  /  LISTEN TO THE KRAKEN OF NOISE"
		host.interact_button.text = "E     LISTEN TO KRAKEN"
	elif near_assay:
		host.prompt_label.text = "E  /  EXAMINE THE MARSH ASSAY"
		host.interact_button.text = "E     EXAMINE ASSAY"
	elif near_arch:
		host.prompt_label.text = "E  /  APPROACH THE MARSH ARCH"
		host.interact_button.text = "E     CROSS THE MARSH" if bool(host.game.get("swamp_puzzle_solved", false)) else "E     EXAMINE ARCH"
	else:
		host.prompt_label.text = ""
		host.interact_button.text = "E     INTERACT"

func interact() -> void:
	if absf(host.player_x - KRAKEN_X) <= REACH:
		show_kraken()
	elif absf(host.player_x - ASSAY_X) <= REACH:
		if bool(host.game.get("swamp_puzzle_solved", false)):
			challenge.show_success()
		else:
			challenge.show()
	elif absf(host.player_x - ARCH_X) <= REACH:
		if bool(host.game.get("swamp_puzzle_solved", false)):
			host.game["swamp_complete"] = true
			host._save_game()
			host._update_hud()
			show_complete()
		else:
			show_blocked_arch()

func show_intro() -> void:
	host._clear_modal()
	host.overlay_kind = "swamp_intro"
	host._dim_screen(0.76)
	host._modal_frame(262, 143, 842, 476)
	host._label(host.modal_layer, "CHAPTER 03   /   EXPRESSION SWAMP", 309, 179, 500, 20, host.UI_FONT, 10, host.TEAL)
	host._line(host.modal_layer, 309, 218, 748, host.DIM_LINE)
	host._label(host.modal_layer, "The loudest voice may mislead.", 307, 238, 725, 66, host.TITLE_FONT, 30, host.IVORY)
	host._label(host.modal_layer, "Listen for the signal beneath the noise.", 309, 314, 695, 42, host.ITALIC_FONT, 25, host.BRIGHT_GOLD)
	host._label(host.modal_layer, "An old assay hints at a signal, but library size and poor-quality reads can mislead. The Kraken guards the arch. Investigate before trusting the counts.", 309, 367, 693, 80, host.BODY_FONT, 22, Color("c8cbc0"))
	host._line(host.modal_layer, 309, 476, 748, host.DIM_LINE)
	host._label(host.modal_layer, "THE MARSH ASSAY", 309, 503, 410, 20, host.UI_FONT, 10, host.MUTED)
	host._button(host.modal_layer, "ENTER THE SWAMP   →", 783, 502, 271, 51, dismiss_intro, "primary", 11)

func dismiss_intro() -> void:
	host.game["swamp_intro_seen"] = true
	host._save_game()
	host._clear_modal()

func show_kraken() -> void:
	host._clear_modal()
	host.overlay_kind = "swamp_kraken"
	host._dim_screen(0.72)
	host._modal_frame(307, 167, 752, 434)
	host._label(host.modal_layer, "THE KRAKEN OF NOISE  /  A SCRIPTED ENCOUNTER", 350, 199, 620, 20, host.UI_FONT, 10, host.TEAL)
	host._label(host.modal_layer, "Not every roar is a signal.", 350, 231, 635, 51, host.TITLE_FONT, 26, host.IVORY)
	var speech := "Counts can grow simply because a library is larger. Check quality, compare samples from the same batch, and scale by mapped reads."
	if bool(host.game.get("swamp_puzzle_solved", false)):
		speech = "The water is still, but one pair does not prove the truth. Keep its limits with the observation and seek independent checks."
	host._label(host.modal_layer, "“" + speech + "”", 350, 302, 635, 103, host.BODY_FONT, 23, Color("ccd4c9"))
	host._line(host.modal_layer, 350, 435, 664, host.DIM_LINE)
	host._button(host.modal_layer, "READ ABOUT RNA-SEQ", 350, 465, 250, 47, _open_expression_codex, "outline", 10)
	host._button(host.modal_layer, "CONTINUE   →", 690, 465, 324, 47, host._clear_modal, "primary", 11)
	host._close_button(997, 183)

func _open_expression_codex() -> void:
	host.return_from_modal = "game"
	host._show_codex(6)

func show_blocked_arch() -> void:
	host._clear_modal()
	host.overlay_kind = "swamp_blocked"
	host._dim_screen(0.72)
	host._modal_frame(411, 244, 544, 280)
	host._label(host.modal_layer, "THE MARSH ARCH", 452, 277, 450, 20, host.UI_FONT, 10, host.GOLD)
	host._label(host.modal_layer, "The water churns.", 452, 308, 460, 46, host.TITLE_FONT, 25, host.IVORY)
	host._label(host.modal_layer, "The old assay on the stone table may reveal what is signal and what is noise.", 452, 365, 450, 70, host.BODY_FONT, 20, host.MUTED)
	host._button(host.modal_layer, "RETURN TO THE SWAMP", 452, 460, 280, 42, host._clear_modal, "outline", 10)
	host._close_button(886, 261)

func show_complete() -> void:
	host._clear_modal()
	host.overlay_kind = "swamp_complete"
	host._dim_screen(0.84)
	host._modal_frame(290, 99, 786, 570)
	host._label(host.modal_layer, "CHAPTER 03 COMPLETE", 358, 143, 650, 24, host.UI_FONT, 11, host.TEAL, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "A quieter marsh.\nA clearer question.", 356, 183, 654, 100, host.TITLE_FONT, 30, host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	host._line(host.modal_layer, 480, 302, 406, host.DIM_LINE)
	host._label(host.modal_layer, "Four fragments now travel with Aren. The evidence is growing, but a careful case still needs stronger checks.", 395, 322, 576, 75, host.BODY_FONT, 22, Color("cbd0c5"), HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "NEXT IN THE STORY", 397, 416, 572, 20, host.UI_FONT, 10, host.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "Dungeon of Missing Data", 397, 442, 572, 38, host.TITLE_FONT, 22, host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "A dragon guards the records beyond.", 397, 485, 572, 26, host.ITALIC_FONT, 19, host.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	host._button(host.modal_layer, "REVISIT THE SWAMP", 375, 546, 280, 49, host._clear_modal, "outline", 10)
	host._button(host.modal_layer, "ENTER THE DUNGEON   →", 669, 546, 322, 49, host._enter_missing, "primary", 11)
