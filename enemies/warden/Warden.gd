extends KinematicBody2D

export var own_name = "Warden"
export var isStationary = false
export(float) var move_speed_x = 1
export var gravity_force = 2000
export(float) var attackCD_time = 1
export(float) var stun_time = 0.6
export(float) var trigger_range = 512
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
var isAttackReady = true
var isStunned = false
var isTriggered = false
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
	if isStationary and !isTriggered: return
	
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

func trigger(var mode):
	if mode and !isTriggered:
		isTriggered = true
		if player.position.x < position.x == isFacingRight:
			commitTurn()
		move_speed_x *= triggered_vel_accel
		$triggered.start()
		$Label.modulate.g = 0
		$Label.modulate.b = 0
	elif !mode and isTriggered:
		isTriggered = false
		move_speed_x /= triggered_vel_accel
		$Label.modulate.g = 1
		$Label.modulate.b = 1

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
	
	#check for an abyss infront
	if !$vision_forGroundBelow.is_colliding() and $vision_forGroundBelow.get_collider() != player:
		turnPossible = true #override
		if !isStunned:commitTurn()
	
	#check for player
	$vision_forPlayer.cast_to = (player.position - position)
	if $vision_forPlayer.get_collider() == player:
		if $vision_forPlayer.cast_to.x > 0 == isFacingRight:
			if position.distance_to(player.position) <= trigger_range:
				trigger(true)
		elif position.distance_to(player.position) <= (trigger_range / 2):
			trigger(true)
	
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
	isStunned = false
	$Label.modulate.a = 1


func _on_hitArea_body_entered(body):
	if body != player:
		turnPossible = true #override
		commitTurn()



func _on_turnCD_timeout():
	turnPossible = true


func _on_triggered_timeout():
	trigger(false)
