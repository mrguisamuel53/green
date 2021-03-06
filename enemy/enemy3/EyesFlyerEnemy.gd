extends Sprite

# Nodes Referencing
onready var eyes = get_children()[0]
onready var player = get_tree().get_current_scene().get_node("Player")
onready var enemy = get_parent().get_parent()

# Constants
const MAX_EYE_UP = -3

# Variables
var max_dist = 5

func _process(_delta) -> void:
	# Eyes following player
	if enemy.founded:
		var eyes_pos = eyes.global_position
		var dir = eyes_pos.direction_to(player.global_position)
		var dist = eyes_pos.distance_to(player.global_position)
		eyes.position = dir * min(dist, max_dist)
		eyes.position.y += 25
	else:
		eyes.position = Vector2(3, 20)
