class_name MissingDataRegion
extends RefCounted

const BACKGROUND: Texture2D = preload("res://assets/missing-data-dungeon.jpg")
const DRAGON: Texture2D = preload("res://assets/variant-dragon.png")
const DRAGON_X := 410.0
const LEDGER_X := 875.0
const DOOR_X := 1182.0
const REACH := 92.0
const DRAGON_Y := 382.0

var host
var challenge: PileupChallengeScreen
var dragon_image: TextureRect
var door_marker: Button
var elapsed := 0.0

func _init(controller) -> void:
	host = controller
	challenge = PileupChallengeScreen.new(host)

func build() -> void:
	var world: TextureRect = host._image(host.scene_layer, BACKGROUND, Vector2.ZERO, Vector2(host.W, host.H), Control.MOUSE_FILTER_STOP)
	world.gui_input.connect(host._on_world_input)
	host._image(host.scene_layer, host.DUNGEON_SHADE, Vector2.ZERO, Vector2(host.W, host.H))
	host.world_ambience = host._add_atmosphere(host.scene_layer)
	dragon_image = host._image(host.scene_layer, DRAGON, Vector2(195, DRAGON_Y), Vector2(430, 225))
	dragon_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	update_dragon()
	host.player = host._image(host.scene_layer, host.AREN, Vector2(host.player_x - 38, 471), Vector2(76, 178))
	host.player.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host.player.pivot_offset = Vector2(38, 89)
	_marker(382, 319, _walk_to_dragon)
	_marker(847, 351, _walk_to_ledger)
	door_marker = _marker(1154, 292, _walk_to_door)
	host._build_world_hud("DUNGEON OF MISSING DATA", "CHAPTER 04   /   THE DRAGON'S LEDGER")
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
	if is_instance_valid(dragon_image):
		dragon_image.position.y = DRAGON_Y + sin(elapsed * 1.2) * 2.5

func update_dragon() -> void:
	if is_instance_valid(dragon_image):
		dragon_image.modulate = Color(0.88, 1.0, 0.92, 1.0) if bool(host.game.get("missing_puzzle_solved", false)) else Color.WHITE

func handle_world_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var point: Vector2 = event.position
		if point.x >= 190 and point.x <= 630 and point.y >= 275 and point.y <= 640:
			_walk_to_dragon()
		elif point.x >= 735 and point.x <= 1020 and point.y >= 300 and point.y <= 650:
			_walk_to_ledger()
		elif point.x >= 1070 and point.y >= 210 and point.y <= 650:
			_walk_to_door()
		else:
			host.target_x = clampf(point.x, host.PLAYER_MIN, host.PLAYER_MAX)
			host.pending_action = ""

func _walk_to_dragon() -> void:
	_walk_to(DRAGON_X, "missing_dragon")
func _walk_to_ledger() -> void:
	_walk_to(LEDGER_X, "missing_ledger")
func _walk_to_door() -> void:
	_walk_to(DOOR_X, "missing_door")
func _walk_to(x: float, action: String) -> void:
	if host.overlay_kind != "":
		return
	host.target_x = x
	host.pending_action = action

func update_objective() -> void:
	var solved := bool(host.game.get("missing_puzzle_solved", false))
	if bool(host.game.get("missing_complete", false)):
		host.objective_title.text = "Dungeon chapter complete"
		host.objective_detail.text = "Approach the door for the trial."
	elif solved:
		host.objective_title.text = "Reach the sealed door"
		host.objective_detail.text = "Draco has yielded. Go east."
	else:
		host.objective_title.text = "Read the dragon's ledger"
		host.objective_detail.text = "Separate evidence from absence."
	if is_instance_valid(door_marker):
		door_marker.modulate = Color(1, 1, 1, 1) if solved else Color(1, 1, 1, 0.45)

func update_prompt() -> void:
	var near_dragon: bool = absf(host.player_x - DRAGON_X) <= REACH
	var near_ledger: bool = absf(host.player_x - LEDGER_X) <= REACH
	var near_door: bool = absf(host.player_x - DOOR_X) <= REACH
	host.interact_button.disabled = not (near_dragon or near_ledger or near_door)
	if near_dragon:
		host.prompt_label.text = "E  /  SPEAK WITH DRACO VARIANTUS"
		host.interact_button.text = "E     SPEAK WITH DRACO"
	elif near_ledger:
		host.prompt_label.text = "E  /  EXAMINE THE DRAGON'S LEDGER"
		host.interact_button.text = "E     EXAMINE LEDGER"
	elif near_door:
		host.prompt_label.text = "E  /  APPROACH THE SEALED DOOR"
		host.interact_button.text = "E     OPEN THE DOOR" if bool(host.game.get("missing_puzzle_solved", false)) else "E     EXAMINE DOOR"
	else:
		host.prompt_label.text = ""
		host.interact_button.text = "E     INTERACT"

func interact() -> void:
	if absf(host.player_x - DRAGON_X) <= REACH:
		show_dragon()
	elif absf(host.player_x - LEDGER_X) <= REACH:
		if bool(host.game.get("missing_puzzle_solved", false)):
			challenge.show_success()
		else:
			challenge.show()
	elif absf(host.player_x - DOOR_X) <= REACH:
		if bool(host.game.get("missing_puzzle_solved", false)):
			host.game["missing_complete"] = true
			host._save_game()
			host._update_hud()
			show_complete()
		else:
			show_blocked_door()

