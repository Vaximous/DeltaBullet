extends Control

@onready var messageContainer : VBoxContainer = $vBoxContainer/chatContainer/chatMessages
@onready var chatScroll : ScrollContainer = $vBoxContainer/chatContainer
@onready var msgField : LineEdit = %messageField

var unreadMessages : bool = false
const MAX_MESSAGES : int = 300
var chatChannel : Messaging.ChatChannel = null:
	set(value):
		if chatChannel != null:
			chatChannel.message_received.disconnect(msgRecieved)
			chatChannel.closed.disconnect(queue_free)

		if value != null:
			value.message_received.connect(msgRecieved)
			value.closed.connect(queue_free)

		$%messageField.editable = value != null
		chatChannel = value

func startChat()->void:
	msgField.grab_focus()

func stopChat()->void:
	if !msgField.has_focus():
		return
	msgField.release_focus()

func msgRecieved(data:Dictionary)->void:
	var messagedata = data.get("messagedata", {})
	var text = messagedata.get("text", "Error")
	if data.has("SYSMESSAGE"):
		addMessage(text)
	else:
		addMessage("[color=%s]%s[/color]: %s" % [messagedata.get("namecolor", Color.YELLOW.to_html()), data.get("sender", {}).get("username", "username_err"), Util.stripBbcode(text)])

func scrollChat() -> void:
	var vScroll := chatScroll.get_v_scroll_bar()
	var barlength := (vScroll.size.y * vScroll.page) / vScroll.min_value - vScroll.max_value
	if vScroll.value >= vScroll.max_value - barlength - 5:
		chatScroll.set_deferred(&"scroll_vertical", vScroll.max_value - barlength)

func msgHistoryLimit() -> void:
	if messageContainer.get_child_count() > MAX_MESSAGES:
		messageContainer.get_children().front().queue_free()

func addMessage(text : String) -> void:
	if !visible:
		unreadMessages = true
	var richtext :RichTextLabel= $MessageReference.duplicate()
	richtext.visible = true
	richtext.bbcode_enabled = true
	richtext.fit_content = true
	richtext.text = text
	richtext.size_flags_vertical = Control.SIZE_SHRINK_END
	richtext.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	messageContainer.add_child(richtext)
	scrollChat.call_deferred()
	msgHistoryLimit()

func _on_user_added(data : Dictionary) -> void:
	addMessage(str(data))


func _on_user_removed(data : Dictionary) -> void:
	addMessage(str(data))

@rpc("any_peer", "reliable", "call_local", 3)
func message_send_fallback(data : Dictionary) -> void:
	_on_message_received(data)

func _on_message_received(data : Dictionary) -> void:
	#text has the message
	var messagedata = data.get("messagedata", {})
	var text = messagedata.get("text", "Error")
	if data.has("SYSMESSAGE"):
		addMessage(text)
	else:
		addMessage("[color=%s]%s[/color]: %s" % [messagedata.get("namecolor", Color.YELLOW.to_html()), data.get("sender", {}).get("username", "username_err"), Util.stripBbcode(text)])
