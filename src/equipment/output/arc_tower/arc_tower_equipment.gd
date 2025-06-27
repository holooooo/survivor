extends EquipmentBase
class_name ArcTowerEquipment

## 电弧塔装备 - 自动锁定攻击装备[br]
## 会自动对进入攻击范围的敌人发起攻击，每秒最多触发5次[br]
## 具备智能目标选择和冷却管理机制

@export var arc_damage: int = 15 ## 电弧基础伤害
@export var attack_range: float = 200.0 ## 攻击范围

# 弹药系统（充能）
var magazine_capacity: int = 5 ## 弹夹容量（充能点数）
var current_ammo: int = 0 ## 当前弹药（充能）
var reload_time: float = 0.2 ## 装弹时间（充能间隔）
var auto_reload: bool = true ## 自动装弹（自动充能）
var reload_timer: float = 0.0 ## 装弹计时器
var is_reloading: bool = false ## 是否正在装弹

var detection_interval: float = 0.1 ## 目标检测间隔（缩短以支持快速连续攻击）
var detection_timer: float = 0.0 ## 检测计时器
var current_targets: Array[Node2D] = [] ## 当前范围内的目标

@onready var range_indicator: Node2D = null

signal target_acquired(target: Node2D)
signal arc_attack_executed(target: Node2D, damage: int)

func _ready() -> void:
	super._ready()
	
	_setup_range_detection()
	# 初始化弹药系统
	current_ammo = magazine_capacity  # 开始时满弹药

func _process(delta: float) -> void:
	# 跟随玩家移动
	if owner_player:
		global_position = owner_player.global_position
	
	# 更新计时器
	reload_timer += delta
	detection_timer += delta
	
	# 弹药系统（自动装弹/充能）
	if auto_reload and current_ammo < magazine_capacity:
		if not is_reloading:
			is_reloading = true
			reload_timer = 0.0
		elif reload_timer >= reload_time:
			current_ammo += 1
			reload_timer = 0.0
			if current_ammo >= magazine_capacity:
				is_reloading = false
	
	# 定期检测目标
	if detection_timer >= detection_interval:
		detection_timer = 0.0
		_detect_targets()
	
	# 尝试攻击目标
	_try_attack_target()



## 检查是否可以使用装备[br]
## 基于弹药系统而不是传统冷却[br]
## [returns] 是否可以使用
func can_use() -> bool:
	if current_targets.is_empty():
		return false
	# 只要有弹药就可以攻击，不需要传统冷却检查
	return current_ammo > 0

## 设置发射器配置[br]
## [param config] 发射器配置字典
func set_emitter_config(config: Dictionary) -> void:
	emitter_config = config
	
	# 应用配置到电弧塔属性
	if config.has("base_damage"):
		arc_damage = config.base_damage
	if config.has("attack_range"):
		attack_range = config.attack_range  # 优先使用attack_range配置
	if config.has("magazine_capacity"):
		magazine_capacity = config.magazine_capacity
		current_ammo = magazine_capacity  # 重新初始化弹药
	if config.has("reload_time"):
		reload_time = config.reload_time
	if config.has("auto_reload"):
		auto_reload = config.auto_reload

## 设置范围检测区域
func _setup_range_detection() -> void:
	# 延迟到 _ready 之后执行，确保配置已经应用
	call_deferred("_create_detection_area")

## 创建检测区域（延迟执行）
func _create_detection_area() -> void:
	# 创建检测区域
	var detection_area = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	
	circle_shape.radius = attack_range
	collision_shape.shape = circle_shape
	
	detection_area.add_child(collision_shape)
	add_child(detection_area)
	
	# 设置碰撞层级
	detection_area.collision_layer = 0
	detection_area.collision_mask = 2  # 敌人层
	
	# 连接信号
	detection_area.area_entered.connect(_on_enemy_entered_range)
	detection_area.area_exited.connect(_on_enemy_exited_range)

