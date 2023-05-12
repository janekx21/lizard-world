extends CharacterBody2D

const SPEED = 400
const ACCELL = 3000
const JUMP_HEIGHT = 1000

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if Input.is_action_pressed("jump"):
			velocity.y = -JUMP_HEIGHT
	
	var dir = Input.get_axis("move_left","move_right")
	velocity.x = move_toward(velocity.x, dir * SPEED, ACCELL * delta)
	
	move_and_slide()
