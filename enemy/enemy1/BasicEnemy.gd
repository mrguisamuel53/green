extends KinematicBody2D

# Constants
const SPEED = 350
const GRAVITY = 20
const FLOOR = Vector2(0, -1)

# Variables
var motion = Vector2()
var direction = 1

# Node Referencing
onready var sprite = $AnimatedSprite
onready var raycast = $RayCast2D
onready var collider = $CollisionShape2D
onready var l_damage_area = $LeftDamageArea
onready var r_damage_area = $RightDamageArea
onready var lifebar = $Lifebar
onready var anim = $AnimationPlayer
onready var wheel = $Wheel
onready var explosions = $Explosion
onready var sound_effect = $ExplosionSoundEffect

func _ready() -> void:
	# When starts, it will play hide explosions
	explosions.visible = false

func _physics_process(_delta) -> void:
	# Tests if player is dead
	if !lifebar.getDeath():
		# Basic Movement and Gravity
		motion.x = SPEED * direction
		motion.y += GRAVITY
		motion = move_and_slide(motion, FLOOR)
			
		# Change direction
		if is_on_wall() || !raycast.is_colliding():
			direction *= -1
			raycast.position.x *= -1
			sprite.flip_h = !sprite.flip_h
			
		if l_damage_area.get_overlapping_areas():
			if l_damage_area.get_overlapping_areas()[0].get_name() == "flame_area":
				take_damage(1)
				Global.score += 1
		elif r_damage_area.get_overlapping_areas():
			if r_damage_area.get_overlapping_areas()[0].get_name() == "flame_area":
				take_damage(1)
				Global.score += 1
	else:
		death()

# Function that runs when the enemy dies
func death() -> void:
	Global.score += 10
	sound_effect.play()
	# Disable collision (bullet & tileset)
	l_damage_area.monitorable = false
	r_damage_area.monitorable = false
	l_damage_area.monitoring = false
	r_damage_area.monitoring = false
	collider.disabled = true
	
	# Explosions visible
	explosions.visible = true
	for explosion in explosions.get_children():
		# Each explosion will start play
		explosion.playing = true
	
	# Sprite & lifebar invisibles
	#lifebar.visible = false
	sprite.visible = false
	wheel.visible = false
	
	# Wait a time before delete enemy
	var t_d = Timer.new()
	t_d.set_wait_time(0.3)
	t_d.set_one_shot(true)
	self.add_child(t_d)
	t_d.start()
	yield(t_d, "timeout")
	queue_free()
	
# take damage
func take_damage(damage : int) -> void:
	anim.play("flash")
	lifebar.damage(damage)

func _on_LeftDamageArea_area_entered(area) -> void:
	Global.hit_side = -1
	which_damage(area)

func _on_RightDamageArea_area_entered(area) -> void:
	Global.hit_side = 1
	which_damage(area)

func which_damage(area):
	if area.is_in_group("bullet-base"):
		take_damage(10)
	elif area.is_in_group("bullet-spread"):
		take_damage(7)
	elif area.is_in_group("bullet-pistol"):
		take_damage(3)
	elif area.is_in_group("bullet-autoaim"):
		take_damage(5)
