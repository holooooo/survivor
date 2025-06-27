extends EquipmentBase
class_name PistolEquipment

## 手枪装备 - 远程射击装备[br]
## 每次射击发射3颗子弹，具备弹夹系统和装填机制

@export var max_ammo: int = 9 ## 弹夹最大容量
@export var bullets_per_shot: int = 3 ## 每次射击的子弹数量
@export var bullet_interval: float = 0.1 ## 连发子弹间隔（秒）
@export var reload_time: float = 2.0 ## 装填时间（秒）
@export var orbit_radius: float = 50.0 ## 围绕玩家的轨道半径

var current_ammo: int = 9 ## 当前弹药数量
var is_reloading: bool = false ## 是否正在装填
var reload_start_time: float = 0.0 ## 装填开始时间
var current_burst_count: int = 0 ## 当前连发计数
var burst_timer: float = 0.0 ## 连发计时器

signal ammo_changed(current: int, max: int)
signal reload_started()
signal reload_finished()

@onready var pistol_sprite: Sprite2D = $PistolSprite

func _ready() -> void:
	# 投射物资源和冷却时间现在通过EquipmentResource配置
	
	# 初始化弹药（将在配置应用后更新）
	current_ammo = max_ammo
	ammo_changed.emit(current_ammo, max_ammo)
	
	# 设置手枪精灵
	_setup_pistol_sprite()

## 设置枪械配置（重写基类方法以应用到手枪逻辑）[br]
## [param config] 枪械配置字典
func set_firearm_config(config: Dictionary) -> void:
	super.set_firearm_config(config)
	
	# 应用枪械配置到手枪属性
	if config.has("bullets_per_shot"):
		bullets_per_shot = config.bullets_per_shot
	if config.has("magazine_capacity"):
		max_ammo = config.magazine_capacity
		current_ammo = min(current_ammo, max_ammo)
	if config.has("reload_time"):
		reload_time = config.reload_time
	if config.has("bullet_interval"):
		bullet_interval = config.bullet_interval
	
	# 更新弹药UI
	ammo_changed.emit(current_ammo, max_ammo)

## 设置发射器配置（同时应用到手枪）[br]
## [param config] 发射器配置字典
func set_emitter_config(config: Dictionary) -> void:
	super.set_emitter_config(config)
	
	# 如果发射器配置包含弹药系统参数，应用到手枪
	if config.has("magazine_capacity"):
		max_ammo = config.magazine_capacity
		current_ammo = min(current_ammo, max_ammo)
	if config.has("reload_time"):
		reload_time = config.reload_time
	
	# 更新弹药UI
	ammo_changed.emit(current_ammo, max_ammo)

## 重写初始化方法，设置手枪初始位置[br]
## [param player] 装备拥有者
func initialize(player: Player) -> void:
	super.initialize(player)
	
	# 设置手枪初始位置
	if pistol_sprite and owner_player:
		pistol_sprite.global_position = owner_player.global_position + Vector2(orbit_radius, 0)

func _process(delta: float) -> void:
	if is_reloading:
		_update_reload_progress()
	
	if current_burst_count > 0:
		burst_timer += delta
		if burst_timer >= bullet_interval:
			_fire_single_bullet()
			burst_timer = 0.0
			current_burst_count -= 1
	
	_update_pistol_position_and_rotation()

## 检查是否可以使用装备[br]
## [returns] 是否可以使用
func can_use() -> bool:
	if is_reloading:
		return false
	
	if current_ammo <= 0:
		_start_reload()
		return false
	
	# 检查基类冷却
	if not super.can_use():
		return false
	
	# 检查攻击距离内是否有敌人
	if not has_enemies_in_attack_range():
		return false
	
	return true

## 执行装备效果 - 开始连发射击[br]
func _execute_equipment_effect() -> void:
	if not owner_player or current_ammo <= 0:
		return
	
	current_ammo -= 1
	ammo_changed.emit(current_ammo, max_ammo)
	
	# 开始连发射击
	current_burst_count = bullets_per_shot
	burst_timer = 0.0
	
	_fire_single_bullet()
	current_burst_count -= 1
	
	if current_ammo <= 0:
		_start_reload()

## 发射单颗子弹[br]
func _fire_single_bullet() -> void:
	if not owner_player or not projectile_scene:
		return
	
	var projectile: Node2D = projectile_scene.instantiate()
	
	var main_scene: Node2D = owner_player.get_parent()
	if main_scene:
		main_scene.add_child(projectile)
		projectile.global_position = _get_projectile_spawn_position()
		
		if projectile.has_method("setup_from_resource") and projectile_resource:
			var target_direction: Vector2 = _get_target_direction()
			projectile.setup_from_resource(projectile_resource, target_direction)

