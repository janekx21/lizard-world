extends CharacterBody2D
class_name Player

const SPEED = 900
const ACCELL = 15000
const JUMP_HEIGHT = 1500

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var team: Color = [Color.RED, Color.BLUE].pick_random()

var hp = 3

func get_id():
	return str(name).to_int()

func _enter_tree():
	print("spawned with id ", get_id(), " my id ", multiplayer.get_unique_id())
	set_multiplayer_authority(get_id())

func _process(delta):
	$Sprite2D.modulate = team

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	var jumping = Input.is_action_pressed("jump")
	if is_on_floor():
		if jumping:
			velocity.y = -JUMP_HEIGHT
	else:
		var gravity_mod = 1.1 if velocity.y > 0 else 1.0
		if not jumping: gravity_mod += 1 # for short hopping
		velocity.y += gravity * delta * gravity_mod
	
	var dir = Input.get_axis("move_left","move_right")
	var accell_mod = 1.0 if is_on_floor() else 0.5 # air accelerate
	velocity.x = move_toward(velocity.x, dir * SPEED, ACCELL * delta * accell_mod)
	
	if Input.is_action_just_pressed("attack"):
		attack.rpc_id(1, $Shape/HurtboxPoint.global_position, multiplayer.get_unique_id())
	
	if dir:
		$Sprite2D.flip_h = dir < 0
		$Shape.scale = Vector2.RIGHT * (1 if dir > 0 else -1) + Vector2.UP
	
	move_and_slide()

@rpc("call_local")
func attack(at: Vector2, from_peer_id: int):
	var hurtbox = preload("res://scenes/hurtbox.tscn").instantiate()
	hurtbox.global_position = at
	hurtbox.origin_peer_id = from_peer_id
	hurtbox.damage = 123
	find_parent("Network").add_child(hurtbox, true)

func get_damage(damage: int):
	hp -= 1
	if hp <= 0:
		queue_free()
