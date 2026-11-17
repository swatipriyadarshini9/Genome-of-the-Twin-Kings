class_name ExpressionTrial
extends Resource

@export var id: String = ""
@export var title: String = ""
@export var samples: Array[Resource] = []
# Each Vector2 contains (control CPM, case CPM), in that order.
@export var options: Array[Vector2] = []

func review_pair(selected: Array) -> Dictionary:
	return ExpressionAnalysis.review_pair(samples, selected)

func grade(selected: Array, option: int) -> bool:
	if option < 0 or option >= options.size():
		return false
	var result := review_pair(selected)
	if not result.get("ok", false):
		return false
	return is_equal_approx(float(result["control_cpm"]), options[option].x) and is_equal_approx(float(result["case_cpm"]), options[option].y)
