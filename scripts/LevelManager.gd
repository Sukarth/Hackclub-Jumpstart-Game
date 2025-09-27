# LevelManager.gd - Manages level progression and sacrifice requirements
extends Node

# Signals
signal level_completed(level_name: String)
signal sacrifice_required(level_name: String, required_sacrifices: Array[String])

# Level data structure
var levels = {
	"tutorial": {
		"name": "Tutorial Realm",
		"description": "Learn the basic controls",
		"required_sacrifices": [],
		"sacrifice_count": 0
	},
	"stable_realm": {
		"name": "The Stable Realm",
		"description": "A peaceful forest - but change approaches...",
		"required_sacrifices": ["gravity", "friction", "jump"],
		"sacrifice_count": 1
	},
	"fractured_heights": {
		"name": "Fractured Heights",
		"description": "Floating islands demand different movement...",
		"required_sacrifices": ["collision", "run", "light"],
		"sacrifice_count": 1
	},
	"void_labyrinth": {
		"name": "The Void Labyrinth",
		"description": "Dark maze where reality bends...",
		"required_sacrifices": ["gravity", "friction", "collision", "jump", "run"],
		"sacrifice_count": 2
	},
	"chaos_theory": {
		"name": "Chaos Theory",
		"description": "Everything shifts unpredictably...",
		"required_sacrifices": ["gravity", "friction", "collision", "jump", "run", "light"],
		"sacrifice_count": 1
	},
	"altar_restoration": {
		"name": "The Altar of Restoration",
		"description": "The final sanctuary where all is restored...",
		"required_sacrifices": [],
		"sacrifice_count": 0
	}
}

# Current progress
var current_level: String = "tutorial"
var levels_completed: Array[String] = []
var sacrifice_ui: Control = null

func _ready():
	add_to_group("level_manager")
	print("🗺 LevelManager ready")
	# Connect to GameManager signals if needed

func set_sacrifice_ui(ui_node: Control):
	print("🗺 LevelManager.set_sacrifice_ui() called with: ", ui_node)
	sacrifice_ui = ui_node
	if sacrifice_ui:
		print("  UI node is valid, connecting signals...")
		# Connect to sacrifice UI signals
		sacrifice_ui.sacrifice_made.connect(_on_sacrifice_made)
		sacrifice_ui.choice_cancelled.connect(_on_sacrifice_cancelled)
		print("📝 Connected to SacrificeChoice UI - reference stored!")
	else:
		print("  ⚠️ UI node is null!")

func start_level(level_key: String):
	if not level_key in levels:
		print("Error: Unknown level '", level_key, "'")
		return false
	
	current_level = level_key
	var level_data = levels[level_key]
	
	print("🎆 Starting level: ", level_data.name)
	print("  Description: ", level_data.description)
	
	# Check if sacrifices are required
	if level_data.sacrifice_count > 0:
		print("⚠️ Level requires ", level_data.sacrifice_count, " sacrifice(s)")
		# Don't auto-trigger sacrifice UI - let level design decide when
		return true
	else:
		print("✓ No sacrifices required for this level")
		return true

func trigger_sacrifice_requirement(reason: String = ""):
	"""Call this when the player reaches a point that requires sacrifice"""
	var level_data = levels.get(current_level, {})
	
	if level_data.is_empty():
		print("Error: No current level data")
		return
	
	if level_data.sacrifice_count <= 0:
		print("No sacrifice required for current level")
		return
	
	# Filter available sacrifices (only show what hasn't been sacrificed yet)
	var available_sacrifices: Array[String] = []
	for sacrifice in level_data.required_sacrifices:
		if GameManager.can_make_sacrifice(sacrifice):
			available_sacrifices.append(sacrifice)
	
	if available_sacrifices.is_empty():
		print("⚠️ No available sacrifices left for this level!")
		# Maybe allow progression anyway or show different message
		return
	
	print("🔮 Triggering sacrifice requirement...")
	if reason:
		print("  Reason: ", reason)
	
	# Show sacrifice UI if available
	if sacrifice_ui:
		sacrifice_ui.show_sacrifice_options(
			level_data.name + (" - " + reason if reason else ""),
			level_data.sacrifice_count,
			available_sacrifices
		)
	else:
		print("Warning: No sacrifice UI connected!")
		# Emit signal for manual handling
		sacrifice_required.emit(level_data.name, available_sacrifices)

