extends RefCounted


signal auth_failure(reason : String)
signal auth_success()
signal auth_register_failure(reason : String)
signal auth_register_success()

const header := "AUTH"

const PHASE_AUTH_START : String = "auth_start"
const PHASE_AUTH_RESULT : String = "auth_result"
const PHASE_AUTH_REGISTER : String = "auth_register"

var auth_response : Dictionary = {}
var last_login_data : Dictionary = {}


func handle_message(data : Dictionary) -> void:
	#print("Got an auth response.")
	var body = data["body"]
	var phase = body.get("phase", "invalid")
	match phase:
		PHASE_AUTH_RESULT:
			var result = body.get("result", "ERROR")
			auth_response["result"] = result
			match result:
				"OK":
					auth_success.emit()
					if body.has("token"):
						#Store token
						store_loginfile(last_login_data.get("username"), last_login_data.get("password"), body["token"])
					return
			auth_failure.emit("unknown")
		PHASE_AUTH_REGISTER:
			var result = body.get("result")
			match result:
				"REGISTER_OK":
					auth_register_success.emit()
					return
				"taken":
					auth_register_failure.emit("taken")
					return
			auth_register_failure.emit("unknown")
			return
		_:
			printerr("Auth: invalid phase '%s'." % phase)
			return


func authenticate_with_masterserver(authdict : Dictionary) -> void:
	last_login_data = authdict
	SmackneckClient.put_message(header, {"phase":PHASE_AUTH_START, "mode":"smackneck_account", "auth":authdict})


func store_loginfile(username : String, password : String, token : int = -2) -> void:
	var fa = FileAccess.open_encrypted_with_pass("user://user_login", FileAccess.WRITE, "loginfile")
	var d = {"username":username, "password":password, "token":token}
	fa.store_var(d)
	fa.close()


func auth_register_account(username : String, password : String) -> void:
	SmackneckClient.put_message(header, {"phase":PHASE_AUTH_REGISTER, "username":username, "password":password})


func is_masterserver_authenticated() -> bool:
	return auth_response.get("result", "") == "OK"


func _on_masterserver_connection_lost() -> void:
	auth_response.clear()
