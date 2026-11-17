extends SceneTree

var failures: Array[String] = []

func _snapshot(path: String) -> Dictionary:
	return {"exists": FileAccess.file_exists(path), "bytes": FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()}
func _restore(path: String, saved: Dictionary) -> void:
	if saved["exists"]:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_buffer(saved["bytes"])
			file.close()
	elif FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
func _check(condition: bool, name: String) -> void:
	if not condition:
		failures.append(name)
		push_error("FAIL: " + name)

func _initialize() -> void:
	var paths := [SaveData.LEGACY_GAME_PATH, SaveData.V2_GAME_PATH, SaveData.V3_GAME_PATH, SaveData.V4_GAME_PATH, SaveData.V5_GAME_PATH, SaveData.GAME_PATH]
	var snapshots: Array[Dictionary] = []
	for path in paths:
		snapshots.append(_snapshot(path))
		_remove(path)
	var completed := {"version": 1, "puzzle_solved": true, "chapter_complete": true, "intro_seen": true, "player_x": 1182.0}
	SaveData._write_json(SaveData.LEGACY_GAME_PATH, completed)
	var legacy_bytes := FileAccess.get_file_as_bytes(SaveData.LEGACY_GAME_PATH)
	var migrated := SaveData.load_game()
	_check(migrated.get("version") == 6 and migrated.get("region") == "forest", "completed V1 continues in forest")
	_check(migrated.get("puzzle_solved") and migrated.get("chapter_complete"), "V1 migration keeps prologue evidence")
	_check(not migrated.get("forest_puzzle_solved") and not migrated.get("forest_intro_seen"), "V1 migration does not invent forest progress")
	_check(migrated.get("player_x") == SaveData.FOREST_START_X, "forest begins at its entry point")
	_check(FileAccess.file_exists(SaveData.GAME_PATH) and FileAccess.get_file_as_bytes(SaveData.LEGACY_GAME_PATH) == legacy_bytes, "V1 migration writes V6 and preserves V1")
	_remove(SaveData.GAME_PATH)
	var unfinished := {"version": 1, "puzzle_solved": false, "chapter_complete": false, "intro_seen": true, "player_x": 512.0}
	SaveData._write_json(SaveData.LEGACY_GAME_PATH, unfinished)
	migrated = SaveData.load_game()
	_check(migrated.get("region") == "dungeon" and migrated.get("player_x") == 512.0, "unfinished V1 stays in dungeon at saved position")
	_remove(SaveData.GAME_PATH)
	var v2 := {"version": 2, "region": "forest", "puzzle_solved": true, "chapter_complete": true, "intro_seen": true, "forest_intro_seen": true, "forest_puzzle_solved": false, "forest_complete": false, "player_x": 812.0}
	SaveData._write_json(SaveData.V2_GAME_PATH, v2)
	migrated = SaveData.load_game()
	_check(migrated.get("region") == "forest" and migrated.get("player_x") == 812.0 and not migrated.get("forest_puzzle_solved"), "unfinished V2 forest progress stays in forest")
	_remove(SaveData.GAME_PATH)
	v2["forest_puzzle_solved"] = true
	v2["forest_complete"] = true
	SaveData._write_json(SaveData.V2_GAME_PATH, v2)
	var v2_bytes := FileAccess.get_file_as_bytes(SaveData.V2_GAME_PATH)
	migrated = SaveData.load_game()
	_check(migrated.get("version") == 6 and migrated.get("region") == "river", "completed V2 forest continues at river")
	_check(migrated.get("forest_complete") and migrated.get("forest_puzzle_solved") and migrated.get("puzzle_solved"), "V2 migration preserves both evidence rewards")
	_check(not migrated.get("river_intro_seen") and not migrated.get("river_puzzle_solved") and migrated.get("player_x") == SaveData.RIVER_START_X, "V2 migration starts river without inventing progress")
	_check(FileAccess.get_file_as_bytes(SaveData.V2_GAME_PATH) == v2_bytes, "migration preserves V2 bytes")
	_remove(SaveData.GAME_PATH)
	var v3 := {"version": 3, "region": "river", "puzzle_solved": true, "chapter_complete": true, "intro_seen": true, "forest_intro_seen": true, "forest_puzzle_solved": true, "forest_complete": true, "river_intro_seen": true, "river_puzzle_solved": true, "river_complete": false, "player_x": 830.0}
	SaveData._write_json(SaveData.V3_GAME_PATH, v3)
	migrated = SaveData.load_game()
	_check(migrated.get("version") == 6 and migrated.get("region") == "river" and migrated.get("player_x") == 830.0, "unfinished V3 remains at its river checkpoint")
	_check(migrated.get("river_puzzle_solved") and not migrated.get("river_complete") and not migrated.get("swamp_intro_seen"), "V3 puzzle retained without inventing completion")
	_remove(SaveData.GAME_PATH)
	v3["river_complete"] = true
	SaveData._write_json(SaveData.V3_GAME_PATH, v3)
	var v3_bytes := FileAccess.get_file_as_bytes(SaveData.V3_GAME_PATH)
	migrated = SaveData.load_game()
	_check(migrated.get("version") == 6 and migrated.get("region") == "swamp" and migrated.get("player_x") == SaveData.SWAMP_START_X, "completed V3 continues at swamp entry")
	_check(migrated.get("puzzle_solved") and migrated.get("forest_puzzle_solved") and migrated.get("river_puzzle_solved") and migrated.get("river_complete"), "V3 migration preserves all three evidence rewards")
	_check(not migrated.get("swamp_intro_seen") and not migrated.get("swamp_puzzle_solved") and not migrated.get("swamp_complete"), "V3 migration does not invent swamp progress")
	_check(FileAccess.get_file_as_bytes(SaveData.V3_GAME_PATH) == v3_bytes, "migration preserves V3 bytes")
	_remove(SaveData.GAME_PATH)
	var v4 := {"version": 4, "region": "swamp", "puzzle_solved": true, "chapter_complete": true, "intro_seen": true, "forest_intro_seen": true, "forest_puzzle_solved": true, "forest_complete": true, "river_intro_seen": true, "river_puzzle_solved": true, "river_complete": true, "swamp_intro_seen": true, "swamp_puzzle_solved": true, "swamp_complete": false, "player_x": 950.0}
	SaveData._write_json(SaveData.V4_GAME_PATH, v4)
	migrated = SaveData.load_game()
	_check(migrated.get("version") == 6 and migrated.get("region") == "swamp" and migrated.get("player_x") == 950.0, "unfinished V4 remains at its swamp checkpoint")
	_check(migrated.get("swamp_puzzle_solved") and not migrated.get("swamp_complete") and not migrated.get("missing_intro_seen"), "unfinished V4 puzzle retained without inventing completion")
	_remove(SaveData.GAME_PATH)
	v4["swamp_complete"] = true
	SaveData._write_json(SaveData.V4_GAME_PATH, v4)
	var v4_bytes := FileAccess.get_file_as_bytes(SaveData.V4_GAME_PATH)
	migrated = SaveData.load_game()
	_check(migrated.get("version") == 6 and migrated.get("region") == "missing" and migrated.get("player_x") == SaveData.MISSING_START_X, "completed V4 continues at missing-data dungeon entry")
	_check(migrated.get("puzzle_solved") and migrated.get("forest_puzzle_solved") and migrated.get("river_puzzle_solved") and migrated.get("swamp_puzzle_solved") and migrated.get("swamp_complete"), "V4 migration preserves all four evidence rewards")
	_check(not migrated.get("missing_intro_seen") and not migrated.get("missing_puzzle_solved") and not migrated.get("missing_complete"), "V4 migration does not invent dungeon progress")
	_check(FileAccess.get_file_as_bytes(SaveData.V4_GAME_PATH) == v4_bytes, "migration preserves V4 bytes")
	_remove(SaveData.GAME_PATH)
	var v5 := {"version": 5, "region": "missing", "puzzle_solved": true, "chapter_complete": true, "intro_seen": true, "forest_intro_seen": true, "forest_puzzle_solved": true, "forest_complete": true, "river_intro_seen": true, "river_puzzle_solved": true, "river_complete": true, "swamp_intro_seen": true, "swamp_puzzle_solved": true, "swamp_complete": true, "missing_intro_seen": true, "missing_puzzle_solved": true, "missing_complete": false, "player_x": 875.0}
	SaveData._write_json(SaveData.V5_GAME_PATH, v5)
	var v5_partial_bytes := FileAccess.get_file_as_bytes(SaveData.V5_GAME_PATH)
	migrated = SaveData.load_game()
	_check(migrated.get("version") == 6 and migrated.get("region") == "missing" and migrated.get("player_x") == 875.0, "unfinished V5 remains at its dungeon checkpoint")
	_check(migrated.get("missing_puzzle_solved") and not migrated.get("missing_complete") and not migrated.get("final_intro_seen"), "unfinished V5 keeps its progress without inventing final-trial flags")
	_check(FileAccess.get_file_as_bytes(SaveData.V5_GAME_PATH) == v5_partial_bytes, "unfinished V5 bytes are preserved")
	_remove(SaveData.GAME_PATH)
	v5["missing_complete"] = true
	v5["player_x"] = 1182.0
	SaveData._write_json(SaveData.V5_GAME_PATH, v5)
	var v5_bytes := FileAccess.get_file_as_bytes(SaveData.V5_GAME_PATH)
	migrated = SaveData.load_game()
	_check(migrated.get("version") == 6 and migrated.get("region") == "final" and migrated.get("player_x") == SaveData.FINAL_START_X, "completed V5 continues at the final-trial entry")
	_check(migrated.get("puzzle_solved") and migrated.get("forest_puzzle_solved") and migrated.get("river_puzzle_solved") and migrated.get("swamp_puzzle_solved") and migrated.get("missing_puzzle_solved") and migrated.get("missing_complete"), "V5 migration retains all five rewards")
	_check(not migrated.get("final_intro_seen") and not migrated.get("final_case_prepared") and not migrated.get("final_complete"), "V5 migration does not invent final-trial progress")
	_check(FileAccess.get_file_as_bytes(SaveData.V5_GAME_PATH) == v5_bytes, "completed V5 bytes are preserved")
	_check(SaveData._valid_v5(v5).get("version") == 5, "V5 validation remains independent of the V6 schema")
	var broken := FileAccess.open(SaveData.GAME_PATH, FileAccess.WRITE)
	broken.store_string("not valid json")
	broken.close()
	_check(SaveData.load_game().is_empty(), "invalid V6 never silently falls back to V5")
	_remove(SaveData.GAME_PATH)
	broken = FileAccess.open(SaveData.V5_GAME_PATH, FileAccess.WRITE)
	broken.store_string("not valid json")
	broken.close()
	_check(SaveData.load_game().is_empty() and not FileAccess.file_exists(SaveData.GAME_PATH), "invalid V5 never silently falls back to V4")
	_remove(SaveData.V5_GAME_PATH)
	broken = FileAccess.open(SaveData.V4_GAME_PATH, FileAccess.WRITE)
	broken.store_string("not valid json")
	broken.close()
	_check(SaveData.load_game().is_empty() and not FileAccess.file_exists(SaveData.GAME_PATH), "invalid V4 never silently falls back to V3")
	_remove(SaveData.V4_GAME_PATH)
	broken = FileAccess.open(SaveData.V3_GAME_PATH, FileAccess.WRITE)
	broken.store_string("not valid json")
	broken.close()
	_check(SaveData.load_game().is_empty() and not FileAccess.file_exists(SaveData.GAME_PATH), "invalid V3 never silently falls back to V2")
	_remove(SaveData.V3_GAME_PATH)
	broken = FileAccess.open(SaveData.V2_GAME_PATH, FileAccess.WRITE)
	broken.store_string("not valid json")
	broken.close()
	_check(SaveData.load_game().is_empty() and not FileAccess.file_exists(SaveData.GAME_PATH), "invalid V2 never silently falls back to V1")
	_check(SaveData._migrate_v1({"version": 1, "puzzle_solved": false, "chapter_complete": true}).is_empty(), "impossible legacy completion is rejected")
	var impossible := SaveData.new_game()
	impossible["region"] = "forest"
	_check(SaveData._valid_v6(impossible).is_empty(), "forest cannot be entered without the completed prologue")
	impossible = SaveData.new_game()
	impossible["region"] = "river"
	_check(SaveData._valid_v6(impossible).is_empty(), "river cannot be entered without completing forest")
	impossible = SaveData.new_game()
	impossible["region"] = "swamp"
	_check(SaveData._valid_v6(impossible).is_empty(), "swamp cannot be entered without completing river")
	impossible = SaveData.new_game()
	impossible["region"] = "missing"
	_check(SaveData._valid_v6(impossible).is_empty(), "missing-data dungeon cannot be entered without completing swamp")
	impossible = SaveData.new_game()
	impossible["swamp_complete"] = true
	_check(SaveData._valid_v6(impossible).is_empty(), "swamp completion requires its puzzle and earlier chapters")
	impossible = SaveData._migrate_v4(v4)
	impossible["missing_complete"] = true
	_check(SaveData._valid_v6(impossible).is_empty(), "new dungeon completion requires its puzzle")
	impossible = SaveData.new_game()
	impossible["region"] = "final"
	_check(SaveData._valid_v6(impossible).is_empty(), "the final trial requires a completed dungeon")
	impossible = SaveData._migrate_v5(v5)
	impossible["final_complete"] = true
	_check(SaveData._valid_v6(impossible).is_empty(), "the ending requires a prepared case")
	impossible["final_case_prepared"] = true
	_check(not SaveData._valid_v6(impossible).is_empty(), "a completed trial is valid after preparation")
	for i in range(paths.size()):
		_restore(paths[i], snapshots[i])
	if failures.is_empty():
		print("PASS: V1/V2/V3/V4/V5 to V6 migration, prior bytes, corrupt-save precedence and progress invariants")
		quit(0)
	else:
		print("FAILURES: ", failures.size())
		quit(1)
