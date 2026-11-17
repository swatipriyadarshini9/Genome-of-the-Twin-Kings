class_name FinalTrialRegion
extends RefCounted

const BACKGROUND: Texture2D = preload("res://assets/court-of-records.jpg")
const LYRA: Texture2D = preload("res://assets/princess-lyra.png")
const LYRA_X := 410.0
const DESK_X := 930.0
const COUNCIL_X := 1182.0
const REACH := 92.0

var host
var challenge: FinalCaseScreen
var council_marker: Button

func _init(controller) -> void:
	host = controller
	challenge = FinalCaseScreen.new(host)

func build() -> void:
	var world: TextureRect = host._image(host.scene_layer, BACKGROUND, Vector2.ZERO, Vector2(host.W, host.H), Control.MOUSE_FILTER_STOP)
	world.gui_input.connect(host._on_world_input)
	host._image(host.scene_layer, host.DUNGEON_SHADE, Vector2.ZERO, Vector2(host.W, host.H))
	host.world_ambience = host._add_atmosphere(host.scene_layer)
	var lyra: TextureRect = host._image(host.scene_layer, LYRA, Vector2(LYRA_X - 47, 471), Vector2(94, 178))
	lyra.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host.player = host._image(host.scene_layer, host.AREN, Vector2(host.player_x - 38, 471), Vector2(76, 178))
	host.player.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host.player.pivot_offset = Vector2(38, 89)
	_marker(382, 389, _walk_to_lyra)
	_marker(902, 363, _walk_to_desk)
	council_marker = _marker(1154, 343, _walk_to_council)
	host._build_world_hud("THE HALL OF RECORDS", "CHAPTER 05   /   THE FINAL TRIAL")
	host._update_hud()
	host._update_player_visual(false)

func _marker(x: float, y: float, callback: Callable) -> Button:
	var button: Button = host._button(host.scene_layer, "", x, y, 56, 49, callback, "plain", 10)
	host._image(button, host.MARKER, Vector2(12, 8), Vector2(32, 32))
	return button

func tick(_delta: float) -> void:
	# The chamber is intentionally still; the shared atmospheric particles honor
	# reduced motion. No character or judicial outcome animates as a reward.
	pass

func handle_world_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var point: Vector2 = event.position
		if point.x >= 300 and point.x <= 530 and point.y >= 330 and point.y <= 650:
			_walk_to_lyra()
		elif point.x >= 730 and point.x <= 1070 and point.y >= 300 and point.y <= 650:
			_walk_to_desk()
		elif point.x >= 1071 and point.y >= 210 and point.y <= 650:
			_walk_to_council()
		else:
			host.target_x = clampf(point.x, host.PLAYER_MIN, host.PLAYER_MAX)
			host.pending_action = ""

func _walk_to_lyra() -> void:
	_walk_to(LYRA_X, "final_lyra")
func _walk_to_desk() -> void:
	_walk_to(DESK_X, "final_desk")
func _walk_to_council() -> void:
	_walk_to(COUNCIL_X, "final_council")
func _walk_to(x: float, action: String) -> void:
	if host.overlay_kind != "":
		return
	host.target_x = x
	host.pending_action = action

func update_objective() -> void:
	var prepared := bool(host.game.get("final_case_prepared", false))
	if bool(host.game.get("final_complete", false)):
		host.objective_title.text = "The trial is complete"
		host.objective_detail.text = "Explore, or return to the title."
	elif prepared:
		host.objective_title.text = "Address the council"
		host.objective_detail.text = "Bring the case to the lectern."
	else:
		host.objective_title.text = "Build a careful case"
		host.objective_detail.text = "Review the records at the table."
	if is_instance_valid(council_marker):
		council_marker.modulate = Color.WHITE if prepared else Color(1, 1, 1, 0.45)

