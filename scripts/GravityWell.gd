# GravityWell.gd - Creates gravitational pull effect on nearby objects
extends Area2D

@export var gravity_strength: float = 500.0 # Strength of gravitational pull
@export var max_range: float = 200.0 # Maximum range of effect
@export var min_range: float = 20.0 # Minimum range (prevents infinite acceleration)
@export var affects_player: bool = true # Whether to affect player
@export var affects_objects: bool = true # Whether to affect other physics objects
@export var well_type: WellType = WellType.PULL # Pull towards or push away
@export var visual_effect: bool = true # Show swirling particle effect
@export var debug_range: bool = false # Show range circles in editor

enum WellType {
	PULL, # Attracts objects (black hole effect)
	PUSH, # Repels objects (explosion effect)
	ORBIT # Creates orbital motion
}

# Visual components
@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var particles = $CPUParticles2D if has_node("CPUParticles2D") else null

# Physics tracking
var affected_bodies: Array[RigidBody2D] = []
var player_body: CharacterBody2D = null

# Visual effects
var rotation_speed: float = 2.0
var pulse_tween: Tween

func _ready():
	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set up collision detection
	monitoring = true
	monitorable = false
	
	# Set up visual effects
	setup_visual_effects()
	
	# Set up collision shape to match max_range
	setup_collision_shape()
	
	print("🌌 Gravity Well ready - Type: ", WellType.keys()[well_type], ", Strength: ", gravity_strength)

func _physics_process(delta):
	# Apply gravitational effects to all affected bodies
	for body in affected_bodies:
		if is_instance_valid(body):
			apply_gravity_to_body(body, delta)
	
	# Handle player separately (CharacterBody2D)
	if player_body and is_instance_valid(player_body):
		apply_gravity_to_player(player_body, delta)
	
	# Update visual effects
	update_visual_effects(delta)

func _on_body_entered(body):
	print("🌌 Body entered gravity well: ", body.name, " (groups: ", body.get_groups(), ")")
	
	if body.is_in_group("player") and affects_player:
		player_body = body as CharacterBody2D
		print("👨‍🚀 Player entered gravity well!")
	elif body is RigidBody2D and affects_objects:
		affected_bodies.append(body)
		print("📦 Object entered gravity well!")

func _on_body_exited(body):
	print("🌌 Body exited gravity well: ", body.name)
	
	if body.is_in_group("player"):
		player_body = null
		print("👨‍🚀 Player exited gravity well!")
	elif body is RigidBody2D:
		affected_bodies.erase(body)
		print("📦 Object exited gravity well!")

func apply_gravity_to_player(player: CharacterBody2D, delta: float):
	"""Apply gravitational force to player (CharacterBody2D)"""
	var distance_vec = global_position - player.global_position
	var distance = distance_vec.length()
	
	# Don't apply force if too close (prevents infinite acceleration)
	if distance < min_range:
		return
	
	# Calculate force based on distance (inverse square law, but clamped for gameplay)
	var force_magnitude = gravity_strength / max(distance * distance / (max_range * max_range), 1.0)
	var force_direction = distance_vec.normalized()
	
	# Apply different effects based on well type
	var final_force: Vector2
	match well_type:
		WellType.PULL:
			final_force = force_direction * force_magnitude
		WellType.PUSH:
			final_force = - force_direction * force_magnitude
		WellType.ORBIT:
			# Create perpendicular force for orbital motion
			var tangent = Vector2(-force_direction.y, force_direction.x)
			final_force = (force_direction * force_magnitude * 0.3) + (tangent * force_magnitude * 0.7)
	
	# Apply force to player velocity
	if player.has_method("apply_gravity_well_force"):
		# If player has custom method for gravity wells
		player.apply_gravity_well_force(final_force * delta)
	else:
		# Direct velocity modification
		player.velocity += final_force * delta

