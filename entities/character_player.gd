extends FpsCharacter

class_name FpsPlayer

const BodyParts = preload("res://scripts/constants/body_parts.gd")
const bulletTraceRes = preload("res://tscn/bullet_trace.tscn")

const SENSITIVITY = 0.01

#camera bob vars
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var fps_view_port = $Head/Camera3D/FpsView
@onready var weapon_slot = $Head/Camera3D/FpsView/Weapon
@onready var arm_slot = $Head/Camera3D/FpsView/Arm
@onready var audio_player = $AudioStreamPlayer3D
@onready var name_label : Label3D = $Label_Name

signal on_weapon_fire(weapon: Weapon)
signal on_hit_enemy(enemy: FpsCharacter)
signal on_weapon_reload(weapon: Weapon)

var arm_model : ArmModel
var weapons : Array[Weapon] = [null , null , null]
var active_weapon : Weapon

var can_control: bool = true
var up_recoil : float = 0.0

var mouse_mode = Input.MOUSE_MODE_CAPTURED
var mouse_mov
var sway_threshold = 5
var sway_lerp = 5

var sway_left : Vector3 = Vector3(0, 0.1 , 0)
var sway_right : Vector3 = Vector3(0, -0.1 , 0)
var sway_normal : Vector3

var multiplayer_id = -1

func get_movement_direction() -> Vector3:
	if not can_control:
		return Vector3.ZERO
	var input_dir = Input.get_vector( "move_left", "move_right", "move_forward", "move_backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	return direction
	
func _ready():
	add_to_group("player")
	# this MUST be done otherwise there will be bug
	name = str(get_multiplayer_authority())
	multiplayer_id = name
	if(not is_multiplayer_authority()):
		can_control = false
		camera.queue_free()
		return
	else:
		name_label.visible = false
		rpc("rpc_set_name" , name)
	
	# Prepare arm
	arm_model = preload("res://arms/HK416_MOD3/hk_416_mod_3_arms.tscn").instantiate()
	arm_slot.add_child(arm_model)
	spawn()

@rpc("call_remote")
func rpc_set_name(name: String):
	name_label.text = name

func spawn():
	super.spawn()
	can_control = true

func get_weapon(weapon_tscn_path : String):
	if(not is_multiplayer_authority()):
		return
	if(active_weapon != null):
		active_weapon.visible = false
		active_weapon.queue_free()
	weapons[0] = load(weapon_tscn_path).instantiate()
	weapon_slot.add_child(weapons[0])
	switch_weapon(0)

func _input(event):
	if not is_multiplayer_authority() || not InGameManager.local_player_manager.can_process_input():
		return
	if (event is InputEventMouseMotion):
		head.rotate_y(-event.relative.x * SettingsManager.get_effective_mouse_sensitivity())
		camera.rotate_x(-event.relative.y * SettingsManager.get_effective_mouse_sensitivity())
		camera.rotation.x = clamp(camera.rotation.x , deg_to_rad(-70) , deg_to_rad(70))
		mouse_mov = -event.relative.x

func process_input():
	if(Input.is_action_just_pressed("toggle_cursor")):
		if(mouse_mode == Input.MOUSE_MODE_CAPTURED):
			mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			mouse_mode = Input.MOUSE_MODE_CAPTURED
		Input.set_mouse_mode(mouse_mode)
	if Input.is_action_pressed("reload"):
		reload()
	if Input.is_action_pressed("slot_1"):
		switch_weapon(0)
	if Input.is_action_pressed("slot_2"):
		switch_weapon(1)

func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("escape"):
		InGameManager.local_player_manager.toggle_player_menu()
		return

	super._physics_process(delta)
	
	if not can_control:
		return
		
	var fired = false;
	if(InGameManager.local_player_manager.can_process_input()):
		process_input()
		if Input.is_action_pressed("fire"):
			fired = shoot()
	
	if fired:
		var recoil = randf_range(1000 , 1500)
		up_recoil += recoil * delta
		camera.rotation.x = lerp(camera.rotation.x , deg_to_rad(camera.rotation_degrees.x + up_recoil) , delta)
		if(up_recoil >= 35):
			up_recoil = 35
	else:
		up_recoil = 0
	
	# Weapon sway
	if(mouse_mov != null):
		if(mouse_mov > sway_threshold):
			fps_view_port.rotation = fps_view_port.rotation.lerp(sway_left , sway_lerp * delta)
		elif (mouse_mov < -sway_threshold):
			fps_view_port.rotation = fps_view_port.rotation.lerp(sway_right , sway_lerp * delta)
		else:
			fps_view_port.rotation = fps_view_port.rotation.lerp(sway_normal , sway_lerp * delta)
			
	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	

	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	# calls the rpc function for this object , on all other peers
	rpc("remote_set_position", global_position)


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ/2) * BOB_AMP
	return pos

func reload():
	if(active_weapon == null):
		return
	active_weapon.reload()
	on_weapon_reload.emit(active_weapon)

func switch_weapon(slot: int):
	if(weapons[slot] == null):
		return
	if(active_weapon != null):
		active_weapon.visible = false
	
	active_weapon = weapons[slot]
	active_weapon.visible = true
	active_weapon.deploy()
	arm_model.bind_to_weapon(active_weapon)
	pass


func shoot() -> bool:
	if(active_weapon == null):
		return false
	var fired = active_weapon.fire()
	if(not fired):
		return false
	on_weapon_fire.emit(active_weapon)
	var space = get_world_3d().direct_space_state
	
	# shoot a ray of 100m from camera
	var mask = 0b00000000_00000000_00000000_00000010
	var query = PhysicsRayQueryParameters3D.create(camera.global_position,camera.global_position - camera.global_transform.basis.z * 100 , mask)
	var bullet_to: Vector3 = (camera.global_position - camera.global_transform.basis.z * 100)
	query.collide_with_areas = true
	var collision = space.intersect_ray(query)
	if collision and collision.collider.is_in_group("Head"):
		# collision.collider = BodyParts
		# collision.collider.owner = Model Scene ( e.g zombie_sawrm.tscn )
		# ... .get_parent() = Model Slot of Character Node
		# ... .owner = Character Node ( FpsCharacter ) 
		var character = collision.collider.owner.get_parent().owner
		character.hit(active_weapon, collision.position , camera.global_position , BodyParts.HEAD)
		bullet_to = collision.position
		on_hit_enemy.emit(character)
	if collision and collision.collider.is_in_group("Body"):
		var character = collision.collider.owner.get_parent().owner
		character.hit(active_weapon, collision.position , camera.global_position , BodyParts.BODY)
		on_hit_enemy.emit(character)
		bullet_to = collision.position
	
	rpc("rpc_create_bullet" , self.global_position , bullet_to)
	return true

@rpc("call_remote")
func play_weapon_fire():
	audio_player.play(active_weapon.get_weapon_fire_sound())

@rpc("call_local")
func rpc_create_bullet(from: Vector3 , to: Vector3):
	var bullet_instance = bulletTraceRes.instantiate()
	bullet_instance.destination = to
	bullet_instance.position = from
	get_parent().add_child(bullet_instance)

# this call makes 60 times per second , so unreliable is better
@rpc("unreliable")
func remote_set_position(authority_position):
	global_position = authority_position

func take_damage(damage: int):
	super.take_damage(damage)

func kill():
	super.kill()
	can_control = false;

func teleport_to(position: Vector3):
	if(is_multiplayer_authority()):
		self.position = position
