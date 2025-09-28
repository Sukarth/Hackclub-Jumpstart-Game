extends CharacterBody2D

# Movement constants
const BASE_SPEED = 1000.0
const BASE_JUMP_VELOCITY = -1000.0
const SLOW_SPEED = 500.0 # Speed when running is sacrificed

var spawned = false

var walking_sfx = load("res://sfx/walking.wav")

# Deadly tile detection system - Using source_id and atlas coordinates
var deadly_tiles = [
	
	{"source": 7, "atlas": Vector2i(0, 0)},
	
	{"source": 4, "atlas": Vector2i(3, 0)},
	{"source": 4, "atlas": Vector2i(3, 1)},
	{"source": 4, "atlas": Vector2i(4, 1)},
	{"source": 4, "atlas": Vector2i(4, 2)},

	{"source": 8, "atlas": Vector2i(5, 3)},
	{"source": 8, "atlas": Vector2i(1, 3)},
	{"source": 8, "atlas": Vector2i(8, 2)},
	{"source": 8, "atlas": Vector2i(8, 1)},
	{"source": 8, "atlas": Vector2i(8, 3)},
	
	{"source": 11, "atlas": Vector2i(8, 2)},
	{"source": 11, "atlas": Vector2i(8, 1)},
	{"source": 11, "atlas": Vector2i(8, 3)},
	{"source": 11, "atlas": Vector2i(5, 3)},
]
var tile_check_timer = 0.0
const TILE_CHECK_INTERVAL = 0.1 # Check every 0.1 seconds for performance
var debug_tiles = true # Set to false to stop tile coordinate spam

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
	
	# Ensure tilemaps are in the correct group for detection
	call_deferred("setup_tilemap_groups")

func _physics_process(delta: float) -> void:
	if !spawned:
		if debug_tiles:
			print("⏸️ Player not spawned yet, skipping physics")
		return
	# === GRAVITY SYSTEM ===
	if GameManager.has_gravity:
		# Normal gravity
		if not is_enough_floor():
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
			if is_enough_floor():
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
		if is_enough_floor():
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
	
	# Check for deadly tiles
	check_deadly_tiles(delta)
	 
	var treshold = 200
	
	if velocity.y > treshold:
		%Sprite.play("fall")
		%AudioPlayer.stream = null
		%AudioPlayer.stop()
	elif velocity.y < -treshold:
		%Sprite.play("jump")
		%AudioPlayer.stream = null
		%AudioPlayer.stop()
	elif abs(velocity).x < treshold:
		%Sprite.play("default")
		%AudioPlayer.stream = null
		%AudioPlayer.stop()
	else:
		%Sprite.play("move")
		if velocity.y == 0 && !%AudioPlayer.playing:
			%AudioPlayer.stream = walking_sfx
			%AudioPlayer.play()

func is_enough_floor():
	return %RayCast2D.is_colliding()

func check_deadly_tiles(delta: float):
	"""Check if player is touching any deadly tiles and kill them if so"""
	tile_check_timer += delta
	if tile_check_timer < TILE_CHECK_INTERVAL:
		return
	tile_check_timer = 0.0
	
	# Get all TileMap nodes in the scene
	var tilemaps = get_tree().get_nodes_in_group("tilemap")
	if tilemaps.is_empty():
		# Fallback: find TileMap nodes manually
		tilemaps = []
		var root = get_tree().current_scene
		_find_tilemaps_recursive(root, tilemaps)
	
	# Check each tilemap
	for tilemap in tilemaps:
		if tilemap is TileMap:
			if is_on_deadly_tile(tilemap, global_position):
				die_from_deadly_tile()
				return

func _find_tilemaps_recursive(node: Node, tilemap_list: Array):
	"""Recursively find all TileMap nodes"""
	if node is TileMap:
		tilemap_list.append(node)
	
	for child in node.get_children():
		_find_tilemaps_recursive(child, tilemap_list)

