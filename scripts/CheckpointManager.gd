# CheckpointManager.gd - Global checkpoint system
extends Node

# Current active checkpoint
var active_checkpoint: Area2D = null
var player_reference: CharacterBody2D = null

func _ready():
	print("📍 CheckpointManager ready")
	# Find player reference
	call_deferred("find_player")

func find_player():
	"""Find player in scene"""
	player_reference = get_tree().get_first_node_in_group("player")
	if player_reference:
		print("📍 Player found for checkpoint system")

func set_active_checkpoint(checkpoint: Area2D):
	"""Set the current active checkpoint"""
	# Only print if it's a different checkpoint
	if active_checkpoint != checkpoint:
		active_checkpoint = checkpoint
		print("📍 Active checkpoint set: ", checkpoint.checkpoint_id)
	else:
		active_checkpoint = checkpoint

func respawn_player():
	"""Respawn player at active checkpoint"""
	if not player_reference:
		find_player()
	
	if not player_reference:
		print("⚠️ No player found for respawn!")
		return
	
	if active_checkpoint:
		print("🔄 Respawning player at: ", active_checkpoint.checkpoint_id)
		player_reference.global_position = active_checkpoint.get_spawn_position()
		player_reference.velocity = Vector2.ZERO
		
		# Optional: Brief invincibility after respawn
		make_player_invincible(1.0)
	else:
		print("⚠️ No active checkpoint for respawn!")

func make_player_invincible(duration: float):
	"""Make player invincible for a short time after respawn"""
	if player_reference and player_reference.has_method("set_invincible"):
		player_reference.set_invincible(duration)

func reset_to_level_start():
	"""Reset to the level's starting checkpoint"""
	var start_checkpoint = get_tree().get_nodes_in_group("checkpoints").filter(
		func(cp): return cp.is_level_start
	).front()
	
	if start_checkpoint:
		set_active_checkpoint(start_checkpoint)
		respawn_player()

# Call this when player dies/falls/gets crushed
func trigger_respawn():
	"""Public function to trigger player respawn"""
	respawn_player()
