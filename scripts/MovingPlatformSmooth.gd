extends AnimatableBody2D

@export var move_distance: float = 300.0
@export var move_speed: float = 5.0  # Duration in seconds
@export var move_direction: Vector2 = Vector2.RIGHT

var start_position: Vector2
var end_position: Vector2
var tween: Tween

func _ready():
	start_position = global_position
	end_position = start_position + (move_direction * move_distance)
	
	# Create tween for smooth movement
	tween = create_tween()
	tween.set_loops()  # Loop forever
	start_movement()

func start_movement():
	# Move to end, then back to start, repeat
	tween.tween_property(self, "global_position", end_position, move_speed)
	tween.tween_property(self, "global_position", start_position, move_speed)
