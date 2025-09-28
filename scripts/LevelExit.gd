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
	
	if next_level_path != "":
		# Load next level
		get_tree().change_scene_to_file(next_level_path)
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
	# Return to main menu or show credits
	if FileAccess.file_exists("res://MainMenu.tscn"):
		get_tree().change_scene_to_file("res://main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://main_menu.tscn")

# Call this when sacrifices are made to recheck availability
func recheck_exit_availability():
	check_sacrifice_requirement()
