extends CharacterBody2D

# Movement Constants
const SPEED = 300.0       # Horizontal movement speed (pixels/second)
const JUMP_VELOCITY = -600.0 # Jump strength (negative because Y goes down)

# Gravity - you can get it from project settings or define it here
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Other variables you might need
var air_jumps = 1         # For a double jump
var current_air_jumps = 0

# Variables for "game feel" techniques (we'll initialize them later)
var coyote_timer = 0.0
const COYOTE_TIME_THRESHOLD = 0.1 # 100 milliseconds of coyote time

var jump_buffer_timer = 0.0
const JUMP_BUFFER_TIME_THRESHOLD = 0.1 # 100 milliseconds for jump buffer

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Reset air jumps and coyote time when on the floor
		current_air_jumps = air_jumps
		coyote_timer = COYOTE_TIME_THRESHOLD # Reload coyote time

	# Update timers
	if coyote_timer > 0:
		coyote_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

	# Handle Jump input (with buffer and coyote time)
	if Input.is_action_just_pressed("jump"): # "jump" is an action defined in InputMap
		jump_buffer_timer = JUMP_BUFFER_TIME_THRESHOLD

	if jump_buffer_timer > 0:
		if is_on_floor() or coyote_timer > 0: # Normal jump or coyote time jump
			velocity.y = JUMP_VELOCITY
			jump_buffer_timer = 0 # Consume buffer
			coyote_timer = 0 # Consume coyote time if used
		elif current_air_jumps > 0: # Air jump (double jump, etc.)
			velocity.y = JUMP_VELOCITY * 0.8 # Perhaps a bit weaker
			current_air_jumps -= 1
			jump_buffer_timer = 0 # Consume buffer

	# Handle Horizontal input
	var direction = Input.get_axis("move_left", "move_right") # "move_left" & "move_right" from InputMap

	# Movement with simple acceleration/deceleration (you can make this more complex)
	if direction:
		# We use move_toward for basic acceleration/deceleration
		velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * 2.0 * delta) # Last value is acceleration
		# Flip the sprite
		if %Sprite: # Ensure the node exists
			%Sprite.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 2.0 * delta) # Decelerate to a stop

	move_and_slide()

	# Update animations (simplified)
	update_animations()
	
func update_animations():
	if not %Sprite: return # Exit if no AnimatedSprite2D

	if not is_on_floor():
		if velocity.y < 0:
			%Sprite.play("jump")
		else:
			%Sprite.play("fall")
	else:
		if abs(velocity.x) > 5: # A small threshold to avoid switching to "run" if barely moving
			%Sprite.play("run")
		else:
			%Sprite.play("idle")
