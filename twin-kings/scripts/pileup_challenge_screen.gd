class_name PileupChallengeScreen
extends RefCounted

# Layout supports the three short loci and three choices in the authored trial.
# Filtering and grading are implemented separately in PileupAnalysis/Trial.
const TRIAL: PileupTrial = preload("res://data/trials/missing_pileup.tres")
const QUEST: QuestDefinition = preload("res://data/quests/missing_ledger.tres")
const STATUS_KEYS := ["candidate", "reference_only", "no_call"]
const STATUS_LABELS := ["CANDIDATE", "REF ONLY", "NO CALL"]

var host
var selected: Array[String] = []
var selected_support := -1
var row_buttons: Array = []
var support_buttons: Array[Button] = []
var feedback: Label

func _init(controller) -> void:
	host = controller

func show() -> void:
	host._clear_modal()
	host.overlay_kind = "missing_puzzle"
	selected.clear()
	row_buttons.clear()
	support_buttons.clear()
	selected_support = -1
	for _site in TRIAL.sites:
		selected.append("")
	host._dim_screen(0.87)
	host._modal_frame(106, 45, 1154, 678)
	host._label(host.modal_layer, "DUNGEON OF MISSING DATA   /   THE DRAGON'S LEDGER", 147, 70, 740, 20, host.UI_FONT, 10, host.TEAL)
	host._label(host.modal_layer, "Read what remains.", 147, 101, 890, 48, host.TITLE_FONT, 29, host.IVORY)
	host._label(host.modal_layer, "Classify each site, then identify the candidate's alternate and support.", 148, 157, 1020, 33, host.BODY_FONT, 20, Color("c8d0c6"))
	host._close_button(1196, 61)
	host._panel(host.modal_layer, 147, 198, 1072, 69, Color("192926"), Color(0.43, 0.62, 0.56, 0.28), 1)
	host._label(host.modal_layer, "BASE:Q = ALIGNED BASE AND ITS QUALITY SCORE. KEEP Q ≥ %d." % TRIAL.min_quality, 163, 203, 1038, 22, host.UI_FONT, 11, host.TEAL)
	host._label(host.modal_layer, "DEPTH < %d: NO CALL   /   DEPTH ≥ %d: ≥ %d SAME ALT = CANDIDATE, ALL PASSING BASES REF = REF ONLY" % [TRIAL.min_depth, TRIAL.min_depth, TRIAL.min_alt], 163, 229, 1038, 25, host.UI_FONT, 11, Color("d7d5c4"))
	host._label(host.modal_layer, "SITE", 158, 273, 75, 20, host.UI_FONT, 10, host.GOLD)
	host._label(host.modal_layer, "REF", 233, 273, 60, 20, host.UI_FONT, 10, host.GOLD)
	host._label(host.modal_layer, "ALIGNED BASE:Q", 300, 273, 315, 20, host.UI_FONT, 10, host.GOLD)
	host._label(host.modal_layer, "CLASSIFY EACH SITE", 646, 273, 520, 20, host.UI_FONT, 10, host.GOLD)
	for i in range(TRIAL.sites.size()):
		var site := TRIAL.sites[i] as PileupSite
		var y := 299.0 + i * 51.0
		host._panel(host.modal_layer, 147, y, 1072, 46, Color("182622"), Color(0.42, 0.59, 0.53, 0.25), 1)
		host._label(host.modal_layer, str(site.position), 158, y + 5, 65, 34, host.UI_FONT, 13, host.IVORY)
		host._label(host.modal_layer, site.reference, 233, y + 5, 48, 34, host.UI_FONT, 14, host.IVORY)
		var tokens: PackedStringArray = []
		for j in range(mini(site.bases.size(), site.qualities.size())):
			tokens.append("%s:%d" % [site.bases[j], site.qualities[j]])
		var reads_text := "   ".join(tokens) if not tokens.is_empty() else "NO READS"
		if site.bases.size() != site.qualities.size():
			reads_text = "DATA UNAVAILABLE"
		host._label(host.modal_layer, reads_text, 300, y + 5, 327, 34, host.UI_FONT, 13, Color("dce3d8"))
		var buttons: Array[Button] = []
		for j in range(STATUS_KEYS.size()):
			var button: Button = host._button(host.modal_layer, STATUS_LABELS[j], 641 + j * 190, y + 4, 180, 38, _choose.bind(i, j), "outline", 10)
			button.toggle_mode = true
			buttons.append(button)
		row_buttons.append(buttons)
	host._label(host.modal_layer, "CANDIDATE SITE  /  SELECT THE ALTERNATE BASE AND PASSING SUPPORT", 148, 463, 1000, 20, host.UI_FONT, 10, host.TEAL)
	for i in range(TRIAL.support_choices.size()):
		var option := TRIAL.support_choices[i] as PileupSupportChoice
		var button: Button = host._button(host.modal_layer, option.display_text(), 147 + i * 357, 489, 342, 44, _choose_support.bind(i), "outline", 11)
		button.toggle_mode = true
		support_buttons.append(button)
	feedback = host._label(host.modal_layer, "Exclude low-quality bases before counting depth and alternate support.", 148, 543, 1030, 55, host.BODY_FONT, 18, host.MUTED)
	host._line(host.modal_layer, 147, 610, 1072, host.DIM_LINE)
	host._button(host.modal_layer, "NEED A HINT?", 147, 630, 180, 45, _hint, "outline", 10)
	host._button(host.modal_layer, "CLEAR", 339, 630, 130, 45, _clear, "outline", 10)
	host._button(host.modal_layer, "CHECK THE LEDGER   →", 917, 630, 302, 45, _check, "primary", 10)
	_refresh()

