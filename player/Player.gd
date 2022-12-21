extends KinematicBody2D

export(float) var move_speed_x = 1
export var jump_strength = 1000
export var dash_strength = 1200
export var gravity_force = 2000
export(int) var camera_limit_left = -10000000
export(int) var camera_limit_right = 10000000
export(int) var camera_limit_top = -10000000
export(int) var camera_limit_bottom = 10000000
export var isOnMenu = false

#onready var healthbar = get_node("HUD/healthbar")
#onready var VFX_player = get_node("HUD/SH_VFX_player")

var maxHealth = 9
var health = maxHealth
var damage = 1

var velvec = Vector2()
var snap = Vector2(0, 100)
var old_isFacingRight = true
var isFacingRight = true
var isJumping = false
var isStriking = false
var maxHealthChanged = false
var isJustDamaged = false
var controlsBlocked_forced = true
var controlsBlockedByKnockback = false
var isJustDamaged_fromRight

func _ready():
	#isOnMenu
	if isOnMenu:
		$HUD.hide()
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	#camera manipulations
	$Camera2D.current = true
	$Camera2D.limit_left = camera_limit_left
	$Camera2D.limit_right = camera_limit_right
	$Camera2D.limit_top = camera_limit_top
	$Camera2D.limit_bottom = camera_limit_bottom
	
	#HUD update
	$HUD.change_healthbar(health, maxHealth, 0)
	
	#multiple signals connection
	var enemies = get_tree().get_nodes_in_group("enemy")  
	for enemy in enemies:
		enemy.connect("died", self, "_on_enemy_died")

func raiseDamage(dmg):
	damage += dmg

func takeDamage(dmg, isDirRight): #isDirRight - hit direction
	health -= dmg
	if health <= 0: get_tree().reload_current_scene()
	isJustDamaged_fromRight = isDirRight
	isJustDamaged = true
	controlsBlockedByKnockback = true
	changeHealth_visuals(-dmg)

func heal(hp): #if hp less than 0 then its a powerup
	if hp > 0:
		health += hp
		if health > maxHealth:
			if (health - maxHealth == hp): hp = 0
			health = maxHealth
	else:
		maxHealth -= hp
		health = maxHealth
		maxHealthChanged = true
	
	changeHealth_visuals(hp)

func changeHealth_visuals(amount):
	if !maxHealthChanged:
		if amount < 0:
			$VFX.play("hurt")
		elif amount != 0:
			$VFX.play("heal")
	
	#HUD manipulations
	var type = -1 if amount == 0 and !maxHealthChanged else (0 if maxHealthChanged else (1 if amount > 0 else 2))
	$HUD.change_healthbar(health, maxHealth, type)
	maxHealthChanged = false

func get_input():
	if controlsBlocked_forced: return
	if controlsBlockedByKnockback: if !is_on_floor() or isJustDamaged:
		set_animation()
		return
	else: controlsBlockedByKnockback = false
	
	velvec.x = 0
	
	#movement
	if Input.is_action_just_pressed('jump') and is_on_floor():
		velvec.y = -jump_strength
		snap.y = 0
		isJumping = true
	else:
		snap.y = 100
		isJumping = !is_on_floor()
	
	old_isFacingRight = isFacingRight
	if Input.is_action_pressed('move_right'):
		velvec.x += move_speed_x * 460
		isFacingRight = true
	if Input.is_action_pressed("move_left"):
		velvec.x -= move_speed_x * 460
		isFacingRight = false
	if isFacingRight != old_isFacingRight: $hitArea.position.x = -$hitArea.position.x
#	if Input.is_action_pressed("descent"):
#		var tile_map = get_node("/root/world/main_TileMap")
#		var tile_pos = tile_map.world_to_map(position/0.4)
#		tile_pos.y += 1
#		if tile_map.tile_set.tile_get_name(tile_map.get_cellv(tile_pos)) in ["platform_right", "platform_left", "platform_center"]:
#			$CollisionShape2D.disabled = true
#			isJumping = true
#		else:
#			$CollisionShape2D.disabled = false
#	elif Input.is_action_just_released("descent"):
#		$CollisionShape2D.disabled = false
	
	#fighting
	if (Input.is_action_pressed("attack")):
		isStriking = true
		
	
	set_animation()
	
	#debug purposes only
	if (Input.is_action_pressed("reload_game")): get_tree().reload_current_scene()

func _physics_process(delta):
	get_input()
	velvec.y += gravity_force * delta
	#move and apply knockback
	if isJustDamaged:
		isJustDamaged = false
		isJumping = true
		velvec = move_and_slide_with_snap(Vector2(400 * (1 if isJustDamaged_fromRight else -1), -600), Vector2(0, 0), Vector2(0, -1), true)
	else: velvec = move_and_slide_with_snap(velvec, snap, Vector2(0, -1), true)
	
	#debug purposes only
	#$velvecRect.rect_position.x = velvec.normalized().x * 100 - 8
	#$velvecRect.rect_position.y = velvec.normalized().y * 100 - 8

func set_animation():
	$AnimatedSprite_body.speed_scale = 1
	if isFacingRight:
		$AnimatedSprite_body.flip_h = false
		$AnimatedSprite_arms.flip_h = false
	else:
		$AnimatedSprite_body.flip_h = true
		$AnimatedSprite_arms.flip_h = true
	
	if isStriking:
		$AnimatedSprite_arms.play("attack")
	if isJumping:
		$AnimatedSprite_body.play("jump")
		if !isStriking: $AnimatedSprite_arms.play("jump")
		if $AnimatedSprite_body.frame == 2 and velvec.y < 0:
			$AnimatedSprite_body.stop()
			if !isStriking: $AnimatedSprite_arms.stop()
		elif velvec.y > 0:
			$AnimatedSprite_body.play()
			if !isStriking: $AnimatedSprite_arms.play()
	elif velvec.x == 0:
		if (!isStriking):
			$AnimatedSprite_body.play("idle")
			$AnimatedSprite_arms.play("idle")
			$AnimatedSprite_arms.frame = $AnimatedSprite_body.frame
		else:
			$AnimatedSprite_body.play("attack")
	else:
		$AnimatedSprite_body.play("walk")
		
		#changing animation speed by move_speed factor
		$AnimatedSprite_body.speed_scale = move_speed_x
		if (!isStriking):
			$AnimatedSprite_arms.play("walk")
			$AnimatedSprite_arms.frame = $AnimatedSprite_body.frame


func _on_AnimatedSprite_arms_animation_finished():
	if isStriking: isStriking = false
func _on_AnimatedSprite_arms_frame_changed():
	if isStriking and ($AnimatedSprite_arms.frame == 2):
		#inflict damage with hitArea
		var targets = $hitArea.get_overlapping_bodies()
		for tar in targets:
			tar.takeDamage(damage, isFacingRight)


func _on_enemy_died():
	heal(2)


func _on_HUD_loaded():
	if !isOnMenu: controlsBlocked_forced = false


func _on_VFX_animation_started(anim_name):
	$AnimatedSprite_arms.modulate = Color(1,1,1,1)
	$AnimatedSprite_body.modulate = Color(1,1,1,1)
