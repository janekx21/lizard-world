extends CharacterBody2D

const SPEED = 900
const ACCELL = 15000
const JUMP_HEIGHT = 1500

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	var jumping = Input.is_action_pressed("jump")
	if is_on_floor():
		if jumping:
			velocity.y = -JUMP_HEIGHT
	else:
		var gravity_mod = 1.1 if velocity.y > 0 else 1
		if not jumping: gravity_mod += 1 # for short hopping
		velocity.y += gravity * delta * gravity_mod
	
	var dir = Input.get_axis("move_left","move_right")
	var accell_mod = 1 if is_on_floor() else .5 # air accelerate
	velocity.x = move_toward(velocity.x, dir * SPEED, ACCELL * delta * accell_mod)
	
	if Input.is_action_just_pressed("attack"):
		attac.rpc($Shape/HurtboxPoint.global_position)
	
	if dir:
		$Sprite2D.flip_h = dir < 0
		$Shape.scale = Vector2.RIGHT * (1 if dir > 0 else -1) + Vector2.UP
	
	move_and_slide()

@rpc("call_local")
func attac(at: Vector2):
	var hurtbox = preload("res://scenes/hurtbox.tscn").instantiate()
	hurtbox.global_position = at
	find_parent("Network").add_child(hurtbox, true)
