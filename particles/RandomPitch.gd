extends AudioStreamPlayer2D

@export var range = .02

func _ready():
	finished.connect(apply)
	apply()

func apply():
	pitch_scale = randf_range(1-range, 1 + range)
