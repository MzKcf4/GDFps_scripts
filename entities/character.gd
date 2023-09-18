extends FpsEntity

class_name FpsCharacter

const Constants = preload("res://scripts/constants/constants.gd")

signal on_health_update(new_value)
signal on_alive_status_changed(new_value)
signal on_killed(character)

var move_speed = 7.0
const JUMP_VELOCITY = 5.0
const gravity = 9.8

var damage_number_template = preload("res://tscn/damage_number.tscn")

var is_alive: bool = true

@onready var climb_ray : RayCast3D  = $RayCast3D
@onready var model: CharacterModel = $Model

var footstep_player : AudioStreamPlayer3D
var footstep_timer : Timer

var hooks = []

func _ready():
	load_model()
	footstep_player = AudioStreamPlayer3D.new()
	footstep_player.volume_db = -5
	add_child(footstep_player)
	footstep_timer = Timer.new()
	footstep_timer.one_shot = true
	add_child(footstep_timer)
	pass

func load_model():
	pass

func add_hook(hook):
	if(!hook):
		return
	hooks.append(hook)
	hook.init_hook(self)

func get_movement_direction() -> Vector3:
	return Vector3.ZERO

func _physics_process(delta):
	process_movement(delta)

func _physics_process_post(delta):
	pass
	
func process_movement(delta):
	if(!is_alive):
		return
	var dir = get_movement_direction()
	
	climb_stair()
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if is_on_floor():
		velocity.x = lerp(velocity.x , dir.x * move_speed , delta * 7.0)
		velocity.z = lerp(velocity.z , dir.z * move_speed , delta * 7.0)
		if(dir != Vector3.ZERO && footstep_timer.time_left <= 0):
			footstep_player.set_stream(ResourceManager.get_footstep())
			footstep_player.pitch_scale = randf_range(0.8 , 1.2)
			footstep_player.play()
			footstep_timer.start(0.35)
	else:
		velocity.x = lerp(velocity.x , dir.x * move_speed , delta * 3.0)
		velocity.z = lerp(velocity.z , dir.z * move_speed , delta * 3.0)
	move_and_slide();

func climb_stair():
	if(climb_ray.is_colliding() && climb_ray.get_collision_normal().y == 1):
		self.position.y = climb_ray.get_collision_point().y + 1
	
	var move_dir = get_movement_direction()
	if(move_dir != Vector3.ZERO):
		var new_climb_pos = move_dir * 0.8
		new_climb_pos.y = -0.5
		climb_ray.position = new_climb_pos

func spawn(spawn_pos: Vector3):
	self.position = spawn_pos
	# small wait to prevent position get override by physics process
	await get_tree().create_timer(0.05).timeout
	self.set_collision_mask_value(Constants.LAYER_ID_ENTITY , true)
	self.set_collision_layer_value(Constants.LAYER_ID_ENTITY , true)
	health = max_health
	is_alive = true;
	on_health_update.emit(health);
	on_alive_status_changed.emit(is_alive);
	
func take_damage(damage: int):
	if(!is_alive):
		return
	health -= damage
	on_health_update.emit(health);
	if(health <= 0):
		kill()

func kill():
	if(!is_alive):
		return
	is_alive = false
	on_alive_status_changed.emit(is_alive);
	on_killed.emit(self)
	# So the corpse won't block 
	self.set_collision_mask_value(Constants.LAYER_ID_ENTITY , false)
	self.set_collision_layer_value(Constants.LAYER_ID_ENTITY , false)

func update_speed(temp_up : bool):
	if(temp_up):
		rpc("rpc_add_speed")
	else:
		rpc("rpc_remove_speed")
	pass
	
@rpc("call_local")
func rpc_add_speed():
	self.move_speed *= 1.5

@rpc("call_local")
func rpc_remove_speed():
	self.move_speed /= 1.5

func update_model_color(color: Color):
	rpc("rpc_update_model_color" , color)

@rpc("call_local")
func rpc_update_model_color(color: Color):
	model.update_mesh_color(color)
