extends SceneTree

var failures: Array[String] = []

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)

func _initialize() -> void:
	var result := CaseAnalysis.compare_profiles(SequencePuzzle.REFERENCE, SequencePuzzle.PRISON_RECORD, CaseAnalysis.REPEAT_RECORD, CaseAnalysis.PUBLIC_DIFFERENCE_COUNT)
	_check(result.get("ok", false) and result["archived_positions"] == [6, 12] and result["repeat_positions"] == [6, 12], "both readings differ at positions 6 and 12")
	_check(result["agree"] and result["summary_conflicts"], "repeat agrees and public summary conflicts")
	var matching := CaseAnalysis.compare_profiles("ACGT", "ACGT", "ACGT", 0)
	_check(matching.ok and matching.agree and not matching.summary_conflicts, "a matching summary is not called a conflict")
	var unequal := CaseAnalysis.compare_profiles("ACGT", "ACGA", "ACGT", 0)
	_check(unequal.ok and not unequal.agree and unequal.summary_conflicts, "a discordant repeat remains visible")
	_check(not CaseAnalysis.compare_profiles("ACGT", "ACG", "ACGT", 0).ok, "unequal lengths rejected")
	_check(not CaseAnalysis.compare_profiles("ACGT", "ACNT", "ACGT", 0).ok, "unknown base rejected")
	_check(not CaseAnalysis.compare_profiles("ACGT", "ACGT", "ACGT", -1).ok, "negative summary rejected")
	_check(not CaseAnalysis.compare_profiles("ACGT", "ACGT", "ACGT", 5).ok, "impossible summary rejected")
	var admitted := 0
	for mask in range(1 << CaseAnalysis.CLAIMS.size()):
		var selected: Array[int] = []
		for i in range(CaseAnalysis.CLAIMS.size()):
			if (mask & (1 << i)) != 0:
				selected.append(i)
		if CaseAnalysis.review_claims(selected).get("ok", false):
			admitted += 1
			_check(selected == [0, 2, 4, 5], "only supported claims are admitted")
	_check(admitted == 1, "exactly one complete set of claims is accepted")
	_check(CaseAnalysis.review_claims([]).error == "select_claims", "empty review rejected")
	_check(CaseAnalysis.review_claims([1]).error == "unsupported", "overclaim rejected")
	_check(CaseAnalysis.review_claims([0]).error == "missing", "incomplete review rejected")
	_check(CaseAnalysis.review_claims([0, 0]).error == "invalid_selection", "duplicate selection rejected")
	_check(CaseAnalysis.review_claims([true]).error == "invalid_selection", "non-integer selection rejected")
	_check(CaseAnalysis.review_profile([-1, -1, -1]).error == "incomplete", "incomplete case rejected")
	_check(CaseAnalysis.review_profile([0, 0, 2]).error == "observation", "wrong profile observation rejected")
	_check(CaseAnalysis.review_profile([1, 1, 2]).error == "conclusion", "identity overclaim rejected")
	_check(CaseAnalysis.review_profile([1, 0, 1]).error == "next_step", "no-call overclaim rejected")
	_check(CaseAnalysis.review_profile([1, 0, 3]).error == "invalid_choice", "out-of-range option rejected")
	var accepted := 0
	for a in range(3):
		for b in range(3):
			for c in range(3):
				if CaseAnalysis.review_profile([a, b, c]).get("ok", false):
					accepted += 1
					_check([a, b, c] == [1, 0, 2], "only the defensible profile case is accepted")
	_check(accepted == 1, "exactly one profile answer is accepted")
	var state := SaveData.new_game()
	for key in ["puzzle_solved", "forest_puzzle_solved", "river_puzzle_solved", "swamp_puzzle_solved", "missing_puzzle_solved", "final_case_prepared"]:
		state[key] = true
	_check(GameProgress.collected_count(state) == 6 and GameProgress.total_xp(state) == 1050, "six evidence entries and XP counted once")
	if failures.is_empty():
		print("PASS: evidence review, profile comparison, overclaim rejection, unique case and six rewards")
		quit(0)
	else:
		print("FAILURES: ", failures.size())
		quit(1)
