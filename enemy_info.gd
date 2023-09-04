extends Resource

class_name EnemyInfo
#
# { Key  - zombie_swarm
#   base_health  - 100
#   base_speed - 100
#   attack_damage - 15
#   model_resource - "res:// .... "

@export var name: String
@export var base_health : int = 100
@export var base_speed : int = 5
@export var damage = 15
@export var model_resource_path: String = ""
@export var stage_start: int = 1
@export var starge_end: int = 6
