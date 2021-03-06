extends Area2D

# Node Referencing
onready var sprite = $AnimatedSprite

# Signal
signal player_entered(type)

# Enum
enum {BASIC, SPREAD, FLAME, PISTOL, AUTO_AIMING}

# General Variables
export(int) var type = BASIC

func _ready() -> void:
	match type:
		BASIC:
			sprite.play("gun1")
		SPREAD:
			sprite.play("gun2")
		FLAME:
			sprite.play("gun3")
		PISTOL:
			sprite.play("gun4")
		AUTO_AIMING:
			sprite.play("gun5")
	sprite.scale = Vector2(1, 1)

func _on_AnimatedSprite_animation_finished() -> void:
	if sprite.get_animation() == "collected":
		queue_free()

func _on_PickupGun_body_entered(body) -> void:
	if body.is_in_group("player"):
		Global.score += 150
		emit_signal("player_entered", type)
		sprite.play("collected")
		sprite.scale = Vector2(1.5, 1.5)
