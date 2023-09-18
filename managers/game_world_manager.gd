extends Node

class_name GameWorldManager

@onready var player_scene : PackedScene = preload("res://tscn/Player.tscn")
var player_spawn : Node3D

var players: = []
var dict_id_to_player : Dictionary = {}

func _init():
	ResourceManager.pre_load_resources()
	InGameManager.game_world_manager = self

func _ready():
	player_spawn = find_child("PlayerSpawn")
	#GameManager.set_player_menu(player_menu)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	call_deferred("post_ready")
	
func post_ready():
	var connected_peers = NetworkManager.connected_peer_ids
	var spawned = 1
	for peer_id in connected_peers:
		var player: Node3D = player_scene.instantiate()
		players.append(player)
		# let that peer id has control over the player
		player.set_multiplayer_authority(peer_id)
		player.position = player_spawn.global_position
		player.position.x += randi_range(0,8)
		player.position.y += randi_range(0,16)
		add_child(player)
		dict_id_to_player[peer_id] = player
		spawned += 1
		# connect the HUD to controlled player
		if(peer_id) == NetworkManager.peer_id:
			InGameManager.local_player_manager.set_in_game_player(player)

	InGameManager.stage_manager.dict_id_to_player = dict_id_to_player
			
	if(NetworkManager.is_host):
		InGameManager.stage_manager.game_start()
		pass
