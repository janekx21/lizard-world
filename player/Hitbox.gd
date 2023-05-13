extends Area2D
class_name Hitbox

@export var player: Player

func _ready():	
	area_entered.connect(_area_entered)

func _area_entered(area: Area2D):
	if not is_multiplayer_authority(): return
	if area is Hurtbox:
		var other = area.get_player()
		if other.team != player.team:
			player.get_damage(area.damage)
