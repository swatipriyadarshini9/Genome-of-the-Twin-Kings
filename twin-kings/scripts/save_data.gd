class_name SaveData
extends RefCounted

# Older save files are preserved. Newer files always take precedence, even if
# unreadable, so migration never silently rolls a journey back to old progress.
const LEGACY_GAME_PATH := "user://twin_kings_save_v1.json"
const V2_GAME_PATH := "user://twin_kings_save_v2.json"
const V3_GAME_PATH := "user://twin_kings_save_v3.json"
const V4_GAME_PATH := "user://twin_kings_save_v4.json"
const V5_GAME_PATH := "user://twin_kings_save_v5.json"
const GAME_PATH := "user://twin_kings_save_v6.json"
const SETTINGS_PATH := "user://twin_kings_settings_v1.json"
const FOREST_START_X := 175.0
const RIVER_START_X := 175.0
const SWAMP_START_X := 175.0
const MISSING_START_X := 175.0
const FINAL_START_X := 175.0
const V3_FLAGS := ["puzzle_solved", "chapter_complete", "intro_seen", "forest_intro_seen", "forest_puzzle_solved", "forest_complete", "river_intro_seen", "river_puzzle_solved", "river_complete"]
const SWAMP_FLAGS := ["swamp_intro_seen", "swamp_puzzle_solved", "swamp_complete"]
const MISSING_FLAGS := ["missing_intro_seen", "missing_puzzle_solved", "missing_complete"]
const FINAL_FLAGS := ["final_intro_seen", "final_case_prepared", "final_complete"]

static func new_game() -> Dictionary:
	return {
		"version": 6,
		"region": "dungeon",
		"puzzle_solved": false,
		"chapter_complete": false,
		"intro_seen": false,
		"forest_intro_seen": false,
		"forest_puzzle_solved": false,
		"forest_complete": false,
		"river_intro_seen": false,
		"river_puzzle_solved": false,
		"river_complete": false,
		"swamp_intro_seen": false,
		"swamp_puzzle_solved": false,
		"swamp_complete": false,
		"missing_intro_seen": false,
		"missing_puzzle_solved": false,
		"missing_complete": false,
		"final_intro_seen": false,
		"final_case_prepared": false,
		"final_complete": false,
		"player_x": 270.0,
	}

static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var parsed: Variant = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

static func _write_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save data to " + path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file.close()
	return true

static func _is_version(data: Dictionary, expected: int) -> bool:
	var version: Variant = data.get("version", 0)
	return (typeof(version) == TYPE_INT or typeof(version) == TYPE_FLOAT) and float(version) == float(expected)

static func _position(data: Dictionary, fallback: float) -> float:
	var value: Variant = data.get("player_x", fallback)
	if (typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT) or not is_finite(float(value)):
		return fallback
	return clampf(float(value), 100.0, 1240.0)

# Original validation stays independent of the newest new_game() schema.
static func _valid_v2(data: Dictionary) -> Dictionary:
	if not _is_version(data, 2):
		return {}
	for key in ["puzzle_solved", "chapter_complete", "intro_seen", "forest_intro_seen", "forest_puzzle_solved", "forest_complete"]:
		if typeof(data.get(key)) != TYPE_BOOL:
			return {}
	var region: Variant = data.get("region")
	if typeof(region) != TYPE_STRING or region not in ["dungeon", "forest"]:
		return {}
	if data["chapter_complete"] and not data["puzzle_solved"]:
		return {}
	if (region == "forest" or data["forest_puzzle_solved"]) and not data["chapter_complete"]:
		return {}
	if data["forest_complete"] and not data["forest_puzzle_solved"]:
		return {}
	return {
		"version": 2,
		"region": region,
		"puzzle_solved": data["puzzle_solved"],
		"chapter_complete": data["chapter_complete"],
		"intro_seen": data["intro_seen"],
		"forest_intro_seen": data["forest_intro_seen"],
		"forest_puzzle_solved": data["forest_puzzle_solved"],
		"forest_complete": data["forest_complete"],
		"player_x": _position(data, FOREST_START_X if region == "forest" else 270.0),
	}

