extends Control

const PORT = 7991
const MAX_CLIENTS = 255
const MSG_HISTORY_LENGTH = 50

var connected = false
var user_id = ""
var users = {}
var messages = []

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	# Initialize 50 blank messages to store message history for new users
	for i in range(MSG_HISTORY_LENGTH):
		messages.append("")


remotesync func add_msg(user_name, msg):
	var text_to_add = "\n" + user_name + ": " + msg
	$HBoxContainer/VBoxContainer2/Panel/ChatMsgs.text += text_to_add
	
	if get_tree().is_network_server():
		if user_name != "SERVER":
			# Push all messages back one while discarding the oldest message
			for i in range(MSG_HISTORY_LENGTH - 1):
				messages[i] = messages[i + 1]
				
			# Remove newline at the beginning of messages before storing it
			text_to_add = text_to_add.substr(1, text_to_add.length() - 1)
			messages[MSG_HISTORY_LENGTH - 1] = text_to_add


remote func add_user(id, user_name):
	# Whenever a new user joins, update the list of users and send it to all clients
	if get_tree().is_network_server():
		users[id] = user_name
		rewrite_user_list()
		
		# Send the recent messages list to the newly connected client
		for i in range(MSG_HISTORY_LENGTH):
			var msg_text = messages[i]
			if (msg_text != ""):
				var msg_name_index = msg_text.find(":", 0)
				var msg_name = msg_text.substr(0, msg_name_index)
				msg_text = msg_text.substr(msg_name_index + 2, msg_text.length() - (msg_name_index + 2))
				
				rpc_id(id, "add_msg", msg_name, msg_text)


func rewrite_user_list():
	# Iterate through the list of users to generate the user list and send it to all clients
	$HBoxContainer/VBoxContainer/Panel/UserList.text = ""
	for user in users:
		$HBoxContainer/VBoxContainer/Panel/UserList.text += (str(users[user]) + "\n")
	
	rpc("update_user_list", $HBoxContainer/VBoxContainer/Panel/UserList.text)


remote func update_user_list(user_text):
	$HBoxContainer/VBoxContainer/Panel/UserList.text = user_text


func _player_connected(id):
	if id == 1:
		add_msg("SERVER", "Server hosting successful. Ensure port " + str(PORT) + " is open.")


func _player_disconnected(id):
	if get_tree().is_network_server():
		users.erase(id)
		rewrite_user_list()


func _connected_ok():
	button_management_server_connect()
	rpc("add_user", get_tree().get_network_unique_id(), user_id)
	
	if not(get_tree().is_network_server()):
		add_msg("SERVER", "Connection Successful")


func _connected_fail():
	add_msg("SERVER", "Invalid Connection")


func _server_disconnected():
	add_msg("SERVER", "Server Shutting Down")
	get_tree().set_network_peer(null)
	button_management_server_disconnect()


func _on_StartServer_pressed():
	user_id = $HBoxContainer/VBoxContainer/NameEntry.text
	if not(user_id == ""):
		var peer = NetworkedMultiplayerENet.new()
		var err = peer.create_server(PORT, MAX_CLIENTS)
		get_tree().set_network_peer(peer)
		users[1] = user_id
		button_management_server_connect()
		add_msg("SERVER", "Server hosting successful. Ensure port " + str(PORT) + " is open.")
		
		# Reset recent messages list
		for i in range(MSG_HISTORY_LENGTH):
			messages[i] = ""


func _on_ConnectButton_pressed():
	if not(connected):
		user_id = $HBoxContainer/VBoxContainer/NameEntry.text
		if not((user_id == "") or (user_id == "SERVER")):
			var ip_address = $HBoxContainer/VBoxContainer/IPEntry.text
			if ip_address.is_valid_ip_address():
				var peer = NetworkedMultiplayerENet.new()
				peer.create_client(ip_address, PORT)
				get_tree().set_network_peer(peer)
			else:
				add_msg("SERVER", "Invalid IP Address")
	else:
		get_tree().set_network_peer(null)
		button_management_server_disconnect()


func button_management_server_connect():
	connected = true
	$HBoxContainer/VBoxContainer/StartServer.disabled = true
	$HBoxContainer/VBoxContainer/ConnectButton.text = "Disconnect"
	$HBoxContainer/VBoxContainer2/Panel/ChatMsgs.text = ""


func button_management_server_disconnect():
	connected = false
	$HBoxContainer/VBoxContainer/StartServer.disabled = false
	$HBoxContainer/VBoxContainer/ConnectButton.text = "Connect"
	$HBoxContainer/VBoxContainer/Panel/UserList.text = ""


func _on_MsgEdit_text_changed():
	if connected:
		var msg_text = $HBoxContainer/VBoxContainer2/HBoxContainer/MsgEdit.text
		
		# Send after pressing enter
		if msg_text.ends_with("\n"):
			# Prevent spamming blank lines
			$HBoxContainer/VBoxContainer2/HBoxContainer/MsgEdit.text = msg_text.substr(0, msg_text.length() - 1)
			msg_text = $HBoxContainer/VBoxContainer2/HBoxContainer/MsgEdit.text
			
			if (msg_text != ""):
				rpc("add_msg", user_id, msg_text)
				$HBoxContainer/VBoxContainer2/HBoxContainer/MsgEdit.text = ""


func _on_SendButton_pressed():
	var msg_text = $HBoxContainer/VBoxContainer2/HBoxContainer/MsgEdit.text
	if (msg_text != ""):
		rpc("add_msg", user_id, msg_text)
		$HBoxContainer/VBoxContainer2/HBoxContainer/MsgEdit.text = ""
