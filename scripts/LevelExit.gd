# LevelExit.gd - End of level trigger
extends Area2D

@export var next_level_path: String = ""
@export var level_name: String = "Next Level"
@export var requires_sacrifice: bool = false # Must make sacrifice to exit
@export var required_sacrifice_count: int = 1

# Visual feedback
@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
var exit_available: bool = true

func _ready():
	# Connect signals
	body_entered.connect(_on_player_entered)
	
	# Add to group for easy finding
	add_to_group("level_exits")
	
	print("🚪 Level Exit ready - leads to: ", level_name)
	
	# Check if sacrifice is required
	if requires_sacrifice:
		check_sacrifice_requirement()

func _on_player_entered(body):
	if body.is_in_group("player"):
		if exit_available:
			trigger_level_complete()
		else:
			show_exit_blocked_message()

func trigger_level_complete():
	"""Complete the level and transition"""
	print("🎉 Level Complete! Transitioning to: ", level_name)
	
	# Optional: Show completion effect
	show_completion_effect()
	
	# Small delay for effect
	await get_tree().create_timer(1.0).timeout
	
	# Check if this is the final level (altar_restoration)
	var is_final_level = is_current_level_final()
	
	if next_level_path != "":
		# If not the final level, show sacrifice UI first
		if not is_final_level:
			var sacrifice_successful = await show_sacrifice_requirement()
			if not sacrifice_successful:
				print("⚠️ Sacrifice was not completed, blocking level progression")
				return
		
		# Proceed with level transition
		# Check if LoreManager exists (may need project restart)
		if has_node("/root/LoreManager"):
			# Get lore for the next level
			var lore_manager = get_node("/root/LoreManager")
			var lore = lore_manager.get_lore_for_scene(next_level_path)
			
			# Load next level with lore transition
			await TransitionManager.transition_with_lore(next_level_path, lore.title, lore.text)
		else:
			print("📖 LoreManager not found, using regular transition")
			await TransitionManager.transition_to_scene(next_level_path, "Loading Next Level...")
	else:
		# No next level - game complete or return to menu
		print("🏆 Game Complete!")
		handle_game_complete()

func show_completion_effect():
	"""Visual effect when level is completed"""
	if sprite:
		# Bright flash effect
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE * 2, 0.3)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

func check_sacrifice_requirement():
	"""Check if player has made required sacrifices"""
	if requires_sacrifice:
		var sacrifice_count = GameManager.get_sacrifice_count()
		if sacrifice_count >= required_sacrifice_count:
			exit_available = true
			enable_exit_visual()
		else:
			exit_available = false
			disable_exit_visual()

func show_exit_blocked_message():
	"""Show message when exit is blocked"""
	print("🚫 Exit blocked - requires ", required_sacrifice_count, " sacrifice(s)")
	print("   Current sacrifices: ", GameManager.get_sacrifice_count())
	
	# You can add UI message here later

func enable_exit_visual():
	"""Visual feedback that exit is available"""
	if sprite:
		sprite.modulate = Color.WHITE

func disable_exit_visual():
	"""Visual feedback that exit is blocked"""
	if sprite:
		sprite.modulate = Color.GRAY

func handle_game_complete():
	"""Handle when all levels are complete"""
	# Return to main menu with fade transition
	await TransitionManager.transition_to_scene("res://main_menu.tscn", "")

# Call this when sacrifices are made to recheck availability
func recheck_exit_availability():
	check_sacrifice_requirement()

func is_current_level_final() -> bool:
	"""Check if the current level is the final level (altar_restoration)"""
	# We can check this by looking at the next level path or current scene
	var current_scene_path = get_tree().current_scene.scene_file_path
	
	# Check if the NEXT level is altar_restoration (meaning we're going TO the final level)
	# or if we have no next level (meaning this IS the final level)
	var going_to_altar = "altar" in next_level_path.to_lower()
	var currently_in_altar = "altar" in current_scene_path.to_lower()
	var is_final_transition = next_level_path == "" # No next level means final
	
	print("🔍 Level check - Current: ", current_scene_path, " Next: ", next_level_path)
	print("🔍 Going to altar: ", going_to_altar, " In altar: ", currently_in_altar, " Final transition: ", is_final_transition)
	
	# We want to show sacrifice UI for all levels EXCEPT when going to or in the altar
	return going_to_altar or currently_in_altar or is_final_transition

func show_sacrifice_requirement() -> bool:
	"""Show the sacrifice UI and wait for player to make a choice. Returns true if sacrifice was made."""
	print("🔮 Showing sacrifice requirement for level progression...")
	
	# Find the sacrifice UI
	var sacrifice_ui = get_tree().get_first_node_in_group("sacrifice_ui")
	if not sacrifice_ui:
		print("⚠️ No sacrifice UI found! Allowing progression...")
		return true # Allow progression if no UI is found
	
	# Get available sacrifices
	var available_sacrifices: Array[String] = []
	var all_possible = ["gravity", "friction", "collision", "jump", "run", "light"]
	
	# Check if GameManager exists
	if not GameManager:
		print("⚠️ GameManager not found! Allowing progression...")
		return true
	
	for sacrifice in all_possible:
		if GameManager.can_make_sacrifice(sacrifice):
			available_sacrifices.append(sacrifice)
	
	if available_sacrifices.is_empty():
		print("⚠️ No available sacrifices - allowing progression")
		return true
	
	print("🔮 Available sacrifices: ", available_sacrifices)
	
	# Show the sacrifice UI (make it uncancellable)
	if sacrifice_ui.has_method("show_sacrifice_options_uncancellable"):
		sacrifice_ui.show_sacrifice_options_uncancellable(level_name, 1, available_sacrifices)
	else:
		# Fallback to regular method
		sacrifice_ui.show_sacrifice_options(level_name, 1, available_sacrifices)
	
	# Wait for sacrifice to be made by awaiting the signal directly
	await sacrifice_ui.sacrifice_made
	
	print("✨ Sacrifice completed, proceeding with level transition")
	return true
