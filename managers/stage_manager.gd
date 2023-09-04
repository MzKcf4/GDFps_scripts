extends Node

class_name StageManager

@export var enemy_config: Array[EnemyInfo]
var dict_name_to_res: Dictionary = {}

var spawn_remaining = 10;

@onready var enemy_scene : PackedScene = preload("res://tscn/entity_ai.tscn")
var enemy_spawn_container : Node
const SPAWN_REMAIN = 25
var enemy_spawn_points: Array[Node]
var enemy_spawn_remain : int = SPAWN_REMAIN
var enemy_spawned_max : int = 8
var enemy_spawned : int = 0
var enemy_respawn_time : int = 5.0
var enemy_id = 0

var stage = 1;
const SPEED_MULTIPLIER_PER_STAGE = 1.1
const HEALTH_MULTIPLIER_PER_STAGE = 1.3


var player_spawn : Node3D
const PLAYER_RESPAWN_TIME = 2
var dict_player_id_to_respawn_time : Dictionary = {}
# Not safe
var dict_id_to_player : Dictionary = {}

var spawn_timer : Timer
@export var ary_respawn_time : Array[float];
var timer_elapsed: int = 0


var dict_stage_weapons : Dictionary = {
	1 : "res://weapons/hk416c/hk416c.tscn",
	2 : "res://weapons/car/car.tscn",
	3 : "res://weapons/ak47/ak47.tscn"
	}

func _init():
	InGameManager.stage_manager = self
	
func _ready():
	ary_respawn_time = []
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	timer_elapsed = 0
	
	player_spawn = get_tree().get_current_scene().find_child("PlayerSpawn")
	enemy_spawn_container = get_tree().get_current_scene().find_child("EnemySpawns")
	enemy_spawn_points = enemy_spawn_container.get_children()
	pass

func game_start():
	stage = 1
	for i in enemy_spawned_max:
		ary_respawn_time.push_back(i)
	spawn_timer.start(1)
	rpc("rpc_deploy_weapon" , dict_stage_weapons[1])
	for player in dict_id_to_player.values():
		player.on_killed.connect(on_player_killed)
	
func advance_stage():
	stage += 1
	enemy_spawn_remain = SPAWN_REMAIN
	for i in enemy_spawned_max:
		ary_respawn_time.push_back(i)
	if(stage <= 3):
		rpc("rpc_deploy_weapon" , dict_stage_weapons[stage])

func _on_spawn_timer_timeout():
	timer_elapsed += 1
	for id in dict_player_id_to_respawn_time.keys():
		if dict_player_id_to_respawn_time[id] <= timer_elapsed:
			rpc("rpc_respawn_player" , id)
			dict_player_id_to_respawn_time.erase(id)
	
	while(ary_respawn_time.size() > 0 && ary_respawn_time[0] <= timer_elapsed):
			ary_respawn_time.pop_front()
			spawn_enemy()

func spawn_enemy():
	if(enemy_spawn_remain <= 0):
		return
	var spawn_position : Vector3 = enemy_spawn_points[randi() % enemy_spawn_points.size()].global_position
	var rand_peer_id = NetworkManager.connected_peer_ids[randi() % NetworkManager.connected_peer_ids.size()]
	rpc("rpc_spawn_enemy" , rand_peer_id , enemy_id , spawn_position)
	enemy_id +=1

@rpc("call_local")
func rpc_spawn_enemy(target_id: int , enemy_id: int , spawn_position : Vector3):
	var enemy = enemy_scene.instantiate()
	var target_player = dict_id_to_player[target_id]
	enemy_spawned += 1
	enemy_spawn_remain -= 1
	get_tree().get_current_scene().add_child(enemy)
	enemy.global_position = spawn_position
	enemy.position.x += randi_range(-1,1)
	enemy.position.z += randi_range(-1,1)
	enemy.position.y += randi_range(0,2)
	enemy.set_target(target_player)
	enemy.name = str("enemy_" , enemy_id)
	enemy.move_speed *= pow(SPEED_MULTIPLIER_PER_STAGE , stage-1)
	enemy.max_health = 500 * pow(HEALTH_MULTIPLIER_PER_STAGE , stage-1)
	enemy.health = enemy.max_health
	enemy.on_killed.connect(on_enemy_killed)
	update_game_info_label()

func on_enemy_killed(enemy: FpsCharacter):
	enemy_spawned -= 1
	update_game_info_label()
	if(enemy_spawned <= 0 && enemy_spawn_remain <= 0):
		advance_stage()
	else:
		ary_respawn_time.push_front(timer_elapsed + enemy_respawn_time)

func on_player_killed(player : FpsCharacter):
	if(!NetworkManager.is_host):
		return
	print('killed')
	if(check_lose_condition()):
		do_lost()
	else:
		queue_player_respawn(player)

func check_lose_condition():
	return false
	for player in dict_id_to_player.values():
		if(player.is_alive):
			return false
	return true

func queue_player_respawn(player : FpsCharacter):
	var id = player.get_multiplayer_authority()
	dict_player_id_to_respawn_time[id] = timer_elapsed + PLAYER_RESPAWN_TIME

@rpc("call_local")
func rpc_respawn_player(player_id: int):
	var player: FpsPlayer = dict_id_to_player[player_id]
	if(player.is_multiplayer_authority()):
		player.spawn()
		var pos = player_spawn.global_position
		pos.x += randi_range(0,3)
		pos.y += randi_range(4,8)
		player.position = pos

func do_lost():
	pass

@rpc("call_local")
func rpc_deploy_weapon(weapon_path: String):
	InGameManager.local_player_manager.get_weapon(weapon_path)

func update_game_info_label():
	var info = str("Stage : " , str(stage) , "\nSpawn remaining : " , str(enemy_spawn_remain) , "\nEnemy on field : " , str(enemy_spawned))
	InGameManager.local_player_manager.update_hud_info_text(info)

func teleport_player(player: FpsPlayer):
	player.teleport_to(player_spawn.global_position)
