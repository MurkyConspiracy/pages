extends Control

@onready var delve_button: Button = %Delve_Button
@onready var login_button: Button = %Login_Button
@onready var inspire_button: Button = %Inspire_Button
@onready var user_label: Label = %UserLabel
@onready var logout_button: Button = %Logout_Button
@onready var exit_button: Button = %Exit_Button

func _ready() -> void:
	Pages_SQL.request_completed.connect(_on_data_received)
	if Pages_SQL.is_authenticated():
		logout_button.visible = true
		user_label.text = str(Pages_SQL.current_user.email).split("@")[0]
		login_button.visible = false
		inspire_button.disabled = false
		inspire_button.material = delve_button.material
		
	
	
func _on_delve_button_pressed() -> void:
	Pages_SQL.get_all_players()
	#GlobalLogger.debug("Re-enable Later!!!")
	
func _on_data_received(data, error):
	if error:
		GlobalLogger.error("Error occurred: " + str(error))
	
	
	GlobalLogger.info("Received data: " + str(data))
		
		


func _on_login_button_pressed() -> void:
	if not Pages_SQL.is_authenticated():
		get_tree().change_scene_to_file("res://scenes/pages_login.tscn")


func _on_exit_button_pressed() -> void:
	GlobalLogger.info("Quiting application")
	get_tree().quit(0)


func _on_logout_button_pressed() -> void:
	Pages_SQL.sign_out()
	get_tree().reload_current_scene()
