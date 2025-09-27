extends Node2D

@onready var level_manager = $LevelManager if has_node("LevelManager") else null
@onready var sacrifice_ui = $CanvasLayer/SacrificeChoice if has_node("CanvasLayer/SacrificeChoice") else null

func _ready():
	if sacrifice_ui:
		sacrifice_ui.hide()
	
	if level_manager and sacrifice_ui:
		level_manager.set_sacrifice_ui(sacrifice_ui)
		print("🎮 Game ready - all systems connected!")
	else:
		print("⚠️ Missing components - add LevelManager and SacrificeChoice UI")

func _input(event):
	if sacrifice_ui and event.is_action_pressed("ui_page_down"):
		sacrifice_ui.show_sacrifice_options("Test Level", 1, ["gravity", "friction", "jump"])
