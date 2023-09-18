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

var net_id : int = -1

func _init():
	pass
	
func _ready():
	add_to_group("player")
	# this MUST be done otherwise there will be bug
	net_id = get_multiplayer_authority()
	name = str(net_id)
	super._ready()

	if(not is_multiplayer_authority()):
		can_control = false
		camera.queue_free()
		return
	else:
		_ready_local()

func load_model():
	var model_scene = load("res://models/hk416_mod3/hk_416_mod_3.tscn")
	if(model_scene):
		model.load_model(model_scene)


func _ready_local():
	model.visible = false
	# player name
	name_label.visible = false
	rpc("rpc_set_name" , name)
	# Prepare arm
	arm_model = preload("res://arms/HK416_MOD3/hk_416_mod_3_arms.tscn").instantiate()
	arm_slot.add_child(arm_model)
	# hear less of self footstep
	footstep_player.volume_db = -25

@rpc("call_remote")
func rpc_set_name(player_name: String):
	name_label.text = player_name

func spawn(spawn_pos: Vector3):
	super.spawn(spawn_pos)
	can_control = is_multiplayer_authority()

func get_weapon(weapon_id : String):
	if(not is_multiplayer_authority()):
		return
	if(active_weapon != null):
		active_weapon.visible = false
		active_weapon.queue_free()
	weapons[0] = ResourceManager.get_weapon(weapon_id)
	weapon_slot.add_child(weapons[0])
	switch_weapon(0)
	
func get_movement_direction() -> Vector3:
	if not can_control or not is_alive:
		return Vector3.ZERO
	var input_dir = Input.get_vector( "move_left", "move_right", "move_forward", "move_backward")
	var direction = (self.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	return direction

func _input(event):
	if not is_multiplayer_authority() || not InGameManager.local_player_manager.can_process_input():
		return
	if (event is InputEventMouseMotion):
		self.rotate_y(-event.relative.x * SettingsManager.get_effective_mouse_sensitivity())
		#self.rotation.
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
	if Input.is_action_pressed("kill"):
		kill()

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
	var is_moving = get_movement_direction() != Vector3.ZERO
	rpc("remote_set_position", global_position , self.rotation , is_moving)


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
	
	var bullet_dest = camera.global_transform.basis.z * 100
	bullet_dest.x += randf_range(-5 , 5)
	bullet_dest.y += randf_range(-5 , 5)
	
	# shoot a ray of 100m from camera
	var mask = 0b00000000_00000000_00000000_00000100
	var query = PhysicsRayQueryParameters3D.create(camera.global_position,camera.global_position - bullet_dest , mask)
	var bullet_to: Vector3 = (camera.global_position - bullet_dest)
	
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
	elif collision and collision.collider.is_in_group("Body"):
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
func remote_set_position(auth_pos: Vector3 , auth_rotation: Vector3 , is_moving: bool):
	self.global_position = auth_pos
	self.rotation = auth_rotation
	model.set_moving(is_moving)

func take_damage(damage: int):
	super.take_damage(damage)

func kill():
	rpc("rpc_kill")

@rpc("call_local")
func rpc_kill():
	super.kill()
	can_control = false;
