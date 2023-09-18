extends Object

class_name AbilityBerserkHook

const BERSERK_DURATION = 8
const BERSERK_COOLDOWN = 10

var timer : Timer
var is_in_berserk: bool = false
var berserk_color: Color = Color(255,0,0,1.0)
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
	timer.start(BERSERK_COOLDOWN)

# Server init the call
func _on_timer_timeout():
	if(is_in_berserk):
		is_in_berserk = false
		timer.start(BERSERK_COOLDOWN)
		character.update_model_color(normal_color)
		character.update_speed(false)
	else :
		is_in_berserk = true
		timer.start(BERSERK_DURATION)
		character.update_model_color(berserk_color)
		character.update_speed(true)

func remove_hook():
	timer.stop()
	timer.queue_free()
