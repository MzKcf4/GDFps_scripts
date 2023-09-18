extends FpsCharacter

const BodyParts = preload("res://scripts/constants/body_parts.gd")

@onready var nav_agent = $NavigationAgent3D
@onready var bullet = preload("res://tscn/projectile.tscn")
@onready var clean_up_timer = $Timers/DestroyTimer
@onready var attack_timer = $Timers/AttackIntervalTimer
var jump_timer: Timer
var target_check_timer : Timer

@onready var melee_area : Area3D = $MeleeArea
@onready var audio_player : AudioStreamPlayer3D = $AudioStreamPlayer3D

var blood_particles_scene : PackedScene = preload("res://tscn/blood_effect.tscn")
var damage_number_scene : PackedScene = preload("res://tscn/damage_number.tscn")
var on_hit_sound : Resource = preload("res://sounds/onhit-1.mp3")

var target: Node3D
var is_attack_on_cooldown = false

var server_position: Vector3
var MAX_DISTANCE = 16

func _ready():
	super._ready()
	jump_timer = Timer.new()
	jump_timer.one_shot = true
	jump_timer.timeout.connect(_on_jump_timer_timeout)
	add_child(jump_timer)
	
	if(NetworkManager.is_host):
		ready_host()

func ready_host():
	target_check_timer = Timer.new()
	target_check_timer.one_shot = false
	target_check_timer.timeout.connect(_on_target_check_timer_timeout)
	add_child(target_check_timer)
	target_check_timer.start(3)

func load_model():
	var model_scene = load("res://models/zombie_swarm/zombie_sawrm_2.tscn")
	if(model_scene):
		model.load_model(model_scene)

func get_movement_direction() -> Vector3:
	if(is_alive and target):
		nav_agent.target_position = target.global_position
		var current_location = global_transform.origin
		var next_location = nav_agent.get_next_path_position()
		var dir = (next_location - current_location).normalized()
		return dir
	return Vector3.ZERO

func _physics_process(delta):
	if(!is_alive):
		return
	
	if(NetworkManager.is_host):
		server_position = global_position
		rpc("rpc_sync_server_pos" , server_position)
	else:
		if(server_position.distance_to(global_position) > MAX_DISTANCE):
			self.global_position = server_position

	var root_pos = model.get_root_motion_position()
	model.position = root_pos
	
	super._physics_process(delta)
	nav_agent.velocity = velocity
	
	# To be reworked
	if velocity != Vector3.ZERO:
		var lookdir = atan2(velocity.x, velocity.z)
		rotation.y = lerp(rotation.y, lookdir, 0.1)
		model.set_moving(true)
		if(!jump_timer.is_stopped()):
			jump_timer.stop()
	else:
		var movedir: Vector3 = get_movement_direction()
		var lookdir = atan2(movedir.x, movedir.z)
		rotation.y = lerp(rotation.y, lookdir, 0.1)
		if(jump_timer.is_stopped()):
			jump_timer.start(2)

		model.set_moving(false)

func climb_stair():
	if(climb_ray.is_colliding() && climb_ray.get_collision_normal().y == 1):
		self.position.y = climb_ray.get_collision_point().y
		
	var movedir: Vector3 = get_movement_direction()
	var lookdir = atan2(movedir.x, movedir.z)
	climb_ray.rotation.y = lookdir

func _on_jump_timer_timeout():
	jump()
	
func jump():
	velocity = transform.basis.z.normalized() * JUMP_VELOCITY
	velocity.y = JUMP_VELOCITY
	
func set_target(target):
	self.target = target

func shoot():
	if(target):
		var bullet_obj = bullet.instantiate()
		bullet_obj.position = position
		bullet_obj.transform.basis = global_transform.basis
		get_parent().add_child(bullet_obj)

func hit(weapon: Weapon , hit_pos: Vector3 , source_pos: Vector3 ,body_part):
	if(!is_alive):
		return
	var damage : int = weapon.damage * randf_range(0.9 , 1.1)
	# show on client only
	if(body_part == BodyParts.HEAD):
		damage *= 2.5
		
	rpc("take_damage" , damage)
	var damage_num : DamageNumber = damage_number_scene.instantiate()
	damage_num.text = str(damage)
	damage_num.position = self.global_position + Vector3.UP * 2
	get_tree().root.add_child(damage_num)
	
	rpc("play_hit_effect" , hit_pos , source_pos)
	if(health <= 0):
		kill()
		rpc("kill")

@rpc("any_peer" , "call_local")
func take_damage(damage: int):
	velocity = Vector3.ZERO
	health -= damage

@rpc("any_peer" , "call_local")
func play_hit_effect(hit_pos: Vector3 , source_pos: Vector3):
	model.play_flinch_animation()
	var blood_particles : GPUParticles3D = blood_particles_scene.instantiate()
	add_child(blood_particles)
	blood_particles.global_position = hit_pos
	var direction = source_pos.direction_to(hit_pos)
	blood_particles.look_at(direction * 10 + blood_particles.global_position);
	blood_particles.emitting = true
	audio_player.stream = on_hit_sound
	audio_player.play()

@rpc("any_peer" , "call_local")
func kill():
	if(!is_alive):
		return
	super.kill()
	model.set_moving(false)
	model.play_death_animation()
	velocity = Vector3.ZERO
	clean_up_timer.start()

func can_attack():
	return is_alive && !is_attack_on_cooldown

func find_body_in_melee_area():
	var bodies : Array[Node3D] = melee_area.get_overlapping_bodies()
	for body in bodies:
		if(body.is_in_group("player")):
			body.take_damage(3);
			is_attack_on_cooldown = true
			model.play_attack_animation()
			break

@rpc("call_remote")
func rpc_sync_server_pos(input : Vector3):
	server_position = input

func _on_navigation_agent_3d_target_reached():
	pass

func _on_target_check_timer_timeout():
	if(target && target.is_alive):
		return
	var new_target_id = pick_random_alive_target()
	rpc("rpc_switch_target" , new_target_id)

func pick_random_alive_target() -> int:
	var players = InGameManager.game_world_manager.dict_id_to_player.values()
	var alive_players = players.filter( func(player:FpsCharacter): return player.is_alive )
	if(!alive_players.is_empty()):
		return alive_players.pick_random().net_id
	return -1

@rpc("call_local")
func rpc_switch_target(id: int):
	if(id == -1):
		target = null
	else:
		target = InGameManager.game_world_manager.dict_id_to_player[id]
	
func _on_destroy_timer_timeout():
	queue_free()

func _on_area_3d_body_entered(body):
	if(can_attack()):
		if(body.is_in_group("player")):
			body.take_damage(15);
			attack_timer.start(2)
			is_attack_on_cooldown = true
			model.play_attack_animation()
	pass # Replace with function body.


func _on_attack_interval_timer_timeout():
	is_attack_on_cooldown = false
	pass # Replace with function body.


func _on_attack_check_timer_timeout():
	if(can_attack()):
		find_body_in_melee_area()
	pass # Replace with function body.
