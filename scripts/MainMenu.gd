# MainMenu.gd - Main menu with proper scene management
extends Control

# Scene paths
const FIRST_LEVEL_PATH = "res://levels/stable_realm/stable_entrance.tscn"
const CREDITS_PATH = "res://credits.tscn"

func _ready():
	print("🎮 Main Menu loaded")
	# Play background music if available
	if $AudioStreamPlayer:
		$AudioStreamPlayer.play()

func _on_start_pressed():
	"""Start the game"""
	print("🎮 Starting game...")
	if $AudioStreamPlayer:
		$AudioStreamPlayer.play()
	
	# Play fade animation then transition
	if %FadeAnimator:
		%FadeAnimator.play("fade_out")
	else:
		# Direct transition if no fade animation
		start_game()

func _on_credits_button_pressed():
	"""Go to credits scene"""
	print("📜 Opening credits...")
	if $AudioStreamPlayer:
		$AudioStreamPlayer.play()
	
	change_scene_safely(CREDITS_PATH)

func _on_quit_pressed():
	"""Quit the game"""
	print("👋 Quitting game...")
	if $AudioStreamPlayer:
		$AudioStreamPlayer.play()
	
	# Small delay for audio feedback
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _on_fade_animator_animation_finished(anim_name: StringName):
	"""Handle fade animation completion"""
	match anim_name:
		"fade_out":
			start_game()

# Handle keyboard input
func _input(event):
	if event.is_action_pressed("jump"): # Space bar to start
		_on_start_pressed()
	elif event.is_action_pressed("ui_cancel"): # ESC to quit
		_on_quit_pressed()

func start_game():
	"""Start the first level"""
	change_scene_safely(FIRST_LEVEL_PATH)

func change_scene_safely(scene_path: String):
	"""Safely change to a new scene with error handling"""
	if not ResourceLoader.exists(scene_path):
		print("❌ Scene file not found: ", scene_path)
		show_error_message("Scene file not found: " + scene_path)
		return
	
	print("🎬 Changing to scene: ", scene_path)
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		print("❌ Failed to change scene: ", error)
		show_error_message("Failed to load scene")

func show_error_message(message: String):
	"""Show error message to player"""
	print("❌ Error: ", message)
	# You could add a popup dialog here if needed
