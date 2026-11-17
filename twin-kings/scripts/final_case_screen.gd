class_name FinalCaseScreen
extends RefCounted

# Two-stage capstone: evaluate all five prior fragments, then compare a short
# profile and choose a defensible statement and next step. The pure rules live
# in CaseAnalysis; no evidence is awarded for an unsupported claim.
const QUEST: QuestDefinition = preload("res://data/quests/final_case.tres")
const PROFILE_OPTIONS := [
	["ALL THREE MATCH", "BOTH DIFFER AT 6 & 12", "ONLY THE ARCHIVE DIFFERS"],
	["SUMMARY CONFLICTS WITH RECORDS", "DNA PROVES WHICH TWIN", "ALL RECORDS ARE FABRICATED"],
	["DISCARD THE ORIGINALS", "TREAT NO-CALL AS A MATCH", "PRESERVE & AUDIT CUSTODY"],
]

var host
var selected_claims: Array[int] = []
var answers: Array[int] = [-1, -1, -1]
var claim_buttons: Array[Button] = []
var claim_titles: Array[Label] = []
var claim_texts: Array[Label] = []
var profile_buttons: Array = []
var feedback: Label

func _init(controller) -> void:
	host = controller

func show() -> void:
	if bool(host.game.get("final_case_prepared", false)):
		show_ready(false)
		return
	selected_claims.clear()
	answers = [-1, -1, -1]
	show_review()

func show_review() -> void:
	host._clear_modal()
	host.overlay_kind = "final_review"
	claim_buttons.clear()
	claim_titles.clear()
	claim_texts.clear()
	host._dim_screen(0.87)
	host._modal_frame(106, 45, 1154, 678)
	host._label(host.modal_layer, "THE FINAL TRIAL   /   01  EVIDENCE REVIEW", 147, 70, 800, 20, host.UI_FONT, 10, host.TEAL)
	host._label(host.modal_layer, "What can the fragments support?", 147, 101, 900, 48, host.TITLE_FONT, 29, host.IVORY)
	host._label(host.modal_layer, "Select every statement that respects the observations and their limits. The Journal holds the five sources.", 148, 158, 1020, 37, host.BODY_FONT, 20, Color("c8d0c6"))
	host._close_button(1196, 61)
	host._label(host.modal_layer, "SELECT ALL DEFENSIBLE STATEMENTS", 148, 211, 760, 20, host.UI_FONT, 10, host.GOLD)
	for i in range(CaseAnalysis.CLAIMS.size()):
		var column := i % 2
		var row := floori(float(i) / 2.0)
		var x := 147.0 + column * 537.0
		var y := 239.0 + row * 87.0
		var card: Button = host._button(host.modal_layer, "", x, y, 522, 76, _toggle_claim.bind(i), "outline", 11)
		card.toggle_mode = true
		claim_buttons.append(card)
		claim_titles.append(host._label(card, "", 17, 7, 486, 18, host.UI_FONT, 10, host.TEAL))
		claim_texts.append(host._label(card, CaseAnalysis.CLAIMS[i]["text"], 17, 28, 486, 38, host.BODY_FONT, 18, host.IVORY))
	feedback = host._label(host.modal_layer, "A strong case includes what the evidence cannot say.", 148, 515, 1030, 66, host.BODY_FONT, 18, host.MUTED)
	host._line(host.modal_layer, 147, 610, 1072, host.DIM_LINE)
	host._button(host.modal_layer, "NEED A HINT?", 147, 630, 180, 45, _review_hint, "outline", 10)
	host._button(host.modal_layer, "CLEAR", 339, 630, 130, 45, _clear_claims, "outline", 10)
	host._button(host.modal_layer, "OPEN JOURNAL", 481, 630, 200, 45, _open_journal.bind("final_review"), "outline", 10)
	host._button(host.modal_layer, "COMPARE THE RECORDS   →", 917, 630, 302, 45, _check_claims, "primary", 10)
	_refresh_claims()

func _refresh_claims() -> void:
	for i in range(claim_buttons.size()):
		var active := selected_claims.has(i)
		claim_buttons[i].set_pressed_no_signal(active)
		claim_titles[i].text = ("SELECTED  /  " if active else "SELECT  /  ") + String(CaseAnalysis.CLAIMS[i]["heading"])
		claim_titles[i].add_theme_color_override("font_color", Color("20332a") if active else host.TEAL)
		claim_texts[i].add_theme_color_override("font_color", Color("111b16") if active else host.IVORY)

func _toggle_claim(index: int) -> void:
	if index < 0 or index >= CaseAnalysis.CLAIMS.size():
		return
	if selected_claims.has(index):
		selected_claims.erase(index)
	else:
		selected_claims.append(index)
	feedback.text = "A strong case includes what the evidence cannot say."
	feedback.add_theme_color_override("font_color", host.MUTED)
	_refresh_claims()

