extends Camera2D

func _process(delta):
	var own_player = $"/root/Game/Network".get_node(str(multiplayer.get_unique_id())) as Player
	if own_player:
		global_position = own_player.global_position
