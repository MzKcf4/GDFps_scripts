extends Node3D

class_name DamageNumber

@onready var damage_label:Label3D = $LabelContainer/Label_DamageNumber
@onready var label_container:Node3D = $LabelContainer
@onready var animation_player : AnimationPlayer = $AnimationPlayer

var text : String;

func _ready():
	if(text == null):
		remove()
	animate()
	#set_values_and_animate("1" , Vector3.ZERO)

func animate():
	damage_label.text = text
	animation_player.play("Pop")

	var tween = get_tree().create_tween()
	var end_pos = global_position + Vector3.UP * 2
	var tween_length = animation_player.get_animation("Pop").length

	tween.tween_property(label_container , "global_position" ,end_pos, tween_length).from(global_position);
	print(label_container.global_position)

func remove():
	animation_player.stop()
	queue_free()
