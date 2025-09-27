extends Node2D

@onready var level_manager = $LevelManager if has_node("LevelManager") else null
@onready var sacrifice_ui = $CanvasLayer/SacrificeChoice if has_node("CanvasLayer/SacrificeChoice") else null

func _ready():
	print("🎮 Game._ready() - Starting setup...")
	
	# Try to find nodes in the scene if not direct children
	if not level_manager:
		level_manager = get_tree().get_first_node_in_group("level_manager")
		print("  Found LevelManager via group: ", level_manager != null)
	else:
		print("  Found LevelManager as direct child: ", level_manager != null)
		
	if not sacrifice_ui:
		sacrifice_ui = get_tree().get_first_node_in_group("sacrifice_ui")
		print("  Found SacrificeUI via group: ", sacrifice_ui != null)
	else:
		print("  Found SacrificeUI as direct child: ", sacrifice_ui != null)
	
	if sacrifice_ui:
		sacrifice_ui.hide()
		print("  Hidden sacrifice UI")
	
	if level_manager and sacrifice_ui:
		print("  Connecting LevelManager to SacrificeUI...")
		level_manager.set_sacrifice_ui(sacrifice_ui)
		print("🎮 Game ready - all systems connected!")
	else:
		print("⚠️ Missing components - add LevelManager and SacrificeChoice UI")
		if not level_manager:
			print("  Missing: LevelManager")
		if not sacrifice_ui:
			print("  Missing: SacrificeChoice UI")

func _input(_event):
	# Fallback debug trigger if LevelManager doesn't handle it
	#if event.is_action_pressed("trigger_sacrifice"):
	#	debug_trigger_sacrifice_fallback()
	pass

func debug_trigger_sacrifice_fallback():
	"""Fallback function to trigger sacrifice UI from Game level"""
	if not sacrifice_ui:
		print("⚠️ [Game.gd DEBUG] No sacrifice UI available!")
		return
	
	# Get available sacrifices
	var available_sacrifices: Array[String] = []
	var all_possible = ["gravity", "friction", "collision", "jump", "run", "light"]
	
	for sacrifice in all_possible:
		if GameManager.can_make_sacrifice(sacrifice):
			available_sacrifices.append(sacrifice)
	
	if available_sacrifices.is_empty():
		print("⚠️ [Game.gd DEBUG] All sacrifices already made!")
		return
	
	print("🎮 [Game.gd DEBUG] Opening sacrifice UI as fallback...")
	sacrifice_ui.show_sacrifice_options("DEBUG - Game Fallback", 1, available_sacrifices)
