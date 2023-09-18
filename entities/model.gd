extends Node3D

class_name CharacterModel

var is_loaded = false;
var use_root_motion = false;
var animation_player: AnimationPlayer
var animation_tree : AnimationTree
var root_motion_track : NodePath
var lower_body_time_sacle : AnimationNodeTimeScale

var model_mesh : Mesh

func _physics_process(delta):
	if( not animation_player):
		return
	var root_pos = animation_tree.get_root_motion_position()
	self.position = root_pos

func load_model(model : PackedScene):
	var mdl_instance = model.instantiate()
	# such that I can trace back to the FpsEntity from model when doing hit detection
	# mdl_instance.owner = self.owner
	add_child(mdl_instance)
	animation_player = mdl_instance.find_child("AnimationPlayer")
	animation_tree = mdl_instance.find_child("AnimationTree")
	is_loaded = true
	if(animation_tree):
		if(animation_tree.root_motion_track):
			root_motion_track = animation_tree.root_motion_track.get_as_property_path()
			use_root_motion = true
	make_material_unique(mdl_instance)
	set_move_animation_speed()
	#debug_animation_tree()

func make_material_unique(model):
	var mesh_instance : MeshInstance3D = find_mesh_instance(model)
	if(!mesh_instance):
		printerr("Mesh Instance not found")
		return
	
	model_mesh = mesh_instance.mesh.duplicate(true)
	mesh_instance.mesh = model_mesh
		
	var surface_count = model_mesh.get_surface_count()
	for i in surface_count:
		var surface_mat = model_mesh.surface_get_material(i);
		var dup_mat = surface_mat.duplicate()
		model_mesh.surface_set_material(i , dup_mat)

func find_mesh_instance(node: Node3D):
	if node is MeshInstance3D:
		return node
	if (node.get_child_count() == 0):
		return null
	
	for c in node.get_children(true):
		var result = find_mesh_instance(c);
		if(result != null):
			return result
	return null

func update_mesh_color(color: Color):
	if(!model_mesh):
		return
	var surface_count = model_mesh.get_surface_count()
	for i in surface_count:
		var surface_mat = model_mesh.surface_get_material(i);
		surface_mat.albedo_color = color;

func play_animation(animation : String):
	if( not is_loaded):
		return
	animation_player.play(animation)

func play_death_animation():
	if( not is_loaded):
		return
	animation_tree.set_root_motion_track(NodePath(""))
	animation_tree.set("parameters/conditions/is_dead" , true)

func play_attack_animation():
	if( not is_loaded):
		return
	animation_tree.set("parameters/BlendTree/AttackShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func play_flinch_animation():
	if( not is_loaded):
		return
	animation_tree.set("parameters/BlendTree/FlinchShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func set_moving(is_moving : bool):
	if(not is_loaded):
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
	if( not is_loaded or not animation_tree):
		return
	animation_tree.set("parameters/BlendTree/LowerBodyTimeScale/scale" , 1.2)

func debug_animation_tree():
	if(animation_tree):
		for condition in animation_tree.get_property_list():
			if condition.name.begins_with("parameters"):
				print(condition.name)
