extends Area2D

signal finished_level()

# Node Referencing
onready var sign_s = $Sign
onready var sign_anim = $Sign/AnimationPlayer

# Variables
var player
var can_play = true

func _on_FinishLevel_body_entered(body) -> void:
	if body.is_in_group("player") && can_play:
		sign_anim.play("black")
		yield(get_tree().create_timer(0.5), "timeout")
		sign_s.play("good")
		player = body

func _process(_delta) -> void:
	if player != null && player.is_on_floor():
		emit_signal("finished_level")
		set_process(false)

func _on_AnimationPlayer_animation_finished(anim_name) -> void:
	if anim_name == "black":
		can_play = false
