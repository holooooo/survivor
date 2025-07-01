extends HitEffectResource
class_name RicochetHitEffect

## 弹射命中效果 - 命中敌人时重置投射物位置并继续攻击范围内的随机敌人[br]
## 支持多次弹射，每次弹射伤害衰减，重置飞行距离

@export_group("弹射配置")
@export var ricochet_count: int = 2 ## 弹射次数
@export var damage_decay: float = 0.1 ## 每次弹射伤害衰减比例（10%）
@export var reset_flight_distance: bool = true ## 是否重置飞行距离
@export var use_equipment_range: bool = true ## 是否使用装备攻击范围搜索目标
@export var fallback_search_radius: float = 300.0 ## 备用搜索范围（当无法获取装备范围时）

func _init():
	effect_name = "弹射效果"
	effect_id = "ricochet"

## 重写执行效果方法[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例[br]
## [param target] 目标节点[br]
## [param hit_info] 命中信息字典
func execute_effect(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, hit_info: Dictionary) -> void:
	if not projectile or not hit_info.has("hit_position"):
		return
	
	# 检查投射物是否已经弹射过
	var current_ricochet_count: int = projectile.get_flag("ricochet_count", 0)
	if current_ricochet_count >= ricochet_count:
		return
	
	# 标记投射物已弹射
	projectile.set_flag("ricochet_count", current_ricochet_count + 1)
	projectile.set_flag("is_ricocheting", true)
	
	var hit_position: Vector2 = hit_info.hit_position
	
	# 延迟执行弹射，避免在物理查询期间修改状态
	call_deferred("_apply_ricochet_deferred", projectile, equipment, target, hit_position, current_ricochet_count)

## 延迟应用弹射效果[br]
## [param projectile] 投射物实例[br]
## [param equipment] 装备实例[br]
## [param old_target] 原目标[br]
## [param hit_position] 命中位置[br]
## [param ricochet_count_before] 弹射前的次数
func _apply_ricochet_deferred(projectile: ProjectileBase, equipment: EquipmentBase, old_target: Node, hit_position: Vector2, ricochet_count_before: int) -> void:
	if not projectile or not is_instance_valid(projectile):
		return
	
	# 获取搜索范围
	var search_radius: float = _get_search_radius(equipment)
	
	# 查找新目标
	var new_target: Node = _find_ricochet_target(hit_position, old_target, search_radius)
	
	# 重置投射物位置
	projectile.global_position = hit_position
	
	# 应用伤害衰减
	_apply_damage_decay(projectile, ricochet_count_before + 1)
	
	# 重置飞行距离（如果启用）
	if reset_flight_distance:
		_reset_projectile_flight_distance(projectile)
	
	if new_target:
		# 有新目标：重置投射物轨迹指向新目标
		var new_direction: Vector2 = (new_target.global_position - hit_position).normalized()
		_redirect_projectile(projectile, new_direction)
		
		# 发送弹射信号
		FightEventBus.on_projectile_ricochet.emit(projectile, old_target, new_target)
	else:
		# 无目标：向随机方向飞行
		var random_direction: Vector2 = _get_random_direction()
		_redirect_projectile(projectile, random_direction)
		
		# 发送弹射信号（无新目标）
		FightEventBus.on_projectile_ricochet.emit(projectile, old_target, null)

## 获取搜索范围[br]
## [param equipment] 装备实例[br]
## [returns] 搜索半径
func _get_search_radius(equipment: EquipmentBase) -> float:
	if not use_equipment_range or not equipment:
		return fallback_search_radius
	
	# 尝试从装备配置获取攻击范围
	var equipment_config = equipment.get_config()
	if equipment_config.has("attack_range"):
		return equipment_config.attack_range
	
	# 备用方案
	return fallback_search_radius

