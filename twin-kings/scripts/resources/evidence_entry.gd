class_name EvidenceEntry
extends Resource

# A journal record carries provenance and limits alongside its conclusion.
@export var id: String = ""
@export var title: String = ""
@export var source: String = ""
@export_multiline var observation: String = ""
@export_multiline var limitation: String = ""
@export var xp: int = 0
