extends Control

const MAIN_MENU_PATH = "res://main_menu.tscn"

func _ready():
	print("📜 Credits scene loaded")
	# Play background music if available
	if $AudioStreamPlayer:
		$AudioStreamPlayer.play()

func _on_back_button_pressed():
	"""Return to main menu"""
	print("📜 Returning to main menu...")
	if $AudioStreamPlayer:
		$AudioStreamPlayer.play()
	
	# Small delay for audio feedback
	await get_tree().create_timer(0.1).timeout
	await TransitionManager.transition_to_scene(MAIN_MENU_PATH, "")

func _input(event):
	"""Handle keyboard input"""
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("jump"):
		_on_back_button_pressed()

# Scene transitions now handled by TransitionManager with fade effects