## 查找弹射目标[br]
## [param center] 搜索中心位置[br]
## [param exclude_target] 要排除的目标（原目标）[br]
## [param radius] 搜索半径[br]
## [returns] 新目标节点，如果没有则返回null
func _find_ricochet_target(center: Vector2, exclude_target: Node, radius: float) -> Node:
	var scene_tree = Engine.get_main_loop() as SceneTree
	if not scene_tree:
		return null
	
	var all_enemies = scene_tree.get_nodes_in_group("enemies")
	var valid_targets: Array[Node] = []
	
	for enemy in all_enemies:
		if not enemy or not is_instance_valid(enemy):
			continue
		
		# 排除原目标
		if enemy == exclude_target:
			continue
		
		# 检查是否在搜索范围内
		var distance = enemy.global_position.distance_to(center)
		if distance <= radius:
			valid_targets.append(enemy)
	
	# 随机选择一个目标
	if valid_targets.size() > 0:
		var random_index = randi() % valid_targets.size()
		return valid_targets[random_index]
	
	return null

## 应用伤害衰减[br]
## [param projectile] 投射物实例[br]
## [param ricochet_number] 当前弹射次数（从1开始）
func _apply_damage_decay(projectile: ProjectileBase, ricochet_number: int) -> void:
	if not projectile:
		return
	
	# 计算衰减倍率
	var decay_multiplier: float = 1.0 - (damage_decay * ricochet_number)
	decay_multiplier = max(decay_multiplier, 0.1)  # 最小保留10%伤害
	
	# 应用到当前伤害
	projectile.current_damage = int(projectile.base_damage * decay_multiplier)

## 重置投射物飞行距离[br]
## [param projectile] 投射物实例
func _reset_projectile_flight_distance(projectile: ProjectileBase) -> void:
	if not projectile:
		return
	
	# 重置飞行相关属性
	projectile.start_position = projectile.global_position
	projectile.traveled_distance = 0.0
	
	# 重置生命周期计时器（如果需要）
	if projectile.has_property("lifetime_timer"):
		projectile.lifetime_timer = 0.0

## 重定向投射物[br]
## [param projectile] 投射物实例[br]
## [param new_direction] 新的飞行方向
func _redirect_projectile(projectile: ProjectileBase, new_direction: Vector2) -> void:
	if not projectile:
		return
	
	# 调用投射物的重定向方法（如果存在）
	if projectile.has_method("redirect"):
		projectile.redirect(new_direction)
		return
	
	# 通用重定向实现
	if projectile.has_method("_initialize_specific"):
		projectile._initialize_specific(new_direction)
	
	# 如果投射物有方向属性，直接设置
	if projectile.has_property("direction"):
		projectile.direction = new_direction
	elif projectile.has_property("velocity"):
		# 保持原速度大小，只改变方向
		var current_speed = projectile.velocity.length()
		projectile.velocity = new_direction * current_speed

## 获取随机方向[br]
## [returns] 随机单位向量
func _get_random_direction() -> Vector2:
	var random_angle = randf() * TAU
	return Vector2.from_angle(random_angle)

## 重写触发条件检查[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例[br]
## [param target] 目标节点[br]
## [param damage] 造成的伤害[br]
## [param damage_type] 伤害类型[br]
## [param is_critical] 是否暴击[br]
## [param is_kill] 是否击杀[br]
## [returns] 是否可以触发
func can_trigger(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, damage: int, damage_type: Constants.DamageType, is_critical: bool = false, is_kill: bool = false) -> bool:
	# 先检查基类条件
	if not super.can_trigger(player, equipment, projectile, target, damage, damage_type, is_critical, is_kill):
		return false
	
	# 检查投射物是否已达到最大弹射次数
	var current_ricochet_count: int = projectile.get_flag("ricochet_count", 0)
	if current_ricochet_count >= ricochet_count:
		return false
	
	# 检查弹射次数是否有效
	if ricochet_count <= 0:
		return false
	
	# 检查投射物是否由分裂创建（分裂的投射物不应该弹射）
	if projectile.get_flag("created_by") == "split":
		return false
	
	return true

## 获取效果描述[br]
## [returns] 效果描述文本
func get_description() -> String:
	var desc = "弹射 %d 次，每次衰减 %.0f%% 伤害" % [ricochet_count, damage_decay * 100]
	if reset_flight_distance:
		desc += "，重置飞行距离"
	if trigger_probability < 1.0:
		desc += "（%.0f%% 概率）" % (trigger_probability * 100)
	if cooldown_time > 0:
		desc += "（冷却 %.1f秒）" % cooldown_time
	return desc 