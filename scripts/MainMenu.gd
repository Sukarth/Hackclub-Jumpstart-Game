# MainMenu.gd - Simple main menu
extends Control

func _ready():
	# Connect buttons (you'll add these in the scene)
	if has_node("VBoxContainer/StartButton"):
		$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	if has_node("VBoxContainer/QuitButton"):
		$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	
	print("🎮 Main Menu Ready")

func _on_start_pressed():
	print("🚀 Starting game...")
	get_tree().change_scene_to_file("res://levels/tutorial/tutorial_01.tscn")

func _on_quit_pressed():
	print("👋 Quitting game...")
	get_tree().quit()

# Handle keyboard input
func _input(event):
	if event.is_action_pressed("jump"): # Space bar to start
		_on_start_pressed()