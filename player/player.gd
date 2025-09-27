extends CharacterBody2D

# Movement constants
const BASE_SPEED = 300.0
const BASE_JUMP_VELOCITY = -600.0
const SLOW_SPEED = 150.0 # Speed when running is sacrificed

var spawned = false

# Visual feedback
@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
var original_modulate: Color
var glitch_tween: Tween

func _ready():
	%Sprite.play("spawn", -1, true)
	# Add to player group for trigger detection
	add_to_group("player")
	
	# Store original appearance
	if sprite:
		original_modulate = sprite.modulate
	
	# Connect to sacrifice signals from GameManager
	GameManager.physics_sacrificed.connect(_on_physics_sacrificed)
	GameManager.ability_sacrificed.connect(_on_ability_sacrificed)
	GameManager.visual_sacrificed.connect(_on_visual_sacrificed)

func _physics_process(delta: float) -> void:
	if !spawned:
		return
	# === GRAVITY SYSTEM ===
	if GameManager.has_gravity:
		# Normal gravity
		if not is_on_floor():
			velocity += get_gravity() * delta
	else:
		# Zero gravity - floating controls with W/S
		if Input.is_action_pressed("move_up"):
			velocity.y = - BASE_SPEED * 0.7
		elif Input.is_action_pressed("move_down"):
			velocity.y = BASE_SPEED * 0.7
		else:
			# Gradual stop in zero-g
			velocity.y = move_toward(velocity.y, 0, BASE_SPEED * 2 * delta)

	# === JUMPING SYSTEM ===
	if Input.is_action_pressed("jump") and GameManager.can_jump:
		if GameManager.has_gravity:
			# Normal jump (only on ground)
			if is_on_floor():
				velocity.y = BASE_JUMP_VELOCITY
		else:
			# Zero-g "push" (can use anywhere)
			velocity.y = BASE_JUMP_VELOCITY * 0.4

	# === MOVEMENT SYSTEM ===
	var direction := 0.0
	if Input.is_action_pressed("move_left"):
		direction -= 1.0
	if Input.is_action_pressed("move_right"):
		direction += 1.0
	
	var current_speed: float
	
	if GameManager.can_run:
		current_speed = BASE_SPEED
	else:
		current_speed = SLOW_SPEED # Slower when running is sacrificed
	
	if direction != 0:
		velocity.x = direction * current_speed
		# Flip sprite if it exists
		if sprite:
			sprite.flip_h = (direction < 0)
	else:
		# === FRICTION SYSTEM ===
		if GameManager.has_friction:
			# Normal stopping
			velocity.x = move_toward(velocity.x, 0, current_speed)
		else:
			# Slippery - momentum continues
			velocity.x *= 0.985 # Very gradual slowdown

	# === COLLISION SYSTEM ===
	if GameManager.has_collision:
		# Normal physics
		move_and_slide()
		
		# === MOVING PLATFORM SUPPORT ===
		# If player is on floor and the floor is moving, move with it
		if is_on_floor():
			for i in get_slide_collision_count():
				var collision = get_slide_collision(i)
				var collider = collision.get_collider()
				# Check if we're standing on a moving platform
				if collider and collider.has_method("get_velocity"):
					# Move with the platform
					global_position += collider.velocity * delta
				elif collider and collider.get_script() and collider.get_script().resource_path.contains("MovingPlatform"):
					# For our custom moving platforms, get their movement
					if collider.has_method("get_platform_velocity"):
						global_position += collider.get_platform_velocity() * delta
	else:
		# Phase through everything
		global_position += velocity * delta
	
	%Sprite.flip_h = velocity.x > 0
	 
	var treshold = 200
	
	if velocity.y > treshold:
		%Sprite.play("fall")
	elif velocity.y < -treshold:
		%Sprite.play("jump")
	elif abs(velocity).x < treshold:
		%Sprite.play("default")
	else:
		%Sprite.play("move")

# Sacrifice reaction functions
func _on_physics_sacrificed(law_type: String):
	if not sprite:
		return
		
	match law_type:
		"gravity":
			# Cyan tint for gravity loss
			tint_player(Color.CYAN)
			print("🌌 Player: Floating freely now!")
		"friction":
			# Magenta tint for friction loss
			tint_player(Color.MAGENTA)
			print("🧊 Player: Everything feels slippery!")
		"collision":
			# Semi-transparent for phasing
			sprite.modulate.a = 0.6
			start_glitch_effect()
			print("👻 Player: Phasing through reality!")

func _on_ability_sacrificed(ability_type: String):
	match ability_type:
		"jump":
			print("⬇️ Player: Legs feel heavy, can't jump!")
		"run":
			print("🐌 Player: Moving like walking through mud!")
		"light":
			if sprite:
				sprite.modulate = sprite.modulate.darkened(0.5)
			print("🕳️ Player: The world grows darker!")

func _on_visual_sacrificed(_visual_type: String):
	if sprite:
		# Increase visual corruption
		sprite.modulate = sprite.modulate.lerp(Color.RED, 0.2)
		print("📺 Player: Reality glitches more...")

# Visual effect functions
func tint_player(color: Color):
	if not sprite:
		return
		
	# Smooth color transition
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", color, 0.5)

func start_glitch_effect():
	if not sprite:
		return
		
	# Stop existing glitch
	if glitch_tween:
		glitch_tween.kill()
	
	# Start glitching position
	glitch_tween = create_tween()
	glitch_tween.set_loops()
	glitch_tween.tween_callback(_do_glitch).set_delay(0.3)

# Knockback system for hazards (boulders, enemies, etc.)
func apply_knockback(force: Vector2):
	"""Apply knockback force to player"""
	print("💥 Player knocked back with force: ", force)
	velocity += force
	
	# Optional: Brief invincibility or stun
	# Add visual feedback
	if sprite:
		var flash_tween = create_tween()
		flash_tween.tween_property(sprite, "modulate", Color.RED, 0.1)
		flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _do_glitch():
	if not sprite or GameManager.has_collision:
		return
		
	# Random position offset
	var original_pos = sprite.position
	var glitch_offset = Vector2(
		randf_range(-4, 4),
		randf_range(-4, 4)
	)
	
	# Quick glitch then return
	sprite.position = original_pos + glitch_offset
	await get_tree().create_timer(0.05).timeout
	sprite.position = original_pos

func _input(_event):
	var sacrifice_ui = get_tree().get_first_node_in_group("sacrifice_ui")
	if sacrifice_ui and sacrifice_ui.visible:
		return


func _on_sprite_animation_finished() -> void:
	spawned = true
