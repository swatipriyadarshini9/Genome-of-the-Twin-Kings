class_name ReadAssembly
extends RefCounted

# A deliberately small exact suffix-to-prefix teaching model. It does not
# perform real de novo assembly, reverse-complement handling, error correction,
# quality checks, or disambiguation of repeats.
static func is_dna(sequence: String) -> bool:
	if sequence.is_empty():
		return false
	for i in range(sequence.length()):
		if sequence[i] not in ["A", "C", "G", "T"]:
			return false
	return true

static func longest_overlap(left: String, right: String) -> int:
	if not is_dna(left) or not is_dna(right):
		return -1
	var max_length := mini(left.length(), right.length())
	for n in range(max_length, 0, -1):
		if left.substr(left.length() - n) == right.substr(0, n):
			return n
	return 0

# Read indices must be unique. Each join uses the longest exact suffix-prefix
# overlap. The overlapping letters appear only once in the output contig.
static func assemble(reads: PackedStringArray, order: Array, min_overlap: int, require_all: bool = true) -> Dictionary:
	if reads.is_empty() or min_overlap < 1:
		return {"ok": false, "error": "invalid_trial"}
	for read in reads:
		if not is_dna(read):
			return {"ok": false, "error": "invalid_read"}
	if order.is_empty():
		return {"ok": false, "error": "empty_order"}
	var seen: Dictionary = {}
	for item in order:
		if typeof(item) != TYPE_INT or item < 0 or item >= reads.size():
			return {"ok": false, "error": "invalid_index"}
		if seen.has(item):
			return {"ok": false, "error": "duplicate_read"}
		seen[item] = true
	if require_all and order.size() != reads.size():
		return {"ok": false, "error": "incomplete"}
	var contig := reads[order[0]]
	var joins := PackedInt32Array()
	for i in range(1, order.size()):
		var overlap := longest_overlap(reads[order[i - 1]], reads[order[i]])
		if overlap < min_overlap:
			return {"ok": false, "error": "short_overlap", "join": i, "overlap": overlap}
		joins.append(overlap)
		contig += reads[order[i]].substr(overlap)
	return {"ok": true, "complete": order.size() == reads.size(), "contig": contig, "joins": joins}
