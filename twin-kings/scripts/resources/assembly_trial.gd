class_name AssemblyTrial
extends Resource

@export var id: String = ""
@export var title: String = ""
@export var reads: PackedStringArray = PackedStringArray()
@export_range(1, 20) var min_overlap: int = 3

func assemble(order: Array, require_all: bool = true) -> Dictionary:
	return ReadAssembly.assemble(reads, order, min_overlap, require_all)

func grade(order: Array) -> bool:
	var result := assemble(order)
	return bool(result.get("ok", false)) and bool(result.get("complete", false))
