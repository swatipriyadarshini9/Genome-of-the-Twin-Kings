extends SceneTree

func _init() -> void:
	var expected: Array[int] = [6, 12]
	assert(SequencePuzzle.differences(SequencePuzzle.REFERENCE, SequencePuzzle.PRISON_RECORD) == expected)
	assert(SequencePuzzle.is_correct([6, 12]))
	assert(SequencePuzzle.is_correct([12, 6]))
	assert(not SequencePuzzle.is_correct([]))
	assert(not SequencePuzzle.is_correct([6]))
	assert(not SequencePuzzle.is_correct([6, 6]))
	assert(not SequencePuzzle.is_correct([6, 11]))
	assert(not SequencePuzzle.is_correct([6, 12, 13]))
	assert(SequencePuzzle.differences("AAAA", "AAAA").is_empty())
	assert(SequencePuzzle.differences("AAA", "AAAA").is_empty())
	var had_original := FileAccess.file_exists(SaveData.GAME_PATH)
	var original_bytes := FileAccess.get_file_as_bytes(SaveData.GAME_PATH) if had_original else PackedByteArray()
	var sample := SaveData.new_game()
	sample["puzzle_solved"] = true
	sample["intro_seen"] = true
	sample["player_x"] = 800.0
	assert(SaveData.save_game(sample))
	assert(SaveData.load_game() == sample)
	if had_original:
		var original_file := FileAccess.open(SaveData.GAME_PATH, FileAccess.WRITE)
		original_file.store_buffer(original_bytes)
		original_file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.GAME_PATH))
	print("PASS: sequence comparisons, grading, duplicate rejection, and save round-trip")
	quit(0)
