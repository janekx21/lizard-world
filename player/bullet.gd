extends Area2D


@onready var velocity: Vector2

func _physics_process(delta):
	#position += transform.x * speed * delta + transform.y * delta * gravity
	#velocity += g * delta
	#look_at(velocity * delta)
	#transform.origin += velocity * delta
	#position = transform.origin
	velocity.y += gravity*0.4 * delta
	position += velocity * delta
	rotation = velocity.angle()
	
func _on_Bullet_body_entered(body):
	if body.is_in_group("Player"):
		print("treffer!")
		body.queue_free()
		queue_free()
