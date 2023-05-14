extends HBoxContainer
class_name ScoreBox

func render_score(players: Array[Player]):
	for child in get_children():
		child.queue_free()
	
	for player in players:
		var label = Label.new()
		label.self_modulate = player.color
		label.text = str(player.score)
		add_child(label)
