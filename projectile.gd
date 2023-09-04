extends Area3D

var speed = 5

func _ready():
	top_level = true

func _process(delta):
	position += transform.basis * Vector3(0,0,-speed) * delta 
