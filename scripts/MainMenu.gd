# MainMenu.gd - Main menu with proper scene management
extends Control

# Scene paths
const FIRST_LEVEL_PATH = "res://levels/stable_realm/stable_entrance.tscn"
const DEBUG_LEVEL_PATH = "res://levels/debug_level.tscn"

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
	#checking for debug mode
	if Input.is_action_pressed("debug_mode"):
		"""Start the debug level"""
		GameManager.reset_all_sacrifices()
		GameManager.has_debug_mode = true
		await TransitionManager.transition_to_scene(DEBUG_LEVEL_PATH, "")
	else:
		GameManager.has_debug_mode = false
		"""Show credits screen"""
		print("📜 Opening credits...")
		if $AudioStreamPlayer:
			$AudioStreamPlayer.play()
		await TransitionManager.transition_to_scene(CREDITS_PATH, "")

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
	#reset sacrifices
	GameManager.reset_all_sacrifices()
	#checking for debug mode
	GameManager.has_debug_mode = Input.is_action_pressed("debug_mode")
		
	"""Start the first level"""
	await TransitionManager.transition_to_scene(FIRST_LEVEL_PATH, "")

# Scene transitions now handled by TransitionManager with fade effects

func show_error_message(message: String):
	"""Show error message to player"""
	print("❌ Error: ", message)
	# You could add a popup dialog here if needed


func _on_github_button_pressed() -> void:
	OS.shell_open("https://github.com/Sukarth/Hackclub-Jumpstart-Game")
	pass # Replace with function body.


	
