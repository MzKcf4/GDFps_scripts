extends Node3D

@onready var player = $Player

func _physics_process(delta):
	get_tree().call_group("entity" , "set_target" , player)
