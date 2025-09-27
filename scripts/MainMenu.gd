# MainMenu.gd - Simple main menu
extends Control


func _on_start_pressed():
	$AudioStreamPlayer.play()
	%FadeAnimator.play("fade_out")

func _on_quit_pressed():
	get_tree().quit()


# Handle keyboard input
func _input(event):
	if event.is_action_pressed("jump"): # Space bar to start
		$AudioStreamPlayer.play()
		_on_start_pressed()


func _on_fade_animator_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"fade_out":
			get_tree().change_scene_to_file("res://levels/stable_realm/stable_entrance.tscn")
			pass
		_:
			pass
	pass # Replace with function body.


func _on_credits_button_pressed() -> void:
	get_tree().change_scene_to_file("res://credits.tscn")
	pass


func _on_ready() -> void:
	$AudioStreamPlayer.play()
	pass # Replace with function body.