func update_prompt() -> void:
	var near_lyra: bool = absf(host.player_x - LYRA_X) <= REACH
	var near_desk: bool = absf(host.player_x - DESK_X) <= REACH
	var near_council: bool = absf(host.player_x - COUNCIL_X) <= REACH
	host.interact_button.disabled = not (near_lyra or near_desk or near_council)
	if near_lyra:
		host.prompt_label.text = "E  /  SPEAK WITH PRINCESS LYRA"
		host.interact_button.text = "E     SPEAK WITH LYRA"
	elif near_desk:
		host.prompt_label.text = "E  /  EXAMINE THE EVIDENCE TABLE"
		host.interact_button.text = "E     REVIEW THE CASE"
	elif near_council:
		host.prompt_label.text = "E  /  ADDRESS THE COUNCIL"
		host.interact_button.text = "E     ADDRESS COUNCIL" if bool(host.game.get("final_case_prepared", false)) else "E     EXAMINE LECTERN"
	else:
		host.prompt_label.text = ""
		host.interact_button.text = "E     INTERACT"

func interact() -> void:
	if absf(host.player_x - LYRA_X) <= REACH:
		show_lyra()
	elif absf(host.player_x - DESK_X) <= REACH:
		challenge.show()
	elif absf(host.player_x - COUNCIL_X) <= REACH:
		if bool(host.game.get("final_complete", false)):
			show_complete()
		elif bool(host.game.get("final_case_prepared", false)):
			show_hearing()
		else:
			show_blocked()

func show_intro() -> void:
	host._clear_modal()
	host.overlay_kind = "final_intro"
	host._dim_screen(0.76)
	host._modal_frame(262, 143, 842, 476)
	host._label(host.modal_layer, "CHAPTER 05   /   THE FINAL TRIAL", 309, 179, 550, 20, host.UI_FONT, 10, host.TEAL)
	host._line(host.modal_layer, 309, 218, 748, host.DIM_LINE)
	host._label(host.modal_layer, "Truth must withstand a question.", 307, 238, 725, 66, host.TITLE_FONT, 29, host.IVORY)
	host._label(host.modal_layer, "The kingdom has come to listen.", 309, 314, 695, 42, host.ITALIC_FONT, 25, host.BRIGHT_GOLD)
	host._label(host.modal_layer, "Lyra has called a public hearing. Review the fragments, compare the records, and present only what the evidence can support.", 309, 367, 693, 80, host.BODY_FONT, 22, Color("c8cbc0"))
	host._line(host.modal_layer, 309, 476, 748, host.DIM_LINE)
	host._label(host.modal_layer, "THE HALL OF RECORDS", 309, 503, 410, 20, host.UI_FONT, 10, host.MUTED)
	host._button(host.modal_layer, "ENTER THE HALL   →", 783, 502, 271, 51, dismiss_intro, "primary", 11)

func dismiss_intro() -> void:
	host.game["final_intro_seen"] = true
	host._save_game()
	host._clear_modal()

func show_lyra() -> void:
	host._clear_modal()
	host.overlay_kind = "final_lyra"
	host._dim_screen(0.72)
	host._modal_frame(307, 167, 752, 434)
	host._label(host.modal_layer, "PRINCESS LYRA  /  THE PUBLIC HEARING", 350, 199, 620, 20, host.UI_FONT, 10, host.TEAL)
	host._label(host.modal_layer, "Let them question us.", 350, 231, 635, 51, host.TITLE_FONT, 26, host.IVORY)
	var speech := "Aren, the villagers deserve the records and their limits. A reread of the same vial is not a new sample. Preserve the originals and follow their custody."
	if bool(host.game.get("final_complete", false)):
		speech = "The inquiry continues in public. We will keep the original records, listen to challenges, and let evidence be checked by others."
	elif bool(host.game.get("final_case_prepared", false)):
		speech = "Your case is ready. Tell the council what the records show—and what they do not. We will request the sealed audit."
	host._label(host.modal_layer, "“" + speech + "”", 350, 302, 635, 103, host.BODY_FONT, 22, Color("ccd4c9"))
	host._line(host.modal_layer, 350, 435, 664, host.DIM_LINE)
	host._button(host.modal_layer, "READ ABOUT CUSTODY", 350, 465, 270, 47, _open_custody_codex, "outline", 10)
	host._button(host.modal_layer, "CONTINUE   →", 690, 465, 324, 47, host._clear_modal, "primary", 11)
	host._close_button(997, 183)

func _open_custody_codex() -> void:
	host.return_from_modal = "game"
	host._show_codex(8)

