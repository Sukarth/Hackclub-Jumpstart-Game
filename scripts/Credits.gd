extends Control

func _on_back_button_pressed() -> void:
	$AudioStreamPlayer.play()
	get_tree().change_scene_to_file("res://main_menu.tscn")
	pass


func _on_ready() -> void:
	$AudioStreamPlayer.play()
	pass # Replace with function body.
