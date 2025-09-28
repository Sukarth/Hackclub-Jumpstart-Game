# ShrinkPowerup.gd - Powerup that temporarily shrinks the player
extends Area2D

@export var shrink_factor: float = 0.5 # How much to shrink (0.5 = 50% size)
@export var shrink_duration: float = 10.0 # How long shrink effect lasts
@export var shrink_speed: float = 2.0 # How fast to shrink/grow
@export var respawn_time: float = 5.0 # Time before powerup respawns
@export var one_time_use: bool = false # Whether powerup respawns
@export var visual_feedback: bool = true # Show pickup effect

# Visual components
@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var particles = $CPUParticles2D if has_node("CPUParticles2D") else null
@onready var collision = $CollisionShape2D if has_node("CollisionShape2D") else null

# State tracking
var is_collected: bool = false
var is_respawning: bool = false
var original_sprite_scale: Vector2
var original_modulate: Color

# Effects
var float_tween: Tween
var pulse_tween: Tween
var respawn_tween: Tween

func _ready():
	# Connect signals
	body_entered.connect(_on_player_entered)
	
	# Store original visual state
	if sprite:
		original_sprite_scale = sprite.scale
		original_modulate = sprite.modulate
	
	# Set up visual effects
	setup_visual_effects()
	
	print("🔬 Shrink Powerup ready - Factor: ", shrink_factor, "x, Duration: ", shrink_duration, "s")

func _on_player_entered(body):
	if body.is_in_group("player") and not is_collected:
		collect_powerup(body)

func collect_powerup(player):
	"""Apply shrink effect to player"""
	if is_collected:
		return
		
	is_collected = true
	print("🔬 Shrink powerup collected!")
	
	# Apply shrink effect to player
	apply_shrink_to_player(player)
	
	# Visual/audio feedback
	spawn_collection_effect()
	
	# Hide powerup
	hide_powerup()
	
	# Start respawn timer if not one-time use
	if not one_time_use:
		start_respawn_timer()

func apply_shrink_to_player(player):
	"""Apply the shrinking effect to the player"""
	if player.has_method("apply_shrink_effect"):
		# If player has custom shrink method
		player.apply_shrink_effect(shrink_factor, shrink_duration, shrink_speed)
	else:
		# Apply shrink effect directly
		apply_direct_shrink_effect(player)

func apply_direct_shrink_effect(player):
	"""Direct shrink implementation for any player"""
	# Store original player scale if not already stored
	if not player.has_meta("original_scale"):
		player.set_meta("original_scale", player.scale)
	
	var original_scale = player.get_meta("original_scale")
	var target_scale = original_scale * shrink_factor
	
	print("🔬 Shrinking player from ", player.scale, " to ", target_scale)
	
	# Shrink animation
	var shrink_tween = create_tween()
	shrink_tween.tween_property(player, "scale", target_scale, 1.0 / shrink_speed)
	
	# Also shrink collision if it exists
	var collision_shape = player.get_node("CollisionShape2D") if player.has_node("CollisionShape2D") else null
	if collision_shape and collision_shape.shape:
		var original_collision_scale = collision_shape.get_meta("original_scale") if collision_shape.has_meta("original_scale") else Vector2.ONE
		collision_shape.set_meta("original_scale", original_collision_scale)
		shrink_tween.parallel().tween_property(collision_shape, "scale", original_collision_scale * shrink_factor, 1.0 / shrink_speed)
	
	# Start return timer
	await shrink_tween.finished
	await get_tree().create_timer(shrink_duration).timeout
	
	# Return to original size
	print("🔬 Returning player to original size")
	var grow_tween = create_tween()
	grow_tween.tween_property(player, "scale", original_scale, 1.0 / shrink_speed)
	
	if collision_shape and collision_shape.has_meta("original_scale"):
		var original_collision_scale = collision_shape.get_meta("original_scale")
		grow_tween.parallel().tween_property(collision_shape, "scale", original_collision_scale, 1.0 / shrink_speed)

func spawn_collection_effect():
	"""Visual effect when powerup is collected"""
	if not visual_feedback:
		return
	
	# Particle burst effect
	if particles:
		particles.emitting = false
		particles.amount = 50
		particles.initial_velocity_min = 100.0
		particles.initial_velocity_max = 200.0
		particles.emitting = true
		
		# Stop particles after burst
		await get_tree().create_timer(0.5).timeout
		if particles:
			particles.emitting = false
	
	# Flash effect
	if sprite:
		var flash_tween = create_tween()
		flash_tween.tween_property(sprite, "modulate", Color.WHITE * 2.0, 0.1)
		flash_tween.tween_property(sprite, "modulate", Color.TRANSPARENT, 0.3)

func hide_powerup():
	"""Hide the powerup visually and disable collision"""
	if sprite:
		sprite.visible = false
	if collision:
		collision.set_deferred("disabled", true)
	if particles:
		particles.emitting = false

func show_powerup():
	"""Show the powerup and enable collision"""
	if sprite:
		sprite.visible = true
		sprite.modulate = original_modulate
	if collision:
		collision.disabled = false
	if particles:
		particles.emitting = true

func start_respawn_timer():
	"""Start the respawn countdown"""
	if one_time_use:
		return
		
	is_respawning = true
	print("🔬 Powerup respawning in ", respawn_time, " seconds...")
	
	await get_tree().create_timer(respawn_time).timeout
	respawn_powerup()

func respawn_powerup():
	"""Make the powerup available again"""
	is_collected = false
	is_respawning = false
	
	# Show powerup with effect
	show_powerup()
	spawn_respawn_effect()
	
	print("✨ Shrink powerup respawned!")

func spawn_respawn_effect():
	"""Visual effect when powerup respawns"""
	if not sprite:
		return
	
	# Spawn with scale animation
	sprite.scale = Vector2.ZERO
	var spawn_tween = create_tween()
	spawn_tween.tween_property(sprite, "scale", original_sprite_scale, 0.5)
	spawn_tween.tween_callback(setup_visual_effects)

func setup_visual_effects():
	"""Set up floating and pulsing animations"""
	if not sprite:
		return
	
	# Floating animation
	float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(sprite, "position:y", sprite.position.y - 5, 1.0)
	float_tween.tween_property(sprite, "position:y", sprite.position.y + 5, 1.0)
	
	# Pulsing animation
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(sprite, "scale", original_sprite_scale * 1.1, 0.8)
	pulse_tween.tween_property(sprite, "scale", original_sprite_scale * 0.9, 0.8)

# Public methods for level scripting

func force_collect():
	"""Manually trigger collection (for scripted events)"""
	var player = get_tree().get_first_node_in_group("player")
	if player:
		collect_powerup(player)

func reset_powerup():
	"""Reset powerup to initial state"""
	# Kill all tweens
	if float_tween:
		float_tween.kill()
	if pulse_tween:
		pulse_tween.kill()
	if respawn_tween:
		respawn_tween.kill()
	
	# Reset state
	is_collected = false
	is_respawning = false
	
	# Show powerup
	show_powerup()
	setup_visual_effects()

func set_shrink_factor(factor: float):
	"""Change shrink factor at runtime"""
	shrink_factor = clamp(factor, 0.1, 1.0) # Prevent extreme values

func set_duration(duration: float):
	"""Change effect duration at runtime"""
	shrink_duration = max(duration, 1.0) # Minimum 1 second

# Debug method
func _input(event):
	if event.is_action_pressed("debug_info"):
		print("🔬 Shrink Powerup state - collected: ", is_collected,
			  ", respawning: ", is_respawning,
			  ", factor: ", shrink_factor,
			  ", duration: ", shrink_duration)
