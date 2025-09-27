# SpinningBoulder.gd - Fast spinning hazard that knocks player around
extends Area2D

@export var spin_speed: float = 720.0 # Degrees per second (2 full rotations/sec)
@export var knockback_force: float = 500.0 # How hard to push player
@export var damage_player: bool = true # Whether to hurt/reset player
@export var orbit_radius: float = 100.0 # Distance from center to orbit
@export var orbit_speed: float = 180.0 # Degrees per second for orbiting

# Orbiting variables
var center_position: Vector2
var orbit_angle: float = 0.0
var should_orbit: bool = false

func _ready():
	# Set up collision detection
	body_entered.connect(_on_body_hit)
	
	# Store center position for orbiting
	center_position = global_position
	
	print("🌪️ Spinning Boulder ready - DANGER!")

func _physics_process(delta):
	# Continuous spinning
	rotation_degrees += spin_speed * delta
	
	# Optional orbiting around a point
	if should_orbit:
		orbit_angle += orbit_speed * delta
		var new_pos = center_position + Vector2(
			cos(deg_to_rad(orbit_angle)) * orbit_radius,
			sin(deg_to_rad(orbit_angle)) * orbit_radius
		)
		global_position = new_pos

func _on_body_hit(body):
	if body.is_in_group("player"):
		print("💥 Boulder hit player!")
		
		# Calculate knockback direction
		var knockback_direction = (body.global_position - global_position).normalized()
		
		# Apply knockback force to player
		if body.has_method("apply_knockback"):
			body.apply_knockback(knockback_direction * knockback_force)
		elif body.has_method("set_velocity"):
			# Direct velocity manipulation
			body.velocity += knockback_direction * knockback_force
		
		# Optional: Reset player (for instant death hazard)
		if damage_player:
			reset_player(body)

func reset_player(_player):
	"""Reset player after being hit by boulder"""
	print("🪨 Boulder hit! Resetting player...")
	
	# Reset player to last checkpoint
	get_node("/root/CheckpointManager").trigger_respawn()

# Configuration functions
func set_orbit_mode(center_pos: Vector2, radius: float = 100.0, speed: float = 180.0):
	"""Make boulder orbit around a point"""
	should_orbit = true
	center_position = center_pos
	orbit_radius = radius
	orbit_speed = speed

func set_stationary_spinner():
	"""Make boulder spin in place"""
	should_orbit = false