## 开始装填弹药[br]
func _start_reload() -> void:
	if is_reloading or current_ammo >= max_ammo:
		return
	
	is_reloading = true
	reload_start_time = Time.get_ticks_msec() / 1000.0
	reload_started.emit()

## 更新装填进度[br]
func _update_reload_progress() -> void:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	var elapsed_time: float = current_time - reload_start_time
	
	if elapsed_time >= reload_time:
		_finish_reload()

## 完成装填[br]
func _finish_reload() -> void:
	is_reloading = false
	current_ammo = max_ammo
	ammo_changed.emit(current_ammo, max_ammo)
	reload_finished.emit()

## 获取装填进度[br]
## [returns] 装填进度（0.0-1.0）
func get_reload_progress() -> float:
	if not is_reloading:
		return 0.0
	
	var current_time: float = Time.get_ticks_msec() / 1000.0
	var elapsed_time: float = current_time - reload_start_time
	return min(elapsed_time / reload_time, 1.0)

## 获取投射物生成位置 - 在玩家位置[br]
## [returns] 投射物生成的世界坐标
func _get_projectile_spawn_position() -> Vector2:
	if owner_player:
		return owner_player.global_position
	return Vector2.ZERO

## 强制装填（用于紧急情况或UI触发）[br]
func force_reload() -> void:
	if not is_reloading and current_ammo < max_ammo:
		_start_reload()

## 获取当前状态信息[br]
## [returns] 状态字典
func get_status_info() -> Dictionary:
	return {
		"current_ammo": current_ammo,
		"max_ammo": max_ammo,
		"is_reloading": is_reloading,
		"reload_progress": get_reload_progress(),
		"can_fire": can_use()
	}

## 设置手枪精灵外观[br]
func _setup_pistol_sprite() -> void:
	if not pistol_sprite:
		return
	
	var default_texture: Texture2D = load("res://icon.svg")
	if default_texture:
		pistol_sprite.texture = default_texture
		pistol_sprite.modulate = Color.WHITE
		pistol_sprite.scale = Vector2(0.3, 0.3)

## 更新手枪位置和朝向[br]
func _update_pistol_position_and_rotation() -> void:
	if not pistol_sprite or not owner_player:
		return
	
	# 获取最近敌人的方向
	var target_direction: Vector2 = _get_target_direction()
	
	# 获取当前手枪相对玩家的方向
	var player_pos: Vector2 = owner_player.global_position
	var current_pos: Vector2 = pistol_sprite.global_position
	var current_direction: Vector2 = (current_pos - player_pos).normalized()
	
	# 如果当前方向无效，使用目标方向
	if current_direction == Vector2.ZERO:
		current_direction = target_direction
	
	# 计算目标方向与当前方向的角度差
	var current_angle: float = current_direction.angle()
	var target_angle: float = target_direction.angle()
	var angle_diff: float = target_angle - current_angle
	
	# 处理角度跳跃（-π到π之间）
	while angle_diff > PI:
		angle_diff -= 2 * PI
	while angle_diff < -PI:
		angle_diff += 2 * PI
	
	# 平滑旋转角度
	var rotation_speed: float = 5.0  # 旋转速度（弧度/秒）
	var max_rotation: float = rotation_speed * get_process_delta_time()
	
	var new_angle: float
	if abs(angle_diff) < max_rotation:
		new_angle = target_angle
	else:
		new_angle = current_angle + sign(angle_diff) * max_rotation
	
	# 计算新的方向向量
	var new_direction: Vector2 = Vector2.from_angle(new_angle)
	
	# 严格保持在orbit_radius距离上
	pistol_sprite.global_position = player_pos + new_direction * orbit_radius
	
	# 设置手枪朝向（指向目标方向）
	pistol_sprite.rotation = new_angle

## 获取目标方向 - 优先选择攻击距离内最近的敌人[br]
## [returns] 目标方向向量
func _get_target_direction() -> Vector2:
	if not owner_player:
		return Vector2.RIGHT
	
	# 优先获取攻击距离内的最近敌人
	var nearest_enemy: Node2D = get_nearest_enemy_in_attack_range()
	
	if nearest_enemy:
		return (nearest_enemy.global_position - owner_player.global_position).normalized()
	else:
		return Vector2.RIGHT 