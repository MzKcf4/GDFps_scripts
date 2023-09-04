extends Node3D

class_name BulletTrace

const SPEED = 200

@onready var timer = $Timer
var direction : Vector3
var destination : Vector3

func _ready():
	self.look_at(destination)

func _physics_process(delta):
	position += transform.basis * Vector3(0,0,-SPEED) * delta

func _on_destroy_timer_timeout():
	self.queue_free()
