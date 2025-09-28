# LoreManager.gd - Handles lore text throughout the game
extends Node

# Level-specific lore texts
var level_lore = {
	"res://game.tscn": {
		"title": "The Beginning",
		"text": """[center][font_size=32][color=cyan]The Custodian Awakens[/color][/font_size][/center]

[font_size=18]You find yourself in a world where the laws of physics bend to your will...
But every power comes with a price.

What will you sacrifice to reach the Core?[/font_size]"""
	},
	"res://levels/stable_realm/stable_entrance.tscn": {
		"title": "First Sacrifice",
		"text": """[center][font_size=28][color=orange]The Weight of Choice[/color][/font_size][/center]

[font_size=18]Each ability you surrender makes the path clearer,
but the journey more difficult.

The construct learns from your sacrifices...[/font_size]"""
	},
	"level_3": {
		"title": "Deeper Mysteries",
		"text": """[center][font_size=28][color=purple]Reality Shifts[/color][/font_size][/center]

[font_size=18]The laws you once knew no longer apply.
Gravity becomes a suggestion.
Friction, merely a memory.

What remains when physics breaks down?[/font_size]"""
	},
	"level_4": {
		"title": "The Approach",
		"text": """[center][font_size=28][color=red]Nearing the Core[/color][/font_size][/center]

[font_size=18]The air itself thrums with power.
Your sacrifices have not gone unnoticed.
The construct reshapes itself around your choices.

The final test approaches...[/font_size]"""
	},
	"level_5": {
		"title": "Chaos Theory",
		"text": """[center][font_size=28][color=gold]Into the Chaos[/color][/font_size][/center]

[font_size=18]Here, order becomes chaos.
Logic becomes intuition.
The very fabric of reality unravels.

Only those who embrace sacrifice can proceed.[/font_size]"""
	},
	"level_6": {
		"title": "The Golden Altar",
		"text": """[center][font_size=28][color=gold]The Final Chamber[/color][/font_size][/center]

[font_size=18]Before you lies the Golden Altar,
where all sacrifices converge.

The Core awaits your final offering.[/font_size]"""
	}
}

# Generic lore for unknown levels
var generic_lore = {
	"title": "The Journey Continues",
	"text": """[center][font_size=24][color=white]Another Step Forward[/color][/font_size][/center]

[font_size=18]The path grows stranger with each sacrifice.
What new trials await?[/font_size]"""
}

func _ready():
	print("📖 LoreManager ready")

func get_lore_for_scene(scene_path: String) -> Dictionary:
	"""Get lore text for a specific scene, personalized with sacrifice info"""
	print("📖 Looking for lore for: '", scene_path, "'")
	
	# Try direct key match first
	if level_lore.has(scene_path):
		print("📖 Found direct match for: ", scene_path)
		return personalize_lore(level_lore[scene_path])
	
	# Extract level name from path if it's a file path
	var level_name = scene_path.get_file().get_basename()
	print("📖 Extracted level name: '", level_name, "'")
	
	if level_lore.has(level_name):
		print("📖 Found match for level name: ", level_name)
		return personalize_lore(level_lore[level_name])
	
	# Try alternative level naming patterns
	var alt_names = [
		"level_" + scene_path,
		scene_path.replace("res://", "").replace(".tscn", ""),
		scene_path.split("/")[-1].replace(".tscn", "")
	]
	
	for alt_name in alt_names:
		if level_lore.has(alt_name):
			print("📖 Found match for alternative name: ", alt_name)
			return personalize_lore(level_lore[alt_name])
	
	print("📖 No specific lore found, using generic lore")
	print("📖 Available keys: ", level_lore.keys())
	return personalize_lore(generic_lore)

