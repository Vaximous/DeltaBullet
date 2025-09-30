extends RefCounted
class_name Messaging

#const header := "CHATROOM" TODO implement

enum ChannelVisibility{PUBLIC, FRIENDSPLUS, FRIENDS, PRIVATE}
var channels : Array[ChatChannel]


var last_channel_list : Dictionary
signal channel_closed(channel : ChatChannel)
signal channel_list_update(list : Dictionary)
signal total_user_count_update(amount : int)
signal channel_state_update() #Joined or left a channel


#TODO: If a message's body is ["chatroom"]
func handle_message(msg : Dictionary) -> void:
	print(msg)
	if msg.has("heartbeat"):
		print("Heartbeat: %s" % msg["heartbeat"])
	if msg.has_all(["sender", "channel", "messagedata"]):
		_on_chatroom_chat_message(msg)
		return
	if msg.has("method"):
		var method = msg["method"]
		if has_method(method):
			callv(method, msg.get("args", []))
	return


func request_set_irc_open(open : bool) -> void:
	SmackneckClient.put_message("MESSAGE", {"msg":"chatroom", "request":"set_irc_open", "open":open})


##The user calls this when it wants to update the channel list
func request_channel_list() -> void:
	SmackneckClient.put_message("MESSAGE", {"msg":"chatroom", "request":"get_channel_list"})


func request_leave_channel(channel_name : String) -> void:
	SmackneckClient.put_message("MESSAGE", {"msg":"chatroom", "request":"leave_channel", "channel_name":channel_name})


##User calls this when they want to join a channel
func request_join_channel(channel_name : String) -> void:
	SmackneckClient.put_message("MESSAGE", {"msg":"chatroom", "request":"join_channel", "channel_name":channel_name})


func request_create_channel(channel_name : String, visibility : ChannelVisibility) -> void:
	SmackneckClient.put_message("MESSAGE", {"msg":"chatroom", "request":"create_channel", "channel_name":channel_name, "visibility":visibility})


func request_usercount() -> void:
	SmackneckClient.put_message("MESSAGE", {"msg":"chatroom","request":"get_total_users"})


func _update_channel_data(channel : String, data : Dictionary) -> void:
	var ch = get_channel(channel)
	if ch.size() == 1:
		for key in data.keys():
			ch[0].set(key, data[key])


func _update_total_usercount(count : int) -> void:
	last_channel_list["total_users"] = count
	total_user_count_update.emit(count)


func _on_join_channel(channel_data : Dictionary) -> void:
	#It handles errors
	add_channel(channel_data)
	return


func _on_leave_channel(channel_name : String) -> void:
	for ch in get_channel(channel_name):
		ch.destroy_chatroom()



func _on_get_available_channels(_channels : Dictionary) -> void:
	if _channels.has_all(["total_users", "rooms"]):
		last_channel_list = _channels
		channel_list_update.emit(last_channel_list)


func _on_chatroom_chat_message(data : Dictionary) -> void:
	var channel = data["channel"]
	var _channels = get_channel(channel)
	for ch in _channels:
		ch.add_message(data)


##The player has either joined the channel or been automatically added to the channel.
func add_channel(channel_data : Dictionary) -> ChatChannel:
	#Client is adding channel to list of channels
	var channel_name = channel_data.get("channel_name", null)
	if not channel_data.has_all(["channel_name", "visibility", "channel_users"]):
		return
	if has_channel(channel_name):
		#Already in channel
		return
	var new_channel = ChatChannel.new(channel_name, channel_data["visibility"])
	new_channel.closed.connect(func():
		channels.erase(new_channel)
		channel_closed.emit(new_channel)
		channel_state_update.emit()
		)
	new_channel.channel_users = channel_data["channel_users"]
	channels.append(new_channel)
	channel_state_update.emit()
	return new_channel


func get_channels_im_not_in() -> Array[Dictionary]:
	var full_list = last_channel_list.get("rooms", [])
	var out : Array[Dictionary] = []
	#Check the full list.
	for listed in full_list:
		var inflag = false
		#If the listed isn't in the channels I'm in, add it to output array.
		for ch in channels:
			if ch.channel_name == listed.get("channel_name", ""):
				inflag = true
				print("You're in %s, excluding.." % listed)
				break
		if inflag == false:
			out.append(listed)
			print("You're not in %s, including..." % listed)
	print("You're not in these channels: %s" % str(out))
	return out


func has_channel(channel_name : String) -> bool:
	for i in channels:
		if i.channel_name == channel_name:
			return true
	return false


func get_channel(channel_name : String) -> Array[ChatChannel]:
	if channel_name == "ALL_CHANNELS":
		return channels
	for i in channels:
		if i.channel_name == channel_name:
			return [i]
	return []


class ChatChannel extends RefCounted:
	const CHANNEL_MAX_MESSAGES : int = 300

	var channel_owner : Dictionary = {}
	var channel_name : String = ""
	var visibility : ChannelVisibility = ChannelVisibility.PUBLIC
	var channel_users : Dictionary = {}
	var messages : Array[Dictionary] = []
	signal closed
	signal messages_updated
	signal message_received(message : Dictionary)
	signal user_added(user)
	signal user_updated(user)
	signal user_removed(user)

	func _init(_cn : String, vis : ChannelVisibility) -> void:
		channel_name = _cn
		visibility = vis

	func add_message(message_data : Dictionary) -> void:
		messages.append(message_data)
		message_received.emit(message_data)
		messages_updated.emit()

	func limit_messages() -> void:
		while messages.size() > CHANNEL_MAX_MESSAGES:
			messages.pop_front()

	func add_user(data : Dictionary) -> void:
		var user_id = data.get("user_id", null)
		if data == null:
			return
		channel_users[user_id] = data
		if !channel_users.has(user_id):
			user_added.emit(data)
		else:
			user_updated.emit(data)

	func get_user_by_id(user_id : int) -> Dictionary:
		if channel_users.has(user_id):
			return channel_users[user_id]
		return {}

	func get_user_by_name(username : String) -> Dictionary:
		for i in channel_users.values():
			if i.get("username") == username:
				return i
		return {}

	func destroy_chatroom() -> void:
		closed.emit()

	func remove_user(user_id : int) -> void:
		channel_users.erase(user_id)
		user_removed.emit(user_id)

	func get_data(less : bool = false) -> Dictionary:
		var users = []
		for i in channel_users:
			if less:
				#if less, don't add user data.
				break
			else:
				users.append(i.get_shared_data())
		var dict = {"channel_name":channel_name, "visibility":visibility, "channel_users":users, "user_count":channel_users.size()}
		if less:
			dict["less"] = true
		return dict
