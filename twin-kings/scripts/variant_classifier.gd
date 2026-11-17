class_name VariantClassifier
extends RefCounted

# Classifies simple, PRE-ALIGNED teaching examples relative to a reference.
# It is not an alignment algorithm, caller, or biological validation pipeline.
# A gap in the reference is an insertion in the sample; a gap in the sample
# is a deletion relative to the reference. Mixed event kinds are 'complex'.
static func classify(reference: String, sample: String) -> String:
	if reference.is_empty() or reference.length() != sample.length():
		return "invalid"
	var kinds: Dictionary = {}
	for i in range(reference.length()):
		var ref_base := reference[i]
		var sample_base := sample[i]
		if ref_base not in ["A", "C", "G", "T", "-"] or sample_base not in ["A", "C", "G", "T", "-"]:
			return "invalid"
		if ref_base == "-" and sample_base == "-":
			return "invalid"
		if ref_base == sample_base:
			continue
		if ref_base == "-":
			kinds["insertion"] = true
		elif sample_base == "-":
			kinds["deletion"] = true
		else:
			kinds["substitution"] = true
	if kinds.is_empty():
		return "identical"
	if kinds.size() > 1:
		return "complex"
	return String(kinds.keys()[0])
