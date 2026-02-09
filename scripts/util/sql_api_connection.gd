extends Node

#Public auth credentals
const api_endpoint: String = "https://qqneupjxzhsobvydfmxy.supabase.co"
const published_key: String = "sb_publishable_dqoaakWLIGLCbyKuepLZ4g_Bsc8G7ht"

#Signal to notify when request completes
signal request_completed(data, error)
#Signal for catching user login events
signal auth_state_changed(user)


var http_request: HTTPRequest
var current_user = null
var access_token = ""
func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	#Check for and load saved session
	#_load_session()
	
	
#region Authentication
#Allows users to signup for an account
func sign_up(email: String, password: String):
	var url = api_endpoint + "/auth/v1/signup"
	var headers = [
		"apikey: " + published_key,
		"Content-Type: application/json"
	]
	
	var body = JSON.stringify({
		"email": email,
		"password": password
	})

	http_request.set_meta("request_type", "signup")
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)

#Allows users to sing into account that is approved
func sign_in(email: String, password: String):
	var url = api_endpoint + "/auth/v1/token?grant_type=password"
	var headers = [
		"apikey: " + published_key,
        "Content-Type: application/json"
	]
	var body = JSON.stringify({
		"email": email,
		"password": password
	})
	http_request.set_meta("request_type", "signin")
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	
#Clears user session for cleanup
func sign_out():
	current_user = null
	access_token = ""
	_clear_session()
	auth_state_changed.emit(null)
	GlobalLogger.debug("Signed out successfully")
	
#Return auth state:
func is_authenticated() -> bool:
	return current_user != null

#endregion Authentication

#region Database Functions
func get_all_players():
	var url = api_endpoint + "/rest/v1/Players?select=*"
	var headers = [
		"apikey: " + published_key,
		"Authorization: Bearer " + published_key
	]
	http_request.request(url, headers)
	
func create_player(player_name: String, theme: Themes):
	if not is_authenticated():
		push_error("User not authenticated!")
		return
	
	var url = api_endpoint + "/rest/v1/Players"
	var headers = [
		"apikey: " + api_endpoint,
		"Authorization: Bearer " + access_token,
		"Content-Type: application/json",
        "Prefer: return=representation"
	]
	var body = JSON.stringify({"name": player_name, "theme_id": theme})
	http_request.set_meta("request_type", "create_player")
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)

#endregion Database Functions

#region Internal Methods
func _on_request_completed(_result, response_code, _headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	var request_type = http_request.get_meta("request_type","")
	match request_type:
		"signup":
			if response_code == 200:
				current_user = json.emailv
				GlobalLogger.debug("User Creation Successful: " + str(current_user.email))
				GlobalLogger.debug("User Requires Email Confirmation: " + str(current_user.email))
			else:
				GlobalLogger.warn("Auth error: " +str(json))
				auth_state_changed.emit(null)
		"signin":
			if response_code == 200:
				current_user = json.user
				access_token = json.access_token
				_save_session(json)
				auth_state_changed.emit(current_user)
				GlobalLogger.debug("Authentication Successful: " + str(current_user.email))
			else:
				GlobalLogger.warn("Auth error: " +str(json))
				auth_state_changed.emit(null)
				
		"get_players","create_player":
			if response_code == 200 or response_code == 201:
				GlobalLogger.debug("Success! Data: " + str(json))
				request_completed.emit(json, null)
			else:
				request_completed.emit(null, json)
				GlobalLogger.error("Error " + str(response_code) + ": " + str(json))
		
#endregion Internal Methods

#region File session
func _save_session(auth_data):
	var file = FileAccess.open("user://session.dat", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(auth_data))
		file.close()

func _load_session():
	if FileAccess.file_exists("user://session.dat"):
		var file = FileAccess.open("user://session.dat", FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var auth_data = JSON.parse_string(json_string)
			if auth_data:
				current_user = auth_data.user
				access_token = auth_data.access_token
				auth_state_changed.emit(current_user)
				GlobalLogger.debug("Session restored: " + str(current_user.email))
				
# Clear saved session
func _clear_session():
	if FileAccess.file_exists("user://session.dat"):
		DirAccess.remove_absolute("user://session.dat")
#endregion Filr session
