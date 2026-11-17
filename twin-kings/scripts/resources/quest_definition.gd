class_name QuestDefinition
extends Resource

# Progress is recorded by flag rather than modifying this shared definition.
@export var id: String = ""
@export var title: String = ""
@export var region: String = ""
@export var completion_flag: String = ""
@export var evidence: EvidenceEntry
