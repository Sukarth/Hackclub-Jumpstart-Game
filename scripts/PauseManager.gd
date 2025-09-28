# PauseManager.gd - Global pause system that works in any scene
extends Node

const MAIN_MENU_PATH = "res://main_menu.tscn"

var pause_menu_scene = preload("res://PauseMenu.tscn")
var pause_menu_instance = null
var is_paused = false
var can_pause = true # Disable in main menu

func _ready():
	# Set process mode to always run even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("⏸️ Global PauseManager ready")

func _input(event):
	# Only handle pause in game scenes (not in main menu or credits)
	if event.is_action_pressed("ui_cancel") and can_pause: # ESC key
		toggle_pause()

func toggle_pause():
	"""Toggle pause state"""
	if is_paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	"""Pause the game and show pause menu"""
	if is_paused:
		return
		
	is_paused = true
	get_tree().paused = true
	
	# Create and show pause menu
	create_pause_menu()
	print("⏸️ Game paused")

func resume_game():
	"""Resume the game and hide pause menu"""
	if not is_paused:
		return
		
	is_paused = false
	get_tree().paused = false
	
	# Remove pause menu
	remove_pause_menu()
	print("▶️ Game resumed")

func create_pause_menu():
	"""Create and display the pause menu"""
	if pause_menu_instance:
		return # Already exists
	
	# Create pause menu instance
	pause_menu_instance = pause_menu_scene.instantiate()
	
	# Connect pause menu signals
	if pause_menu_instance.has_signal("resume_requested"):
		pause_menu_instance.resume_requested.connect(_on_resume_requested)
	if pause_menu_instance.has_signal("main_menu_requested"):
		pause_menu_instance.main_menu_requested.connect(_on_main_menu_requested)
	if pause_menu_instance.has_signal("quit_requested"):
		pause_menu_instance.quit_requested.connect(_on_quit_requested)
	
	# Create a CanvasLayer to ensure the pause menu appears on top
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100 # High layer to appear on top
	canvas_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Add pause menu to canvas layer, then canvas layer to scene
	canvas_layer.add_child(pause_menu_instance)
	get_tree().current_scene.add_child(canvas_layer)

func remove_pause_menu():
	"""Remove the pause menu from the scene"""
	if pause_menu_instance:
		# Remove the CanvasLayer (which contains the pause menu)
		var canvas_layer = pause_menu_instance.get_parent()
		if canvas_layer:
			canvas_layer.queue_free()
		pause_menu_instance = null

func _on_resume_requested():
	"""Handle resume button press"""
	resume_game()

func _on_main_menu_requested():
	"""Handle main menu button press"""
	print("🏠 Returning to main menu...")
	get_tree().paused = false # Unpause before changing scene
	remove_pause_menu()
	await TransitionManager.transition_to_scene(MAIN_MENU_PATH, "")

func _on_quit_requested():
	"""Handle quit button press"""
	print("👋 Quitting game...")
	get_tree().quit()

# Scene transitions now handled by TransitionManager

# Scene detection - disable pause in menu scenes
func _on_scene_changed():
	"""Detect when scene changes to enable/disable pause"""
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_name = current_scene.scene_file_path
		
		# Disable pause in menu scenes
		if "main_menu" in scene_name or "credits" in scene_name:
			can_pause = false
			if is_paused:
				resume_game() # Force resume if we were paused
		else:
			can_pause = true
		
		print("🎬 Scene changed - can_pause: ", can_pause)

# Connect to scene changes
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()

# Alternative method to detect scene changes
func _process(_delta):
	# Simple scene detection
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_path = current_scene.scene_file_path
		var should_allow_pause = not ("main_menu" in scene_path or "credits" in scene_path)
		
		if can_pause != should_allow_pause:
			can_pause = should_allow_pause
			if not can_pause and is_paused:
				resume_game() # Force resume in menu scenes
