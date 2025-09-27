# GameManager.gd - Global Singleton for Sacrifice System
extends Node

# Sacrifice signals - other nodes can listen to these
signal physics_sacrificed(law_type: String)
signal ability_sacrificed(ability_type: String)
signal visual_sacrificed(visual_type: String)

# Physics Laws State
var has_gravity: bool = true
var has_friction: bool = true
var has_collision: bool = true

# Player Abilities State  
var can_jump: bool = true
var can_run: bool = true
var has_light: bool = true

# Visual/Audio State
var has_visuals: bool = true
var has_audio: bool = true
var visual_corruption_level: int = 0

# Game progression
var sacrifice_points: int = 0
var current_level: int = 1
var sacrifices_made: Array[String] = []

# Sacrifice functions
func sacrifice_physics_law(law_type: String):
	if law_type in sacrifices_made:
		print("Already sacrificed: ", law_type)
		return
		
	match law_type:
		"gravity":
			has_gravity = false
			physics_sacrificed.emit("gravity")
			print("🌌 Gravity sacrificed - reality shifts...")
		"friction": 
			has_friction = false
			physics_sacrificed.emit("friction")
			print("🧊 Friction sacrificed - surfaces become slippery...")
		"collision":
			has_collision = false
			physics_sacrificed.emit("collision")
			print("👻 Collision sacrificed - you phase through matter...")
	
	sacrifices_made.append(law_type)
	sacrifice_points += 1

func sacrifice_ability(ability_type: String):
	if ability_type in sacrifices_made:
		print("Already sacrificed: ", ability_type)
		return
		
	match ability_type:
		"jump":
			can_jump = false
			ability_sacrificed.emit("jump")
			print("⬇️ Jumping sacrificed - bound to the ground...")
		"run":
			can_run = false
			ability_sacrificed.emit("run")
			print("🐌 Running sacrificed - movement slowed...")
		"light":
			has_light = false
			ability_sacrificed.emit("light")
			print("🕳️ Light sacrificed - darkness consumes...")
	
	sacrifices_made.append(ability_type)
	sacrifice_points += 1

func sacrifice_visual(visual_type: String):
	visual_corruption_level += 1
	visual_sacrificed.emit(visual_type)
	sacrifice_points += 1
	sacrifices_made.append(visual_type)
	print("📺 Visual corruption increases...")

# Utility functions
func can_make_sacrifice(sacrifice_name: String) -> bool:
	return not (sacrifice_name in sacrifices_made)

func get_sacrifice_count() -> int:
	return sacrifices_made.size()

func reset_all_sacrifices():
	# For testing or new game
	has_gravity = true
	has_friction = true
	has_collision = true
	can_jump = true
	can_run = true
	has_light = true
	has_visuals = true
	has_audio = true
	visual_corruption_level = 0
	sacrifice_points = 0
	current_level = 1
	sacrifices_made.clear()
	print("🔄 All sacrifices reset")

# Debug function for testing
func _input(event):
	# Temporary test controls (remove later)
	if event.is_action_pressed("ui_select"): # Enter/Space
		sacrifice_physics_law("gravity")
	elif event.is_action_pressed("ui_cancel"): # Escape
		sacrifice_physics_law("friction")
	elif Input.is_action_just_pressed("ui_right") and event.is_pressed():
		sacrifice_ability("jump")