extends Sprite

# Enum
enum {BASIC, SPREAD, FLAME, PISTOL, AUTO_AIMING, NO_GUN}

# Variables
var can_fire = true
var velocity = Vector2(0, 0)
var mouse_pos = Vector2(0, 0)
var muzzle_pos = 4.8
var gun_type = BASIC
var gun_pos_flip_false = Vector2(4, -88)
var gun_pos_flip_true = Vector2(4, -88)
var p_knock_side = -1
var changing = false
var impulse_strength = 2

# Bullet Referecing
var bullet = preload("res://others/bullet/BulletBase.tscn")

# Nodes Referecing
onready var muzzle = $Muzzle
onready var player = get_parent()
onready var hands = get_parent().get_node("Hands")
onready var flame = get_parent().get_node("FlameParticles")
onready var flame_area = get_parent().get_node("FlameParticles/flame_area")
onready var sound_effect_1 = $GunShooting
onready var sound_effect_2 = $Shotgun
onready var sound_effect_3 = $Laser
onready var sound_effect_4 = $ChangeGun
onready var sound_effect_5 = $AddGun
onready var fire_sfx = $Fire

# Textures
export(Array, StreamTexture)var gun_texture

func _ready() -> void:
	enable_flame_area(false)
	visible = false
	hands.visible = true
	gun_type = NO_GUN
	texture = gun_texture[5]
	for gun in get_parent().get_parent().get_node("Guns").get_children():
		gun.connect("player_entered", self, "_pickup_gun")

func add_gun_at_inventory(which_gun) -> void:
	if !Global.inventory_guns.has(which_gun):
		sound_effect_5.play()
		if len(Global.inventory_guns) < 2:
			Global.inventory_guns.append(which_gun)
		else:
			if len(Global.inventory_guns) == 2:
				player.dropping_gun(Global.inventory_guns[0])
			Global.inventory_guns[0] = Global.inventory_guns[1]
			Global.inventory_guns[1] = which_gun

func remove_gun() -> void:
	if len(Global.inventory_guns) > 0:
		if gun_type == FLAME:
			flame.emitting = false
			fire_sfx.stream_paused = true
		if len(Global.inventory_guns) < 2:
			hands.visible = true
			visible = false
			player.dropping_gun(gun_type)
			gun_type = NO_GUN
			Global.inventory_guns.clear()
		else:
			player.dropping_gun(Global.inventory_guns[1])
			change_gun()
			Global.inventory_guns.remove(1)

func change_gun() -> void:
	if len(Global.inventory_guns) >= 2:
		sound_effect_4.play()
		Global.inventory_guns.invert()
		changing = true
		_pickup_gun(Global.inventory_guns[1])

func _pickup_gun(type) -> void:
	flame.emitting = false
	match type:
		0: # Basic
			visible = true
			hands.visible = false
			gun_pos_flip_false = Vector2(4, -88)
			gun_pos_flip_true = Vector2(4, -88)
			gun_type = BASIC
			muzzle.position.x = 24
			texture = gun_texture[0]
			bullet = load("res://others/bullet/BulletBase.tscn")
		1: # Spread
			visible = true
			hands.visible = false
			gun_pos_flip_false = Vector2(4, -88)
			gun_pos_flip_true = Vector2(4, -88)
			gun_type = SPREAD
			muzzle.position.x = 24
			texture = gun_texture[1]
			bullet = load("res://others/bullet/BulletSpread.tscn")
		2: # Flame
			visible = true
			hands.visible = false
			gun_pos_flip_false = Vector2(4, -88)
			gun_pos_flip_true = Vector2(4, -88)
			gun_type = FLAME
			muzzle.position.x = 26
			texture = gun_texture[2]
		3: # Pistol
			can_fire = true
			visible = true
			hands.visible = false
			gun_pos_flip_false = Vector2(4, -88)
			gun_pos_flip_true = Vector2(-22, -88)
			gun_type = PISTOL
			muzzle.position.x = 8
			texture = gun_texture[3]
			bullet = load("res://others/bullet/BulletPistol.tscn")
		4: # Auto-Aiming
			visible = true
			hands.visible = false
			gun_pos_flip_false = Vector2(4, -88)
			gun_pos_flip_true = Vector2(-22, -88)
			gun_type = AUTO_AIMING
			muzzle.position.x = 8
			texture = gun_texture[4]
			bullet = load("res://others/bullet/BulletAutoAim.tscn")			
		_:
			gun_type = NO_GUN
			visible = false
			hands.visible = true
	if !changing && gun_type != NO_GUN:
		add_gun_at_inventory(gun_type)
	changing = false

