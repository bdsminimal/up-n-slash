extends KinematicBody2D

export var own_name = "Warden"
export var isStationary = false
export(float) var move_speed_x = 1
export var gravity_force = 2000
export(float) var attackCD_time = 1
export(float) var stun_time = 0.6
export(float) var chase_init_range = 384
var blood_ps = preload("res://enemies/aux_scenes/bloodSplatter.tscn")
var gore_ps = preload("res://enemies/aux_scenes/gore.tscn")

signal died
onready var player = get_node("/root/world/Player")
onready var healthbar = get_node("scaler/healthbar")
onready var ground = get_node("/root/world/main_TileMap")

var maxHealth = 10
var health = maxHealth
var damage = 1

var velvec = Vector2()
var snap = Vector2(0, 100)
var isFacingRight = true
var isAttackReady = true
var isStunned = false
var hasTarget = false
var target
var delayedChase = false
var turnPossible = true
var isJustDamaged = false
var isJustDamaged_fromRight

func _ready():
	$stun.wait_time = stun_time
	$AnimatedSprite.speed_scale = move_speed_x
	$attackCD.wait_time = attackCD_time
	
	$Label.text = own_name

func takeDamage(dmg, isDirRight): #isDirRight - hit direction
	health -= dmg
	isJustDamaged = true
	isJustDamaged_fromRight = isDirRight
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
	
	delayedChase = true
	
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
	if isStationary and !hasTarget: return
	
	if hasTarget: if target.x < position.x == isFacingRight:
		commitTurn()
	
	velvec.x += move_speed_x * 160

func commitTurn():
	if !turnPossible or isStunned or !is_on_floor(): return
	turnPossible = false
	$turnCD.start()
	move_speed_x *= -1
	isFacingRight = !isFacingRight
	$vision_forGroundBelow.position.x = -$vision_forGroundBelow.position.x
	$hitArea.position.x = -$hitArea.position.x
	$AnimatedSprite.flip_h = !$AnimatedSprite.flip_h

func chase(var mode):
	if mode and !hasTarget:
		hasTarget = true
		target = player.position
		move_speed_x *= 1
		$memoryTimer.start()
	elif !mode and hasTarget:
		hasTarget = false
		move_speed_x /= 1

func _physics_process(delta):
	#inflict damage
	if isAttackReady and !isStunned:
		var bodies_in_hitArea = $hitArea.get_overlapping_bodies()
		for body in bodies_in_hitArea:
			if body == player:
				var isDirRight = player.position.x > position.x
				player.takeDamage(damage, isDirRight)
				$attackCD.start()
				isAttackReady = false
	
	#check for an abyse infront
	if !$vision_forGroundBelow.is_colliding():
		chase(false)
		turnPossible = true #override
		commitTurn()
	elif $vision_forGroundBelow.get_collision_point().y - global_position.y > 136:
		if !hasTarget and !isStunned: commitTurn()
	
	#check for player visibility
	$vision_forPlayer.cast_to = (player.position - position)
	if $vision_forPlayer.cast_to.x > 0 == isFacingRight and !hasTarget:
		if $vision_forPlayer.get_collider() == player and position.distance_to(player.position) <= chase_init_range:
			chase(true)
	
	#in-chase pathfinding
	if hasTarget:
		if $vision_forPlayer.get_collider() == player:
			target = player.position
	
	#think where to move
	think()
	velvec.y += gravity_force * delta
	
	#move and apply knockback
	if isJustDamaged:
		isJustDamaged = false
		velvec = move_and_slide_with_snap(Vector2(200 * (1 if isJustDamaged_fromRight else -1), -400), Vector2(0, 0), Vector2(0, -1), true)
	else: velvec = move_and_slide_with_snap(velvec, snap, Vector2(0, -1), true)

func _on_attackCD_timeout():
	isAttackReady = true


func _on_stun_timeout():
	if delayedChase:
		delayedChase = false
		chase(true)
	isStunned = false
	$Label.modulate.a = 1


func _on_memoryTimer_timeout():
	chase(false)


func _on_hitArea_body_entered(body):
	if body != player:
		chase(false)
		turnPossible = true #override
		commitTurn()
	else: chase(true)



func _on_turnCD_timeout():
	turnPossible = true
