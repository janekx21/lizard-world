extends AudioStreamPlayer2D

@export var sounds : Array[AudioStream]

func _ready():
	assert(len(sounds) > 0, "must have one sound at least")
	finished.connect(apply)
	apply()

func apply():
	stream = sounds.pick_random()
