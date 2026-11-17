class_name ExpressionAnalysis
extends RefCounted

# A transparent teaching calculation, NOT a differential-expression pipeline.
# CPM divides one target's count by total mapped reads expressed in millions.
# QC statuses are supplied, not calculated. One sample per condition cannot
# support statistical inference, and CPM alone cannot remove batch effects.
static func cpm(target_count: int, mapped_reads: int) -> float:
	if target_count < 0 or mapped_reads <= 0:
		return -1.0
	return float(target_count) * 1000000.0 / float(mapped_reads)

static func review_pair(samples: Array, selected: Array) -> Dictionary:
	if selected.size() != 2:
		return {"ok": false, "error": "choose_two"}
	for index in selected:
		if typeof(index) != TYPE_INT or index < 0 or index >= samples.size():
			return {"ok": false, "error": "invalid_index"}
	if selected[0] == selected[1]:
		return {"ok": false, "error": "duplicate"}
	var first := samples[selected[0]] as ExpressionSample
	var second := samples[selected[1]] as ExpressionSample
	if first == null or second == null:
		return {"ok": false, "error": "invalid_sample"}
	if first.condition not in ["control", "case"] or second.condition not in ["control", "case"] or first.batch.is_empty() or second.batch.is_empty():
		return {"ok": false, "error": "invalid_sample"}
	if not first.qc_pass or not second.qc_pass:
		return {"ok": false, "error": "failed_qc"}
	if first.condition == second.condition:
		return {"ok": false, "error": "need_control_and_case"}
	if first.batch != second.batch:
		return {"ok": false, "error": "different_batch"}
	var control := first if first.condition == "control" else second
	var case_sample := second if first.condition == "control" else first
	var control_cpm := cpm(control.target_count, control.mapped_reads)
	var case_cpm := cpm(case_sample.target_count, case_sample.mapped_reads)
	if control_cpm < 0.0 or case_cpm < 0.0:
		return {"ok": false, "error": "invalid_counts"}
	return {"ok": true, "control_cpm": control_cpm, "case_cpm": case_cpm}
