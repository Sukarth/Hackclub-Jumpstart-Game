extends TextureRect



func _on_ready() -> void:
	if GameManager.has_light:
		hide()
	else:
		show()
	pass # Replace with function body.
