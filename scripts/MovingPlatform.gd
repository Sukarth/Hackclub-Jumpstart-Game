# MovingPlatform.gd - Simple moving platform
extends CharacterBody2D

@export var move_distance: float = 200.0 # How far to move
@export var move_speed: float = 100.0 # How fast to move
@export var move_direction: Vector2 = Vector2.RIGHT # Direction (RIGHT, UP, etc.)

var start_position: Vector2
var target_position: Vector2
var moving_to_target: bool = true

func _ready():
	start_position = global_position
	target_position = start_position + (move_direction * move_distance)

func _physics_process(_delta):
	var target = target_position if moving_to_target else start_position
	
	# Move towards target
	velocity = global_position.direction_to(target) * move_speed
	move_and_slide()
	
	# Check if reached target
	if global_position.distance_to(target) < 5.0:
		moving_to_target = !moving_to_target