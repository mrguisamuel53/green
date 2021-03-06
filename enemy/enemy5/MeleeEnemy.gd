extends KinematicBody2D

# Constants
const GRAVITY = 20
const FLOOR = Vector2(0, -1)
const MIN_SPEED = 0
const MAX_SPEED = 200
const SWORD_POSITION_X = 36

# Variables
var motion = Vector2()
var direction = 1
var founded = false
var can_flip = true
var speed = MAX_SPEED
var distance : bool

# Node Referencing
onready var head = $Head
onready var eyes = $Head/Eyes
onready var body_s = $Body
onready var raycast = $RayCast2D
onready var collider = $CollisionShape2D
onready var l_damage_area = $LeftDamageArea
onready var r_damage_area = $RightDamageArea
onready var lifebar = $Lifebar
onready var anim = $AnimationPlayer
onready var wheel = $Wheel
onready var explosions = $Explosion
onready var sword_anim = $Sword/AnimationPlayer
onready var sword = $Sword
onready var sword_area = $Sword/SwordArea
onready var sound_effect = $ExplosionSoundEffect
onready var s_sound_effect = $SwordSoundEffect

# Get Player Node
onready var player = get_tree().get_current_scene().get_node("Player")

func _ready() -> void:
	# When starts, it will play hide explosions
	explosions.visible = false
	sword_anim.play("default")
	anim.play("default")

func animation() -> void:
	distance = sword.global_position.x > player.global_position.x
	if founded:
		eyes.play("angry")
		wheel.playing = false
		speed = MIN_SPEED
		if can_flip && distance:
			sword_anim.play("attack_left")
			flip_sword(true)
			can_flip = false
			var t_d = Timer.new()
			t_d.set_wait_time(1)
			t_d.set_one_shot(true)
			self.add_child(t_d)
			t_d.start()
			yield(t_d, "timeout")
			t_d.queue_free()
			can_flip = true
		elif can_flip && !distance:
			flip_sword(false)
			sword_anim.play("attack_right")
	else:
		sword_anim.play("default")
		eyes.play("default")
		eyes.position = Vector2(9, 18)
		speed = MAX_SPEED
		wheel.playing = true

func flip_sword(value : bool) -> void:
	if value:
		sword.flip_h = true
		sword.position.x = -SWORD_POSITION_X
	else:
		sword.flip_h = false
		sword.position.x = SWORD_POSITION_X	

func _physics_process(_delta) -> void:
	# Tests if player is dead
	if !lifebar.getDeath():
		# Basic Movement and Gravity
		motion.x = speed * direction
		motion.y += GRAVITY
		motion = move_and_slide(motion, FLOOR)
			
		# Change direction
		if is_on_wall() || !raycast.is_colliding():
			change_direction()
	else:
		death()
	animation()
	
	if l_damage_area.monitoring && r_damage_area.monitoring:
		if l_damage_area.get_overlapping_areas():
			if l_damage_area.get_overlapping_areas()[0].get_name() == "DamageArea":
				if !player.hit:
					player.take_damage(5)
					Global.hit_side = -1
			elif l_damage_area.get_overlapping_areas()[0].get_name() == "flame_area":
				take_damage(1)
				Global.score += 1
		elif r_damage_area.get_overlapping_areas():
			if r_damage_area.get_overlapping_areas()[0].get_name() == "DamageArea":
				if !player.hit:
					player.take_damage(5)
					Global.hit_side = 1
			elif r_damage_area.get_overlapping_areas()[0].get_name() == "flame_area":
				take_damage(1)
				Global.score += 1

# Change direction
func change_direction() -> void:
	direction *= -1
	raycast.position.x *= -1
	var flip_s = true if raycast.position.x < 0 else false
	flip_sword(flip_s)

# Function that runs when the enemy dies
func death() -> void:
	Global.score += 25
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
	body_s.visible = false
	head.visible = false
	wheel.visible = false
	sword.visible = false
	
	# Wait a time before delete enemy
	var t_d = Timer.new()
	t_d.set_wait_time(0.3)
	t_d.set_one_shot(true)
	self.add_child(t_d)
	t_d.start()
	yield(t_d, "timeout")
	queue_free()

func which_damage(area):
	if area.is_in_group("bullet-base"):
		take_damage(10)
		area.queue_free()
	elif area.is_in_group("bullet-spread"):
		take_damage(3)
		area.queue_free()
	elif area.is_in_group("bullet-pistol"):
		take_damage(2)
		area.queue_free()
	elif area.is_in_group("bullet-autoaim"):
		take_damage(20)
		area.queue_free()

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

func _on_DetectArea_body_entered(body) -> void:
	if body.is_in_group("player"):
		founded = true

func _on_DetectArea_body_exited(_body) -> void:
	founded = false

func _on_SwordArea_body_entered(body) -> void:
	if body.is_in_group("player") && !player.hit:
		if distance:
			Global.hit_side = -1
		else:
			Global.hit_side = 1
		player.take_damage(5)
