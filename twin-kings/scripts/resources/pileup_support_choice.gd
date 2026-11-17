class_name PileupSupportChoice
extends Resource

@export var alt_base: String = ""
@export var alt_count: int = 0
@export var depth: int = 0

func display_text() -> String:
	return "%s   /   %d OF %d PASSING READS" % [alt_base, alt_count, depth]
