extends Control

@onready var email_input: LineEdit = %email_input
@onready var password_input: LineEdit = %password_input
@onready var signup_button: Button = %signup_button
@onready var status_label: Label = %Status_Label
@onready var login_button: Button = %login_button


func _ready() -> void:
	
	Pages_SQL.auth_state_changed.connect(_on_auth_changed)
	
	if Pages_SQL.is_authenticated():
		_go_to_main_menu()
		


func _on_login_button_pressed() -> void:
	var email = email_input.text
	var password = password_input.text
	
	if email.is_empty() or password.is_empty():
		status_label.add_theme_color_override("font_color",Color.RED)
		status_label.text = "Invalid Inputs!"
		return
		
	status_label.add_theme_color_override("font_color",Color.WHITE)
	status_label.text = "Logging In..."
	Pages_SQL.sign_in(email,password)
	



func _on_signup_button_pressed() -> void:
	var email = email_input.text
	var password = password_input.text
	
	if email.is_empty() or password.is_empty():
		status_label.add_theme_color_override("font_color",Color.RED)
		status_label.text = "Please enter email and password"
		return
	
	if password.length() < 6:
		status_label.add_theme_color_override("font_color",Color.RED)
		status_label.text = "Password must be at least 6 characters"
		return
	
	status_label.add_theme_color_override("font_color",Color.YELLOW)
	status_label.text = "Creating account..."
	Pages_SQL.sign_up(email, password)
	
func _on_auth_changed(user):
	if user:
		status_label.add_theme_color_override("font_color",Color.GREEN_YELLOW)
		status_label.text = "Login successful!"
		await get_tree().create_timer(0.5).timeout
		_go_to_main_menu()
	else:
		status_label.add_theme_color_override("font_color",Color.RED)
		status_label.text = "Login failed. Please try again."
		
		
func _go_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/pages_main.tscn")
