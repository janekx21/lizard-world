extends CharacterBody2D
class_name Player

const SPEED = 1200
const ACCELL = 17000
const JUMP_HEIGHT = 1800

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var team: Color = [Color.RED, Color.BLUE].pick_random()

var max_hp = 3
@export var hp: int
@onready var sprite = $Shape/SpriteMod/Sprite2D

var last_on_ground = false

func get_id():
	return str(name).to_int()

func _enter_tree():
	print("spawned with id ", get_id(), " my id ", multiplayer.get_unique_id())
	set_multiplayer_authority(get_id())

func _ready():
	if is_multiplayer_authority():
		spawn()

func _process(delta):
	sprite.modulate = team.lightened(.5)
	for child in $Health.get_children():
		if child is Sprite2D && child.name.is_valid_int():
			child.visible = child.name.to_int() <= hp
	
	var vel = abs(velocity/SPEED).clamp(-Vector2.ONE, Vector2.ONE)
	vel = (Vector2.ONE + vel * 0.2).normalized() * 1.41
	$Shape/SpriteMod.scale = $Shape/SpriteMod.scale.move_toward(vel, delta)
	
	$Shape/WalkParticles.emitting = is_on_floor() and abs(velocity.x) > 10

func spawn():
	hp = 3
	global_position = get_tree().root.get_node("Game").get_random_spawn()

func _physics_process(delta):
	if not last_on_ground and is_on_floor():
		$Shape/LandParticles.restart()
	last_on_ground = is_on_floor()
	
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
			$AnimationPlayer.play("attack")
			$SwordAttack.play()
	
	if Input.is_action_just_pressed("shoot"):
		if $AttackCooldown.is_stopped():
			shoot.rpc_id(1, $Shape/HurtboxPoint.global_position, multiplayer.get_unique_id())
			$AttackCooldown.start(0.5)
	
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
	
@rpc("call_local")
func shoot(at: Vector2, from_peer_id: int):
	var bullet_scene = preload("res://player/bullet.tscn")
	var b1 = bullet_scene.instantiate()
	var b2 = bullet_scene.instantiate()
	var b3 = bullet_scene.instantiate()
	find_parent("Network").add_child(b1)
	find_parent("Network").add_child(b2)
	find_parent("Network").add_child(b3)
	#b1.global_transform = $Shape/Muzzle1.global_transform
	#b2.global_transform = $Shape/Muzzle2.global_transform
	#if $Shape.scale.get_scale() == Vector2:
	print($Shape.get_scale())
	if $Shape.get_scale() == Vector2(-1,1):
		print("ich bims")
		b1.get_node("Sprite2D").set_flip_v(true)
		b2.get_node("Sprite2D").set_flip_v(true)
		b3.get_node("Sprite2D").set_flip_v(true)
	#	$bullet/Sprite2D.set_scale(1,-1)
		
	b1.velocity = Vector2(999, 0).rotated($Shape/Muzzle1.rotation)*$Shape.scale
	b1.global_position = $Shape/Muzzle1.global_position

	b2.velocity = Vector2(999, 0).rotated($Shape/Muzzle2.rotation)*$Shape.scale
	b2.global_position = $Shape/Muzzle2.global_position
	
	b3.velocity = Vector2(999, 0).rotated($Shape/Muzzle3.rotation)*$Shape.scale
	b3.global_position = $Shape/Muzzle3.global_position
	
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
	$BloodSplash.play()
	var splash = preload("res://particles/splash.tscn").instantiate()
	splash.global_position = global_position
	get_tree().root.add_child(splash)

@rpc("any_peer", "call_local")
func swap_team():
	if is_multiplayer_authority():
		team = [Color.RED, Color.BLUE].pick_random()

