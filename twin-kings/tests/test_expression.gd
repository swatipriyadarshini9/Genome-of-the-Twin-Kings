extends SceneTree

func _init() -> void:
	assert(ExpressionAnalysis.cpm(60, 2000000) == 30.0)
	assert(ExpressionAnalysis.cpm(120, 4000000) == 30.0)
	assert(ExpressionAnalysis.cpm(0, 4000000) == 0.0)
	assert(ExpressionAnalysis.cpm(-1, 4000000) == -1.0)
	assert(ExpressionAnalysis.cpm(5, 0) == -1.0)
	assert(ExpressionAnalysis.cpm(5, -1) == -1.0)
	var trial := load("res://data/trials/swamp_expression.tres") as ExpressionTrial
	assert(trial != null and trial.samples.size() == 4 and trial.options.size() == 3)
	var pair := trial.review_pair([0, 1])
	assert(pair.ok and pair.control_cpm == 30.0 and pair.case_cpm == 30.0)
	assert(trial.review_pair([1, 0]).ok and trial.grade([1, 0], 0))
	assert(trial.grade([0, 1], 0))
	assert(not trial.grade([0, 1], 1) and not trial.grade([0, 1], 2))
	assert(not trial.grade([0, 1], -1) and not trial.grade([0, 1], 3))
	assert(trial.review_pair([]).error == "choose_two")
	assert(trial.review_pair([0, 0]).error == "duplicate")
	assert(trial.review_pair([0, 4]).error == "invalid_index")
	assert(trial.review_pair([0, 1.0]).error == "invalid_index")
	assert(trial.review_pair([0, 2]).error == "failed_qc")
	assert(trial.review_pair([0, 3]).error == "different_batch")
	assert(trial.review_pair([1, 3]).error == "need_control_and_case")
	var valid_pairs := 0
	for a in range(4):
		for b in range(a + 1, 4):
			if trial.review_pair([a, b]).get("ok", false):
				valid_pairs += 1
	assert(valid_pairs == 1)
	var bad := ExpressionSample.new()
	bad.condition = "case"
	bad.batch = "I"
	bad.qc_pass = true
	bad.mapped_reads = 0
	bad.target_count = 10
	assert(ExpressionAnalysis.review_pair([trial.samples[0], bad], [0, 1]).error == "invalid_counts")
	var state := SaveData.new_game()
	state["puzzle_solved"] = true
	state["forest_puzzle_solved"] = true
	state["river_puzzle_solved"] = true
	state["swamp_puzzle_solved"] = true
	assert(GameProgress.collected_count(state) == 4 and GameProgress.total_xp(state) == 500)
	print("PASS: CPM arithmetic, pair/QC/batch checks, invalid input, unique puzzle and swamp reward")
	quit(0)
