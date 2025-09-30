extends PanelContainer
var lastChannel : Messaging.ChatChannel
var cboxScene : PackedScene = load("res://assets/scenes/ui/phoneUI/apps/smacknetChat/smacknetChatbox.tscn")

var messaging : Messaging:
	get:
		return SmackneckClient.Messaging

func _ready() -> void:
	messaging.request_channel_list()
	messaging.channel_list_update.connect(updateList)
	messaging.total_user_count_update.connect(updateUserCount)
	messaging.channel_state_update.connect(channelStateUpdate)
	refreshConnectedChannels()
	var tabBar : TabBar = %chats.get_tab_bar()
	tabBar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ACTIVE_ONLY
	tabBar.tab_close_pressed.connect(func(idx):
		var ch : Messaging.ChatChannel = messaging.channels[clamp(idx, 0, messaging.channels.size())]
		messaging.request_leave_channel(ch.channel_name)
		)
	%connectionSuccess.play()

func updateUserCount(value:int)->void:
	%totalUserCount.text = "Total Users: %s"%value

func channelStateUpdate()->void:
	refreshConnectedChannels()
	setUserList(lastChannel)

func deleteRoom(room:String)->void:
	var _room = %chats.get_node_or_null(room)
	if _room:
		_room.queue_free()

func displayChatroom(index : int) -> void:
	var r = %chats.get_child(index)
	if r != null:
		if r.has_meta(&"keep"):
			return
		setUserList(messaging.channels[index])
		lastChannel = messaging.channels[index]


func setUserList(channel : Messaging.ChatChannel) -> void:
	if !is_instance_valid(channel):
		Util.queue_free_node_children(%userContainer)
		var label = Label.new()
		label.text = "Not in a room..."
		%userContainer.add_child(label)
		return
	var users = channel.channel_users
	%ChatMemberCount.text = "%s in room" % users.size()
	var user_cont = %userContainer
	Util.queue_free_node_children(user_cont)
	var label = Label.new()
	label.text = "Users"
	user_cont.add_child(label)
	for user in users.values():
		var button = Button.new()
		#TODO use username later, use id for now
		var username = user.get("username", "NAME_ERROR")
		button.text = str(username)
		button.tooltip_text = str(user)
		#TODO add pressed signals
		user_cont.add_child(button)

func createChatroomTab(channel : Messaging.ChatChannel) -> MarginContainer:
	if %chats.has_node(channel.channel_name):
		return
	var m = MarginContainer.new()
	var chatbox = cboxScene.instantiate()
	chatbox.channel = channel
	m.name = channel.channel_name
	m.add_child(chatbox)
	%chats.add_child(m)
	#Move the + to the back
	%chats.move_child(%chats.get_node("+"), -1)
	return m

func refreshConnectedChannels()->void:
	Console.add_rich_console_message("[color=purple]Refreshing connected channels..[/color]")
	var roomNames = []
	for room in messaging.channels:
		roomNames.append(room)

	for chat in %chats.get_children():
		if chat.has_meta(&"keep"):
			continue

		if chat.name in roomNames:
			continue
		else:
			deleteRoom(chat.name)

func createRoomToJoin(text:String)->VBoxContainer:
		var newLbl = Label.new()
		newLbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		newLbl.text = text
		var newVbox = VBoxContainer.new()
		newVbox.add_child(newLbl)
		return newVbox

func updateList(list:Dictionary)->void:
	var totalUserCount = list.get("total_users",-1)
	updateUserCount(totalUserCount)
	Console.add_rich_console_message("[color=purple]Updating channel list..[/color]")
	Console.add_rich_console_message("[color=purple]List Data: %s[/color]"%list)
	Util.queueFreeNodeChildren(%chatrooms)
	var public = createRoomToJoin("Public")
	var friends = createRoomToJoin("Friends")
	public.hide()
	friends.hide()
	%chatrooms.add_child(public)
	%chatrooms.add_child(friends)
	for notIn in messaging.get_channels_im_notIn():
		var button := Button.new()
		var button_label := Label.new()
		button.add_child(button_label)
		button.set_meta(&"room_data", notIn)
		button.pressed.connect(func():
			messaging.request_join_channel(notIn.get("channel_name", ""))
			button.disabled = true
			)
		#button_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
		#button_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		button_label.text = "%s users  " % [notIn.get("user_count", -1)]
		button.text = notIn.get("channel_name", "Channel Name Error!")
		match notIn.get("visibility", 0):
			0: #Public
				public.add_child(button)
				public.show()
			1:
				friends.add_child(button)
				friends.show()
			2:#Private
				#You can't get these so don't bother
				pass
