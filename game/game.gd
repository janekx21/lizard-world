extends Node

const PORT = 4433

func _ready():
	# Automatically start the server in headless mode.
	if DisplayServer.get_name() == "headless":
		print("Automatically starting dedicated server.")
		start_server()
		#_on_host_pressed.call_deferred()
	else:
		# Start paused.
		get_tree().paused = true
		await get_tree().process_frame
		$MasterPopup.popup_centered()

func _on_host_pressed():
	$UI_Click.play()
	#await($UI_Click, "finished")
	start_server()
	$MasterPopup.hide()
	get_tree().paused = false
	add_player(multiplayer.get_unique_id())

func start_server():
	$LavaLoop.play()
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		return
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.connect(add_player)
	peer.peer_disconnected.connect(remove_player)

func _on_connect_pressed():
	$UI_Click.play()
	start_client()
	await multiplayer.multiplayer_peer.peer_connected
	$MasterPopup.hide()
	get_tree().paused = false
	await multiplayer.multiplayer_peer.peer_disconnected
	get_tree().reload_current_scene()

func start_client():
	var txt: String = $MasterPopup/CenterContainer/VBoxContainer/Host.text
	if txt == "":
		OS.alert("Need a remote to connect to.")
		return
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(txt, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client.")
		return
	multiplayer.multiplayer_peer = peer

func add_player(peer_id):
	$PlayerJoin.play()
	var player = preload("res://player/player.tscn").instantiate()
	player.name = str(peer_id)
	$Network.add_child(player)

func remove_player(peer_id):
	$PlayerLeave.play()
	$Network.remove_child($Network.get_node(str(peer_id)))

func get_random_spawn():
	return $Spawns.get_children().pick_random().global_position

func _on_local_pressed():
	$MasterPopup/CenterContainer/VBoxContainer/Host.text = "localhost"

func _on_global_pressed():
	$MasterPopup/CenterContainer/VBoxContainer/Host.text = "server.ch-l.de"

func _process(_delta):
	var players: Array[Player] = []
	for c in $Network.get_children():
		if c is Player:
			players.push_back(c)
	$CanvasLayer/UI/ScoreBox.render_score(players)

func _on_credits_pressed():
	$"Credits Popup".popup_centered()

func _on_close_popup_pressed():
	$"Credits Popup".hide()

func _on_fullscreen_check_toggled(button_pressed):
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if button_pressed else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_audio_volume_slider_drag_ended(value_changed: bool):
	if not value_changed: return
	var slider = $MasterPopup/CenterContainer/VBoxContainer/HBoxContainer2/AudioVolumeSlider
	var db = remap(sqrt(slider.value), 0, 1, -80, 0)
	AudioServer.set_bus_volume_db(0, db)
