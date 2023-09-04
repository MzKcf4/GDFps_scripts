extends Node

@onready var title : Node = $title

func _ready():
	GameManager.scene_container = self
	GameManager.active_scene = title
