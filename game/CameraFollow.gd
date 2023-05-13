extends Camera2D

func _process(_delta):
	var own_player = $"/root/Game/Network".get_node_or_null(str(multiplayer.get_unique_id())) as Player
	if own_player:
		global_position = own_player.global_position
