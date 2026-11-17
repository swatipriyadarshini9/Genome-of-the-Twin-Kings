extends SceneTree

func _init() -> void:
	assert(ReadAssembly.longest_overlap("ATGCCG", "CCGTTA") == 3)
	assert(ReadAssembly.longest_overlap("ATAT", "TATC") == 3)
	assert(ReadAssembly.longest_overlap("AAAA", "AAAA") == 4)
	assert(ReadAssembly.longest_overlap("AAAA", "CCCC") == 0)
	assert(ReadAssembly.longest_overlap("", "AAAA") == -1)
	assert(ReadAssembly.longest_overlap("A-N", "AAAA") == -1)
	var trial := load("res://data/trials/river_assembly.tres") as AssemblyTrial
	assert(trial != null and trial.reads.size() == 4 and trial.min_overlap == 3)
	var order: Array[int] = [1, 3, 0, 2]
	var built := trial.assemble(order)
	assert(built.ok and built.complete)
	assert(built.contig == "ATGCCGTTAGCTAAC")
	assert(built.joins == PackedInt32Array([3, 3, 3]))
	assert(trial.grade(order))
	assert(not trial.grade([1, 3, 0]))
	assert(trial.assemble([1, 3], false).contig == "ATGCCGTTA")
	assert(trial.assemble([1, 3, 1]).error == "duplicate_read")
	assert(trial.assemble([1, -1, 0, 2]).error == "invalid_index")
	assert(trial.assemble([1, 3, 4, 2]).error == "invalid_index")
	assert(trial.assemble([1, 2, 0, 3]).error == "short_overlap")
	assert(ReadAssembly.assemble(PackedStringArray(["ACN", "ACG"]), [0, 1], 2).error == "invalid_read")
	assert(ReadAssembly.assemble(PackedStringArray(["ACG", "CGT"]), [0, 1], 0).error == "invalid_trial")
	var valid_orders := 0
	for a in range(4):
		for b in range(4):
			for c in range(4):
				for d in range(4):
					if trial.grade([a, b, c, d]):
						valid_orders += 1
	assert(valid_orders == 1)
	var state := SaveData.new_game()
	state["puzzle_solved"] = true
	state["forest_puzzle_solved"] = true
	state["river_puzzle_solved"] = true
	assert(GameProgress.collected_count(state) == 3 and GameProgress.total_xp(state) == 300)
	print("PASS: exact overlaps, contig construction, invalid/duplicate/incomplete orders, unique trial and river reward")
	quit(0)
