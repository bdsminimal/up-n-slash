extends KinematicBody2D

export var own_name = "Zombie"
export var isStationary = false
export(float) var move_speed_x = 1
export var gravity_force = 2000
export(float) var stun_time = 0.6
export(float) var trigger_range = 384
export(float) var trigger_range_before_target = 16
export(float) var trigger_time = 5
export(float) var triggered_vel_accel = 1.4
var blood_ps = preload("res://enemies/aux_scenes/bloodSplatter.tscn")
var gore_ps = preload("res://enemies/aux_scenes/gore.tscn")

signal died
onready var player = get_node("/root/world/Player")
onready var healthbar = get_node("scaler/healthbar")
onready var ground = get_node("/root/world/main_TileMap")

var maxHealth = 6
var health = maxHealth
var damage = 1

var velvec = Vector2()
var snap = Vector2(0, 100)
var isFacingRight = true
var isStriking = false
var isStunned = false
var isTriggered = false
var target = Vector2()
var envCollisionFlags = {
	abyssInfront = false,
	wallInfront = false
}
var isJustDamaged = false
var isJustDamaged_fromRight
var damageIntakeForce

func _ready():
	$stun.wait_time = stun_time
	$trigger.wait_time = trigger_time
	
	$Label.text = own_name

func takeDamage(dmg, isDirRight, DIF): #isDirRight - hit direction
	health -= dmg
	isJustDamaged = true
	isJustDamaged_fromRight = isDirRight
	damageIntakeForce = DIF
	$stun.start()
	isStunned = true
	
	#emit blood particles
	emit_particles("blood", isDirRight)
	
	#is dead
	if health <= 0:
		hide()
		emit_signal("died")
		emit_particles("gore", isDirRight)
		queue_free()
	
	$Label.modulate.a = 0.6
	healthbar.value -= dmg
	$VFX.play("hurt")

func emit_particles(type, isDirRight):
	if type == "blood":
		var blood = blood_ps.instance().init(position.x, position.y, isDirRight, health <= 0)
		get_node("/root/world").add_child(blood)
	elif type == "gore":
		var gore = gore_ps.instance().init(position.x, position.y, isDirRight, isFacingRight, velvec)
		get_node("/root/world").call_deferred("add_child", gore)

func think():
	if !is_on_floor(): return
	
	velvec.x = 0
	if isStationary and !isTriggered:
		set_animation()
		return
	
	if isTriggered:
		$vision_forPlayerPos.cast_to = (player.global_position - $vision_forPlayerPos.global_position)
		if $vision_forPlayerPos.get_collider() == player:
			target = player.position
		if target.x > position.x != isFacingRight:
			commitTurn()
		if envCollisionFlags.abyssInfront or envCollisionFlags.wallInfront:
			set_animation()
			return
		if abs(target.x - position.x) <= trigger_range_before_target:
			set_animation()
			return
	
	velvec.x += move_speed_x * 100 * (1 if isFacingRight else -1)
	set_animation()

func _physics_process(delta):
	#initiate attack
	var targets = $hitArea.get_overlapping_bodies()
	for tar in targets:
		if tar == player and !isStunned:
			isStriking = true
	
	#check for an abyss infront
	if $vision_forGroundBelow.get_collider() != player: if !$vision_forGroundBelow.is_colliding():
		envCollisionFlags.abyssInfront = true
		if !isStunned and !isTriggered: commitTurn()
	else:
		envCollisionFlags.abyssInfront = false
	
	#check for a wall infront
	if $vision_forGroundInfront.is_colliding() and $vision_forGroundInfront.get_collider() != player:
		envCollisionFlags.wallInfront = true
		if !isStunned and !isTriggered: commitTurn()
	else:
		envCollisionFlags.wallInfront = false
	
	#check for player
	$vision_forPlayer.cast_to = (player.global_position - $vision_forPlayer.global_position)
	var lengthLimit = trigger_range
	if $vision_forPlayer.cast_to.x < 0 == isFacingRight: lengthLimit /= 2
	$vision_forPlayer.cast_to = $vision_forPlayer.cast_to.limit_length(lengthLimit)
	if $vision_forPlayer.get_collider() == player: trigger(true)
	
	#think where to move
	think()
	velvec.y += gravity_force * delta
	
	#move and apply knockback
	var oldSnapY = snap.y
	if isJustDamaged:
		isJustDamaged = false
		velvec = damageIntakeForce
		velvec.x *= 1 if isJustDamaged_fromRight else -1
		snap.y = 0
	velvec = move_and_slide_with_snap(velvec, snap, Vector2(0, -1), true)
	snap.y = oldSnapY

func trigger(var mode):
	if mode and !isTriggered:
		isTriggered = true
		if player.position.x < position.x == isFacingRight:
			commitTurn()
		move_speed_x *= triggered_vel_accel
		$trigger.start()
		$Label.modulate.g = 0
		$Label.modulate.b = 0
	elif mode:
		$trigger.start()
	elif !mode and isTriggered:
		isTriggered = false
		move_speed_x /= triggered_vel_accel
		$Label.modulate.g = 1
		$Label.modulate.b = 1

func commitTurn():
	if isStunned or !is_on_floor(): return
	isFacingRight = !isFacingRight
	$vision_forGroundBelow.position.x = -$vision_forGroundBelow.position.x
	$vision_forGroundInfront.position.x = -$vision_forGroundInfront.position.x
	$hitArea.position.x = -$hitArea.position.x

func set_animation():
	$AnimatedSprite_body.speed_scale = 1
	$AnimatedSprite_arms.speed_scale = 1
	if isFacingRight:
		$AnimatedSprite_body.flip_h = true
		$AnimatedSprite_arms.flip_h = true
	else:
		$AnimatedSprite_body.flip_h = false
		$AnimatedSprite_arms.flip_h = false
	
	if isStriking:
		$AnimatedSprite_arms.play("attack")
	if velvec.x == 0:
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
			
			#changing animation speed by move_speed factor
			$AnimatedSprite_arms.speed_scale = move_speed_x
			$AnimatedSprite_arms.frame = $AnimatedSprite_body.frame


func _on_stun_timeout():
	isStunned = false
	$Label.modulate.a = 1


func _on_baseHitArea_body_entered(body):
	if body == player:
		#inflict damage with baseHitArea
		player.takeDamage(damage, player.position.x > position.x, Vector2(400, -400))


func _on_trigger_timeout():
	trigger(false)


func _on_AnimatedSprite_arms_animation_finished():
	if isStriking and $AnimatedSprite_arms.animation == "attack": isStriking = false
func _on_AnimatedSprite_arms_frame_changed():
	if isStriking and ($AnimatedSprite_arms.frame == 4):
		#inflict damage with hitArea
		var targets = $hitArea.get_overlapping_bodies()
		for tar in targets:
			if tar == player:
				player.takeDamage(damage, isFacingRight, Vector2(600, -400))
