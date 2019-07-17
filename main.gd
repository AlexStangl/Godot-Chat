extends Control

const PORT = 7991
const MAX_CLIENTS = 255

var connected = false
var user_id = ""
var users = {}

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

remote func add_user(id, user_name):
	if get_tree().is_network_server():
		users[id] = user_id
		
		$HBoxContainer/VBoxContainer/Panel/UserList.text = ""
		for user in users:
			$HBoxContainer/VBoxContainer/Panel/UserList.text += (user + "\n")
		
		rpc("update_user_list", $HBoxContainer/VBoxContainer/Panel/UserList.text)

remote func update_user_list(user_text):
	$HBoxContainer/VBoxContainer/Panel/UserList.text = user_text

func _player_connected(id):
	pass

func _player_disconnected(id):
	pass

func _connected_ok():
	button_management_server_connect()
	rpc("add_user", get_tree().get_network_unique_id(), user_id)

func _connected_fail():
	pass

func _server_disconnected():
	pass

func _on_StartServer_pressed():
	user_id = $HBoxContainer/VBoxContainer/NameEntry.text
	if not(user_id == ""):
		var peer = NetworkedMultiplayerENet.new()
		var err = peer.create_server(PORT, MAX_CLIENTS)
		get_tree().set_network_peer(peer)
		button_management_server_connect()

func _on_ConnectButton_pressed():
	if not(connected):
		user_id = $HBoxContainer/VBoxContainer/NameEntry.text
		if not(user_id == ""):
			var peer = NetworkedMultiplayerENet.new()
			peer.create_client($HBoxContainer/VBoxContainer/IPEntry.text, PORT)
			get_tree().set_network_peer(peer)
	else:
		pass

func button_management_server_connect():
	connected = true
	$HBoxContainer/VBoxContainer/StartServer.disabled = true
	$HBoxContainer/VBoxContainer/ConnectButton.text = "Disconnect"