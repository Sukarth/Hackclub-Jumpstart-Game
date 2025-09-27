# DeathBorder.gd - Invisible boundary that kills player on contact
extends Area2D

@export var border_name: String = "death_border"
@export var show_debug_outline: bool = false  # For level design - shows red outline
@export var death_message: String = "You fell out of bounds!"
@export var respawn_delay: float = 0.5  # Brief delay before respawn

# Debug visualization
@onready var debug_sprite = $DebugSprite2D if has_node("DebugSprite2D") else null
var is_killing_player: bool = false

func _ready():
	# Add to group for easy management
	add_to_group("death_borders")
	
	# Set up debug visualization if enabled
	setup_debug_visual()
	
	print("💀 Death Border ready: ", border_name)

func _on_player_entered(body):
	if body.is_in_group("player") and not is_killing_player:
		kill_player(body)

func _on_player_exited(body):
	# Reset killing flag when player leaves (in case of respawn)
	if body.is_in_group("player"):
		is_killing_player = false

func kill_player(player):
	"""Kill the player and respawn at last checkpoint"""
	if is_killing_player:
		return  # Prevent multiple kills
		
	is_killing_player = true
	print("💀 ", death_message)
	
	# Optional: Add death effect
	spawn_death_effect(player.global_position)
	
	# Brief delay then respawn
	if respawn_delay > 0:
		await get_tree().create_timer(respawn_delay).timeout
	
	# Respawn at last checkpoint
	get_node("/root/CheckpointManager").trigger_respawn()
	
	# Reset flag after respawn
	await get_tree().process_frame
	is_killing_player = false

func spawn_death_effect(death_position: Vector2):
	"""Optional visual effect at death location"""
	# Simple particle-like effect using a temporary sprite
	var effect = Node2D.new()
	get_tree().current_scene.add_child(effect)
	effect.global_position = death_position
	
	# Create multiple small dots that spread out
	for i in range(8):
		var dot = ColorRect.new()
		dot.size = Vector2(3, 3)
		dot.color = Color.RED
		dot.position = Vector2.ZERO
		effect.add_child(dot)
		
		# Animate dots spreading out
		var angle = i * PI / 4
		var target_pos = Vector2(cos(angle), sin(angle)) * 30
		
		var tween = create_tween()
		tween.parallel().tween_property(dot, "position", target_pos, 0.3)
		tween.parallel().tween_property(dot, "modulate:a", 0.0, 0.3)
	
	# Clean up effect after animation
	await get_tree().create_timer(0.4).timeout
	if is_instance_valid(effect):
		effect.queue_free()

func setup_debug_visual():
	"""Set up debug outline for level design"""
	if not show_debug_outline:
		return
		
	# Create debug sprite if it doesn't exist
	if not debug_sprite:
		debug_sprite = Sprite2D.new()
		debug_sprite.name = "DebugSprite2D"
		add_child(debug_sprite)
	
	# Create a simple red outline texture
	var collision_shape = get_child(0) as CollisionShape2D
	if collision_shape and collision_shape.shape:
		debug_sprite.modulate = Color(1, 0, 0, 0.3)  # Semi-transparent red
		
		# For rectangle shapes, create a simple colored rectangle
		if collision_shape.shape is RectangleShape2D:
			var rect_shape = collision_shape.shape as RectangleShape2D
			var image = Image.create(int(rect_shape.size.x), int(rect_shape.size.y), false, Image.FORMAT_RGBA8)
			image.fill(Color.RED)
			var texture = ImageTexture.new()
			texture.set_image(image)
			debug_sprite.texture = texture

# Utility functions for setting up death borders in code
static func create_death_border(pos: Vector2, size: Vector2, name_override: String = "death_border"):
	"""Helper function to create death borders programmatically"""
	var border_script = preload("res://scripts/DeathBorder.gd")
	var border = Area2D.new()
	border.set_script(border_script)
	border.border_name = name_override
	border.global_position = pos
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	border.add_child(collision)
	
	return border

# For level designers: Common border configurations
func setup_level_boundaries(level_size: Vector2):
	"""Set up borders around a level area"""
	var border_thickness = 100.0
	
	# Top border
	var top_border = create_death_border(
		Vector2(level_size.x / 2.0, -border_thickness / 2.0),
		Vector2(level_size.x + border_thickness * 2.0, border_thickness),
		"top_border"
	)
	get_parent().add_child(top_border)
	
	# Bottom border  
	var bottom_border = create_death_border(
		Vector2(level_size.x / 2.0, level_size.y + border_thickness / 2.0),
		Vector2(level_size.x + border_thickness * 2.0, border_thickness),
		"bottom_border"
	)
	get_parent().add_child(bottom_border)
	
	# Left border
	var left_border = create_death_border(
		Vector2(-border_thickness / 2.0, level_size.y / 2.0),
		Vector2(border_thickness, level_size.y),
		"left_border"
	)
	get_parent().add_child(left_border)
	
	# Right border
	var right_border = create_death_border(
		Vector2(level_size.x + border_thickness / 2.0, level_size.y / 2.0),
		Vector2(border_thickness, level_size.y),
		"right_border"
	)
	get_parent().add_child(right_border)
