extends Button



func _on_ReloadButton_button_up() -> void:
	PlayerData.reset()
	get_tree().reload_current_scene()
