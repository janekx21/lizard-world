extends Area2D
class_name Hurtbox

@export var origin_peer_id: int
@export var damage: int

signal on_remove

@rpc
func remove():
	if is_multiplayer_authority():
		queue_free()
		on_remove.emit()

func get_player() -> Player:
	if origin_peer_id == 0: return null
	return $"/root/Game/Network".get_node(str(origin_peer_id)) as Player