func apply_gravity_to_body(body: RigidBody2D, _delta: float):
	"""Apply gravitational force to RigidBody2D objects"""
	var distance_vec = global_position - body.global_position
	var distance = distance_vec.length()
	
	if distance < min_range:
		return
	
	var force_magnitude = gravity_strength / max(distance * distance / (max_range * max_range), 1.0)
	var force_direction = distance_vec.normalized()
	
	var final_force: Vector2
	match well_type:
		WellType.PULL:
			final_force = force_direction * force_magnitude
		WellType.PUSH:
			final_force = - force_direction * force_magnitude
		WellType.ORBIT:
			var tangent = Vector2(-force_direction.y, force_direction.x)
			final_force = (force_direction * force_magnitude * 0.3) + (tangent * force_magnitude * 0.7)
	
	# Apply force to RigidBody2D
	body.apply_central_force(final_force)

func setup_visual_effects():
	"""Set up particle effects and sprite animation"""
	if particles and visual_effect:
		# Configure particles based on well type
		match well_type:
			WellType.PULL:
				particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
				particles.direction = Vector2(0, 0) # Inward spiral
				particles.initial_velocity_min = 50.0
				particles.initial_velocity_max = 100.0
				particles.gravity = Vector2.ZERO
				particles.radial_accel_min = -200.0 # Pull inward
				particles.radial_accel_max = -300.0
				particles.color = Color.PURPLE
			WellType.PUSH:
				particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
				particles.direction = Vector2(0, -1)
				particles.spread = 45.0
				particles.initial_velocity_min = 100.0
				particles.initial_velocity_max = 200.0
				particles.radial_accel_min = 100.0 # Push outward
				particles.radial_accel_max = 200.0
				particles.color = Color.ORANGE
			WellType.ORBIT:
				particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
				particles.direction = Vector2(1, 0)
				particles.initial_velocity_min = 80.0
				particles.initial_velocity_max = 120.0
				particles.tangential_accel_min = 100.0 # Orbital motion
				particles.tangential_accel_max = 150.0
				particles.color = Color.CYAN
		
		particles.emitting = true
	
	# Set up sprite animation
	if sprite:
		match well_type:
			WellType.PULL:
				sprite.modulate = Color.PURPLE
			WellType.PUSH:
				sprite.modulate = Color.ORANGE
			WellType.ORBIT:
				sprite.modulate = Color.CYAN

func setup_collision_shape():
	"""Set up collision shape to match max_range"""
	var collision_shape = $CollisionShape2D if has_node("CollisionShape2D") else null
	if collision_shape and collision_shape.shape is CircleShape2D:
		var circle_shape = collision_shape.shape as CircleShape2D
		circle_shape.radius = max_range

func update_visual_effects(delta: float):
	"""Update rotating and pulsing effects"""
	if sprite:
		sprite.rotation += rotation_speed * delta
		
		# Pulsing effect
		if not pulse_tween or not pulse_tween.is_valid():
			pulse_tween = create_tween()
			pulse_tween.set_loops()
			pulse_tween.tween_property(sprite, "scale", sprite.scale * 1.2, 1.0)
			pulse_tween.tween_property(sprite, "scale", sprite.scale, 1.0)

# Public methods for level scripting

func set_gravity_strength(strength: float):
	"""Change gravity strength at runtime"""
	gravity_strength = strength

func toggle_well_type():
	"""Cycle through well types"""
	match well_type:
		WellType.PULL:
			well_type = WellType.PUSH
		WellType.PUSH:
			well_type = WellType.ORBIT
		WellType.ORBIT:
			well_type = WellType.PULL
	
	setup_visual_effects()
	print("🌌 Well type changed to: ", WellType.keys()[well_type])

func activate_well(duration: float = 0.0):
	"""Activate gravity well (useful for timed effects)"""
	set_physics_process(true)
	monitoring = true
	if particles:
		particles.emitting = true
	
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		deactivate_well()

func deactivate_well():
	"""Deactivate gravity well"""
	set_physics_process(false)
	monitoring = false
	if particles:
		particles.emitting = false
	
	# Clear all affected bodies
	affected_bodies.clear()
	player_body = null

# Debug visualization
func _draw():
	if debug_range and Engine.is_editor_hint():
		# Draw range circles
		draw_circle(Vector2.ZERO, max_range, Color.WHITE, false, 2.0)
		draw_circle(Vector2.ZERO, min_range, Color.RED, false, 2.0)