extends Control

@onready var delve_button: Button = %Delve_Button

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