static func _valid_v3(data: Dictionary) -> Dictionary:
	if not _is_version(data, 3):
		return {}
	for key in V3_FLAGS:
		if typeof(data.get(key)) != TYPE_BOOL:
			return {}
	var region: Variant = data.get("region")
	if typeof(region) != TYPE_STRING or region not in ["dungeon", "forest", "river"]:
		return {}
	if data["chapter_complete"] and not data["puzzle_solved"]:
		return {}
	if (region == "forest" or data["forest_puzzle_solved"]) and not data["chapter_complete"]:
		return {}
	if data["forest_complete"] and not data["forest_puzzle_solved"]:
		return {}
	if (region == "river" or data["river_intro_seen"] or data["river_puzzle_solved"] or data["river_complete"]) and not data["forest_complete"]:
		return {}
	if data["river_complete"] and not data["river_puzzle_solved"]:
		return {}
	var fallback := 270.0
	if region == "forest":
		fallback = FOREST_START_X
	elif region == "river":
		fallback = RIVER_START_X
	var clean := {"version": 3, "region": region, "player_x": _position(data, fallback)}
	for key in V3_FLAGS:
		clean[key] = data[key]
	return clean

static func _valid_v4(data: Dictionary) -> Dictionary:
	if not _is_version(data, 4):
		return {}
	for key in SWAMP_FLAGS:
		if typeof(data.get(key)) != TYPE_BOOL:
			return {}
	var region: Variant = data.get("region")
	if typeof(region) != TYPE_STRING or region not in ["dungeon", "forest", "river", "swamp"]:
		return {}
	var prior := data.duplicate()
	prior["version"] = 3
	if region == "swamp":
		prior["region"] = "river"
	if _valid_v3(prior).is_empty():
		return {}
	if (region == "swamp" or data["swamp_intro_seen"] or data["swamp_puzzle_solved"] or data["swamp_complete"]) and not data["river_complete"]:
		return {}
	if data["swamp_complete"] and not data["swamp_puzzle_solved"]:
		return {}
	var fallback := 270.0
	if region == "forest":
		fallback = FOREST_START_X
	elif region == "river":
		fallback = RIVER_START_X
	elif region == "swamp":
		fallback = SWAMP_START_X
	# Explicitly construct V4, so future schema changes cannot invalidate it.
	var clean := {"version": 4, "region": region, "player_x": _position(data, fallback)}
	for key in V3_FLAGS:
		clean[key] = data[key]
	for key in SWAMP_FLAGS:
		clean[key] = data[key]
	return clean

static func _valid_v5(data: Dictionary) -> Dictionary:
	if not _is_version(data, 5):
		return {}
	for key in MISSING_FLAGS:
		if typeof(data.get(key)) != TYPE_BOOL:
			return {}
	var region: Variant = data.get("region")
	if typeof(region) != TYPE_STRING or region not in ["dungeon", "forest", "river", "swamp", "missing"]:
		return {}
	var prior := data.duplicate()
	prior["version"] = 4
	if region == "missing":
		prior["region"] = "swamp"
	if _valid_v4(prior).is_empty():
		return {}
	if (region == "missing" or data["missing_intro_seen"] or data["missing_puzzle_solved"] or data["missing_complete"]) and not data["swamp_complete"]:
		return {}
	if data["missing_complete"] and not data["missing_puzzle_solved"]:
		return {}
	var fallback := 270.0
	if region == "forest":
		fallback = FOREST_START_X
	elif region == "river":
		fallback = RIVER_START_X
	elif region == "swamp":
		fallback = SWAMP_START_X
	elif region == "missing":
		fallback = MISSING_START_X
	# V5 validation must not depend on future new_game() keys.
	var clean := {"version": 5, "region": region, "player_x": _position(data, fallback)}
	for key in V3_FLAGS:
		clean[key] = data[key]
	for key in SWAMP_FLAGS:
		clean[key] = data[key]
	for key in MISSING_FLAGS:
		clean[key] = data[key]
	return clean

static func _valid_v6(data: Dictionary) -> Dictionary:
	if not _is_version(data, 6):
		return {}
	for key in FINAL_FLAGS:
		if typeof(data.get(key)) != TYPE_BOOL:
			return {}
	var region: Variant = data.get("region")
	if typeof(region) != TYPE_STRING or region not in ["dungeon", "forest", "river", "swamp", "missing", "final"]:
		return {}
	var prior := data.duplicate()
	prior["version"] = 5
	if region == "final":
		prior["region"] = "missing"
	if _valid_v5(prior).is_empty():
		return {}
	if (region == "final" or data["final_intro_seen"] or data["final_case_prepared"] or data["final_complete"]) and not data["missing_complete"]:
		return {}
	if data["final_complete"] and not data["final_case_prepared"]:
		return {}
	var fallback := 270.0
	if region == "forest":
		fallback = FOREST_START_X
	elif region == "river":
		fallback = RIVER_START_X
	elif region == "swamp":
		fallback = SWAMP_START_X
	elif region == "missing":
		fallback = MISSING_START_X
	elif region == "final":
		fallback = FINAL_START_X
	var clean := new_game()
	for key in clean.keys():
		if key != "version" and key != "player_x":
			clean[key] = data[key]
	clean["player_x"] = _position(data, fallback)
	return clean