func show_blocked() -> void:
	host._clear_modal()
	host.overlay_kind = "final_blocked"
	host._dim_screen(0.72)
	host._modal_frame(411, 244, 544, 280)
	host._label(host.modal_layer, "THE COUNCIL LECTERN", 452, 277, 450, 20, host.UI_FONT, 10, host.GOLD)
	host._label(host.modal_layer, "The hall is waiting.", 452, 308, 460, 46, host.TITLE_FONT, 25, host.IVORY)
	host._label(host.modal_layer, "Review the evidence at the table before presenting a case to the villagers.", 452, 365, 450, 70, host.BODY_FONT, 20, host.MUTED)
	host._button(host.modal_layer, "RETURN TO THE HALL", 452, 460, 280, 42, host._clear_modal, "outline", 10)
	host._close_button(886, 261)

func show_hearing() -> void:
	host._clear_modal()
	host.overlay_kind = "final_hearing"
	host._dim_screen(0.82)
	host._modal_frame(307, 143, 752, 482)
	host._label(host.modal_layer, "THE FINAL TRIAL   /   A PUBLIC HEARING", 351, 181, 650, 21, host.UI_FONT, 10, host.TEAL)
	host._label(host.modal_layer, "Let the records speak.", 351, 216, 650, 53, host.TITLE_FONT, 27, host.IVORY)
	host._label(host.modal_layer, "Aren gives the villagers the comparison, its sources and its limits. Lyra asks the archivists to authenticate a sealed instruction from Varen's office before anyone draws further conclusions.", 351, 292, 650, 132, host.BODY_FONT, 23, Color("cbd2c8"))
	host._line(host.modal_layer, 351, 475, 660, host.DIM_LINE)
	host._button(host.modal_layer, "HEAR THE REVIEW   →", 685, 503, 326, 49, show_review, "primary", 11)

func show_review() -> void:
	host._clear_modal()
	host.overlay_kind = "final_hearing_review"
	host._dim_screen(0.82)
	host._modal_frame(307, 143, 752, 482)
	host._label(host.modal_layer, "THE FINAL TRIAL   /   INDEPENDENT CORROBORATION", 351, 181, 650, 21, host.UI_FONT, 10, host.TEAL)
	host._label(host.modal_layer, "A second kind of evidence.", 351, 216, 650, 53, host.TITLE_FONT, 26, host.IVORY)
	host._label(host.modal_layer, "The archivists authenticate an office-sealed order to change the report. Confronted in public, Varen admits he ordered the change and imprisoned Aren. His admission—not the short DNA profile—establishes his role.", 351, 292, 650, 142, host.BODY_FONT, 22, Color("cbd2c8"))
	host._line(host.modal_layer, 351, 475, 660, host.DIM_LINE)
	host._button(host.modal_layer, "HEAR THE VERDICT   →", 685, 503, 326, 49, _finish_trial, "primary", 11)

func _finish_trial() -> void:
	host.game["final_complete"] = true
	host._save_game()
	host._update_hud()
	show_complete()

func show_complete() -> void:
	host._clear_modal()
	host.overlay_kind = "final_complete"
	host._dim_screen(0.84)
	host._modal_frame(290, 99, 786, 570)
	host._label(host.modal_layer, "THE FINAL TRIAL   /   STORY COMPLETE", 358, 143, 650, 24, host.UI_FONT, 11, host.TEAL, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "The truth is heard.\nThe records endure.", 356, 183, 654, 100, host.TITLE_FONT, 30, host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	host._line(host.modal_layer, 480, 302, 406, host.DIM_LINE)
	host._label(host.modal_layer, "Varen is removed from power. Lyra frees Aren and calls a public inquiry; the original records are preserved for independent review.", 395, 322, 576, 83, host.BODY_FONT, 22, Color("cbd0c5"), HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "A CASE BUILT TO BE QUESTIONED", 397, 424, 572, 20, host.UI_FONT, 10, host.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "Observations. Sources. Limits.", 397, 451, 572, 38, host.TITLE_FONT, 20, host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "Thank you for playing this prototype.", 397, 492, 572, 26, host.ITALIC_FONT, 19, host.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	host._button(host.modal_layer, "REVISIT THE HALL", 375, 546, 280, 49, host._clear_modal, "outline", 10)
	host._button(host.modal_layer, "SAVE & RETURN TO TITLE   →", 669, 546, 322, 49, host._save_and_menu, "primary", 11)
