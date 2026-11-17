extends SceneTree

func _init() -> void:
	assert(VariantClassifier.classify("ATCGTA", "ATCGAA") == "substitution")
	assert(VariantClassifier.classify("ATCG-A", "ATCGTA") == "insertion")
	assert(VariantClassifier.classify("ACGTCA", "AC-TCA") == "deletion")
	assert(VariantClassifier.classify("ATCG", "ATCG") == "identical")
	assert(VariantClassifier.classify("AT-C", "ATT-") == "complex")
	assert(VariantClassifier.classify("AT-", "AT-") == "invalid")
	assert(VariantClassifier.classify("ACN", "ACT") == "invalid")
	assert(VariantClassifier.classify("AAA", "AAAA") == "invalid")
	assert(VariantClassifier.classify("", "") == "invalid")
	var trial := load("res://data/trials/forest_variants.tres") as VariantTrial
	assert(trial != null and trial.cases.size() == 3)
	assert(trial.grade(["substitution", "insertion", "deletion"]))
	assert(not trial.grade(["substitution", "deletion", "insertion"]))
	assert(not trial.grade(["substitution"]))
	var state := SaveData.new_game()
	assert(GameProgress.collected_count(state) == 0 and GameProgress.total_xp(state) == 0)
	state["puzzle_solved"] = true
	assert(GameProgress.collected_count(state) == 1 and GameProgress.total_xp(state) == 50)
	state["forest_puzzle_solved"] = true
	assert(GameProgress.collected_count(state) == 2 and GameProgress.total_xp(state) == 150)
	print("PASS: data-driven variant cases, gap orientation, invalid/complex examples, grading and evidence totals")
	quit(0)
