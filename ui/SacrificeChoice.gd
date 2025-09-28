# SacrificeChoice.gd - UI for selecting sacrifices to progress
extends Control

# Signals
signal sacrifice_made(sacrifice_type: String, sacrifice_name: String)
signal choice_cancelled

# UI References (will connect in _ready)
var background_panel: Panel
var title_label: Label
var description_label: Label
var choice_container: VBoxContainer
var cancel_button: Button

# Current sacrifice options
var current_choices: Array[Dictionary] = []
var is_cancellable: bool = true

func _ready():
	# Add to groups for easy finding
	add_to_group("sacrifice_ui")
	add_to_group("ui")
	
	# Enable processing during pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Find UI elements manually
	background_panel = get_node("BackgroundPanel") if has_node("BackgroundPanel") else null
	title_label = get_node("VBoxContainer/TitleLabel") if has_node("VBoxContainer/TitleLabel") else null
	description_label = get_node("VBoxContainer/DescriptionLabel") if has_node("VBoxContainer/DescriptionLabel") else null
	choice_container = get_node("VBoxContainer/ChoiceContainer") if has_node("VBoxContainer/ChoiceContainer") else null
	cancel_button = get_node("VBoxContainer/CancelButton") if has_node("VBoxContainer/CancelButton") else null
	
	print("🔍 Found UI elements:")
	print("  background_panel: ", background_panel != null)
	print("  title_label: ", title_label != null)
	print("  description_label: ", description_label != null)
	print("  choice_container: ", choice_container != null)
	print("  cancel_button: ", cancel_button != null)
	
	# Style the labels for better visibility
	if title_label:
		title_label.add_theme_font_size_override("font_size", 28)
		title_label.add_theme_color_override("font_color", Color.WHITE)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
	if description_label:
		description_label.add_theme_font_size_override("font_size", 18)
		description_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Connect cancel button if it exists
	if cancel_button:
		cancel_button.process_mode = Node.PROCESS_MODE_ALWAYS
		cancel_button.pressed.connect(_on_cancel_pressed)
		cancel_button.add_theme_font_size_override("font_size", 16)
	
	# Start hidden
	hide()
	
	print("📝 SacrificeChoice UI ready")

# Show sacrifice options for level progression
func show_sacrifice_options(level_name: String, required_count: int = 1, sacrifice_types: Array[String] = []):
	show_sacrifice_options_internal(level_name, required_count, sacrifice_types, true)

# Show sacrifice options that cannot be cancelled (for mandatory level progression)
func show_sacrifice_options_uncancellable(level_name: String, required_count: int = 1, sacrifice_types: Array[String] = []):
	show_sacrifice_options_internal(level_name, required_count, sacrifice_types, false)

func show_sacrifice_options_internal(level_name: String, required_count: int = 1, sacrifice_types: Array[String] = [], cancellable: bool = true):
	print("🔮 Showing sacrifice options for: ", level_name, " (cancellable: ", cancellable, ")")
	print("🔍 UI Elements check:")
	print("  title_label: ", title_label != null)
	print("  description_label: ", description_label != null)
	print("  choice_container: ", choice_container != null)
	print("  cancel_button: ", cancel_button != null)
	
	# Store cancellable state
	is_cancellable = cancellable
	
	if title_label:
		if cancellable:
			title_label.text = "Sacrifice Required: " + level_name
		else:
			title_label.text = "Mandatory Sacrifice: " + level_name
	if description_label:
		if cancellable:
			description_label.text = "Choose " + str(required_count) + " sacrifice(s) to progress..."
		else:
			description_label.text = "The path forward demands sacrifice.\nChoose " + str(required_count) + " ability to give up forever..."
	
	# Show/hide cancel button based on cancellable flag
	if cancel_button:
		cancel_button.visible = cancellable
	
	# Clear previous choices
	clear_choices()
	
	# Create sacrifice options
	var buttons_created = 0
	if sacrifice_types.is_empty():
		# Default sacrifice options
		create_default_sacrifice_options()
	else:
		# Specific sacrifice types requested
		for sac_type in sacrifice_types:
			if GameManager.can_make_sacrifice(sac_type):
				create_sacrifice_button(sac_type)
				buttons_created += 1
				print("🔮 Created button for: ", sac_type)
	
	print("🔮 Total buttons created: ", buttons_created)
	if choice_container:
		print("🔮 Choice container children count: ", choice_container.get_child_count())
	
	# Show the UI
	show()
	
	# Make sure the parent CanvasLayer is visible if it exists
	var parent = get_parent()
	while parent != null:
		if parent is CanvasLayer:
			parent.visible = true
			# Set high layer to appear above everything else
			parent.layer = 100
			print("🔮 Set CanvasLayer visible and layer to 100")
			break
		elif parent.has_method("set_visible"):
			parent.visible = true
			print("🔮 Set parent visible: ", parent.name)
		parent = parent.get_parent()
	
	# Force this control to be visible and on top
	modulate = Color.WHITE
	z_index = 1000
	
	# Pause the game
	get_tree().paused = true
	
	print("🔮 SacrificeChoice UI should now be visible - paused: ", get_tree().paused)
	print("🔮 UI visible: ", visible, " modulate: ", modulate)
	if background_panel:
		print("🔮 Background panel visible: ", background_panel.visible, " modulate: ", background_panel.modulate)
	print("🔮 UI global position: ", global_position, " size: ", size)

func create_default_sacrifice_options():
	# Physics laws
	var physics_options = ["friction", "collision"]
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
	button.custom_minimum_size = Vector2(400, 60)
	
	# Style the button to make it more visible
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.YELLOW)
	
	# Style the button based on sacrifice type
	if sacrifice_name in ["friction", "collision"]:
		button.modulate = Color.CYAN
	elif sacrifice_name in ["jump", "run", "light"]:
		button.modulate = Color.YELLOW
	else:
		button.modulate = Color.MAGENTA
	
	# Connect button press
	button.pressed.connect(_on_sacrifice_chosen.bind(sacrifice_name, sacrifice_info.type))
	
	choice_container.add_child(button)
	print("🔮 Added button to choice_container: ", sacrifice_info.title, " - Button visible: ", button.visible)
	
	current_choices.append({
		"name": sacrifice_name,
		"type": sacrifice_info.type,
		"button": button
	})

func get_sacrifice_info(sacrifice_name: String) -> Dictionary:
	match sacrifice_name:
		# "gravity":
		# 	return {
		# 		"title": "🌌 Sacrifice Gravity",
		# 		"description": "Float freely through space, but lose connection to the ground. Use WASD to fly.",
		# 		"type": "physics"
		# 	}
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
	# Only allow cancellation if the UI is in cancellable mode
	if not is_cancellable:
		print("🚫 Cannot cancel - sacrifice is mandatory for level progression")
		return
		
	print("🔥 [SacrificeUI] Cancel button clicked!")
	print("❌ Sacrifice cancelled")
	choice_cancelled.emit()
	hide_ui()

func hide_ui():
	hide()
	get_tree().paused = false
	clear_choices()
	# Reset to default cancellable state
	is_cancellable = true

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
		# Only allow cancellation if the UI is in cancellable mode
		if is_cancellable:
			_on_cancel_pressed()
		else:
			print("🚫 Cannot cancel - sacrifice is mandatory for level progression")