# Recoil
func recoil(recoil_force) -> void:
	var dir = Vector2(1, 0).rotated(global_rotation)
	var kickdirection = recoil_force * (dir * -1)
	velocity = velocity + kickdirection

func shoot() -> void: # Shotting with gun
	var bullet_instance = bullet.instance()
	bullet_instance.rotation = rotation
	bullet_instance.global_position = muzzle.global_position
	recoil(20)
	if gun_type == AUTO_AIMING:
		sound_effect_3.play()
	else:	
		sound_effect_1.play()
	get_parent().add_child(bullet_instance)
	get_parent().screen_shake.shake(0.2, 2)
	can_fire = false
	if gun_type == PISTOL:
		yield(get_tree().create_timer(0.2), "timeout")
		can_fire = true

func shoot_spread():
	var rots = [-0.1, 0, 0.1]
	for i in range(3):
		var bullet_instance = bullet.instance()
		bullet_instance.global_position = muzzle.global_position
		bullet_instance.rotation = rotation + rots[i]
		recoil(5)
		get_parent().screen_shake.shake(0.2, 3)
		get_parent().add_child(bullet_instance)
	sound_effect_2.play()
	can_fire = false

func _input(event) -> void:
	if !player.lifebar.getDeath():
		if event.is_action_pressed("ui_change"):
			change_gun()
		if event.is_action_pressed("ui_remove"):
			remove_gun()

func _process(_delta) -> void:
	if gun_type != FLAME:
		enable_flame_area(false)

func _physics_process(_delta: float) -> void:
	flame.global_position = muzzle.global_position
	if !player.lifebar.getDeath() && !Global.finished_level:
		if gun_type != NO_GUN:
			position += velocity
			velocity = velocity * 0.7
			global_position.x = lerp(global_position.x, get_parent().global_position.x, 0.4)
			global_position.y = lerp(global_position.y, get_parent().global_position.y - 90, 0.4)
			
			
			mouse_pos = get_global_mouse_position()
			look_at(mouse_pos)
			flame.look_at(mouse_pos)
		
		# Flipping gun
		if get_parent().get_local_mouse_position().x < 0:
			flip_v = true
			muzzle.position.y = muzzle_pos
			p_knock_side = 1
		else:
			flip_v = false
			muzzle.position.y = -muzzle_pos
			p_knock_side = -1
		
		# Press the left button mouse to shoot
		if Input.is_action_pressed("ui_fire"):
			if can_fire && gun_type != NO_GUN:
				match gun_type:
					SPREAD:
						shoot_spread()
					FLAME:
						flame.emitting = true
						yield(get_tree().create_timer(0.1), "timeout")
						enable_flame_area(true)
						fire_sfx.play()
						fire_sfx.stream_paused = false
					_:
						shoot()
		
		else:
			flame.emitting = false
			fire_sfx.stream_paused = true
			enable_flame_area(false)
			if !can_fire && gun_type != PISTOL:
				can_fire = true
	else:
		can_fire = false
		if !Global.finished_level:
			if flip_v:
				rotation_degrees = -180
			else:
				rotation_degrees = 0

func enable_flame_area(value : bool) -> void:
	flame_area.monitorable = value
	flame_area.monitoring = value
