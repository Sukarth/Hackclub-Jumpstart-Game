# LevelTransition.gd - Simple script to move between levels
extends Area2D

@export var next_level_path: String = ""
@export var level_name: String = "Next Level"

func _ready():
	body_entered.connect(_on_player_entered)
	print("🚪 Level transition ready - leads to: ", level_name)

func _on_player_entered(body):
	if body.is_in_group("player"):
		print("🚀 Player reached end - transitioning to: ", level_name)
		
		if next_level_path != "":
			# Small delay for effect
			await get_tree().create_timer(0.5).timeout
			get_tree().change_scene_to_file(next_level_path)
		else:
			print("🎉 Game Complete! No next level set.")
			# Show win screen or restart
			get_tree().change_scene_to_file("res://game.tscn") # Go back to main scene