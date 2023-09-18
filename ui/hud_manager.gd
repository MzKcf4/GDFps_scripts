extends CanvasLayer

class_name PlayerHud

@onready var health_label = $Label_Health
@onready var wasted_label = $Label_Wasted
@onready var ammo_label = $Label_Ammo
@onready var fps_label = $Label_Fps
@onready var info_label = $Label_Info
@onready var crosshair: Crosshair = $Crosshair
@onready var enemy_health_bar: ProgressBar = $Enemy_Health_Bar
@onready var timer_hide_health_bar : Timer = $Enemy_Health_Bar/Timer
@onready var enemy_health_label : Label = $Enemy_Health_Bar/Label_Enemy_Health
@onready var reload_bar : ProgressBar = $Reload_Bar
@onready var timer_reload_bar : Timer = $Reload_Bar/Timer
@onready var weapon_menu: WeaponSelectionMenu = $Weapon_Selection_Container

func _process(delta):
	fps_label.text = str(Engine.get_frames_per_second())
	if(reload_bar.visible):
		reload_bar.value += delta
	
func connect_player_signals(player: FpsCharacter):
	player.on_health_update.connect(on_player_health_update)
	player.on_alive_status_changed.connect(on_player_alive_status_changed)
	player.on_weapon_fire.connect(on_player_fired)
	player.on_hit_enemy.connect(update_enemy_health_bar)
	player.on_weapon_reload.connect(on_weapon_reload)
	timer_hide_health_bar.timeout.connect(_on_hide_enemy_health_bar_timer_timeout)
	timer_reload_bar.timeout.connect(_on_reload_bar_timer_timeout)
	pass

func update_info_text(text: String):
	info_label.text = text

func on_player_health_update(health: int):
	health_label.text = str(health);

func on_player_alive_status_changed(is_alive: bool):
	wasted_label.visible = !is_alive;

func on_player_fired(weapon: Weapon):
	ammo_label.text = str(weapon.curr_ammo)
	crosshair.trigger()

func on_weapon_reload(weapon: Weapon):
	var reload_time:float = weapon.get_reload_time();
	timer_reload_bar.start(reload_time);
	reload_bar.visible = true
	reload_bar.max_value = reload_time;
	reload_bar.value = 0
	
func update_enemy_health_bar(enemy : FpsCharacter):
	enemy_health_bar.visible = true
	var percentage = float(enemy.health) / float(enemy.max_health) * 100
	enemy_health_bar.value = percentage
	print(percentage)
	enemy_health_label.text = str(enemy.health) + "/" + str(enemy.max_health)
	timer_hide_health_bar.start()

func _on_hide_enemy_health_bar_timer_timeout():
	enemy_health_bar.visible = false

func _on_reload_bar_timer_timeout():
	reload_bar.visible = false

func show_weapon_selection(weapon_ids: Array):
	weapon_menu.show_weapon_selection(weapon_ids)
