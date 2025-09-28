# SceneManager.gd - Handles loading and transitioning between level scenes
extends Node

# Signals
signal scene_transition_started(scene_path: String)
signal scene_transition_completed(scene_name: String)

# References
@onready var level_manager = GameManager if GameManager else null

# Scene transition
var is_transitioning: bool = false
var fade_duration: float = 0.5

func _ready():
	print("🎬 SceneManager ready")

# Load a specific level scene
func load_level_scene(level_key: String, sublevel_name: String = ""):
	if is_transitioning:
		print("⚠️ Scene transition already in progress")
		return false
	
	# Get level data from LevelManager
	var level_manager_ref = get_tree().get_first_node_in_group("level_manager")
	if not level_manager_ref:
		print("⚠️ No LevelManager found!")
		return false
	
	var levels = level_manager_ref.levels
	if not level_key in levels:
		print("⚠️ Unknown level: ", level_key)
		return false
	
	var level_data = levels[level_key]
	var scene_path = level_data.scene_path
	
	# Add sublevel to path if specified
	if sublevel_name != "":
		scene_path += sublevel_name + ".tscn"
	else:
		# Use first sublevel by default
		if level_data.sublevels.size() > 0:
			scene_path += level_data.sublevels[0] + ".tscn"
		else:
			scene_path += level_key + ".tscn"
	
	print("🎬 Loading scene: ", scene_path)
	
	# Check if scene file exists
	if not FileAccess.file_exists(scene_path):
		print("⚠️ Scene file not found: ", scene_path)
		print("  Create the scene file or use a placeholder")
		# Load placeholder scene for development
		load_placeholder_scene(level_key, sublevel_name)
		return false
	
	# Start transition
	transition_to_scene(scene_path)
	return true

func load_placeholder_scene(level_key: String, sublevel_name: String):
	"""Load a simple placeholder scene for development"""
	print("🔧 Loading placeholder scene for: ", level_key, "/", sublevel_name)
	
	# For now, just print - later you can create a basic scene
	scene_transition_completed.emit(level_key + "_" + sublevel_name + "_placeholder")

func transition_to_scene(scene_path: String):
	"""Handle scene transition with fade effect"""
	is_transitioning = true
	scene_transition_started.emit(scene_path)
	
	# Use TransitionManager for fade effects
	var success = await TransitionManager.transition_to_scene(scene_path, "")
	
	if success:
		print("✅ Scene loaded successfully")
		scene_transition_completed.emit(scene_path)
	else:
		print("❌ Failed to load scene: ", scene_path)
	
	is_transitioning = false

# Create basic level directory structure
func create_level_directories():
	"""Helper function to create the expected directory structure"""
	var dir = DirAccess.open("res://")
	if dir:
		# Create main levels directory
		if not dir.dir_exists("levels"):
			dir.make_dir("levels")
		
		# Create subdirectories for each level
		var level_names = ["tutorial", "stable_realm", "fractured_heights",
						  "void_labyrinth", "chaos_theory", "altar_restoration"]
		
		for level_name in level_names:
			var level_path = "levels/" + level_name
			if not dir.dir_exists(level_path):
				dir.make_dir(level_path)
				print("📁 Created directory: ", level_path)

# Debug function to list expected scene files
func list_expected_scenes():
	print("📋 Expected scene structure:")
	var level_manager_ref = get_tree().get_first_node_in_group("level_manager")
	if level_manager_ref:
		for level_key in level_manager_ref.levels:
			var level_data = level_manager_ref.levels[level_key]
			print("  Level: ", level_key)
			for sublevel in level_data.sublevels:
				var expected_path = level_data.scene_path + sublevel + ".tscn"
				print("    - ", expected_path)
