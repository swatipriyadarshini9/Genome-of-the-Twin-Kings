extends SceneTree

# These cards and journal panels have fixed-height labels. Guard their known
# line budgets so new copy cannot silently clip a key claim or limitation.
# Godot's get_visible_line_count() uses font metrics that can differ from the
# actually drawn glyph extents, so these checks use explicit design budgets;
# screenshots of an exported build are still necessary.
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)

func _find_label(node: Node, start: String) -> Label:
	for child in node.get_children():
		if child is Label and child.text.begins_with(start):
			return child
	return null

func _run() -> void:
	# The menu may migrate an older save on startup; restore the active file.
	var had_save := FileAccess.file_exists(SaveData.GAME_PATH)
	var old_bytes := FileAccess.get_file_as_bytes(SaveData.GAME_PATH) if had_save else PackedByteArray()
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.settings = {"reduced_motion": true, "show_hints": true}
	main.game = SaveData.new_game()
	for key in ["puzzle_solved", "chapter_complete", "intro_seen", "forest_intro_seen", "forest_puzzle_solved", "forest_complete", "river_intro_seen", "river_puzzle_solved", "river_complete", "swamp_intro_seen", "swamp_puzzle_solved", "swamp_complete", "missing_intro_seen", "missing_puzzle_solved", "missing_complete", "final_case_prepared"]:
		main.game[key] = true
	main.game["region"] = "final"
	main.player_x = SaveData.FINAL_START_X
	main._build_game()
	main.final_region.challenge.show_review()
	await process_frame
	for i in range(main.final_region.challenge.claim_texts.size()):
		var label: Label = main.final_region.challenge.claim_texts[i]
		_check(label.get_line_count() == 1, "final review card %d must fit one visible line" % (i + 1))
	for i in range(GameProgress.QUESTS.size()):
		main.journal.show(i)
		await process_frame
		var quest: QuestDefinition = GameProgress.QUESTS[i]
		var observation := _find_label(main.modal_layer, quest.evidence.observation)
		var limitation := _find_label(main.modal_layer, "LIMITATION   /   ")
		_check(is_instance_valid(observation) and observation.get_line_count() <= 2, "journal observation %d fits its two-line panel" % (i + 1))
		_check(is_instance_valid(limitation) and limitation.get_line_count() <= 2, "journal limitation %d fits its two-line panel" % (i + 1))
	main.queue_free()
	if had_save:
		var file := FileAccess.open(SaveData.GAME_PATH, FileAccess.WRITE)
		if file != null:
			file.store_buffer(old_bytes)
			file.close()
	elif FileAccess.file_exists(SaveData.GAME_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.GAME_PATH))
	if failures.is_empty():
		print("PASS: final review cards and all evidence observations/limitations fit their line budgets")
		quit(0)
	else:
		print("FAILURES: ", failures.size())
		quit(1)