static func _migrate_v1(data: Dictionary) -> Dictionary:
	if not _is_version(data, 1):
		return {}
	if typeof(data.get("puzzle_solved")) != TYPE_BOOL or typeof(data.get("chapter_complete")) != TYPE_BOOL:
		return {}
	if data["chapter_complete"] and not data["puzzle_solved"]:
		return {}
	var progress := new_game()
	progress["puzzle_solved"] = data["puzzle_solved"]
	progress["chapter_complete"] = data["chapter_complete"]
	var intro_seen: Variant = data.get("intro_seen", false)
	progress["intro_seen"] = intro_seen if typeof(intro_seen) == TYPE_BOOL else false
	progress["player_x"] = _position(data, 270.0)
	if data["chapter_complete"]:
		progress["region"] = "forest"
		progress["player_x"] = FOREST_START_X
	return progress

static func _migrate_v2(data: Dictionary) -> Dictionary:
	var old := _valid_v2(data)
	if old.is_empty():
		return {}
	var progress := new_game()
	for key in ["region", "puzzle_solved", "chapter_complete", "intro_seen", "forest_intro_seen", "forest_puzzle_solved", "forest_complete", "player_x"]:
		progress[key] = old[key]
	if old["forest_complete"]:
		progress["region"] = "river"
		progress["player_x"] = RIVER_START_X
	return progress

static func _migrate_v3(data: Dictionary) -> Dictionary:
	var old := _valid_v3(data)
	if old.is_empty():
		return {}
	var progress := new_game()
	for key in V3_FLAGS:
		progress[key] = old[key]
	progress["region"] = old["region"]
	progress["player_x"] = old["player_x"]
	if old["river_complete"]:
		progress["region"] = "swamp"
		progress["player_x"] = SWAMP_START_X
	return progress

static func _migrate_v4(data: Dictionary) -> Dictionary:
	var old := _valid_v4(data)
	if old.is_empty():
		return {}
	var progress := new_game()
	for key in V3_FLAGS:
		progress[key] = old[key]
	for key in SWAMP_FLAGS:
		progress[key] = old[key]
	progress["region"] = old["region"]
	progress["player_x"] = old["player_x"]
	# A completed Swamp build resumes at the next chapter's entry.
	if old["swamp_complete"]:
		progress["region"] = "missing"
		progress["player_x"] = MISSING_START_X
	return progress

static func _migrate_v5(data: Dictionary) -> Dictionary:
	var old := _valid_v5(data)
	if old.is_empty():
		return {}
	var progress := new_game()
	for key in V3_FLAGS:
		progress[key] = old[key]
	for key in SWAMP_FLAGS:
		progress[key] = old[key]
	for key in MISSING_FLAGS:
		progress[key] = old[key]
	progress["region"] = old["region"]
	progress["player_x"] = old["player_x"]
	# The completed dungeon build resumes at the public hearing's entry.
	if old["missing_complete"]:
		progress["region"] = "final"
		progress["player_x"] = FINAL_START_X
	return progress

static func load_game() -> Dictionary:
	if FileAccess.file_exists(GAME_PATH):
		return _valid_v6(_read_json(GAME_PATH))
	var migrated: Dictionary
	if FileAccess.file_exists(V5_GAME_PATH):
		migrated = _migrate_v5(_read_json(V5_GAME_PATH))
	elif FileAccess.file_exists(V4_GAME_PATH):
		migrated = _migrate_v4(_read_json(V4_GAME_PATH))
	elif FileAccess.file_exists(V3_GAME_PATH):
		migrated = _migrate_v3(_read_json(V3_GAME_PATH))
	elif FileAccess.file_exists(V2_GAME_PATH):
		migrated = _migrate_v2(_read_json(V2_GAME_PATH))
	else:
		migrated = _migrate_v1(_read_json(LEGACY_GAME_PATH))
	if not migrated.is_empty():
		_write_json(GAME_PATH, migrated)
	return migrated

static func save_game(data: Dictionary) -> bool:
	var valid := _valid_v6(data)
	if valid.is_empty():
		push_warning("Refusing to save invalid game progress")
		return false
	return _write_json(GAME_PATH, valid)

static func load_settings() -> Dictionary:
	var data := _read_json(SETTINGS_PATH)
	var reduced: Variant = data.get("reduced_motion", false)
	var hints: Variant = data.get("show_hints", true)
	return {
		"reduced_motion": reduced if typeof(reduced) == TYPE_BOOL else false,
		"show_hints": hints if typeof(hints) == TYPE_BOOL else true,
	}

static func save_settings(data: Dictionary) -> bool:
	return _write_json(SETTINGS_PATH, data)
