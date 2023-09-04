extends Node

class_name CharacterModel

var animation_player: AnimationPlayer
var animation_tree : AnimationTree
var root_motion_track : NodePath
var lower_body_time_sacle : AnimationNodeTimeScale

func _physics_process(delta):
	var root_pos = animation_tree.get_root_motion_position()
	self.position = root_pos
	
	pass

func load_model(model : PackedScene):
	var mdl_instance = model.instantiate()
	# such that I can trace back to the FpsEntity from model when doing hit detection
	# mdl_instance.owner = self.owner
	add_child(mdl_instance)
	animation_player = mdl_instance.find_child("AnimationPlayer")
	animation_tree = mdl_instance.find_child("AnimationTree")
	if(animation_tree):
		if(animation_tree.root_motion_track):
			root_motion_track = animation_tree.root_motion_track.get_as_property_path()
	set_move_animation_speed()
	#debug_animation_tree()
	
func play_animation(animation : String):
	if( not animation_player):
		return
	animation_player.play(animation)

func play_death_animation():
	animation_tree.set_root_motion_track(NodePath(""))
	animation_tree.set("parameters/conditions/is_dead" , true)

func play_attack_animation():
	animation_tree.set("parameters/BlendTree/AttackShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func play_flinch_animation():
	animation_tree.set("parameters/BlendTree/FlinchShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func set_moving(is_moving : bool):
	if(not animation_tree):
		return
	if(is_moving):
		animation_tree.set("parameters/BlendTree/LowerBodyStateMachine/conditions/is_idle" , false)
		animation_tree.set("parameters/BlendTree/LowerBodyStateMachine/conditions/is_running" , true)
	else:
		animation_tree.set("parameters/BlendTree/LowerBodyStateMachine/conditions/is_idle" , true)
		animation_tree.set("parameters/BlendTree/LowerBodyStateMachine/conditions/is_running" , false)

func get_root_motion_position():
	return animation_tree.get_root_motion_position()

func set_move_animation_speed():
	animation_tree.set("parameters/BlendTree/LowerBodyTimeScale/scale" , 1.2)

func debug_animation_tree():
	if(animation_tree):
		for condition in animation_tree.get_property_list():
			if condition.name.begins_with("parameters"):
				print(condition.name)
