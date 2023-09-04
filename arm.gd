extends Node

class_name ArmModel

@export var skeleton : Skeleton3D
var wpn_skeleton : Skeleton3D

var dict_arm_to_wpn_bone_idx = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for arm_idx in dict_arm_to_wpn_bone_idx:
		var wpn_bone_idx = dict_arm_to_wpn_bone_idx[arm_idx]
		var wpn_bone_pose = wpn_skeleton.get_bone_global_pose(wpn_bone_idx)
#		var wpn_bone_pos = wpn_skeleton.get_bone_pose_position(wpn_bone_idx)
#		var wpn_bone_rot = wpn_skeleton.get_bone_pose_rotation(wpn_bone_idx)
#		var wpn_bone_scale = wpn_skeleton.get_bone_pose_scale(wpn_bone_idx)
		
		skeleton.set_bone_global_pose_override(arm_idx , wpn_bone_pose , 1.0 , false)
		#skeleton.set_bone_pose_position(arm_idx,wpn_bone_pos)
		#skeleton.set_bone_pose_rotation(arm_idx,wpn_bone_rot)
		#skeleton.set_bone_pose_scale(arm_idx,wpn_bone_scale)
	pass

func bind_to_weapon(weapon):
	# 1st : find all bones from weapon
	wpn_skeleton = weapon.skeleton
	var wpn_bone_count = wpn_skeleton.get_bone_count()
	for idx in wpn_bone_count:
		var wpn_bone_name = wpn_skeleton.get_bone_name(idx)
		#print(wpn_bone_name)
		var arm_bone_mapped_idx = skeleton.find_bone(wpn_bone_name)
		#print(arm_bone_mapped_idx)
		if(arm_bone_mapped_idx > -1):
			dict_arm_to_wpn_bone_idx[arm_bone_mapped_idx] = idx
	pass
