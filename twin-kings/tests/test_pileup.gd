extends SceneTree

func _init() -> void:
	var trial := load("res://data/trials/missing_pileup.tres") as PileupTrial
	assert(trial != null and trial.sites.size() == 3 and trial.support_choices.size() == 3)
	var first := PileupAnalysis.review_site(trial.sites[0], trial.min_quality, trial.min_depth, trial.min_alt)
	var second := PileupAnalysis.review_site(trial.sites[1], trial.min_quality, trial.min_depth, trial.min_alt)
	var third := PileupAnalysis.review_site(trial.sites[2], trial.min_quality, trial.min_depth, trial.min_alt)
	assert(first.ok and first.position == 112 and first.reference == "A")
	assert(first.status == "candidate" and first.depth == 4 and first.alt_base == "G" and first.alt_count == 2)
	assert(first.counts["A"] == 2 and first.counts["G"] == 2)
	assert(second.status == "reference_only" and second.depth == 4 and second.counts["T"] == 0)
	assert(third.status == "no_call" and third.depth == 1)
	var answer := ["candidate", "reference_only", "no_call"]
	assert(trial.review_answer(answer, 0).ok)
	assert(trial.review_answer(answer, 1).error == "support")
	assert(trial.review_answer(answer, 2).error == "support")
	assert(trial.review_answer(answer, -1).error == "choose_support")
	assert(trial.review_answer(["candidate", "", "no_call"], 0).error == "classify_all")
	assert(trial.review_answer(["candidate", "reference_only", "reference_only"], 0).error == "classification")
	assert(trial.review_answer(["candidate", "reference_only", "unknown"], 0).error == "invalid_choice")
	var matching := 0
	for i in range(trial.support_choices.size()):
		if trial.review_answer(answer, i).get("ok", false):
			matching += 1
	assert(matching == 1)
	# If the authored data is missing or the options are impossible, report a
	# trial error instead of telling a learner that their classification is wrong.
	var missing_reads := PileupTrial.new()
	for original in trial.sites:
		var blank := original.duplicate(true) as PileupSite
		blank.bases = PackedStringArray()
		blank.qualities = PackedInt32Array()
		missing_reads.sites.append(blank)
	missing_reads.support_choices.assign(trial.support_choices)
	assert(missing_reads.review_answer(answer, 0).error == "invalid_trial")
	var no_correct_choice := PileupTrial.new()
	no_correct_choice.sites.assign(trial.sites)
	no_correct_choice.support_choices.append(trial.support_choices[1])
	assert(no_correct_choice.review_answer(answer, 0).error == "invalid_trial")

	var site := PileupSite.new()
	site.position = 10
	site.reference = "A"
	site.bases = PackedStringArray(["A", "A", "G", "G", "T"])
	site.qualities = PackedInt32Array([30, 35, 30, 29, 2])
	var threshold := PileupAnalysis.review_site(site, 30, 4, 2)
	assert(threshold.ok and threshold.depth == 3 and threshold.status == "no_call")
	site.qualities[3] = 30
	threshold = PileupAnalysis.review_site(site, 30, 4, 2)
	assert(threshold.depth == 4 and threshold.status == "candidate" and threshold.alt_count == 2)
	site.bases = PackedStringArray(["A", "A", "A", "G"])
	site.qualities = PackedInt32Array([30, 30, 30, 30])
	assert(PileupAnalysis.review_site(site).status == "uncertain") # one alternate is not ref-only
	site.bases = PackedStringArray(["C", "C", "G", "G"])
	assert(PileupAnalysis.review_site(site).status == "ambiguous") # never select an alternate arbitrarily
	site.bases = PackedStringArray([])
	site.qualities = PackedInt32Array([])
	assert(PileupAnalysis.review_site(site).status == "no_call")
	site.bases = PackedStringArray(["N"])
	site.qualities = PackedInt32Array([30])
	assert(not PileupAnalysis.review_site(site).ok)
	site.bases = PackedStringArray(["A"])
	site.qualities = PackedInt32Array([])
	assert(not PileupAnalysis.review_site(site).ok)
	assert(not PileupAnalysis.review_site(site, 30, 0, 2).ok)
	var state := SaveData.new_game()
	state["puzzle_solved"] = true
	state["forest_puzzle_solved"] = true
	state["river_puzzle_solved"] = true
	state["swamp_puzzle_solved"] = true
	state["missing_puzzle_solved"] = true
	assert(GameProgress.collected_count(state) == 5 and GameProgress.total_xp(state) == 750)
	print("PASS: quality/depth filtering, reference/alternate/no-call/uncertain statuses, support grading and five rewards")
	quit(0)