func is_on_deadly_tile(tilemap: TileMap, world_pos: Vector2) -> bool:
	"""Check if the player is on a deadly tile"""
	
	# Check multiple points around the player (center, feet, corners)
	var check_offsets = [
		Vector2(0, 0), # Center
		Vector2(0, 8), # Feet
		Vector2(-8, 8), # Bottom left
		Vector2(8, 8), # Bottom right
		Vector2(-8, 0), # Left
		Vector2(8, 0), # Right
	]
	
	var found_any_tile = false
	
	for offset in check_offsets:
		var check_world_pos = world_pos + offset
		var local_pos = tilemap.to_local(check_world_pos)
		var tile_pos = tilemap.local_to_map(local_pos)
		
		var source_id = tilemap.get_cell_source_id(0, tile_pos)
		if source_id == -1:
			continue
			
		found_any_tile = true
		var atlas_coords = tilemap.get_cell_atlas_coords(0, tile_pos)
		
		# DEBUG: Only print when we find tiles (reduce spam)
		if debug_tiles:
			print("� Found tile - {\"source\": ", source_id, ", \"atlas\": Vector2i(", atlas_coords.x, ", ", atlas_coords.y, ")},")
		
		# Check if this tile is deadly
		for deadly_tile in deadly_tiles:
			if deadly_tile.source == source_id and deadly_tile.atlas == atlas_coords:
				print("💀 DEADLY TILE DETECTED! Source: ", source_id, " Atlas: ", atlas_coords)
				return true
	
	# Only print "empty space" occasionally to avoid spam
	if debug_tiles and not found_any_tile and randf() < 0.1: # Only 10% of the time
		print("🌌 Player in empty space (no tiles found in area)")
	
	return false

func die_from_deadly_tile():
	"""Kill the player and respawn at last checkpoint"""
	print("💀 Player touched deadly tile!")
	
	# Visual feedback
	if sprite:
		var death_tween = create_tween()
		death_tween.tween_property(sprite, "modulate", Color.RED, 0.2)
		death_tween.tween_property(sprite, "modulate", Color.TRANSPARENT, 0.3)
	
	# Respawn at checkpoint after short delay
	await get_tree().create_timer(0.5).timeout
	CheckpointManager.respawn_player()
	
	# Reset visual
	if sprite:
		sprite.modulate = original_modulate

func setup_tilemap_groups():
	"""Ensure all TileMap nodes are in the tilemap group"""
	var tilemaps = []
	_find_tilemaps_recursive(get_tree().current_scene, tilemaps)
	
	for tilemap in tilemaps:
		if not tilemap.is_in_group("tilemap"):
			tilemap.add_to_group("tilemap")
	
	print("🗺️ Found and grouped ", tilemaps.size(), " tilemaps for deadly tile detection")

func add_deadly_tile(source_id: int, atlas_coords: Vector2i):
	"""Add a tile to the deadly tiles list"""
	var new_tile = {"source": source_id, "atlas": atlas_coords}
	
	# Check if already exists
	for tile in deadly_tiles:
		if tile.source == source_id and tile.atlas == atlas_coords:
			print("⚠️ Deadly tile already exists: Source ", source_id, " Atlas ", atlas_coords)
			return
	
	deadly_tiles.append(new_tile)
	print("💀 Added deadly tile: Source ", source_id, " Atlas ", atlas_coords)

func remove_deadly_tile(source_id: int, atlas_coords: Vector2i):
	"""Remove a tile from the deadly tiles list"""
	for i in range(deadly_tiles.size() - 1, -1, -1):
		var tile = deadly_tiles[i]
		if tile.source == source_id and tile.atlas == atlas_coords:
			deadly_tiles.remove_at(i)
			print("✅ Removed deadly tile: Source ", source_id, " Atlas ", atlas_coords)
			return
	print("⚠️ Deadly tile not found: Source ", source_id, " Atlas ", atlas_coords)

func get_deadly_tiles() -> Array:
	"""Get the current list of deadly tiles"""
	return deadly_tiles.duplicate()

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
		pass


func _on_sprite_animation_finished() -> void:
	spawned = true
