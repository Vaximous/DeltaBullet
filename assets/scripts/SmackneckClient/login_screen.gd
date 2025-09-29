extends PanelContainer


func _ready() -> void:
	SmackneckClient.Authentication.auth_register_success.connect(_on_register_success)
	SmackneckClient.Authentication.auth_register_failure.connect(_on_register_failure)
	SmackneckClient.Authentication.auth_failure.connect(_on_register_failure)
	SmackneckClient.Authentication.auth_success.connect(_on_auth_success)
	%RegisterButton.disabled = SmackneckClient.Authentication.is_masterserver_authenticated()
	%LoginButton.disabled = SmackneckClient.Authentication.is_masterserver_authenticated()


func check_fields() -> bool:
	var success : bool = true
	if %UsernameField.text == "":
		success = false
		blink_control(%UsernameField)
	if %PasswordField.text == "":
		success = false
		blink_control(%PasswordField)
		blink_control(%RetypePasswordField)
	if %RetypePasswordField.text != %PasswordField.text:
		success = false
		blink_control(%PasswordField)
		blink_control(%RetypePasswordField)
	return success


func _on_login_button_pressed() -> void:
	%ErrorMessage.text = ""
	%LoginButton.disabled = true
	%RegisterButton.disabled = true
	if check_fields():
		SmackneckClient.Authentication.authenticate_with_masterserver(get_auth_dict())
		gameManager.playSound2D("res://assets/sounds/ui/smacknet/connectedChat.wav")
	else:
		gameManager.playSound2D("res://assets/sounds/ui/select2.wav")
		%LoginButton.disabled = false
		%RegisterButton.disabled = false


func _on_register_button_pressed() -> void:
	%ErrorMessage.text = ""
	%LoginButton.disabled = true
	%RegisterButton.disabled = true
	if check_fields():
		SmackneckClient.Authentication.auth_register_account(%UsernameField.text, %PasswordField.text)
		gameManager.playSound2D("res://assets/sounds/ui/smacknet/connectedChat.wav")
	else:
		gameManager.playSound2D("res://assets/sounds/ui/select2.wav")
		%LoginButton.disabled = false
		%RegisterButton.disabled = false


func get_auth_dict() -> Dictionary:
	return {
		"username":%UsernameField.text,
		"password":%PasswordField.text
	}


func blink_control(control : Control) -> void:
	var time : float = 0.0
	var ticks : int = 0
	while ticks < 4:
		control.modulate = Color.RED if ticks % 2 == 0 else Color.YELLOW
		time += get_process_delta_time()
		if time > 0.2:
			ticks += 1
			time = 0.0
		await get_tree().process_frame
	control.modulate = Color.WHITE


func _on_register_success() -> void:
	%RegisterButton.disabled = true
	%LoginButton.disabled = false
	%RegisterButton.text = "Register OK!"
	gameManager.playSound2D("res://assets/sounds/ui/smacknet/connectedChat.wav")
	return


func _on_auth_success() -> void:
	gameManager.notifyCheck("Logged into Smacknet Sucessfully!",2,5)
	gameManager.playSound2D("res://assets/sounds/ui/smacknet/connectedChat.wav")
	hide()
	return


func _on_register_failure(reason : String) -> void:
	%RegisterButton.disabled = false
	%LoginButton.disabled = false
	%ErrorMessage.text = reason
	return


func _on_cancel_button_pressed() -> void:
	hide()
	return
