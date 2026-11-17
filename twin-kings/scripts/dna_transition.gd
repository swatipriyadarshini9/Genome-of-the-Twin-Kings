extends Control

signal midpoint
signal finished

const TITLE_FONT = preload("res://assets/fonts/Cinzel.ttf")
const UI_FONT = preload("res://assets/fonts/DMSans.ttf")
var elapsed := 0.0
var duration := 1.45
var passed_midpoint := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	elapsed += delta
	if not passed_midpoint and elapsed >= duration * 0.47:
		passed_midpoint = true
		midpoint.emit()
	if elapsed >= duration:
		set_process(false)
		finished.emit()
	queue_redraw()

func _draw() -> void:
	var opacity := minf(clampf(elapsed * 4.0, 0.0, 1.0), clampf((duration - elapsed) * 4.0, 0.0, 1.0))
	draw_rect(Rect2(Vector2.ZERO, Vector2(1366, 768)), Color(0.015, 0.026, 0.025, opacity))
	var center := Vector2(683, 335)
	for i in range(28):
		var y := center.y - 112.0 + i * 8.0
		var phase := float(i) * 0.28 + elapsed * 3.0
		var x1 := center.x + sin(phase) * 30.0
		var x2 := center.x - sin(phase) * 30.0
		if i % 3 == 0:
			draw_line(Vector2(x1, y), Vector2(x2, y), Color(0.66, 0.60, 0.43, 0.38 * opacity), 1.0)
		draw_circle(Vector2(x1, y), 2.5, Color(0.80, 0.69, 0.47, opacity))
		draw_circle(Vector2(x2, y), 2.5, Color(0.37, 0.70, 0.65, opacity))
	draw_string(TITLE_FONT, Vector2(493, 504), "THE TRUTH IS IN THE DETAILS", HORIZONTAL_ALIGNMENT_CENTER, 380, 16, Color(0.82, 0.75, 0.59, opacity))
	draw_string(UI_FONT, Vector2(583, 535), "DECODING THE RECORD", HORIZONTAL_ALIGNMENT_CENTER, 200, 10, Color(0.58, 0.62, 0.58, opacity))
