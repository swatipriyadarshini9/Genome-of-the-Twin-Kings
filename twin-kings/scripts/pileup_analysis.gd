class_name PileupAnalysis
extends RefCounted

# An intentionally small, transparent teaching rule; NOT a variant caller.
# Bases are assumed to have been aligned already. The routine does not assess
# mapping quality, read independence, duplicate/strand bias, genotype or disease.
const DNA := ["A", "C", "G", "T"]

static func review_site(site: Resource, min_quality: int = 30, min_depth: int = 4, min_alt: int = 2) -> Dictionary:
	if not site is PileupSite or min_quality < 0 or min_quality > 93 or min_depth < 1 or min_alt < 1:
		return {"ok": false, "error": "invalid_site_or_rule"}
	var locus := site as PileupSite
	if locus.position < 1 or locus.reference not in DNA or locus.bases.size() != locus.qualities.size():
		return {"ok": false, "error": "invalid_site"}
	var counts := {"A": 0, "C": 0, "G": 0, "T": 0}
	var depth := 0
	for i in range(locus.bases.size()):
		var base: String = locus.bases[i]
		var quality: int = locus.qualities[i]
		if base not in DNA or quality < 0 or quality > 93:
			return {"ok": false, "error": "invalid_read"}
		if quality >= min_quality:
			counts[base] += 1
			depth += 1
	var alt_total := 0
	var qualifying: Array[String] = []
	for base in DNA:
		if base != locus.reference:
			alt_total += int(counts[base])
			if int(counts[base]) >= min_alt:
				qualifying.append(base)
	var status := "no_call"
	var alternate := ""
	if depth >= min_depth:
		if qualifying.size() == 1:
			status = "candidate"
			alternate = qualifying[0]
		elif qualifying.size() > 1:
			# Do not arbitrarily choose one if multiple alternates meet the rule.
			status = "ambiguous"
		elif alt_total == 0:
			status = "reference_only"
		else:
			# One or more alternate observations below the threshold are not
			# the same as observing only reference bases.
			status = "uncertain"
	return {
		"ok": true,
		"position": locus.position,
		"reference": locus.reference,
		"counts": counts,
		"depth": depth,
		"status": status,
		"alt_base": alternate,
		"alt_count": int(counts[alternate]) if alternate != "" else 0,
	}
