class_name CaseAnalysis
extends RefCounted

# A deliberately small, authored courtroom exercise. The repeat is another
# reading of the SAME aliquot, not an independently collected biological sample.
# These short toy profiles cannot identify twins, establish disease or intent,
# or replace quality control, chain-of-custody checks and independent evidence.
const REPEAT_RECORD := "ATGCCTTTAGGTTAACCG"
const PUBLIC_DIFFERENCE_COUNT := 0
const DNA := ["A", "C", "G", "T"]

# The first item links the first two recovered fragments without suggesting
# that the Forest's teaching examples came from the prison sample.
const CLAIMS := [
	{"heading": "PRISON / FOREST", "text": "Prison record and separate Forest examples do not prove identity.", "supported": true},
	{"heading": "RIVER", "text": "One exact-overlap contig proves all real assemblies are unique.", "supported": false},
	{"heading": "RIVER", "text": "A toy contig does not resolve real repeats and errors.", "supported": true},
	{"heading": "SWAMP", "text": "One pair at 30 CPM each proves equal expression.", "supported": false},
	{"heading": "SWAMP", "text": "One 30 CPM pair lacks replication and cannot establish equality.", "supported": true},
	{"heading": "DRAGON", "text": "Site 112 is a candidate; site 143 is a no-call, not a match.", "supported": true},
]

static func review_claims(selected: Array) -> Dictionary:
	if selected.is_empty():
		return {"ok": false, "error": "select_claims"}
	var unique: Array[int] = []
	for value in selected:
		if typeof(value) != TYPE_INT or value < 0 or value >= CLAIMS.size() or unique.has(value):
			return {"ok": false, "error": "invalid_selection"}
		unique.append(value)
		if not CLAIMS[value]["supported"]:
			return {"ok": false, "error": "unsupported", "index": value}
	for i in range(CLAIMS.size()):
		if CLAIMS[i]["supported"] and not unique.has(i):
			return {"ok": false, "error": "missing", "index": i}
	return {"ok": true}

static func compare_profiles(reference: String, archived: String, repeat: String, public_count: int) -> Dictionary:
	if reference.is_empty() or reference.length() != archived.length() or reference.length() != repeat.length():
		return {"ok": false, "error": "invalid_lengths"}
	if public_count < 0 or public_count > reference.length():
		return {"ok": false, "error": "invalid_public_count"}
	for sequence in [reference, archived, repeat]:
		for i in range(sequence.length()):
			if sequence[i] not in DNA:
				return {"ok": false, "error": "invalid_base"}
	var first := SequencePuzzle.differences(reference, archived)
	var reread := SequencePuzzle.differences(reference, repeat)
	return {
		"ok": true,
		"archived_positions": first,
		"repeat_positions": reread,
		"agree": first == reread and archived == repeat,
		"summary_conflicts": first.size() != public_count or reread.size() != public_count,
	}

# The screen has exactly three options per question. Grading first validates the
# underlying authored records so a data-export error is not blamed on a player.
static func review_profile(answers: Array) -> Dictionary:
	var comparison := compare_profiles(SequencePuzzle.REFERENCE, SequencePuzzle.PRISON_RECORD, REPEAT_RECORD, PUBLIC_DIFFERENCE_COUNT)
	if not comparison.get("ok", false) or comparison["archived_positions"] != [6, 12] or comparison["repeat_positions"] != [6, 12] or not comparison["agree"] or not comparison["summary_conflicts"]:
		return {"ok": false, "error": "invalid_data"}
	if answers.size() != 3:
		return {"ok": false, "error": "incomplete"}
	for value in answers:
		if typeof(value) != TYPE_INT or value == -1:
			return {"ok": false, "error": "incomplete"}
		if value < 0 or value > 2:
			return {"ok": false, "error": "invalid_choice"}
	if answers[0] != 1:
		return {"ok": false, "error": "observation"}
	if answers[1] != 0:
		return {"ok": false, "error": "conclusion"}
	if answers[2] != 2:
		return {"ok": false, "error": "next_step"}
	return {"ok": true, "comparison": comparison}