func personalize_lore(base_lore: Dictionary) -> Dictionary:
	"""Add personalized sacrifice information to lore"""
	var personalized = base_lore.duplicate()
	
	# Get current sacrifice info (with fallback if GameManager not available)
	var sacrifice_count = 0
	var sacrificed_abilities = []
	
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		if game_manager.has_method("get_sacrifice_count"):
			sacrifice_count = game_manager.get_sacrifice_count()
		if game_manager.has_method("get_sacrificed_abilities"):
			sacrificed_abilities = game_manager.get_sacrificed_abilities()
	
	# Add sacrifice-specific flavor text
	if sacrifice_count > 0:
		var sacrifice_text = get_sacrifice_flavor_text(sacrificed_abilities)
		personalized.text += "\n\n" + sacrifice_text
	
	return personalized

func get_sacrifice_flavor_text(sacrificed_abilities: Array) -> String:
	"""Generate flavor text based on sacrificed abilities"""
	if sacrificed_abilities.is_empty():
		return "[font_size=16][i]The path ahead remains unchanged...[/i][/font_size]"
	
	var sacrifice_lines = []
	
	for ability in sacrificed_abilities:
		match ability:
			"gravity":
				sacrifice_lines.append("[color=cyan]Without gravity's pull, you drift between worlds...[/color]")
			"friction":
				sacrifice_lines.append("[color=orange]Your essence flows like liquid light...[/color]")
			"collision":
				sacrifice_lines.append("[color=purple]You phase through reality itself...[/color]")
			"jump":
				sacrifice_lines.append("[color=green]Your connection to the ground is severed...[/color]")
			"run":
				sacrifice_lines.append("[color=red]Time moves differently around you...[/color]")
			"light":
				sacrifice_lines.append("[color=yellow]You become one with the shadows...[/color]")
			_:
				sacrifice_lines.append("[color=gray]Something fundamental has changed...[/color]")
	
	var result = "[font_size=16][i]Your sacrifices echo in this place:\n"
	result += "\n".join(sacrifice_lines)
	result += "[/i][/font_size]"
	
	return result

func show_level_lore(scene_path: String):
	"""Show lore for a specific level using TransitionManager"""
	var lore = get_lore_for_scene(scene_path)
	
	# Use TransitionManager's enhanced lore display
	if TransitionManager.has_method("show_lore_screen"):
		await TransitionManager.show_lore_screen(lore.title, lore.text)
	else:
		# Fallback: use regular transition text
		print("📖 Showing lore: ", lore.title)

func add_custom_lore(scene_path: String, title: String, text: String):
	"""Add custom lore for a specific scene"""
	level_lore[scene_path] = {
		"title": title,
		"text": text
	}
	print("📖 Added custom lore for: ", scene_path)

# Test functions - call these in the remote console
func test_lore_display(level_name: String = "level_2"):
	"""Test lore display for a specific level"""
	print("🧪 Testing lore for: ", level_name)
	print("🧪 Available lore keys: ", level_lore.keys())
	
	var lore = get_lore_for_scene(level_name)
	
	if has_node("/root/TransitionManager"):
		var tm = get_node("/root/TransitionManager")
		if tm.has_method("show_lore_screen"):
			await tm.show_lore_screen(lore.title, lore.text, 6.0)
		else:
			print("📖 TransitionManager found but no show_lore_screen method")
			print("📖 Title: ", lore.title)
			print("📖 Text: ", lore.text)
	else:
		print("📖 TransitionManager not found")
		print("📖 Title: ", lore.title)
		print("📖 Text: ", lore.text)

func test_first_sacrifice():
	"""Test the 'First Sacrifice' lore specifically"""
	await test_lore_display("level_2")

func test_beginning():
	"""Test the 'Beginning' lore specifically"""
	await test_lore_display("res://game.tscn")

func preview_all_lore():
	"""Preview all available lore"""
	print("📚 All available lore:")
	for scene_path in level_lore.keys():
		var lore = level_lore[scene_path]
		print("  ", scene_path, " -> ", lore.title)

func test_sacrifice_lore():
	"""Test how lore changes with sacrifices"""
	print("🧪 Testing sacrifice-aware lore...")
	var base_lore = level_lore["level_2"]
	var personalized = personalize_lore(base_lore)
	print("📖 Personalized lore: ")
	print("   Title: ", personalized.title)
	print("   Text: ", personalized.text)
