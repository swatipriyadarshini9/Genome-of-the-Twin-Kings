class_name VariantTrial
extends Resource

@export var id: String = ""
@export var title: String = ""
@export var cases: Array[Resource] = []

func grade(answers: Array) -> bool:
	if answers.size() != cases.size() or cases.is_empty():
		return false
	for i in range(cases.size()):
		var item := cases[i] as VariantCase
		if item == null:
			return false
		var expected := VariantClassifier.classify(item.reference, item.sample)
		if expected not in ["substitution", "insertion", "deletion"] or answers[i] != expected:
			return false
	return true
