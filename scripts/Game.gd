extends Node2D

@onready var level_manager = $LevelManager
@onready var sacrifice_ui = $CanvasLayer/SacrificeChoice

func _ready():
	# Connect level manager to UI
	level_manager.set_sacrifice_ui(sacrifice_ui)
	
	# Start first level
	level_manager.start_level("tutorial")
	
	print("🎮 Game ready - all systems connected!")
