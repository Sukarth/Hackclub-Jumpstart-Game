# SacrificeTrigger.gd - Invisible areas that trigger sacrifice requirements
extends Area2D

# Configuration (set in editor or script)
@export var trigger_message: String = "Progress requires sacrifice..."
@export var required_sacrifices: Array[String] = []  # Specific sacrifices, or empty for any
@export var sacrifice_count: int = 1  # How many sacrifices needed
@export var one_time_only: bool = true  # Trigger only once
@export var level_name_override: String = ""  # Custom level name for UI

# Internal state
var has_triggered: bool = false
var level_manager: Node = null

func _ready():
	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Find LevelManager (will be created in main scene)
	level_manager = get_tree().get_first_node_in_group("level_manager")
	if not level_manager:
		print("Warning: SacrificeTrigger couldn't find LevelManager")
	
	print("⚡ SacrificeTrigger ready: '", trigger_message, "'")

func _on_body_entered(body: Node2D):
	# Check if it's the player
	if not body.is_in_group("player") and not body.name.to_lower().contains("player"):
		return
	
	if one_time_only and has_triggered:
		print("⚡ SacrificeTrigger already used")
		return
	
	print("⚡ Player entered SacrificeTrigger")
	trigger_sacrifice_requirement()

func _on_body_exited(body: Node2D):
	# Optional: Handle player leaving trigger area
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		print("⚡ Player left SacrificeTrigger area")

func trigger_sacrifice_requirement():
	print("🔮 Triggering sacrifice requirement...")
	print("  Message: ", trigger_message)
	
	has_triggered = true
	
	# Use LevelManager if available
	if level_manager and level_manager.has_method("trigger_sacrifice_requirement"):
		level_manager.trigger_sacrifice_requirement(trigger_message)
	else:
		# Fallback - direct GameManager interaction
		trigger_sacrifice_fallback()

func trigger_sacrifice_fallback():
	"""Direct sacrifice triggering when no LevelManager is available"""
	print("⚠️ Using fallback sacrifice trigger")
	
	# Find SacrificeChoice UI in the scene
	var sacrifice_ui = get_tree().get_first_node_in_group("sacrifice_ui")
	if not sacrifice_ui:
		# Try to find by node name
		sacrifice_ui = get_tree().get_nodes_in_group("ui").filter(
			func(node): return node.name.to_lower().contains("sacrifice")
		).front()
	
	if sacrifice_ui and sacrifice_ui.has_method("show_sacrifice_options"):
		var level_name = level_name_override if level_name_override else "Unknown Area"
		var available_sacrifices = get_available_sacrifices()
		
		if available_sacrifices.is_empty():
			print("⚠️ No available sacrifices!")
			return
		
		sacrifice_ui.show_sacrifice_options(level_name, sacrifice_count, available_sacrifices)
	else:
		print("⚠️ No SacrificeChoice UI found! Adding debug sacrifice...")
		# Emergency fallback - just sacrifice gravity
		GameManager.sacrifice_physics_law("gravity")

func get_available_sacrifices() -> Array[String]:
	"""Get list of sacrifices that can still be made"""
	var available = []
	
	if required_sacrifices.is_empty():
		# Default: all possible sacrifices
		var all_sacrifices = ["gravity", "friction", "collision", "jump", "run", "light"]
		for sacrifice in all_sacrifices:
			if GameManager.can_make_sacrifice(sacrifice):
				available.append(sacrifice)
	else:
		# Specific required sacrifices
		for sacrifice in required_sacrifices:
			if GameManager.can_make_sacrifice(sacrifice):
				available.append(sacrifice)
	
	return available

func reset_trigger():
	"""Reset the trigger so it can be used again"""
	has_triggered = false
	print("⚡ SacrificeTrigger reset")

# Helper function to setup trigger from code
func configure_trigger(message: String, sacrifices: Array[String] = [], count: int = 1, one_time: bool = true):
	trigger_message = message
	required_sacrifices = sacrifices
	sacrifice_count = count
	one_time_only = one_time
	print("⚙️ SacrificeTrigger configured: ", message)

# Debug visualization (only in debug builds)
func _draw():
	if OS.is_debug_build():
		# Draw trigger area outline in debug mode
		var shape = $CollisionShape2D.shape if has_node("CollisionShape2D") else null
		if shape and shape is RectangleShape2D:
			var rect = Rect2(-shape.size/2, shape.size)
			var color = Color.YELLOW if not has_triggered else Color.GRAY
			color.a = 0.3
			draw_rect(rect, color)
			# Draw trigger message
			draw_string(get_theme_default_font(), Vector2(-50, -shape.size.y/2 - 10), 
					   trigger_message, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, color)

# Make this node detectable by groups
func _enter_tree():
	add_to_group("sacrifice_triggers")