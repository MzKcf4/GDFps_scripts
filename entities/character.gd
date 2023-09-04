extends FpsEntity

class_name FpsCharacter

signal on_health_update(new_value)
signal on_alive_status_changed(new_value)
signal on_killed(character)

var move_speed = 7.0
const JUMP_VELOCITY = 5.0
const gravity = 9.8

var damage_number_template = preload("res://tscn/damage_number.tscn")

var is_alive: bool = true

@onready var climb_ray : RayCast3D  = $RayCast3D

func get_movement_direction() -> Vector3:
	return Vector3.ZERO

func _physics_process(delta):
	process_movement(delta)

func process_movement(delta):
	var dir = get_movement_direction()
	
	climb_stair()
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if is_on_floor():
		if(dir != Vector3.ZERO):
			velocity.x = lerp(velocity.x , dir.x * move_speed , delta * 7.0)
			velocity.z = lerp(velocity.z , dir.z * move_speed , delta * 7.0)
		else:
			velocity.x = lerp(velocity.x , dir.x * move_speed , delta * 7.0)
			velocity.z = lerp(velocity.z , dir.z * move_speed , delta * 7.0)
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

func spawn():
	self.collision_layer = 1
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
	self.collision_layer = 0
	pass
