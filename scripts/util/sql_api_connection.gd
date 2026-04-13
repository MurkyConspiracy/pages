extends Node

#Public auth credentals
const api_endpoint: String = "https://qqneupjxzhsobvydfmxy.supabase.co"
const published_key: String = "sb_publishable_dqoaakWLIGLCbyKuepLZ4g_Bsc8G7ht"

#Signal to notify when request completes
signal request_completed(data, error)
#Signal for catching user login events
signal auth_state_changed(user)
#Signal for holding filedata
signal fear_list_ready(files)
#Signal for recusive directory listing
signal fear_recursive_list_ready(files)


var http_request: HTTPRequest
var current_user = null
var access_token = ""
var refresh_token = ""

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	#Check for and load saved session
	_load_session()
	
	fear_list_ready.connect(func(files):
		download_fear_local_copy(files))
	
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
	
func refresh_session():
	var url = api_endpoint + "/auth/v1/token?grant_type=refresh_token"
	var headers = [
		"apikey: " + published_key,
		"Content-Type: application/json"
	]
	
	var body = JSON.stringify({
		"refresh_token": refresh_token
	})
	
	http_request.set_meta("request_type", "refresh")
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	
func is_token_expired() -> bool:
	var data = decode_jwt_payload(access_token)
	if not data.has("exp"):
		GlobalLogger.error("Refreshing due to failed JSON parse")
		return true  # assume expired if unreadable

	var now = Time.get_unix_time_from_system()
	if now > int(data.exp):
		GlobalLogger.debug("Refreshing JWT due to expired token")
	else:
		GlobalLogger.debug("Token still valid!")
	return now > int(data.exp)

func decode_jwt_payload(token: String) -> Dictionary:
	var parts = token.split(".")
	if parts.size() < 2:
		return {}
	var payload = parts[1]
	# Convert Base64URL → Base64
	payload = payload.replace("-", "+").replace("_", "/")
	# Add padding if missing
	while payload.length() % 4 != 0:
		payload += "="
	var decoded = Marshalls.base64_to_utf8(payload)
	var json = JSON.parse_string(decoded)
	return json if typeof(json) == TYPE_DICTIONARY else {}

#endregion Authentication

#region Database Functions
func get_all_players():
	var url = api_endpoint + "/rest/v1/Players?select=*"
	var headers = [
		"apikey: " + published_key
	]
	if is_authenticated():
		if is_token_expired():
			await refresh_session()
		headers.append("Authorization: Bearer " + str(access_token))
	else:
		headers.append("Authorization: Bearer " + str(published_key))
	http_request.set_meta("request_type", "get_players")
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
				current_user = json.email
				GlobalLogger.debug("User Creation Successful: " + str(current_user))
				GlobalLogger.debug("User Requires Email Confirmation: " + str(current_user))
			elif response_code == 429:
				GlobalLogger.error("API Error: " + str(json))
			else:
				GlobalLogger.warn("Auth error: " +str(json))
				auth_state_changed.emit(null)
		"signin":
			if response_code == 200:
				current_user = json.user
				access_token = json.access_token
				_save_session(json)
				auth_state_changed.emit(current_user)
				GlobalLogger.debug("Authentication Successful: " + str(current_user))
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
		"list_fear_bucket":
			var prefix = http_request.get_meta("prefix")
			var files = json
			#TODO implement recussion next!!
			fear_list_ready.emit(json)
		"refresh":
			if response_code == 200:
				access_token = json.access_token
				refresh_token = json.refresh_token
				_save_session(json)
				GlobalLogger.debug("Session refreshed")
			else:
				GlobalLogger.warn("Refresh failed, user must sign in again")
		_:
			GlobalLogger.error("Unhandled API Request!")
			request_completed.emit(null)
		
#endregion Internal Methods

#region Local Save session
func _save_session(auth_data):
	var file = FileAccess.open("user://session.dat", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"user":auth_data.user,
			"access_token":auth_data.access_token,
			"refresh_token":auth_data.refresh_token
			}))
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
				refresh_token = auth_data.refresh_token
				if is_token_expired():
					refresh_session()
				auth_state_changed.emit(current_user)
				GlobalLogger.debug("Session restored: " + str(current_user.email) + " JWT Token : " + str(access_token.left(4) + "..." + str(access_token.right(4))))
				
# Clear saved session
func _clear_session():
	if FileAccess.file_exists("user://session.dat"):
		DirAccess.remove_absolute("user://session.dat")
#endregion Local Save session

#region Remote File session

func list_fear(prefix : String):
	if not is_authenticated():
		push_error("User not authenticated! Cannot get private information!")
		return
	if is_token_expired():
		await refresh_session()

	var bucket_name = "TheFear"  # URL-encoded bucket name
	var url = api_endpoint + "/storage/v1/object/list/" + bucket_name
	
	var headers = [
		"apikey: " + published_key,
		"Authorization: Bearer " + str(access_token),
		"Content-Type: application/json"
	]
	
	var body = JSON.stringify({
		"prefix": prefix,
		"limit": 100,
		"offset": 0
	})

	http_request.set_meta("request_type", "list_fear_bucket")
	http_request.set_meta("prefix",prefix)
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)  # list endpoint requires POST
	

	
func download_fear_local_copy(fear_files : Array):
	
	for fear in fear_files:
		GlobalLogger.debug(str(fear))
		var file = FileAccess.open("user://Fear/"+fear["name"], FileAccess.READ_WRITE)
		if file:
			if FileAccess.get_modified_time("user://Fear/"+fear["name"]) < fear["meatdata"]["lastModified"]:
				GlobalLogger.debug("File outdated!")
		else:
			GlobalLogger.debug("File Missing: " + fear["name"])
			
	
#endregion Remote File session
