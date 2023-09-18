extends Control

class_name WeaponSelectionMenu

func show_weapon_selection(weapon_ids : Array):
	for n in self.get_children():
		self.remove_child(n)
		n.queue_free()
	for weapon_id in weapon_ids:
		add_weapon(weapon_id)
	self.visible = true

func add_weapon(weapon_id : String):
	var btn: Button = Button.new()
	btn.text = weapon_id
	btn.connect("pressed" ,_on_weapon_selected.bind(weapon_id))
	self.add_child(btn)

func _on_weapon_selected(weapon_id: String):
	InGameManager.local_player_manager.get_weapon(weapon_id)
	self.visible = false

