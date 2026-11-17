class_name SequencePuzzle
extends RefCounted

# Positions presented to the player are 1-based. These equal-length strings
# deliberately contain two substitutions; this is not a general aligner.
const REFERENCE := "ATGCCATTAGGCTAACCG"
const PRISON_RECORD := "ATGCCTTTAGGTTAACCG"

static func differences(reference: String, sample: String) -> Array[int]:
	var positions: Array[int] = []
	if reference.length() != sample.length():
		return positions
	for i in range(reference.length()):
		if reference[i] != sample[i]:
			positions.append(i + 1)
	return positions

static func is_correct(selected: Array) -> bool:
	var expected := differences(REFERENCE, PRISON_RECORD)
	if selected.size() != expected.size():
		return false
	var unique: Array[int] = []
	for value in selected:
		if typeof(value) != TYPE_INT or value < 1 or value > REFERENCE.length() or unique.has(value):
			return false
		unique.append(value)
	unique.sort()
	return unique == expected
