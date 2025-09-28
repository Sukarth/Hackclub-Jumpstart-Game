# EndingManager.gd - Simple, guaranteed-working ending sequence
extends CanvasLayer

# Visual elements
var flash_rect: ColorRect
var black_rect: ColorRect
var text_label: RichTextLabel
var is_running: bool = false

func _ready():
	layer = 9999 # Maximum layer to appear over everything
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Wait for viewport to be ready, then create UI
	await get_tree().process_frame
	await get_tree().process_frame
	create_ui()
	print("🎬 EndingManager ready - simple version")

func create_ui():
	var viewport_size = get_viewport().get_visible_rect().size
	print("🔍 DEBUG: Viewport size=", viewport_size)
	
	# Black background
	black_rect = ColorRect.new()
	black_rect.color = Color.BLACK
	black_rect.position = Vector2.ZERO
	black_rect.size = viewport_size
	black_rect.modulate.a = 0.0 # Start invisible
	black_rect.visible = true
	black_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black_rect)
	print("🔍 DEBUG: Created black_rect - size=", black_rect.size, " pos=", black_rect.position)
	
	# White flash
	flash_rect = ColorRect.new()
	flash_rect.color = Color.WHITE
	flash_rect.position = Vector2.ZERO
	flash_rect.size = viewport_size
	flash_rect.modulate.a = 0.0 # Start invisible
	flash_rect.visible = true
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash_rect)
	print("🔍 DEBUG: Created flash_rect - size=", flash_rect.size, " pos=", flash_rect.position)
	
	# Text display
	text_label = RichTextLabel.new()
	text_label.position = Vector2(100, 200)
	text_label.size = Vector2(viewport_size.x - 200, viewport_size.y - 400)
	text_label.bbcode_enabled = true
	text_label.modulate.a = 0.0 # Start invisible
	text_label.visible = true
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.add_theme_color_override("default_color", Color.WHITE)
	add_child(text_label)
	print("🔍 DEBUG: Created text_label - size=", text_label.size, " pos=", text_label.position)

func start_ending_sequence(_completion_text: String = ""):
	if is_running:
		print("⚠️ Ending already running")
		return
	
	is_running = true
	print("🌟 STARTING ENDING SEQUENCE")
	print("🔍 DEBUG: viewport=", get_viewport().get_visible_rect().size)
	
	# Disable player immediately
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_physics_process"):
		player.set_physics_process(false)
		print("🚫 Player disabled")
	
	# Start the sequence
	run_ending()

# Manual test function - call this in the remote console
func test_ending_ui():
	print("🧪 MANUAL UI TEST")
	if not flash_rect or not black_rect or not text_label:
		print("❌ UI elements not created yet!")
		return
	
	print("🧪 Flash test...")
	flash_rect.modulate.a = 1.0
	await get_tree().create_timer(1.0).timeout
	flash_rect.modulate.a = 0.0
	
	print("🧪 Black test...")
	black_rect.modulate.a = 1.0
	await get_tree().create_timer(1.0).timeout
	
	print("🧪 Text test...")
	text_label.bbcode_text = "[center][font_size=48][color=gold]TEST MESSAGE[/color][/font_size][/center]"
	text_label.modulate.a = 1.0
	await get_tree().create_timer(2.0).timeout
	
	print("🧪 Cleanup...")
	black_rect.modulate.a = 0.0
	text_label.modulate.a = 0.0
	print("🧪 Test complete!")

func run_ending():
	print("⚡ Step 1: White flash")
	print("🔍 DEBUG: flash_rect visible=", flash_rect.visible, " modulate=", flash_rect.modulate)
	# Flash white immediately so player sees something
	var flash_tween = create_tween()
	flash_tween.tween_property(flash_rect, "modulate:a", 1.0, 0.1)
	await flash_tween.finished
	print("🔍 DEBUG: After flash - flash_rect modulate=", flash_rect.modulate)
	
	print("🌑 Step 2: Fade to black")
	print("🔍 DEBUG: black_rect visible=", black_rect.visible, " modulate=", black_rect.modulate)
	# Fade white to black
	var to_black = create_tween()
	to_black.parallel().tween_property(flash_rect, "modulate:a", 0.0, 0.5)
	to_black.parallel().tween_property(black_rect, "modulate:a", 1.0, 0.5)
	await to_black.finished
	print("🔍 DEBUG: After fade - black_rect modulate=", black_rect.modulate)
	
	print("📜 Step 3: Show text")
	print("🔍 DEBUG: text_label visible=", text_label.visible, " modulate=", text_label.modulate)
	# Show ending text
	text_label.bbcode_text = """[center][font_size=48][color=gold]Game Complete![/color][/font_size]

[font_size=24]The Custodian has reached the Core of Reality.

Every sacrifice has led to this moment.

Thank you for playing![/font_size][/center]"""
	
	var text_tween = create_tween()
	text_tween.tween_property(text_label, "modulate:a", 1.0, 1.0)
	await text_tween.finished
	print("🔍 DEBUG: After text - text_label modulate=", text_label.modulate)
	
	print("⏰ Step 4: Wait")
	# Wait a bit
	await get_tree().create_timer(4.0).timeout
	
	print("🎬 Step 5: Go to credits")
	# Fade out and go to credits
	var fade_out = create_tween()
	fade_out.tween_property(text_label, "modulate:a", 0.0, 1.0)
	await fade_out.finished
	
	# Change scene
	get_tree().change_scene_to_file("res://credits.tscn")
	is_running = false

func _input(event):
	# Allow skip after text appears
	if is_running and text_label.modulate.a > 0.5 and event.is_pressed():
		print("⏭️ Skipping to credits")
		get_tree().change_scene_to_file("res://credits.tscn")
		is_running = false

# Compatibility functions for old calls
func dramatic_sequence(_text: String):
	run_ending()

func white_flash_effect():
	pass

func fade_to_black():
	pass

func show_lore_sequence():
	pass

func transition_to_credits():
	get_tree().change_scene_to_file("res://credits.tscn")

func skip_to_credits():
	get_tree().change_scene_to_file("res://credits.tscn")
	is_running = false
