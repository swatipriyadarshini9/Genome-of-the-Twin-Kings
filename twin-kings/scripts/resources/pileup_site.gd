@tool
class_name PileupSite
extends Resource

# @tool is important: Godot 4.4's export-time text-to-binary resource
# conversion otherwise drops these packed-array values on placeholder scripts.
# One teaching locus with bases already aligned to a supplied reference.
# Base-quality values are supplied; this model does not perform alignment.
@export var position: int = 0
@export var reference: String = ""
@export var bases: PackedStringArray = []
@export var qualities: PackedInt32Array = []
