extends Node

# AWS Cognito endpoint
const AWS_COGNITO_URI = 'https://cognito-idp.us-east-1.amazonaws.com/'


#Signal to notify when request completes
signal request_completed(data, error)
# HTTP request handler object
var http_request: HTTPRequest

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func register_account(email: String, password: String):
	var headers = [
		'Content-Type: application/x-amz-json-1.1',
		'X-Amz-Target: AWSCognitoIdentityProviderService.SignUp'
	]
	
	var body = JSON.stringify({
		"ClientId": "gdang24gcos1j7klk8cd401b",
		"Username": email,
		"Password": password,
		"UserAttributes":[{
			"Name": "email",
			"Value": email
		}]
	})

	http_request.set_meta("request_type", "signup")
	http_request.request(AWS_COGNITO_URI, headers, HTTPClient.METHOD_POST, body)
	
	
func validate_account(email: String, token: String):
	var headers = [
		'Content-Type: application/x-amz-json-1.1',
		'X-Amz-Target: AWSCognitoIdentityProviderService.ConfirmSignUp'
	]
	
	var body = JSON.stringify({
		"ClientId": "gdang24gcos1j7klk8cd401b",
		"Username": email,
		"ConfirmationCode": token
	})

	http_request.set_meta("request_type", "confirm_signup")
	http_request.request(AWS_COGNITO_URI, headers, HTTPClient.METHOD_POST, body)

func _on_request_completed(_result, response_code, _headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	var request_type = http_request.get_meta("request_type","")
	match request_type:
		"signup":
			GlobalLogger.debug("AWS account signup!")
		"confirm_signup":
			GlobalLogger.debug("Confrim account!")
		_:
			pass
