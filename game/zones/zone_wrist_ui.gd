extends PanelContainer


func _on_save_button_pressed() -> void:
	var _did_save := GameState.auto_save_game()


func _on_quit_button_pressed() -> void:
	var _did_save := GameState.quit_game()
