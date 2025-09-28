# PauseMenu.gd - Pause menu UI (managed by global PauseManager)
extends Control

# Signals for PauseManager to listen to
signal resume_requested
signal main_menu_requested
signal quit_requested

func _ready():
	# Always visible when created, process when paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = true
	
	# Connect buttons (only if not already connected)
	if has_node("VBoxContainer/ResumeButton"):
		var resume_btn = $VBoxContainer/ResumeButton
		if not resume_btn.pressed.is_connected(_on_resume_pressed):
			resume_btn.pressed.connect(_on_resume_pressed)
	if has_node("VBoxContainer/MainMenuButton"):
		var main_menu_btn = $VBoxContainer/MainMenuButton
		if not main_menu_btn.pressed.is_connected(_on_main_menu_pressed):
			main_menu_btn.pressed.connect(_on_main_menu_pressed)
	if has_node("VBoxContainer/QuitButton"):
		var quit_btn = $VBoxContainer/QuitButton
		if not quit_btn.pressed.is_connected(_on_quit_pressed):
			quit_btn.pressed.connect(_on_quit_pressed)
	
	print("⏸️ Pause menu created")

# Input handling is now done by PauseManager globally
# This menu just provides UI and emits signals

func show_menu():
	"""Show the pause menu"""
	visible = true
	print("⏸️ Pause menu shown")

func hide_menu():
	"""Hide the pause menu"""
	visible = false
	print("▶️ Pause menu hidden")

func _on_resume_pressed():
	"""Resume game"""
	print("▶️ Resume requested")
	resume_requested.emit()

func _on_main_menu_pressed():
	"""Return to main menu"""
	print("🏠 Main menu requested")
	main_menu_requested.emit()

func _on_quit_pressed():
	"""Quit game"""
	print("👋 Quit requested")
	quit_requested.emit()
