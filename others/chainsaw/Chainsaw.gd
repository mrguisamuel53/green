extends Node2D

# Node Referencing
onready var saw = $Saw
onready var tween = $Tween
onready var chain_h = $Chain_H
onready var chain_v = $Chain_V

# Variables
export var speed = 3.0
export var horizontal = true
export var distance = 192

var follow = Vector2.ZERO

const WAIT_DURATION = 1.0

func _ready() -> void:
	_start_tween()
	if horizontal:
		chain_h.visible = true
		chain_v.visible = false
	else:
		chain_h.visible = false
		chain_v.visible = true		

func _start_tween() -> void:
	var move_direction = Vector2.RIGHT * distance if horizontal else Vector2.UP * distance
	var duration = move_direction.length() / float(speed * 16)
	tween.interpolate_property(
		self, "follow", Vector2.ZERO, move_direction, duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, WAIT_DURATION
	)
	tween.interpolate_property(
		self, "follow", move_direction, Vector2.ZERO, duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, duration + WAIT_DURATION * 2
	)
	tween.start()

func _physics_process(_delta) -> void:
	saw.position = saw.position.linear_interpolate(follow, 0.05)

func _on_Left_area_entered(_area) -> void:
	Global.hit_side = -1

func _on_Right_area_entered(_area):
	Global.hit_side = 1
