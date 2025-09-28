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
	change_scene_safely(MAIN_MENU_PATH)

func _input(event):
	"""Handle keyboard input"""
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("jump"):
		_on_back_button_pressed()

func change_scene_safely(scene_path: String):
	"""Safely change to a new scene with error handling"""
	if not ResourceLoader.exists(scene_path):
		print("❌ Scene file not found: ", scene_path)
		return
	
	print("🎬 Changing to scene: ", scene_path)
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		print("❌ Failed to change scene: ", error)
