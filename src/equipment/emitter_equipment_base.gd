extends EquipmentBase
class_name EmitterEquipmentBase

## 发射器装备抽象基类 - 所有发射器类装备的通用逻辑[br]
## 提供投射物生成、弹药管理、冷却处理等共同功能[br]
## 子类只需实现特定的发射逻辑和移动行为

@export_group("发射器配置")
@export var attack_range: float = 300.0 ## 攻击范围

# 弹药系统（可选）
var magazine_capacity: int = 0 ## 弹夹容量（0=无限弹药）
var current_ammo: int = 0 ## 当前弹药数
var reload_time: float = 2.0 ## 装弹时间
var reload_mode: EmitterEquipmentResource.ReloadMode = EmitterEquipmentResource.ReloadMode.换弹 ## 装弹模式
var reload_amount: int = 1 ## 单次装弹量（仅充能型使用）
var is_reloading: bool = false ## 是否正在装弹
var reload_timer: float = 0.0 ## 装弹计时器

# 发射参数
var emit_count: int = 1 ## 单次发射数量
var emit_interval: float = 0.1 ## 发射间隔
var base_damage: int = 10 ## 基础伤害

# 内部状态
var current_burst_count: int = 0 ## 当前连发计数
var burst_timer: float = 0.0 ## 连发计时器

signal ammo_changed(current: int, max: int)
signal reload_started()
signal reload_finished()
signal target_acquired(target: Node2D)

func _ready() -> void:
	super._ready()
	_setup_emitter_system()

func _process(delta: float) -> void:
	_update_ammo_system(delta)
	_update_burst_system(delta)
	_custom_update(delta)

## 设置发射器系统
func _setup_emitter_system() -> void:
	# 从配置应用弹药系统参数
	if emitter_config.has("magazine_capacity"):
		magazine_capacity = emitter_config.magazine_capacity
		current_ammo = magazine_capacity
	if emitter_config.has("reload_time"):
		reload_time = emitter_config.reload_time
	if emitter_config.has("reload_mode"):
		reload_mode = emitter_config.reload_mode
	if emitter_config.has("reload_amount"):
		reload_amount = emitter_config.reload_amount
	if emitter_config.has("base_damage"):
		base_damage = emitter_config.base_damage
	if emitter_config.has("emit_count"):
		emit_count = emitter_config.emit_count
	if emitter_config.has("emit_interval"):
		emit_interval = emitter_config.emit_interval
	if emitter_config.has("attack_range"):
		attack_range = emitter_config.attack_range
	
	# 应用玩家的装弹速度加成
	_apply_player_reload_speed_bonus()

## 更新弹药系统[br]
## [param delta] 时间增量
func _update_ammo_system(delta: float) -> void:
	if magazine_capacity <= 0:
		return # 无限弹药，不需要管理
	
	# 根据装弹模式处理不同逻辑
	match reload_mode:
		EmitterEquipmentResource.ReloadMode.换弹:
			_update_magazine_reload(delta)
		EmitterEquipmentResource.ReloadMode.充能:
			_update_regenerative_reload(delta)

## 换弹型装弹更新[br]
## [param delta] 时间增量
func _update_magazine_reload(delta: float) -> void:
	if is_reloading:
		reload_timer += delta
		if reload_timer >= reload_time:
			_finish_magazine_reload()

## 充能型装弹更新[br]
## [param delta] 时间增量
func _update_regenerative_reload(delta: float) -> void:
	# 只要弹药未满就持续充能
	if current_ammo < magazine_capacity:
		if not is_reloading:
			_start_regenerative_reload()
		
		if is_reloading:
			reload_timer += delta
			if reload_timer >= reload_time:
				_finish_regenerative_reload()
	else:
		# 弹药已满，停止充能
		if is_reloading:
			is_reloading = false
			reload_timer = 0.0

## 更新连发系统[br]
## [param delta] 时间增量
func _update_burst_system(delta: float) -> void:
	if current_burst_count > 0:
		burst_timer += delta
		if burst_timer >= emit_interval:
			_fire_single_projectile()
			burst_timer = 0.0
			current_burst_count -= 1

## 检查是否可以使用装备[br]
## [returns] 是否可以使用
func can_use() -> bool:
	# 检查基类冷却
	if not super.can_use():
		return false
	
	# 检查弹药和装弹状态
	if magazine_capacity > 0 and not _has_infinite_ammo():
		match reload_mode:
			EmitterEquipmentResource.ReloadMode.换弹:
				# 换弹型：装弹期间或弹药耗尽时无法攻击
				if is_reloading or current_ammo <= 0:
					if current_ammo <= 0 and not is_reloading:
						_start_reload()
					return false
			EmitterEquipmentResource.ReloadMode.充能:
				# 充能型：只要有弹药就可以攻击，弹药耗尽时无法攻击
				if current_ammo <= 0:
					return false
	
	# 检查特定条件
	return _can_use_specific()

