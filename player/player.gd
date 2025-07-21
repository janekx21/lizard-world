extends CharacterBody2D
class_name Player

const SPEED = 1000
const ACCELL = 5000#17000
const JUMP_HEIGHT = 1800

enum Hat {
	ACAGAMICS,
	HORNS,
	WITCHS_HAT,
	TOP_HAT
}

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var color: Color = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.VIOLET, Color.CYAN, Color.ORANGE, Color.OLIVE, Color.DARK_RED, Color.NAVY_BLUE].pick_random()
@export var team: Hat = Hat.values().pick_random() #  Hat.ACAGAMICS#
@export var fireball_count = 3
@export var hp: int
@export var score: int

@onready var sprite = $Shape/SpriteMod/Lizard

@export var hat_sprites: Dictionary[Hat,Sprite2D]

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
	sprite.self_modulate = color.lightened(.5)
	#sprite.get_node("Hat").frame = hat_to_texture(team)
	set_hat(team)
	sprite.get_node("Wings").self_modulate = color.lightened(.4)
	sprite.get_node("Hand/Sword").self_modulate = color.lightened(.8)
	
	var eye = sprite.get_node("Eye") as AnimatedSprite2D
	eye.play("default" if $AttackCooldown.is_stopped() else "cross")
	
	for child in $Health.get_children():
		if child is Sprite2D && child.name.is_valid_int():
			child.visible = child.name.to_int() <= hp
	
	var vel = abs(get_real_velocity()/SPEED).clamp(-Vector2.ONE, Vector2.ONE)
	vel = (Vector2.ONE + vel * 0.2).normalized() * 1.41
	$Shape/SpriteMod.scale = $Shape/SpriteMod.scale.move_toward(vel, delta)
	
	$Shape/WalkParticles.emitting = is_on_floor() and abs(get_real_velocity().x) > 10
	

	
	if fireball_count:
		$Shape/Breath.emitting = fireball_count > 0
	else:
		$Shape/Breath.emitting = false

func spawn():
	hp = 3
	fireball_count = 3
	global_position = get_tree().root.get_node("Game").get_random_spawn()


func _physics_process(delta):
	if not last_on_ground and is_on_floor():
		land_effect.rpc()
	last_on_ground = is_on_floor()
	
	if not is_multiplayer_authority(): return
	var jumping = Input.is_action_pressed("jump")
	if is_on_floor():
		if jumping:
			$Jump.play()
			velocity.y = -JUMP_HEIGHT
			$Shape/SpriteMod.scale = Vector2(0.8, 1.2)
	else:
		var gravity_mod = 1.1 if velocity.y > 0 else 1.0
		if not jumping: gravity_mod += 1 # for short hopping
		velocity.y += gravity * delta * gravity_mod
	
	var dir = Input.get_axis("move_left","move_right")
	var accell_mod = 1.0 if is_on_floor() else 0.6 # air accelerate
	var speed_mod = 1.0 if $AttackCooldown.is_stopped() else 0.5
	velocity.x = move_toward(velocity.x, dir * SPEED * speed_mod, ACCELL * delta * accell_mod)
	
	if Input.is_action_just_pressed("attack"):
		if $AttackCooldown.is_stopped():
			start_attack()
			$AttackCooldown.start(0.3)
			$AnimationPlayer.play("attack")
			attack_effect.rpc()
			
	
	if Input.is_action_just_pressed("shoot") && fireball_count > 0:
		if $AttackCooldown.is_stopped():
			for muzzle in $Shape/Muzzles.get_children():
				var t = (muzzle as Node2D).global_transform
				shoot.rpc_id(1, t.origin, t.x, multiplayer.get_unique_id())
			shoot_effect.rpc()
			$AttackCooldown.start(0.5)
			fireball_count -= 1
			if fireball_count <= 0:
				await get_tree().create_timer(5).timeout
				fireball_count = 3
	
	if dir:
		$Shape.scale = Vector2.RIGHT * (1 if dir > 0 else -1) + Vector2.DOWN
		if (not $AnimationPlayer.is_playing() or $AnimationPlayer.current_animation == "idle") and is_on_floor() and get_real_velocity().abs().x > 10:
			$AnimationPlayer.play("hover")
			#$Footsteps.play()
	
	if not $AnimationPlayer.is_playing():
		$AnimationPlayer.play("idle")
	
	move_and_slide()

func start_attack():
	await get_tree().create_timer(0.1).timeout
	attack.rpc_id(1, $Shape/HurtboxPoint.global_position, $Shape.scale, multiplayer.get_unique_id())

@rpc("any_peer", "call_local")
func attack_effect():
	$SwordAttack.play()

@rpc("any_peer","call_local")
func land_effect():
	$Shape/LandParticles.restart()
	$LandSound.play()

@rpc("call_local")
func attack(at: Vector2, scale: Vector2, from_peer_id: int):
	$Hit.play()
	var hurtbox = preload("res://player/hurtbox.tscn").instantiate()
	hurtbox.global_position = at
	hurtbox.scale = scale #Vector2(sign(scale.x), 1)
	hurtbox.origin_peer_id = from_peer_id
	hurtbox.damage = 1
	find_parent("Network").add_child(hurtbox, true)

@rpc("call_local")
func shoot(at: Vector2, direction: Vector2, from_peer_id: int):
	var bullet = preload("res://player/bullet.tscn").instantiate()
	find_parent("Network").add_child(bullet, true)
	bullet.get_node("Sprite2D").set_flip_v($Shape.get_scale().x < 0)
	bullet.velocity = direction * 1500
	bullet.global_position = at
	bullet.set_origin(from_peer_id)

@rpc("call_local", "any_peer")
func shoot_effect():
	$Fireball.play()
	
func hitbox_entered(area: Area2D):
	if not is_multiplayer_authority(): return
	if not $InvisibilityTimer.is_stopped(): return
	if not area is Hurtbox: return
	var hurtbox = area as Hurtbox
	var other = hurtbox.get_player()
	if other && other.team == team: return
	var direction = (global_position - area.global_position).normalized()
	direction = lerp(direction, Vector2.UP, 0.5)
	get_damage(hurtbox.damage, other, direction)
	if hurtbox.remove_on_damage: hurtbox.remove.rpc_id(1)

func get_damage(damage: int, player: Player, direction: Vector2):
	damage_effect.rpc()
	hp -= damage
	velocity += direction * 3000
	if hp <= 0:
		if player:
			player.award_kill.rpc_id(player.get_id(), 5)
		else:
			score -= 1
		spawn()
		for child in get_parent().get_children():
			if child is Player:
				child.swap_team.rpc()

@rpc("any_peer")
func award_kill(p: int):
	score += p
	$Kill.play()

@rpc("any_peer", "call_local")
func damage_effect():
	$BloodSplash.play()
	var splash = preload("res://particles/splash.tscn").instantiate()
	splash.global_position = global_position
	get_tree().root.add_child(splash)

@rpc("any_peer", "call_local")
func swap_team():
	if is_multiplayer_authority():
		if randi_range(1, 3) != 1: return # 33% chance for a swap
		var last = team
		team = Hat.values().pick_random()
		if team == last: return # 25% chance for the same team
		$SwapTeam.play()
		

func hat_to_texture(hat: Hat) -> int:
	if hat == Hat.ACAGAMICS:
		return 0
	if hat == Hat.HORNS:
		return 1
	if hat == Hat.TOP_HAT:
		return 2
	if hat == Hat.WITCHS_HAT:
		return 3
	printerr("add a condition here")
	return -1

func set_hat(hat: Hat):
	for key in hat_sprites:
		hat_sprites[key].visible = hat == key
