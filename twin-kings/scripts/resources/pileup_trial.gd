class_name PileupTrial
extends Resource

@export var id: String = ""
@export var title: String = ""
@export var min_quality: int = 30
@export var min_depth: int = 4
@export var min_alt: int = 2
@export var sites: Array[Resource] = []
@export var support_choices: Array[Resource] = []

# The fixed interface supports exactly three sites and these three statuses.
# If a future authored site needs uncertain/ambiguous, extend the UI first.
func review_answer(statuses: Array, support_index: int) -> Dictionary:
	if sites.size() != 3 or support_choices.is_empty():
		return {"ok": false, "error": "invalid_trial"}
	if statuses.size() != sites.size():
		return {"ok": false, "error": "classify_all"}
	for status in statuses:
		if typeof(status) != TYPE_STRING or status == "":
			return {"ok": false, "error": "classify_all"}
		if status not in ["candidate", "reference_only", "no_call"]:
			return {"ok": false, "error": "invalid_choice"}
	# Validate the complete authored trial before suggesting a learner is wrong.
	# In particular, missing export data must not turn a candidate into a
	# misleading "too few reads" feedback message.
	var results: Array[Dictionary] = []
	var candidate: Dictionary = {}
	for site in sites:
		var result := PileupAnalysis.review_site(site, min_quality, min_depth, min_alt)
		if not result.get("ok", false) or result.get("status") not in ["candidate", "reference_only", "no_call"]:
			return {"ok": false, "error": "invalid_trial"}
		results.append(result)
		if result["status"] == "candidate":
			if not candidate.is_empty():
				return {"ok": false, "error": "invalid_trial"}
			candidate = result
	if candidate.is_empty():
		return {"ok": false, "error": "invalid_trial"}
	var matching_support := 0
	for option in support_choices:
		if not option is PileupSupportChoice:
			return {"ok": false, "error": "invalid_trial"}
		var possible := option as PileupSupportChoice
		if possible.alt_base == candidate["alt_base"] and possible.alt_count == candidate["alt_count"] and possible.depth == candidate["depth"]:
			matching_support += 1
	if matching_support != 1:
		return {"ok": false, "error": "invalid_trial"}
	for i in range(results.size()):
		if results[i]["status"] != statuses[i]:
			return {"ok": false, "error": "classification", "position": results[i]["position"], "expected": results[i]["status"], "chosen": statuses[i]}
	if support_index < 0 or support_index >= support_choices.size():
		return {"ok": false, "error": "choose_support"}
	var choice: Resource = support_choices[support_index]
	if not choice is PileupSupportChoice:
		return {"ok": false, "error": "invalid_trial"}
	var answer := choice as PileupSupportChoice
	if answer.alt_base != candidate["alt_base"] or answer.alt_count != candidate["alt_count"] or answer.depth != candidate["depth"]:
		return {"ok": false, "error": "support"}
	return {"ok": true, "candidate": candidate}