## 执行装备效果[br]
func _execute_equipment_effect() -> void:
	# 消耗弹药
	if magazine_capacity > 0 and not _has_infinite_ammo():
		current_ammo -= 1
		ammo_changed.emit(current_ammo, magazine_capacity)
	
	# 开始连发
	current_burst_count = emit_count
	burst_timer = 0.0
	
	# 立即发射第一发
	_fire_single_projectile()
	current_burst_count -= 1
	
	# 检查是否需要自动装弹（仅换弹型）
	if magazine_capacity > 0 and current_ammo <= 0 and not _has_infinite_ammo():
		if reload_mode == EmitterEquipmentResource.ReloadMode.换弹:
			_start_reload()

## 发射单个投射物[br]
func _fire_single_projectile() -> void:
	if not owner_player or not projectile_scene:
		return
	
	var projectile: Node2D = projectile_scene.instantiate()
	var main_scene: Node2D = owner_player.get_parent()
	
	if main_scene:
		main_scene.add_child(projectile)
		projectile.global_position = _get_projectile_spawn_position()
		
		# 配置投射物
		if projectile.has_method("setup_from_resource") and projectile_resource:
			var target_direction: Vector2 = _get_target_direction()
			var equipment_stats = _get_current_stats()
			projectile.setup_from_resource(self, projectile_resource, target_direction, equipment_stats)
		
		# 应用特定配置
		_configure_projectile_specific(projectile)

## 开始装弹[br]
func _start_reload() -> void:
	match reload_mode:
		EmitterEquipmentResource.ReloadMode.换弹:
			_start_magazine_reload()
		EmitterEquipmentResource.ReloadMode.充能:
			_start_regenerative_reload()

## 开始换弹型装弹[br]
func _start_magazine_reload() -> void:
	if is_reloading or current_ammo > 0:
		return # 换弹型只有弹药耗尽时才换弹
	
	is_reloading = true
	reload_timer = 0.0
	reload_started.emit()

## 开始充能型装弹[br]
func _start_regenerative_reload() -> void:
	if is_reloading or current_ammo >= magazine_capacity:
		return # 已在充能中或弹药已满
	
	is_reloading = true
	reload_timer = 0.0
	# 充能型不发送 reload_started 信号，因为这是持续过程

## 完成装弹[br]
func _finish_reload() -> void:
	match reload_mode:
		EmitterEquipmentResource.ReloadMode.换弹:
			_finish_magazine_reload()
		EmitterEquipmentResource.ReloadMode.充能:
			_finish_regenerative_reload()

## 完成换弹型装弹[br]
func _finish_magazine_reload() -> void:
	is_reloading = false
	current_ammo = magazine_capacity # 换弹型直接填满
	reload_timer = 0.0
	ammo_changed.emit(current_ammo, magazine_capacity)
	reload_finished.emit()

## 完成充能型装弹[br]
func _finish_regenerative_reload() -> void:
	# 充能型每次增加指定数量
	current_ammo = min(current_ammo + reload_amount, magazine_capacity)
	reload_timer = 0.0
	ammo_changed.emit(current_ammo, magazine_capacity)
	
	# 如果还未充满，继续充能；否则停止
	if current_ammo >= magazine_capacity:
		is_reloading = false
		reload_finished.emit() # 只有完全充满时才发送完成信号
	# 如果未满，is_reloading 保持 true，下一轮继续充能

## 检查是否有无限弹药效果[br]
## [returns] 是否有无限弹药
func _has_infinite_ammo() -> bool:
	return false  # Infinite ammo now handled by global mod system

## 获取状态信息[br]
## [returns] 状态信息字典
func get_emitter_status() -> Dictionary:
	return {
		"current_ammo": current_ammo,
		"magazine_capacity": magazine_capacity,
		"is_reloading": is_reloading,
		"reload_progress": reload_timer / reload_time if is_reloading else 0.0,
		"reload_mode": reload_mode,
		"reload_amount": reload_amount,
		"can_fire": can_use(),
		"attack_range": attack_range,
		"base_damage": base_damage
	}

## === 抽象方法 - 子类必须实现 ===

## 检查特定使用条件[br]
## [returns] 是否满足特定条件
func _can_use_specific() -> bool:
	# 默认实现：检查攻击范围内是否有敌人
	return has_enemies_in_attack_range()

## 配置投射物特定属性[br]
## [param projectile] 投射物实例
func _configure_projectile_specific(projectile: Node2D) -> void:
	# 子类可重写此方法来设置特定的投射物配置
	pass

## 自定义更新逻辑[br]
## [param delta] 时间增量
func _custom_update(delta: float) -> void:
	# 子类可重写此方法来实现特定的更新逻辑（如位置跟踪、旋转等）
	pass

## 应用玩家装弹速度加成[br]
func _apply_player_reload_speed_bonus() -> void:
	if owner_player and owner_player.stats_manager:
		var equipment_damage_type = get_damage_type()
		var reload_multiplier = owner_player.stats_manager.get_reload_speed_multiplier(equipment_damage_type)
		reload_time /= reload_multiplier

## 重新计算装备属性（重写基类方法）[br]
func recalculate_stats() -> void:
	super.recalculate_stats()
	# 重新应用装弹速度加成
	_apply_player_reload_speed_bonus()

## === 可重写方法 ===

## 获取投射物生成位置[br]
## [returns] 生成位置
func _get_projectile_spawn_position() -> Vector2:
	if owner_player:
		return owner_player.global_position
	return Vector2.ZERO 