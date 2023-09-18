extends Node

class_name StageManager

const HookRegistry = preload("res://scripts/hooks/hook_registry.gd")

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
var enemy_respawn_time : int = 5
var enemy_id_counter = 0

var stage = 1;
const MAX_STAGE = 8
const MAX_WEAPONS = 4
const SPEED_MULTIPLIER_PER_STAGE = 1.1
const HEALTH_MULTIPLIER_PER_STAGE = 1.3


var player_spawn : Node3D
const PLAYER_RESPAWN_TIME = 2
var dict_player_id_to_respawn_time : Dictionary = {}
# Not safe
var dict_id_to_player : Dictionary = {}

var spawn_timer : Timer
@export var ary_respawn_time : Array[float];
var timer_elapsed: float = 0

var enemy_info_normal = {
	"model" : "res://models/zombie_swarm/zombie_sawrm_2.tscn",
	"name" : "zombie",
	"health" : 400,
	"speed" : 5.0,
	"hook" : null
}

var enemy_info_bersek = {
	"model" : "res://models/zombie_swarm/zombie_sawrm_2.tscn",
	"name" : "zombie",
	"health" : 750,
	"speed" : 4.0,
	"hook" : HookRegistry.HookType.BERSERK
}

var enemy_info_stalk = {
	"model" : "res://models/zombie_swarm/zombie_sawrm_2.tscn",
	"name" : "zombie",
	"health" : 200,
	"speed" : 7.5,
	"hook" : HookRegistry.HookType.STALK
}

var enemy_list_stage_1 = [ enemy_info_normal ]
var enemy_list_stage_2 = [ enemy_info_normal , enemy_info_bersek ]
var enemy_list_stage_3 = [ enemy_info_normal , enemy_info_bersek , enemy_info_stalk ]
var enemy_list_stage_4 = [ enemy_info_normal , enemy_info_bersek , enemy_info_stalk ]
var enemy_list_stage_5 = [ enemy_info_normal , enemy_info_bersek , enemy_info_stalk ]
var enemy_list_stage_6 = [ enemy_info_normal , enemy_info_bersek , enemy_info_stalk ]


var stage_enemy_list : = [ {} ,
	enemy_list_stage_1 , enemy_list_stage_2 , enemy_list_stage_3 , enemy_list_stage_4 , enemy_list_stage_5 , enemy_list_stage_6 , enemy_list_stage_6,enemy_list_stage_6,enemy_list_stage_6,enemy_list_stage_6,enemy_list_stage_6,enemy_list_stage_6
]

var stage_weapons_id : Array = []
	# 1 : [ "ak47" , "car" ]
	# 2 : [ "..." , "..." , .. ]

func _init():
	InGameManager.stage_manager = self
	
func _ready():
	ready_host()
	player_spawn = get_tree().get_current_scene().find_child("PlayerSpawn")
	enemy_spawn_container = get_tree().get_current_scene().find_child("EnemySpawns")
	enemy_spawn_points = enemy_spawn_container.get_children()

func ready_host():
	if(!NetworkManager.is_host):
		return
	_prepare_weapon_list()
	ary_respawn_time = []
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	timer_elapsed = 0

func game_start():
	stage = 0
	for player in dict_id_to_player.values():
		player.on_killed.connect(on_player_killed)
	advance_stage()
	spawn_timer.start(0.5)
	#rpc("rpc_deploy_weapon" , "ak47_transformer")
	#rpc("rpc_show_weapon_list" , _get_weapon_ids(stage))

func _prepare_weapon_list():
	for i in MAX_STAGE + 1:
		stage_weapons_id.append([])
	for wpn_id in ResourceManager.weapon_registry.keys():
		var wpn_stats : WeaponStats = ResourceManager.weapon_registry[wpn_id]
		stage_weapons_id[wpn_stats.z_tier].append(wpn_stats.weapon_id)

func advance_stage():
	stage += 1
	enemy_spawn_remain = SPAWN_REMAIN
	for i in enemy_spawned_max:
		ary_respawn_time.push_back(i)
	if(NetworkManager.is_host && stage <= 5):
		rpc("rpc_show_weapon_list" , JSON.stringify(_get_weapon_ids(stage)))

func _on_spawn_timer_timeout():
	timer_elapsed += 0.5
	for id in dict_player_id_to_respawn_time.keys():
		if dict_player_id_to_respawn_time[id] <= timer_elapsed:
			rpc("rpc_respawn_player" , id)
			dict_player_id_to_respawn_time.erase(id)
	
	if(ary_respawn_time.size() > 0 && ary_respawn_time[0] <= timer_elapsed):
		ary_respawn_time.pop_front()
		spawn_enemy()

func _get_weapon_ids(stage_num: int) -> Array[String]:
	var index_list = [];
	for i in stage_weapons_id[stage_num].size():
		index_list.append(i);
	randomize()
	index_list.shuffle()
	var weapon_ids : Array[String] = []
	for i in MAX_WEAPONS:
		if i == index_list.size():
			break;
		weapon_ids.append(stage_weapons_id[stage_num][i])
	return weapon_ids

func spawn_enemy():
	if(enemy_spawn_remain <= 0):
		return
	
	var enemy_list = stage_enemy_list[stage];
	var enemy_spawn_info = enemy_list.pick_random()

	var spawn_position : Vector3 = enemy_spawn_points[randi() % enemy_spawn_points.size()].global_position
	var rand_peer_id = NetworkManager.connected_peer_ids[randi() % NetworkManager.connected_peer_ids.size()]
	rpc("rpc_spawn_enemy" , rand_peer_id , enemy_id_counter , spawn_position , JSON.stringify(enemy_spawn_info))
	
	enemy_id_counter +=1

@rpc("call_local")
func rpc_spawn_enemy(target_id: int , enemy_id: int , spawn_position : Vector3 , spawn_info_json: String):
	var enemy_spawn_info = JSON.parse_string(spawn_info_json);
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
	
	enemy.move_speed = enemy_spawn_info.speed * pow(SPEED_MULTIPLIER_PER_STAGE , stage-1)
	enemy.max_health = enemy_spawn_info.health * pow(HEALTH_MULTIPLIER_PER_STAGE , stage-1)
	enemy.health = enemy.max_health
	enemy.on_killed.connect(on_enemy_killed)
	
	if(enemy_spawn_info.hook != null):
		var hook = HookRegistry.get_hook(enemy_spawn_info.hook)
		enemy.add_hook(hook)
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
	var pos : Vector3 = player_spawn.global_position
	pos.x += randi_range(0,3)
	pos.y += randi_range(4,8)
	player.spawn(pos)

func do_lost():
	pass

@rpc("call_local")
func rpc_show_weapon_list(weapon_ids_json : String):
	var weapon_ids: Array = JSON.parse_string(weapon_ids_json)
	InGameManager.local_player_manager.show_weapon_selection(weapon_ids)

@rpc("call_local")
func rpc_deploy_weapon(weapon_id):
	InGameManager.local_player_manager.get_weapon(weapon_id)

func update_game_info_label():
	var info = str("Stage : " , str(stage) , "\nSpawn remaining : " , str(enemy_spawn_remain) , "\nEnemy on field : " , str(enemy_spawned))
	InGameManager.local_player_manager.update_hud_info_text(info)