func show_intro() -> void:
	host._clear_modal()
	host.overlay_kind = "missing_intro"
	host._dim_screen(0.76)
	host._modal_frame(262, 143, 842, 476)
	host._label(host.modal_layer, "CHAPTER 04   /   DUNGEON OF MISSING DATA", 309, 179, 550, 20, host.UI_FONT, 10, host.TEAL)
	host._line(host.modal_layer, 309, 218, 748, host.DIM_LINE)
	host._label(host.modal_layer, "An absence is not an answer.", 307, 238, 725, 66, host.TITLE_FONT, 30, host.IVORY)
	host._label(host.modal_layer, "The dragon keeps what the records forgot.", 309, 314, 695, 42, host.ITALIC_FONT, 25, host.BRIGHT_GOLD)
	host._label(host.modal_layer, "Draco Variantus guards a damaged ledger. Separate a candidate variant from poor-quality reads and sites with too little evidence.", 309, 367, 693, 80, host.BODY_FONT, 22, Color("c8cbc0"))
	host._line(host.modal_layer, 309, 476, 748, host.DIM_LINE)
	host._label(host.modal_layer, "THE DRAGON'S LEDGER", 309, 503, 410, 20, host.UI_FONT, 10, host.MUTED)
	host._button(host.modal_layer, "ENTER THE DUNGEON   →", 783, 502, 271, 51, dismiss_intro, "primary", 11)

func dismiss_intro() -> void:
	host.game["missing_intro_seen"] = true
	host._save_game()
	host._clear_modal()

func show_dragon() -> void:
	host._clear_modal()
	host.overlay_kind = "missing_dragon"
	host._dim_screen(0.72)
	host._modal_frame(307, 167, 752, 434)
	host._label(host.modal_layer, "DRACO VARIANTUS  /  KEEPER OF THE LEDGER", 350, 199, 620, 20, host.UI_FONT, 10, host.TEAL)
	host._label(host.modal_layer, "Do not invent what is missing.", 350, 231, 635, 51, host.TITLE_FONT, 25, host.IVORY)
	var speech := "A missing observation is not a match. Read the ledger: discard weak bases, count what remains, and tell me where a difference is supported."
	if bool(host.game.get("missing_puzzle_solved", false)):
		speech = "You have named a candidate and kept the unknown unknown. Bring the record to others; a single ledger cannot prove the truth."
	host._label(host.modal_layer, "“" + speech + "”", 350, 302, 635, 103, host.BODY_FONT, 22, Color("ccd4c9"))
	host._line(host.modal_layer, 350, 435, 664, host.DIM_LINE)
	host._button(host.modal_layer, "READ ABOUT VARIANT EVIDENCE", 350, 465, 300, 47, _open_pileup_codex, "outline", 10)
	host._button(host.modal_layer, "CONTINUE   →", 690, 465, 324, 47, host._clear_modal, "primary", 11)
	host._close_button(997, 183)

func _open_pileup_codex() -> void:
	host.return_from_modal = "game"
	host._show_codex(7)

func show_blocked_door() -> void:
	host._clear_modal()
	host.overlay_kind = "missing_blocked"
	host._dim_screen(0.72)
	host._modal_frame(411, 244, 544, 280)
	host._label(host.modal_layer, "THE ARCHIVE DOOR", 452, 277, 450, 20, host.UI_FONT, 10, host.GOLD)
	host._label(host.modal_layer, "The seal holds.", 452, 308, 460, 46, host.TITLE_FONT, 25, host.IVORY)
	host._label(host.modal_layer, "Draco will yield only when the ledger's evidence and its gaps are understood.", 452, 365, 450, 70, host.BODY_FONT, 20, host.MUTED)
	host._button(host.modal_layer, "RETURN TO THE DUNGEON", 452, 460, 280, 42, host._clear_modal, "outline", 10)
	host._close_button(886, 261)

func show_complete() -> void:
	host._clear_modal()
	host.overlay_kind = "missing_complete"
	host._dim_screen(0.84)
	host._modal_frame(290, 99, 786, 570)
	host._label(host.modal_layer, "CHAPTER 04 COMPLETE", 358, 143, 650, 24, host.UI_FONT, 11, host.TEAL, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "The dragon yields.\nThe record endures.", 356, 183, 654, 100, host.TITLE_FONT, 30, host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	host._line(host.modal_layer, 480, 302, 406, host.DIM_LINE)
	host._label(host.modal_layer, "Five fragments now travel with Aren. Each must be checked and interpreted before the kingdom can hear the case.", 395, 322, 576, 75, host.BODY_FONT, 22, Color("cbd0c5"), HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "NEXT IN THE STORY", 397, 416, 572, 20, host.UI_FONT, 10, host.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "The Final Trial", 397, 442, 572, 38, host.TITLE_FONT, 22, host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "The council awaits in the Hall of Records.", 397, 485, 572, 26, host.ITALIC_FONT, 19, host.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	host._button(host.modal_layer, "REVISIT THE DUNGEON", 375, 546, 280, 49, host._clear_modal, "outline", 10)
	host._button(host.modal_layer, "ENTER THE FINAL TRIAL   →", 669, 546, 322, 49, host._enter_final, "primary", 11)
