extends Object

class_name AbilityStalkHook

const ABILITY_DURATION = 8
const ABILITY_COOLDOWN = 10

var timer : Timer
var is_in_ability: bool = false
var stalk_color: Color = Color(1,1,1,0.1)
var normal_color: Color = Color(1,1,1,1.0)
var character: FpsCharacter

func init_hook(character: FpsCharacter):
	if(!NetworkManager.is_host):
		return
	self.character = character
	timer = Timer.new()
	character.add_child(timer)
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	timer.start(ABILITY_COOLDOWN)

# Server init the call
func _on_timer_timeout():
	if(is_in_ability):
		is_in_ability = false
		timer.start(ABILITY_COOLDOWN)
		character.update_model_color(normal_color)
		character.update_speed(false)
	else :
		is_in_ability = true
		timer.start(ABILITY_DURATION)
		character.update_model_color(stalk_color)
		character.update_speed(true)

func remove_hook():
	timer.stop()
	timer.queue_free()
