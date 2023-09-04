#extends "res://scripts/entities/entity.gd"
#
#@onready var nav_agent = $NavigationAgent3D
#@onready var bullet = preload("res://tscn/projectile.tscn")
#@onready var timer = $Timers/Timer
#@onready var clean_up_timer = $Timers/DestroyTimer
#@onready var attack_timer = $Timers/AttackIntervalTimer
#@onready var melee_area : Area3D = $MeleeArea
#
#@onready var model_slot = $Model
#var blood_particles_scene : PackedScene = preload("res://tscn/BloodParticles.tscn")
#
#
#@export var model: PackedScene
#
#var is_dead: bool = false
#var can_attack: bool = true
#var gravity = 9.8
#var SPEED = 3.0
#var target: Node3D
#
#func _ready():
#	if(model) :
#		model_slot.load_model(model)
#
#func _physics_process(delta):
#	if (not is_dead and target and is_on_floor()) :
#		nav_agent.target_position = target.global_position
#		var current_location = global_transform.origin
#		var next_location = nav_agent.get_next_path_position()
#		var new_velocity = (next_location - current_location).normalized() * SPEED
#		velocity = new_velocity
#
#	if not is_on_floor():
#		velocity.y -= gravity * delta
#
#	if velocity != Vector3.ZERO:
#		var lookdir = atan2(velocity.x, velocity.z)
#		rotation.y = lerp(rotation.y, lookdir, 0.1)
#		model_slot.set_moving(true)
#	else:
#		model_slot.set_moving(false)
#
#	move_and_slide()
#
#func set_target(target):
#	self.target = target
#
#func shoot():
#	if(target):
#		var bullet_obj = bullet.instantiate()
#		bullet_obj.position = position
#		bullet_obj.transform.basis = global_transform.basis
#		get_parent().add_child(bullet_obj)
#
#func hit(hit_pos: Vector3 , source_pos: Vector3):
#	if(is_dead):
#		return
#	# take_damage(5)
#	rpc("take_damage" , 5)
#	play_hit_effect(hit_pos , source_pos)
#	rpc("play_hit_effect" , hit_pos , source_pos)
#	if(health <= 0):
#		kill()
#		rpc("kill")
#
#@rpc("any_peer" , "call_local")
#func take_damage(damage: int):
#	velocity = Vector3.ZERO
#	health -= damage
#
#@rpc("any_peer")
#func play_hit_effect(hit_pos: Vector3 , source_pos: Vector3):
#	var blood_particles : GPUParticles3D = blood_particles_scene.instantiate()
#	add_child(blood_particles)
#	var direction = (self.global_position - source_pos).normalized() * 10
#	blood_particles.global_position = hit_pos
#	blood_particles.process_material.direction = direction
#	blood_particles.emitting = true
#
#@rpc("any_peer")
#func kill():
#	if(is_dead):
#		return
#	model_slot.play_death_animation()
#	is_dead = true
#	velocity = Vector3.ZERO
#	clean_up_timer.start()
#
#func find_body_in_melee_area():
#	var bodies : Array[Node3D] = melee_area.get_overlapping_bodies()
#	for body in bodies:
#		if(body.is_in_group("player")):
#			body.take_damage(60);
#			print (body)
#			can_attack = false
#			break
#
#func _on_timer_timeout():
#	pass
#	# shoot()
#
#
#func _on_navigation_agent_3d_target_reached():
#	print('reached')
#
#
#func _on_destroy_timer_timeout():
#	queue_free()
#
#func _on_area_3d_body_entered(body):
#	if(can_attack):
#		if(body.is_in_group("player")):
#			body.take_damage(60);
#			attack_timer.start(2)
#			can_attack = false
#	pass # Replace with function body.
#
#
#func _on_attack_interval_timer_timeout():
#	can_attack = true
#	pass # Replace with function body.
#
#
#func _on_attack_check_timer_timeout():
#	if(can_attack):
#		find_body_in_melee_area()
#	pass # Replace with function body.
