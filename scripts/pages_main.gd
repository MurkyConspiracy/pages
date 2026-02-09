extends Control

@onready var delve_button: Button = %Delve_Button
@onready var login_button: Button = %Login_Button

func _ready() -> void:
	#Pages_SQL.request_completed.connect(_on_data_received)
	GlobalLogger.debug("SQL init disabled")
	pass
	
func _on_delve_button_pressed() -> void:
	#Pages_SQL.get_all_players()
	GlobalLogger.debug("Re-enable Later!!!")
	
func _on_data_received(data, error):
	if error:
		GlobalLogger.error("Error occurred: " + str(error))
	else:
		GlobalLogger.info("Received data: " + str(data))
		


func _on_login_button_pressed() -> void:
	if not Pages_SQL.is_authenticated():
		get_tree().change_scene_to_file("res://scenes/pages_login.tscn")
