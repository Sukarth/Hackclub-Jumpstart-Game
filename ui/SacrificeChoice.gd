# SacrificeChoice.gd - UI for selecting sacrifices to progress
extends Control

# Signals
signal sacrifice_made(sacrifice_type: String, sacrifice_name: String)
signal choice_cancelled

# UI References (will connect in editor)
@onready var background_panel = $BackgroundPanel if has_node("BackgroundPanel") else null
@onready var title_label = $VBoxContainer/TitleLabel if has_node("VBoxContainer/TitleLabel") else null
@onready var description_label = $VBoxContainer/DescriptionLabel if has_node("VBoxContainer/DescriptionLabel") else null
@onready var choice_container = $VBoxContainer/ChoiceContainer if has_node("VBoxContainer/ChoiceContainer") else null
@onready var cancel_button = $VBoxContainer/CancelButton if has_node("VBoxContainer/CancelButton") else null

# Current sacrifice options
var current_choices: Array[Dictionary] = []

func _ready():
	# Add to groups for easy finding
	add_to_group("sacrifice_ui")
	add_to_group("ui")
	
	# Enable processing during pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect cancel button if it exists
	if cancel_button:
		cancel_button.process_mode = Node.PROCESS_MODE_ALWAYS
		cancel_button.pressed.connect(_on_cancel_pressed)
	
	# Start hidden
	hide()
	
	print("📝 SacrificeChoice UI ready")

# Show sacrifice options for level progression
func show_sacrifice_options(level_name: String, required_count: int = 1, sacrifice_types: Array[String] = []):
	print("🔮 Showing sacrifice options for: ", level_name)
	
	if title_label:
		title_label.text = "Sacrifice Required: " + level_name
	if description_label:
		description_label.text = "Choose " + str(required_count) + " sacrifice(s) to progress..."
	
	# Clear previous choices
	clear_choices()
	
	# Create sacrifice options
	if sacrifice_types.is_empty():
		# Default sacrifice options
		create_default_sacrifice_options()
	else:
		# Specific sacrifice types requested
		for sac_type in sacrifice_types:
			if GameManager.can_make_sacrifice(sac_type):
				create_sacrifice_button(sac_type)
	
	# Show the UI
	show()
	# Pause the game
	get_tree().paused = true

func create_default_sacrifice_options():
	# Physics laws
	var physics_options = ["gravity", "friction", "collision"]
	for physics in physics_options:
		if GameManager.can_make_sacrifice(physics):
			create_sacrifice_button(physics)
	
	# Abilities  
	var ability_options = ["jump", "run", "light"]
	for ability in ability_options:
		if GameManager.can_make_sacrifice(ability):
			create_sacrifice_button(ability)

func create_sacrifice_button(sacrifice_name: String):
	if not choice_container:
		print("Warning: No choice container found!")
		return
	
	var button = Button.new()
	var sacrifice_info = get_sacrifice_info(sacrifice_name)
	
	# Enable button to work during pause
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	
	button.text = sacrifice_info.title
	button.tooltip_text = sacrifice_info.description
	button.custom_minimum_size = Vector2(300, 50)
	
	# Style the button based on sacrifice type
	if sacrifice_name in ["gravity", "friction", "collision"]:
		button.modulate = Color.CYAN
	elif sacrifice_name in ["jump", "run", "light"]:
		button.modulate = Color.YELLOW
	else:
		button.modulate = Color.MAGENTA
	
	# Connect button press
	button.pressed.connect(_on_sacrifice_chosen.bind(sacrifice_name, sacrifice_info.type))
	
	choice_container.add_child(button)
	current_choices.append({
		"name": sacrifice_name,
		"type": sacrifice_info.type,
		"button": button
	})

func get_sacrifice_info(sacrifice_name: String) -> Dictionary:
	match sacrifice_name:
		"gravity":
			return {
				"title": "🌌 Sacrifice Gravity",
				"description": "Float freely through space, but lose connection to the ground. Use WASD to fly.",
				"type": "physics"
			}
		"friction":
			return {
				"title": "🧊 Sacrifice Friction",
				"description": "Slide endlessly on surfaces - momentum never stops, but movement becomes unpredictable.",
				"type": "physics"
			}
		"jump ":
			return {
				"title": "⬇️ Sacrifice Jumping",
				"description": "Lose the ability to jump - bound to walk only on solid ground.",
				"type": "ability"
			}
		"run":
			return {
				"title": "🐌 Sacrifice Running",
				"description": "Move slowly and carefully - no more quick escapes or fast traversal.",
				"type": "ability"
			}
		"light":
			return {
				"title": "🕳️ Sacrifice Light",
				"description": "Embrace darkness - the world becomes dimmer and harder to see.",
				"type": "ability"
			}
		_:
			return {
				"title": "Unknown Sacrifice",
				"description": "A mysterious offering to the void.",
				"type": "unknown"
			}

func _on_sacrifice_chosen(sacrifice_name: String, sacrifice_type: String):
	print("🔥 [SacrificeUI] Button clicked: ", sacrifice_name, " (type: ", sacrifice_type, ")")
	print("✨ Sacrifice chosen: ", sacrifice_name, " (type: ", sacrifice_type, ")")
	
	# Apply the sacrifice through GameManager
	if sacrifice_type == "physics":
		GameManager.sacrifice_physics_law(sacrifice_name)
	elif sacrifice_type == "ability":
		GameManager.sacrifice_ability(sacrifice_name)
	else:
		GameManager.sacrifice_visual(sacrifice_name)
	
	# Emit signal for level progression
	sacrifice_made.emit(sacrifice_type, sacrifice_name)
	
	# Hide UI and unpause
	hide_ui()

func _on_cancel_pressed():
	print("🔥 [SacrificeUI] Cancel button clicked!")
	print("❌ Sacrifice cancelled")
	choice_cancelled.emit()
	hide_ui()

func hide_ui():
	hide()
	get_tree().paused = false
	clear_choices()

func clear_choices():
	if choice_container:
		for child in choice_container.get_children():
			child.queue_free()
	current_choices.clear()

# Convenience function to trigger from other scripts
func request_sacrifice_for_level(level_name: String, sacrifice_count: int = 1):
	show_sacrifice_options(level_name, sacrifice_count)

# Handle input while UI is shown
func _input(event):
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_cancel_pressed()
