# CrumblingPlatform.gd - Platform that falls apart when stepped on
extends StaticBody2D

@export var crumble_delay: float = 1.0 # Time before platform starts crumbling
@export var fall_speed: float = 300.0 # How fast platform falls
@export var respawn_time: float = 5.0 # Time to respawn after falling
@export var shake_intensity: float = 2.0 # How much to shake before falling
@export var warning_blinks: int = 3 # Number of warning blinks

# Visual components
@onready var tilemap = $TileMap if has_node("TileMap") else null
@onready var collision = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var detection_area = $DetectionArea if has_node("DetectionArea") else null

# State tracking
var original_position: Vector2
var original_modulate: Color
var is_crumbling: bool = false
var is_falling: bool = false
var is_respawning: bool = false
var player_on_platform: bool = false

# Effects
var shake_tween: Tween
var blink_tween: Tween
var fall_tween: Tween

func _ready():
	# Store original state
	original_position = global_position
	if tilemap:
		original_modulate = tilemap.modulate
	
	# Set up detection area if it exists (only connect if not already connected)
	if detection_area:
		if not detection_area.body_entered.is_connected(_on_player_entered):
			detection_area.body_entered.connect(_on_player_entered)
		if not detection_area.body_exited.is_connected(_on_player_exited):
			detection_area.body_exited.connect(_on_player_exited)
	
	print("🧱 Crumbling Platform ready at: ", global_position)

func _on_player_entered(body):
	print("🔍 Crumbling Platform touched by: ", body.name, " (groups: ", body.get_groups(), ")")
	print("🔍 Platform state - crumbling: ", is_crumbling, ", falling: ", is_falling)
	
	if body.is_in_group("player") and not is_crumbling and not is_falling:
		player_on_platform = true
		print("⚠️ Starting crumbling sequence!")
		start_crumbling()
	elif body.is_in_group("player"):
		print("ℹ️ Player detected but platform already crumbling/falling")

func _on_player_exited(body):
	if body.is_in_group("player"):
		player_on_platform = false

func start_crumbling():
	"""Begin the crumbling sequence"""
	if is_crumbling or is_falling:
		return
		
	is_crumbling = true
	print("⚠️ Platform starting to crumble!")
	
	# Start warning effects
	start_warning_effects()
	
	# Wait for delay, then fall
	await get_tree().create_timer(crumble_delay).timeout
	
	if player_on_platform or is_crumbling: # Still fall even if player left
		start_falling()

func start_warning_effects():
	"""Visual/audio warnings before falling"""
	# Shaking effect
	shake_tween = create_tween()
	shake_tween.set_loops()
	var shake_offset = Vector2(randf_range(-shake_intensity, shake_intensity),
							   randf_range(-shake_intensity, shake_intensity))
	shake_tween.tween_property(self, "position", original_position + shake_offset, 0.1)
	shake_tween.tween_property(self, "position", original_position - shake_offset, 0.1)
	
	# Blinking effect
	if tilemap:
		blink_tween = create_tween()
		blink_tween.set_loops()
		blink_tween.tween_property(tilemap, "modulate:a", 0.5, 0.2)
		blink_tween.tween_property(tilemap, "modulate:a", 1.0, 0.2)

func start_falling():
	"""Make the platform fall"""
	if is_falling:
		return
		
	is_falling = true
	is_crumbling = false
	print("💥 Platform falling!")
	
	# Stop warning effects
	if shake_tween:
		shake_tween.kill()
	if blink_tween:
		blink_tween.kill()
	
	# Reset position to original (stop shaking)
	position = Vector2.ZERO
	
	# Disable collision so player falls through
	if collision:
		collision.set_deferred("disabled", true)
	
	# Fall animation
	fall_tween = create_tween()
	fall_tween.parallel().tween_property(self, "global_position:y",
										global_position.y + 1000,
										1000.0 / fall_speed)
	
	# Fade out while falling
	if tilemap:
		fall_tween.parallel().tween_property(tilemap, "modulate:a", 0.0, 1.0)
	
	# Start respawn timer
	await fall_tween.finished
	start_respawn()

func start_respawn():
	"""Respawn the platform after delay"""
	if is_respawning:
		return
		
	is_respawning = true
	print("⏳ Platform respawning in ", respawn_time, " seconds...")
	
	# Wait for respawn time
	await get_tree().create_timer(respawn_time).timeout
	
	respawn_platform()

func respawn_platform():
	"""Reset platform to original state"""
	print("✨ Platform respawned!")
	
	# Reset position
	global_position = original_position
	position = Vector2.ZERO
	
	# Reset visual state
	if tilemap:
		tilemap.modulate = original_modulate
	
	# Re-enable collision
	if collision:
		collision.disabled = false
	
	# Reset state flags
	is_crumbling = false
	is_falling = false
	is_respawning = false
	player_on_platform = false
	
	# Optional: Spawn effect
	spawn_respawn_effect()

func spawn_respawn_effect():
	"""Visual effect when platform respawns"""
	if not tilemap:
		return
		
	# Brief flash effect
	var flash_tween = create_tween()
	tilemap.modulate = Color.WHITE * 2.0 # Bright flash
	flash_tween.tween_property(tilemap, "modulate", original_modulate, 0.3)

# Public methods for level design

func force_crumble():
	"""Manually trigger crumbling (for scripted events)"""
	if not is_crumbling and not is_falling:
		start_crumbling()

func reset_platform():
	"""Immediately reset platform to original state"""
	# Kill all tweens
	if shake_tween:
		shake_tween.kill()
	if blink_tween:
		blink_tween.kill()
	if fall_tween:
		fall_tween.kill()
	
	respawn_platform()

func set_crumble_delay(delay: float):
	"""Change crumble delay at runtime"""
	crumble_delay = delay

# For debugging
func _input(event):
	if event.is_action_pressed("debug_info"):
		print("🧱 Platform state - crumbling: ", is_crumbling,
			  ", falling: ", is_falling,
			  ", respawning: ", is_respawning,
			  ", player_on: ", player_on_platform)