## 检测当前范围内的目标
func _detect_targets() -> void:
	if not owner_player:
		return
	
	
	# 更新目标列表，移除无效或已死亡的目标
	current_targets = current_targets.filter(func(target): return is_instance_valid(target) and not target.is_dead)
	
	# 主动搜索范围内的敌人（备用方法，确保能找到敌人）
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in all_enemies:
		if enemy and is_instance_valid(enemy) and not enemy.is_dead:
			var distance = owner_player.global_position.distance_to(enemy.global_position)
			
			if distance <= attack_range:
				if enemy not in current_targets:
					current_targets.append(enemy)
			else:
				if enemy in current_targets:
					current_targets.erase(enemy)


## 尝试攻击目标
func _try_attack_target() -> void:
	# 检查是否有弹药
	if current_ammo <= 0:
		return
	
	# 检查是否有可攻击的目标
	if current_targets.is_empty():
		return
		
	# 连续攻击所有目标（直到弹药耗尽或没有目标）
	var attacks_this_frame = 0
	var max_attacks_per_frame = min(current_ammo, current_targets.size(), 3)  # 限制每帧最多3次攻击，避免卡顿
	
	while current_ammo > 0 and not current_targets.is_empty() and attacks_this_frame < max_attacks_per_frame:
		var target = _select_nearest_target()
		if target:
			_execute_arc_attack(target)
			attacks_this_frame += 1
		else:
			break


## 选择最近的目标[br]
## [returns] 最近的敌人目标
func _select_nearest_target() -> Node2D:
	if current_targets.is_empty() or not owner_player:
		return null
	
	var nearest_target: Node2D = null
	var nearest_distance: float = INF
	
	for target in current_targets:
		if is_instance_valid(target):
			var distance = owner_player.global_position.distance_to(target.global_position)
			if distance < nearest_distance and distance <= attack_range:
				nearest_distance = distance
				nearest_target = target
	
	return nearest_target

## 执行电弧攻击[br]
## [param target] 攻击目标
func _execute_arc_attack(target: Node2D) -> void:
	if not target or not is_instance_valid(target):
		return
	
	
	# 消耗弹药
	current_ammo -= 1
	
	# 创建电弧投射物
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		var main_scene = owner_player.get_parent()
		
		if main_scene and projectile:
			main_scene.add_child(projectile)
			
			# 设置投射物目标 - 优先使用电弧攻击方法
			if projectile.has_method("setup_arc_attack"):
				projectile.setup_arc_attack(owner_player.global_position, target.global_position, projectile_resource)
			elif projectile.has_method("setup_from_resource"):
				# 备用方法
				projectile.global_position = owner_player.global_position
				var direction = (target.global_position - owner_player.global_position).normalized()
				projectile.setup_from_resource(projectile_resource, direction)
	
	# 发射信号
	target_acquired.emit(target)
	arc_attack_executed.emit(target, arc_damage)
	equipment_used.emit(self)

## 敌人进入范围回调
func _on_enemy_entered_range(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy and enemy.is_in_group("enemies") and enemy not in current_targets:
		current_targets.append(enemy)

## 敌人离开范围回调
func _on_enemy_exited_range(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy in current_targets:
		current_targets.erase(enemy)

## 重写装备效果执行方法
func _execute_equipment_effect() -> void:
	# 电弧塔的攻击由自动触发系统处理，这里不需要额外逻辑
	pass

## 获取当前状态信息[br]
## [returns] 状态信息字典
func get_status_info() -> Dictionary:
	return {
		"current_ammo": current_ammo,
		"magazine_capacity": magazine_capacity,
		"reload_progress": reload_timer / reload_time if is_reloading else 0.0,
		"is_reloading": is_reloading,
		"targets_in_range": current_targets.size(),
		"can_attack": can_use(),
		"attack_range": attack_range,
		"arc_damage": arc_damage
	}

## 获取弹药状态[br]
## [returns] 弹药信息字典
func get_ammo_info() -> Dictionary:
	return {
		"current": current_ammo,
		"capacity": magazine_capacity,
		"reload_progress": reload_timer / reload_time if is_reloading else 0.0,
		"is_reloading": is_reloading,
		"time_to_next_ammo": reload_time - reload_timer if is_reloading else 0.0
	} 