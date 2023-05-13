extends CharacterBody2D
class_name Player

const SPEED = 1200
const ACCELL = 17000
const JUMP_HEIGHT = 1800

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var team: Color = [Color.RED, Color.BLUE].pick_random()

var max_hp = 3
@export var hp: int

func get_id():
	return str(name).to_int()

func _enter_tree():
	print("spawned with id ", get_id(), " my id ", multiplayer.get_unique_id())
	set_multiplayer_authority(get_id())

func _ready():
	if is_multiplayer_authority():
		spawn()

func _process(_delta):
	$Shape/Sprite2D.modulate = team.lightened(.5)
	for child in $Health.get_children():
		if child is Sprite2D && child.name.is_valid_int():
			child.visible = child.name.to_int() <= hp

func spawn():
	hp = 3
	global_position = get_tree().root.get_node("Game").get_random_spawn()

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
	var speed_mod = 1.0 if $AttackCooldown.is_stopped() else 0.5
	velocity.x = move_toward(velocity.x, dir * SPEED * speed_mod, ACCELL * delta * accell_mod)
	
	if Input.is_action_just_pressed("attack"):
		if $AttackCooldown.is_stopped():
			attack.rpc_id(1, $Shape/HurtboxPoint.global_position, multiplayer.get_unique_id())
			$AttackCooldown.start(0.2)
	
	if dir:
		$Shape.scale = Vector2.RIGHT * (1 if dir > 0 else -1) + Vector2.DOWN
		if not $AnimationPlayer.is_playing() and is_on_floor():
			$AnimationPlayer.play("hover")
	
	move_and_slide()

@rpc("call_local")
func attack(at: Vector2, from_peer_id: int):
	var hurtbox = preload("res://player/hurtbox.tscn").instantiate()
	hurtbox.global_position = at
	hurtbox.origin_peer_id = from_peer_id
	hurtbox.damage = 1
	find_parent("Network").add_child(hurtbox, true)

func hitbox_entered(area: Area2D):
	if not is_multiplayer_authority(): return
	if not $InvisibilityTimer.is_stopped(): return
	if not area is Hurtbox: return
	var other = area.get_player()
	if other && other.team == team: return
	get_damage(area.damage)

func get_damage(damage: int):
	damage_effect.rpc()
	hp -= damage
	if hp <= 0:
		spawn()
		for child in get_parent().get_children():
			if child is Player:
				child.swap_team.rpc()

@rpc("any_peer", "call_local")
func damage_effect():
	var splash = preload("res://particles/splash.tscn").instantiate()
	splash.global_position = global_position
	get_tree().root.add_child(splash)

@rpc("any_peer", "call_local")
func swap_team():
	if is_multiplayer_authority():
		team = [Color.RED, Color.BLUE].pick_random()

