extends SceneTree

# Run AFTER a Web export, pointing to Godot's converted binary .res file.
# Testing only the authored .tres is insufficient: export-time conversion
# previously dropped the packed read and quality arrays from this resource.
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Pass the converted export-...-missing_pileup.res path after --")
		quit(2)
		return
	var path: String = args[0]
	if path.is_absolute_path():
		path = ProjectSettings.localize_path(path)
	elif not path.begins_with("res://"):
		path = "res://" + path.trim_prefix("./")
	var trial := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as PileupTrial
	if trial == null or trial.sites.size() != 3:
		push_error("Cannot load the converted pileup trial: " + path)
		quit(1)
		return
	var expected_bases := [
		PackedStringArray(["A", "A", "G", "G", "G"]),
		PackedStringArray(["C", "C", "C", "C", "T"]),
		PackedStringArray(["T", "T", "C"]),
	]
	var expected_qualities := [
		PackedInt32Array([36, 34, 35, 32, 12]),
		PackedInt32Array([38, 35, 31, 33, 8]),
		PackedInt32Array([36, 18, 12]),
	]
	for i in range(3):
		var site := trial.sites[i] as PileupSite
		if site == null or site.bases != expected_bases[i] or site.qualities != expected_qualities[i]:
			push_error("Export lost or changed the reads at site index %d" % i)
			quit(1)
			return
	var answer := trial.review_answer(["candidate", "reference_only", "no_call"], 0)
	if not answer.get("ok", false):
		push_error("Converted pileup trial cannot be solved: " + str(answer))
		quit(1)
		return
	print("PASS: exported binary resource preserves the reads, qualities and correct grading")
	quit(0)
