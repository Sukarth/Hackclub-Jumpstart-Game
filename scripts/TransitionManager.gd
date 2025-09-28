# TransitionManager.gd - Global scene transition with fade effects
extends CanvasLayer

# Fade settings
var fade_duration: float = 0.5
var is_transitioning: bool = false

# UI elements
var fade_rect: ColorRect
var transition_label: Label

func _ready():
	# Set high layer to appear above everything
	layer = 1000
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Create fade overlay
	create_fade_overlay()
	print("🎬 TransitionManager ready")

func create_fade_overlay():
	"""Create the black fade overlay"""
	# Create ColorRect for fading
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.size = get_viewport().get_visible_rect().size
	fade_rect.anchors_preset = Control.PRESET_FULL_RECT
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.modulate.a = 0.0  # Start transparent
	add_child(fade_rect)
	
	# Create optional transition label
	transition_label = Label.new()
	transition_label.text = ""
	transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	transition_label.anchors_preset = Control.PRESET_FULL_RECT
	transition_label.add_theme_color_override("font_color", Color.WHITE)
	transition_label.modulate.a = 0.0
	add_child(transition_label)
	
	# Handle viewport size changes
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed():
	"""Update fade overlay size when viewport changes"""
	if fade_rect:
		fade_rect.size = get_viewport().get_visible_rect().size

func transition_to_scene(scene_path: String, transition_text: String = ""):
	"""Transition to a new scene with fade effect"""
	if is_transitioning:
		print("⚠️ Transition already in progress")
		return false
	
	is_transitioning = true
	print("🌅 Starting transition to: ", scene_path)
	
	# Set transition text if provided
	if transition_text != "":
		transition_label.text = transition_text
	
	# Fade out
	await fade_out()
	
	# Load new scene
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		print("❌ Failed to load scene: ", scene_path, " Error: ", error)
		is_transitioning = false
		await fade_in()
		return false
	
	# Small delay to ensure scene is loaded
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Fade in
	await fade_in()
	
	# Clear transition text
	transition_label.text = ""
	is_transitioning = false
	print("✅ Transition completed to: ", scene_path)
	return true

func fade_out():
	"""Fade out to black"""
	var tween = create_tween()
	tween.parallel().tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	if transition_label.text != "":
		tween.parallel().tween_property(transition_label, "modulate:a", 1.0, fade_duration)
	await tween.finished

func fade_in():
	"""Fade in from black"""
	var tween = create_tween()
	tween.parallel().tween_property(fade_rect, "modulate:a", 0.0, fade_duration)
	tween.parallel().tween_property(transition_label, "modulate:a", 0.0, fade_duration)
	await tween.finished

func quick_fade_in():
	"""Quick fade in for scene start"""
	fade_rect.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, fade_duration * 0.5)
	await tween.finished

func set_fade_duration(duration: float):
	"""Set custom fade duration"""
	fade_duration = duration

func is_faded_out() -> bool:
	"""Check if currently faded out"""
	return fade_rect.modulate.a >= 1.0