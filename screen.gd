extends Node

const PORT = 4433

func _ready():
	# Start paused.
	#get_tree().paused = true

	# Automatically start the server in headless mode.
	if DisplayServer.get_name() == "headless":
		print("Automatically starting dedicated server.")
		_on_host_pressed.call_deferred()
	await get_tree().create_timer(.1).timeout
	$MasterPopup.popup_centered()


func _on_host_pressed():
	print("on host")
	# Start as server.
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		return
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.connect(add_player)
	$MasterPopup.hide()
	get_tree().paused = false
	add_player(multiplayer.get_unique_id())

func _on_connect_pressed():
	print("on connect")
	# Start as client.
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
	await peer.peer_connected
	$MasterPopup.hide()
	get_tree().paused = false

func add_player(peer_id):
	var player = preload("res://scenes/player.tscn").instantiate()
	player.name = str(peer_id)
	player.position = $Spawns.get_children().pick_random().position
	$Network.add_child(player)
