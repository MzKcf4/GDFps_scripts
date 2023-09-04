extends Object

class_name PlayerSettings

# effective is 0.01
@export var mouse_sensitivity: int = 10
@export var audio_volumne: int = 100



func to_dict() -> Dictionary:
	return {
		"audio_volumne": audio_volumne,
		"mouse_sensitivity": mouse_sensitivity
	}