func _refresh() -> void:
	for i in range(row_buttons.size()):
		for j in range(STATUS_KEYS.size()):
			(row_buttons[i][j] as Button).set_pressed_no_signal(selected[i] == STATUS_KEYS[j])
	for i in range(support_buttons.size()):
		support_buttons[i].set_pressed_no_signal(i == selected_support)

func _choose(row: int, option: int) -> void:
	if row < 0 or row >= selected.size() or option < 0 or option >= STATUS_KEYS.size():
		return
	selected[row] = "" if selected[row] == STATUS_KEYS[option] else STATUS_KEYS[option]
	feedback.text = "Exclude low-quality bases before counting depth and alternate support."
	feedback.add_theme_color_override("font_color", host.MUTED)
	_refresh()

func _choose_support(index: int) -> void:
	if index < 0 or index >= TRIAL.support_choices.size():
		return
	selected_support = -1 if selected_support == index else index
	feedback.text = "Support is the number of passing alternate reads over all passing reads at that site."
	feedback.add_theme_color_override("font_color", host.MUTED)
	_refresh()

func _hint() -> void:
	feedback.text = "Cross out every Q below %d. Count what's left; a low-depth site is not a reference call." % TRIAL.min_quality
	feedback.add_theme_color_override("font_color", host.TEAL)

func _clear() -> void:
	for i in range(selected.size()):
		selected[i] = ""
	selected_support = -1
	feedback.text = "Start again: classify all three sites, then choose the candidate's support."
	feedback.add_theme_color_override("font_color", host.MUTED)
	_refresh()

func _check() -> void:
	var result := TRIAL.review_answer(selected, selected_support)
	if not result.get("ok", false):
		match String(result.get("error", "")):
			"classify_all":
				feedback.text = "Choose a classification for every site."
			"classification":
				var position: int = result["position"]
				if result.get("expected") == "no_call":
					feedback.text = "Site %d has too few passing reads. Low coverage is not a reference call." % position
				else:
					feedback.text = "Recheck site %d. Exclude low-quality bases, then count passing reference and alternate bases." % position
			"choose_support":
				feedback.text = "Now select the candidate's alternate base and passing-read support."
			"support":
				feedback.text = "Count the alternate among passing reads only; do not include reads below the quality cutoff."
			"invalid_trial":
				feedback.text = "Ledger data is unavailable or inconsistent. Please reload or update the game."
			_:
				feedback.text = "That answer cannot be checked. Review the sites and try again."
		feedback.add_theme_color_override("font_color", Color("e6a49a"))
		return
	host.game["missing_puzzle_solved"] = true
	host._save_game()
	host._update_hud()
	if host.missing_region != null:
		host.missing_region.update_dragon()
	show_success(true)

func show_success(newly_recovered: bool = false) -> void:
	host._clear_modal()
	host.overlay_kind = "missing_success"
	host._dim_screen(0.84)
	host._modal_frame(307, 118, 752, 532)
	host._image(host.modal_layer, host.HELIX, Vector2(643, 147), Vector2(80, 80))
	host._label(host.modal_layer, "EVIDENCE RECOVERED" if newly_recovered else "EVIDENCE ALREADY RECOVERED", 405, 231, 556, 22, host.UI_FONT, 10, host.TEAL, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "A candidate, not a verdict.", 357, 264, 652, 52, host.TITLE_FONT, 25, host.IVORY, HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "At site 112, G appears in two of four passing reads. At site 143, sparse coverage means no call.", 396, 330, 574, 76, host.BODY_FONT, 22, Color("cbd2c8"), HORIZONTAL_ALIGNMENT_CENTER)
	host._label(host.modal_layer, "Toy thresholds are not validation. Mapping, strand bias and independent checks still matter.", 396, 418, 574, 68, host.ITALIC_FONT, 20, Color("aac5b8"), HORIZONTAL_ALIGNMENT_CENTER)
	host._line(host.modal_layer, 401, 508, 565, host.DIM_LINE)
	var reward_text := "+ 1 DATA FRAGMENT       •       + %d XP" % QUEST.evidence.xp if newly_recovered else "FRAGMENT ALREADY RECOVERED       •       NO ADDITIONAL XP"
	host._label(host.modal_layer, reward_text, 413, 522, 540, 23, host.UI_FONT, 11, host.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	host._button(host.modal_layer, "RETURN TO THE DUNGEON   →", 501, 558, 365, 48, host._clear_modal, "primary", 11)
