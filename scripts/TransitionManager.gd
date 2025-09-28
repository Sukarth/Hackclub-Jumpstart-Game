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
	fade_rect.modulate.a = 0.0 # Start transparent
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
	
	# Create lore screen for rich text display
	create_lore_screen()
	
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

# Lore screen elements
var lore_container: Control
var lore_title: Label
var lore_text: RichTextLabel

func create_lore_screen():
	"""Create rich lore display screen"""
	lore_container = Control.new()
	lore_container.anchors_preset = Control.PRESET_FULL_RECT
	lore_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lore_container.modulate.a = 0.0
	add_child(lore_container)
	
	# Background for lore (semi-transparent)
	var lore_bg = ColorRect.new()
	lore_bg.color = Color(0, 0, 0, 0.8)
	lore_bg.anchors_preset = Control.PRESET_FULL_RECT
	lore_container.add_child(lore_bg)
	
	# Title
	lore_title = Label.new()
	lore_title.anchors_preset = Control.PRESET_TOP_WIDE
	lore_title.position = Vector2(0, 150)
	lore_title.size = Vector2(0, 60)
	lore_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lore_title.add_theme_color_override("font_color", Color.WHITE)
	lore_title.add_theme_font_size_override("font_size", 36)
	lore_container.add_child(lore_title)
	
	# Main lore text
	lore_text = RichTextLabel.new()
	lore_text.anchors_preset = Control.PRESET_CENTER
	lore_text.position = Vector2(-400, -200)
	lore_text.size = Vector2(800, 400)
	lore_text.bbcode_enabled = true
	lore_text.fit_content = true
	lore_text.add_theme_color_override("default_color", Color.WHITE)
	lore_container.add_child(lore_text)

func show_lore_screen(title: String, text: String, duration: float = 4.0):
	"""Show lore screen with title and text"""
	if is_transitioning:
		print("⚠️ Cannot show lore during transition")
		return
	
	print("📖 Showing lore screen: ", title)
	
	# Set content
	lore_title.text = title
	lore_text.bbcode_text = text
	
	# Fade in lore screen
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(lore_container, "modulate:a", 1.0, 0.8)
	await fade_in_tween.finished
	
	# Wait for duration
	await get_tree().create_timer(duration).timeout
	
	# Fade out lore screen
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(lore_container, "modulate:a", 0.0, 0.8)
	await fade_out_tween.finished

func transition_with_lore(scene_path: String, title: String, lore_content: String):
	"""Transition to scene with lore display"""
	if is_transitioning:
		print("⚠️ Transition already in progress")
		return false
	
	is_transitioning = true
	print("🌅 Starting lore transition to: ", scene_path)
	
	# Fade out current scene
	await fade_out()
	
	# Show lore while black
	lore_title.text = title
	lore_text.bbcode_text = lore_content
	
	var lore_tween = create_tween()
	lore_tween.tween_property(lore_container, "modulate:a", 1.0, 1.0)
	await lore_tween.finished
	
	# Hold lore for reading
	await get_tree().create_timer(5.0).timeout
	
	# Fade out lore
	var lore_out = create_tween()
	lore_out.tween_property(lore_container, "modulate:a", 0.0, 1.0)
	await lore_out.finished
	
	# Load new scene
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		print("❌ Failed to load scene: ", scene_path, " Error: ", error)
		is_transitioning = false
		await fade_in()
		return false
	
	# Wait for scene to load
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Fade in new scene
	await fade_in()
	
	is_transitioning = false
	print("✅ Lore transition completed to: ", scene_path)
	return true