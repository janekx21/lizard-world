extends Node2D

@export var hp = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	visible = hp > 0
	if not visible: return
	for child in find_parent("Network").get_children():
		if child is Player:
			var dir = child.global_position - global_position
			if dir.length() > 1: dir = dir.normalized()
			global_position += dir * 100 * delta

func _on_area_2d_area_entered(area: Area2D):
	if not is_multiplayer_authority(): return
	# if not $InvisibilityTimer.is_stopped(): return
	if not area is Hurtbox: return
	var hurtbox = area as Hurtbox
	var other = hurtbox.get_player()
	# if other && other.team == team: return
	get_damage(hurtbox.damage, other)
	if hurtbox.remove_on_damage: hurtbox.remove.rpc_id(1)

func get_damage(damage, player: Player):
	if hp <= 0 or !player: return
	hp -= damage
	damage_effect.rpc()
	if hp <= 0:
		hp = 0
		player.award_kill.rpc_id(player.get_id(), 50)
		$AnimatedSprite2D.play("death")
		await get_tree().process_frame
		await $AnimatedSprite2D.animation_finished
		global_position = Vector2(0, -10000)
		hp = -1

@rpc("any_peer", "call_local")
func damage_effect():
	$BloodSplash.play()
	var splash = preload("res://particles/splash.tscn").instantiate()
	splash.global_position = global_position
	get_tree().root.add_child(splash)

func _on_timer_timeout():
	$AnimatedSprite2D.play("chase")
	hp = 50
	global_position = Vector2(0, -1000)
