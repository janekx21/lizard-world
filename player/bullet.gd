extends CharacterBody2D

# @onready var velocity: Vector2

const gravity = 2000

func set_origin(id: int):
	$Hurtbox.origin_peer_id = id

func _physics_process(delta):
	#position += transform.x * speed * delta + transform.y * delta * gravity
	#velocity += g * delta
	#look_at(velocity * delta)
	#transform.origin += velocity * delta
	#position = transform.origin
	velocity.y += gravity * delta
	# position += velocity * delta
	rotation = velocity.angle()
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		queue_free()
	
func _on_Bullet_body_entered(body):
	if body.is_in_group("Player"):
		print("treffer!")
		body.queue_free()
		queue_free()


func _on_hurtbox_on_remove():
	queue_free()
