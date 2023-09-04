extends Node

var title_scene : PackedScene = preload("res://tscn/UI/Title.tscn")
var lobby_scene : PackedScene = preload("res://tscn/UI/Lobby.tscn")
var game_scene : PackedScene = preload("res://tscn/game_world.tscn")

var scene_container : Node
var active_scene : Node

var is_in_main_menu : bool = true
var player_menu : PlayerMenu

func _ready():
	NetworkManager.on_server_shutdown.connect(server_shutdown)
	pass

# Network stuff
func start_server():
	NetworkManager.create_server()
	NetworkManager.is_host = true
	get_tree().change_scene_to_packed(lobby_scene)
	is_in_main_menu = false
	
func start_client(address: String):
	NetworkManager.join_server(address)
	NetworkManager.is_host = false
	get_tree().change_scene_to_packed(lobby_scene)
	is_in_main_menu = false

func stop_game():
	NetworkManager.disconnect_server()
	get_tree().change_scene_to_packed(title_scene)
	is_in_main_menu = true

func start_game():
	get_tree().change_scene_to_packed(game_scene)
	is_in_main_menu = false
	
func server_shutdown():
	get_tree().change_scene_to_packed(title_scene)
	is_in_main_menu = true

func set_player_menu(menu: Control):
	self.player_menu = menu
