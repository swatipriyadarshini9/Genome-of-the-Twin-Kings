class_name GameProgress
extends RefCounted

const QUESTS: Array = [
	preload("res://data/quests/dungeon_investigation.tres"),
	preload("res://data/quests/forest_investigation.tres"),
	preload("res://data/quests/river_assembly.tres"),
	preload("res://data/quests/swamp_assay.tres"),
	preload("res://data/quests/missing_ledger.tres"),
	preload("res://data/quests/final_case.tres"),
]

static func collected_count(state: Dictionary) -> int:
	var total := 0
	for quest: QuestDefinition in QUESTS:
		if bool(state.get(quest.completion_flag, false)):
			total += 1
	return total

static func total_xp(state: Dictionary) -> int:
	var total := 0
	for quest: QuestDefinition in QUESTS:
		if bool(state.get(quest.completion_flag, false)) and quest.evidence != null:
			total += quest.evidence.xp
	return total

static func is_collected(state: Dictionary, quest: QuestDefinition) -> bool:
	return bool(state.get(quest.completion_flag, false))
