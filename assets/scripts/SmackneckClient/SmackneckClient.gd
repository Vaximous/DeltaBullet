extends Node


#region ---------------------- masterserver connectivity
var connect_on_startup : bool = false
signal masterserver_connected
signal masterserver_connection_lost
signal masterserver_authentication_success
signal masterserver_data_received(data : Dictionary)
signal response_recieved(data : Dictionary)

var masterserver_connection : StreamPeerTCP = StreamPeerTCP.new()
var masterserver_address : String = "5.161.123.32"
var pending_response_messages : Array[Dictionary]
const masterserver_port : int = 7777
#localhost	: 127.0.0.1
#hetzner ip	: 5.161.123.32
#toaflo  ip	: 174.87.17.39
const MASTERSERVER_POLL_INTERVAL : float = 0.1

var Messaging = preload("client_Messaging.gd").new()
var Authentication = preload("client_Authentication.gd").new()


func _ready() -> void:
	#export auto change
	if not OS.has_feature("editor"):
		masterserver_address = "5.161.123.32"
	if connect_on_startup:
		connect_to_masterserver()
	Authentication.auth_success.connect(func():
		masterserver_authentication_success.emit()
		)
	masterserver_connection_lost.connect(_on_masterserver_connection_lost)
	masterserver_connection_lost.connect(Authentication._on_masterserver_connection_lost)


func connect_to_masterserver() -> void:
	print("Connecting to masterserver.")
	Console.add_rich_console_message("[color=blue]Connecting to Smacknet™..[/color]")
	var err = masterserver_connection.connect_to_host(masterserver_address, masterserver_port)
	print("Connection code: %s" % err)
	if err == OK:
		masterserver_connected.emit()
		Console.add_rich_console_message("[color=green]Connection to Smacknet™ Successful![/color]")
	while masterserver_connection.get_status() != 0:
		poll_masterserver()
		await get_tree().create_timer(MASTERSERVER_POLL_INTERVAL).timeout
	print("Lost connection to masterserver.")
	Console.add_rich_console_message("[color=red]Lost connection to Smacknet™[/color]")
	masterserver_connection_lost.emit()


func _on_masterserver_connection_lost() -> void:
	return


func is_connected_to_masterserver() -> bool:
	return masterserver_connection.get_status() == 2


func poll_masterserver() -> void:
	masterserver_connection.poll()
	if is_connected_to_masterserver():
		while masterserver_connection.get_available_bytes() > 0:
			var data = masterserver_connection.get_var(false)
			if data is Dictionary:
				parse_message(data)


func put_message(header : String, body : Dictionary, full_objects : bool = false) -> void:
	masterserver_connection.put_var({
		"header":header,
		"body":body
	}, full_objects)


func parse_message(data : Dictionary) -> void:
	print(data)
	masterserver_data_received.emit(data)
	if data["header"] == Authentication.header:
		Authentication.handle_message(data)
		return
	if data["header"] == "MESSAGE":
		if data.get("body",{}).has("chatroom"):
			Messaging.handle_message(data.get("body"))

		if data.has("response"):
			#ignore malformed response
			var response : String = data["response"].get("response", null)
			var handle : int = data["response"].get("handle", null)
			var parameters = data["response"].get("parameters", null)
			if response == null or handle == null or parameters == null:
				return
			pending_response_messages.append({"response":response, "handle":handle, "parameters":parameters, "timestamp":Time.get_ticks_msec()})
			return


func wait_for_response(response : String, handle : int, timeout : float = 30.0) -> Variant:
	var full_time : float = timeout
	const WAIT_INVERVAL : float = 0.1
	while timeout > 0.0:
		timeout -= WAIT_INVERVAL
		await get_tree().create_timer(min(WAIT_INVERVAL, timeout)).timeout
		for i in pending_response_messages:
			if i.get("response") == response and i.get("handle") == handle:
				pending_response_messages.erase(i)
				response_recieved.emit(i)
				return i["parameters"]
			if Time.get_ticks_msec() - i.get("timestamp", 0) > 60000:
				pending_response_messages.erase(i)
	print("Response for '%s' (handle %s) timed out after %s seconds." % [response, handle, full_time])
	return {}
#endregion
