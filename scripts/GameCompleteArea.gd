# GameCompleteArea.gd - Invisible trigger for game completion
extends Area2D

# Game completion settings
@export var completion_text: String = "The Construct Restored"
@export var auto_trigger: bool = true

signal game_completed

func _ready():
	# Ensure proper setup
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect player detection
	body_entered.connect(_on_player_entered)
	print("🔗 Connected body_entered signal")
	
	# Check if we have a collision shape
	var collision_shape = get_node("CollisionShape2D")
	if collision_shape and collision_shape.shape:
		print("✅ CollisionShape2D found with shape: ", collision_shape.shape)
	else:
		print("❌ WARNING: No collision shape found! Area won't detect player.")
	
	# Make invisible in game (visible in editor for placement)
	if not Engine.is_editor_hint():
		modulate.a = 0.0
		print("👻 Made invisible for gameplay")
	else:
		modulate.a = 0.3
		print("👁️ Visible in editor")
	
	print("🏆 Game Complete Area ready: '", completion_text, "'")
	print("🎯 Auto-trigger enabled: ", auto_trigger)

func _on_player_entered(body: Node2D):
	"""Triggered when player enters the completion area"""
	print("🔍 GameCompleteArea: Body entered - ", body.name, " Groups: ", body.get_groups())
	
	if not body.is_in_group("player"):
		print("⚠️ Body is not in 'player' group, ignoring")
		return
	
	print("✅ Player detected! Auto-trigger: ", auto_trigger)
	
	if auto_trigger:
		trigger_game_completion()
	else:
		print("⏸️ Auto-trigger disabled")

func trigger_game_completion():
	"""Start the game completion sequence"""
	print("🎉 GAME COMPLETED! Starting ending sequence...")
	print("🔍 Completion text: ", completion_text)
	
	# Emit signal and start ending sequence
	game_completed.emit()
	print("📡 Game completed signal emitted")
	
	# Start the dramatic ending sequence
	if has_node("/root/EndingManager"):
		print("✅ EndingManager found, starting dramatic sequence")
		get_node("/root/EndingManager").start_ending_sequence(completion_text)
	else:
		print("⚠️ EndingManager not found, using fallback transition")
		# Fallback: direct transition to credits
		await TransitionManager.transition_to_scene("res://credits.tscn", "Game Complete!")

func set_completion_text(text: String):
	"""Set the completion text for this area"""
	completion_text = text
	print("📝 Game completion text set: ", text)