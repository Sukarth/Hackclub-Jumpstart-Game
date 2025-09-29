extends Area2D
@export var text: String = ""
var charCount:int = 0
var near:bool = false

func _ready():
	body_entered.connect(_on_player_entered)
	body_exited.connect(on_body_exited)
	%Text.text = ""

func _physics_process(delta: float) -> void:
	if near && text.length()>charCount:
		charCount=charCount+1
		%Text.text = text.substr(0,charCount)
	elif not near && not charCount == 0:
		charCount=charCount-1
		%Text.text = text.substr(0,charCount)

func _on_player_entered(body):
	if body.is_in_group("player"):
		near = true
func on_body_exited(body):
	if body.is_in_group("player"):
		near = false
