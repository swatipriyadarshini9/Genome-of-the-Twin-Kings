class_name ExpressionSample
extends Resource

# A deliberately small, already-scored RNA-seq teaching sample.
@export var id: String = ""
@export var condition: String = "" # "control" or "case"
@export var batch: String = ""
@export var qc_pass: bool = false
@export var qc_note: String = ""
@export var mapped_reads: int = 0
@export var target_count: int = 0
