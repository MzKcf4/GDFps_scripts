extends Node

# Represents everything needed for a Local Player ( Client )
class_name LocalPlayerManager

var in_game_player : FpsPlayer
var player_hud: PlayerHud
var player_menu : PlayerMenu

func _init():
	InGameManager.local_player_manager = self

func _ready():
	player_hud = get_tree().get_current_scene().find_child("player_hud")
	player_menu = get_tree().get_current_scene().find_child("player_menu")

func set_in_game_player(player : FpsPlayer):
	in_game_player = player
	player_hud.connect_player_signals(player)

func get_weapon(weapon_path):
	in_game_player.get_weapon(weapon_path)

func update_hud_info_text(text: String):
	player_hud.update_info_text(text)

func toggle_player_menu():
	player_menu.toggle()

func can_process_input() -> bool:
	return !player_menu.visible
