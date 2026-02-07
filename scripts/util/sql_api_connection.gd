extends Node

var api_endpoint: String = "https://qqneupjxzhsobvydfmxy.supabase.co"
var published_key: String = "sb_publishable_dqoaakWLIGLCbyKuepLZ4g_Bsc8G7ht"

var http_request: HTTPRequest

# Signal to notify when request completes
signal request_completed(data, error)

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	
func get_all_players():
	var url = api_endpoint + "/rest/v1/Players?select=*"
	var headers = [
		"apikey: " + published_key,
		"Authorization: Bearer " + published_key
	]
	http_request.request(url, headers)

func _on_request_completed(_result, response_code, _headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	if response_code == 200 or response_code == 201:
		GlobalLogger.debug("Success! Data: " + str(json))
		request_completed.emit(json, null)
	else:
		request_completed.emit(null, json)
		GlobalLogger.error("Error " + str(response_code) + ": " + str(json))
