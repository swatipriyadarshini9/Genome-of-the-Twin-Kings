extends Control

var elapsed := 0.0
var reduced_motion := false
var visible_particles := true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	if not reduced_motion:
		elapsed += delta
		queue_redraw()

func _draw() -> void:
	if not visible_particles:
		return
	# Deterministic ember motes: ambient rather than a looped video.
	for i in range(34):
		var x := fmod(float(i * 241 + i * i * 19), 1366.0)
		var y := fmod(float(i * 113 + i * i * 7) - elapsed * (4.0 + float(i % 5) * 2.0) + 7680.0, 768.0)
		var flicker := 0.3 + 0.2 * sin(elapsed * (0.6 + float(i % 4) * 0.2) + i)
		draw_circle(Vector2(x, y), 0.8 + float(i % 3) * 0.35, Color(0.92, 0.65, 0.36, flicker))