func _on_sacrifice_made(sacrifice_type: String, sacrifice_name: String):
	print("✨ LevelManager: Sacrifice completed - ", sacrifice_name)
	
	# Check if level can now progress
	var level_data = levels.get(current_level, {})
	if not level_data.is_empty():
		# For now, any sacrifice allows progression
		# You can add more complex logic here later
		complete_current_level()

func _on_sacrifice_cancelled():
	print("❌ LevelManager: Sacrifice was cancelled")
	# Handle cancellation - maybe reset player position or show message

func complete_current_level():
	if current_level and not current_level in levels_completed:
		levels_completed.append(current_level)
		print("🏆 Level completed: ", levels[current_level].name)
		level_completed.emit(levels[current_level].name)
		
		# Auto-progress to next level (you can customize this logic)
		var next_level = get_next_level()
		if next_level:
			print("➡️ Advancing to: ", next_level)
			# Small delay before next level
			await get_tree().create_timer(1.0).timeout
			start_level(next_level)
		else:
			print("🎉 All levels completed! Game won!")

func get_next_level() -> String:
	# Simple progression - you can make this more sophisticated
	var level_order = ["tutorial", "stable_realm", "fractured_heights",
					  "void_labyrinth", "chaos_theory", "altar_restoration"]
	
	var current_index = level_order.find(current_level)
	if current_index >= 0 and current_index < level_order.size() - 1:
		return level_order[current_index + 1]
	else:
		return "" # No more levels

func get_current_level_info() -> Dictionary:
	return levels.get(current_level, {})

func has_completed_level(level_key: String) -> bool:
	return level_key in levels_completed

func get_progress_summary() -> Dictionary:
	return {
		"current_level": current_level,
		"levels_completed": levels_completed,
		"total_levels": levels.size(),
		"sacrifices_made": GameManager.get_sacrifice_count()
	}

# Debug functions
func _input(event):
	# Temporary test controls (remove later)
	if event.is_action_pressed("trigger_sacrifice"): # Down Arrow
		print("🔮 [DEBUG] Triggering sacrifice requirement")
		debug_trigger_sacrifice()
	
	elif event.is_action_pressed("show_progress"): # Up Arrow
		print("📊 [DEBUG] Progress summary:")
		var summary = get_progress_summary()
		for key in summary:
			print("  ", key, ": ", summary[key])

func debug_trigger_sacrifice():
	"""Debug function to trigger sacrifice UI regardless of level requirements"""
	print("🔮 [DEBUG] Forcing sacrifice UI to open...")
	print("  Current sacrifice_ui reference: ", sacrifice_ui)
	print("  Is sacrifice_ui valid? ", sacrifice_ui != null)
	
	# Try to find UI again if it's null
	if not sacrifice_ui:
		print("  Attempting to find UI in scene tree...")
		sacrifice_ui = get_tree().get_first_node_in_group("sacrifice_ui")
		print("  Found via group search: ", sacrifice_ui != null)
	
	# Get all available sacrifices (not already made)
	var available_sacrifices: Array[String] = []
	var all_possible = ["gravity", "friction", "collision", "jump", "run", "light"]
	
	for sacrifice in all_possible:
		if GameManager.can_make_sacrifice(sacrifice):
			available_sacrifices.append(sacrifice)
	
	print("  Available sacrifices: ", available_sacrifices)
	
	if available_sacrifices.is_empty():
		print("⚠️ [DEBUG] No sacrifices available - all have been made!")
		return
	
	# Show sacrifice UI if available
	if sacrifice_ui:
		print("  Calling sacrifice_ui.show_sacrifice_options()...")
		sacrifice_ui.show_sacrifice_options(
			"DEBUG TEST - " + levels[current_level].name,
			1,
			available_sacrifices
		)
		print("✨ [DEBUG] Sacrifice UI should now be visible!")
	else:
		print("⚠️ [DEBUG] No sacrifice UI found! UI reference is null.")