func _clear_claims() -> void:
	selected_claims.clear()
	feedback.text = "Start again. Select every defensible statement."
	feedback.add_theme_color_override("font_color", host.MUTED)
	_refresh_claims()

func _review_hint() -> void:
	feedback.text = "A toy contig cannot resolve all real repeats. One pair lacks replication; a low-depth no-call is not a match."
	feedback.add_theme_color_override("font_color", host.TEAL)

func _check_claims() -> void:
	var result := CaseAnalysis.review_claims(selected_claims)
	if not result.get("ok", false):
		match String(result.get("error", "")):
			"select_claims":
				feedback.text = "Select the statements that the fragments support."
			"unsupported":
				feedback.text = "A selected statement claims more than the evidence supports. Revisit the limitations."
			"missing":
				feedback.text = "At least one defensible observation or limitation is still missing."
			_:
				feedback.text = "That selection cannot be checked. Clear the cards and try again."
		feedback.add_theme_color_override("font_color", Color("e6a49a"))
		return
	show_profile()

func show_profile() -> void:
	host._clear_modal()
	host.overlay_kind = "final_profile"
	profile_buttons.clear()
	host._dim_screen(0.87)
	host._modal_frame(106, 45, 1154, 678)
	host._label(host.modal_layer, "THE FINAL TRIAL   /   02  THE PUBLIC REPORT", 147, 70, 800, 20, host.UI_FONT, 10, host.TEAL)
	host._label(host.modal_layer, "Compare before you accuse.", 147, 101, 900, 48, host.TITLE_FONT, 29, host.IVORY)
	host._label(host.modal_layer, "Choose an observation, a defensible conclusion, and the next check.", 148, 157, 1020, 33, host.BODY_FONT, 20, Color("c8d0c6"))
	host._close_button(1196, 61)
	host._panel(host.modal_layer, 147, 196, 1072, 166, Color("192926"), Color(0.43, 0.62, 0.56, 0.28), 1)
	host._label(host.modal_layer, "ALIGNED TOY PROFILES  /  POSITIONS ARE 1-BASED", 163, 200, 1000, 20, host.UI_FONT, 10, host.TEAL)
	var start_x := 421.0
	var step := 31.0
	for i in range(SequencePuzzle.REFERENCE.length()):
		host._label(host.modal_layer, str(i + 1), start_x + i * step, 224, 29, 19, host.UI_FONT, 9, host.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	var sequences := [SequencePuzzle.REFERENCE, SequencePuzzle.PRISON_RECORD, CaseAnalysis.REPEAT_RECORD]
	var names := ["REFERENCE", "ARCHIVED PRISON RECORD", "REREAD OF SAME ALIQUOT"]
	for row in range(sequences.size()):
		var y := 246.0 + row * 27.0
		host._label(host.modal_layer, names[row], 163, y, 242, 24, host.UI_FONT, 10, host.IVORY)
		for i in range(sequences[row].length()):
			host._label(host.modal_layer, sequences[row][i], start_x + i * step, y, 29, 24, host.UI_FONT, 13, Color("dce3d8"), HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "PUBLIC SUMMARY: ZERO DIFFERENCES. THE REREAD IS NOT AN INDEPENDENTLY COLLECTED SAMPLE.", 163, 333, 1038, 22, host.UI_FONT, 10, host.GOLD)
	var row_titles := ["01   /   WHAT DO THE TWO READINGS SHOW?", "02   /   WHAT CAN YOU CLAIM?", "03   /   WHAT SHOULD HAPPEN NEXT?"]
	for row in range(3):
		var label_y := 369.0 + row * 60.0
		host._label(host.modal_layer, row_titles[row], 148, label_y, 1010, 20, host.UI_FONT, 10, host.TEAL)
		var row_buttons: Array[Button] = []
		for option in range(3):
			var button: Button = host._button(host.modal_layer, PROFILE_OPTIONS[row][option], 147 + option * 357, label_y + 20, 342, 38, _choose_answer.bind(row, option), "outline", 10)
			button.toggle_mode = true
			row_buttons.append(button)
		profile_buttons.append(row_buttons)
	feedback = host._label(host.modal_layer, "A reread of one aliquot may repeat a shared labeling error.", 148, 554, 1030, 46, host.BODY_FONT, 18, host.MUTED)
	host._line(host.modal_layer, 147, 610, 1072, host.DIM_LINE)
	host._button(host.modal_layer, "REVIEW FRAGMENTS", 147, 630, 200, 45, show_review, "outline", 10)
	host._button(host.modal_layer, "NEED A HINT?", 359, 630, 180, 45, _profile_hint, "outline", 10)
	host._button(host.modal_layer, "OPEN JOURNAL", 551, 630, 200, 45, _open_journal.bind("final_profile"), "outline", 10)
	host._button(host.modal_layer, "PRESENT FOR REVIEW   →", 917, 630, 302, 45, _present, "primary", 10)
	_refresh_profile()

func _open_journal(return_screen: String) -> void:
	host.return_from_modal = return_screen
	host.journal.show(0)

func _refresh_profile() -> void:
	for row in range(profile_buttons.size()):
		for option in range(3):
			(profile_buttons[row][option] as Button).set_pressed_no_signal(answers[row] == option)

func _choose_answer(row: int, option: int) -> void:
	if row < 0 or row >= 3 or option < 0 or option >= 3:
		return
	answers[row] = -1 if answers[row] == option else option
	feedback.text = "A reread of one aliquot may repeat a shared labeling error."
	feedback.add_theme_color_override("font_color", host.MUTED)
	_refresh_profile()

func _profile_hint() -> void:
	feedback.text = "Compare each column with the reference. A report conflict is not proof of a person's identity."
	feedback.add_theme_color_override("font_color", host.TEAL)

func _present() -> void:
	var result := CaseAnalysis.review_profile(answers)
	if not result.get("ok", false):
		var error := String(result.get("error", ""))
		if error == "incomplete" or error == "invalid_choice":
			feedback.text = "Choose one answer in each row before presenting."
			feedback.add_theme_color_override("font_color", Color("e6a49a"))
		elif error == "invalid_data":
			feedback.text = "The comparison data is unavailable or inconsistent. Please reload or update the game."
			feedback.add_theme_color_override("font_color", Color("e6a49a"))
		else:
			show_dismissed(error)
		return
	host.game["final_case_prepared"] = true
	host._save_game()
	host._update_hud()
	show_ready(true)

func show_dismissed(reason: String) -> void:
	host._clear_modal()
	host.overlay_kind = "final_dismissed"
	host._dim_screen(0.84)
	host._modal_frame(307, 151, 752, 466)
	host._label(host.modal_layer, "CASE RETURNED FOR REVISION", 355, 188, 650, 22, host.UI_FONT, 10, host.GOLD)
	host._label(host.modal_layer, "The council cannot accept that yet.", 355, 224, 650, 57, host.TITLE_FONT, 24, host.IVORY)
	var detail := "Recompare the archived record and reread with the reference, one column at a time."
	if reason == "conclusion":
		detail = "A short profile does not identify a twin or prove guilt. State the conflict with the public summary."
	elif reason == "next_step":
		detail = "Preserve the originals and audit custody. A no-call is not a reference match."
	host._label(host.modal_layer, detail, 355, 302, 650, 96, host.BODY_FONT, 23, Color("cbd2c8"))
	host._label(host.modal_layer, "Your selections are kept; you may revise and try again.", 355, 415, 650, 38, host.ITALIC_FONT, 20, host.MUTED)
	host._line(host.modal_layer, 355, 477, 656, host.DIM_LINE)
	host._button(host.modal_layer, "REVIEW FRAGMENTS", 355, 500, 260, 48, show_review, "outline", 10)
	host._button(host.modal_layer, "REVISE THE CASE   →", 643, 500, 368, 48, show_profile, "primary", 11)

func show_ready(newly_prepared: bool = false) -> void:
	host._clear_modal()
	host.overlay_kind = "final_ready"
	host._dim_screen(0.84)
	host._modal_frame(307, 118, 752, 532)
	host._image(host.modal_layer, host.HELIX, Vector2(643, 147), Vector2(80, 80))
	host._label(host.modal_layer, "CASE RECORD SAVED" if newly_prepared else "CASE ALREADY PREPARED", 405, 231, 556, 22, host.UI_FONT, 10, host.TEAL, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "The case is ready to be heard.", 357, 264, 652, 52, host.TITLE_FONT, 25, host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "Both readings differ at two sites; the public summary says none. A reread of the same aliquot cannot identify the twins.", 396, 330, 574, 76, host.BODY_FONT, 22, Color("cbd2c8"), HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "Preserve the originals, audit custody and ask for independent review.", 396, 418, 574, 68, host.ITALIC_FONT, 20, Color("aac5b8"), HORIZONTAL_ALIGNMENT_CENTER)
	host._line(host.modal_layer, 401, 508, 565, host.DIM_LINE)
	var reward_text := "+ 1 CASE RECORD       •       + %d XP" % QUEST.evidence.xp if newly_prepared else "CASE ALREADY RECORDED       •       NO ADDITIONAL XP"
	host._label(host.modal_layer, reward_text, 413, 522, 540, 23, host.UI_FONT, 11, host.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	host._button(host.modal_layer, "RETURN TO THE HALL   →", 501, 558, 365, 48, host._clear_modal, "primary", 11)
