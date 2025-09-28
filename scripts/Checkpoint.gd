# Checkpoint.gd - Save player progress and respawn point
extends Area2D

@export var checkpoint_id: String = "checkpoint_1"
@export var is_level_start: bool = false # Mark starting checkpoint
@export var show_activation_effect: bool = true

# Visual feedback
@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
var is_activated: bool = false
var original_sprite = "default"
var activated_sprite = "active"

func _ready():
	# Connect signals if not already connected (scene connections take priority)
	if not body_entered.is_connected(_on_player_entered):
		body_entered.connect(_on_player_entered)
	
	# Set up visual feedback
	if sprite:
		sprite.play("default")
	
	# Auto-activate if it's the level start
	if is_level_start:
		print("🏁 Auto-activating start checkpoint: ", checkpoint_id)
		activate_checkpoint()
		get_node("/root/CheckpointManager").set_active_checkpoint(self)
	
	print("📍 Checkpoint ready: ", checkpoint_id)

func _on_player_entered(body):
	if body.is_in_group("player"):
		if not is_activated:
			activate_checkpoint()
			
			# Save this checkpoint as active
			get_node("/root/CheckpointManager").set_active_checkpoint(self)
			
			print("✅ Checkpoint activated: ", checkpoint_id)
		else:
			# Silently set as active checkpoint (no spam)
			get_node("/root/CheckpointManager").set_active_checkpoint(self)

func activate_checkpoint():
	"""Activate this checkpoint with visual feedback"""
	is_activated = true
	
	if sprite and show_activation_effect:
		# Color change effect
		$Sprite2D.play("active")
		# Optional: Particle effect or sound
		spawn_activation_effect()

func spawn_activation_effect():
	"""Optional visual effect when checkpoint activates"""
	# Simple scale pulse effect
	if sprite:
		var pulse_tween = create_tween()
		pulse_tween.tween_property(sprite, "scale", sprite.scale * 1.2, 0.2)
		pulse_tween.tween_property(sprite, "scale", sprite.scale, 0.2)

func get_spawn_position() -> Vector2:
	"""Return position where player should respawn"""
	return global_position

# For manual activation (if needed)
func force_activate():
	activate_checkpoint()
