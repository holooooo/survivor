extends EffectResource
class_name EffectSpawnProjectile

## 生成投射物效果 - 在指定位置生成投射物[br]
## 支持自定义投射物配置和生成位置

@export_group("投射物配置")
@export var projectile_resource: EmitterProjectileResource ## 投射物资源
@export var spawn_count: int = 1 ## 生成数量
@export var spawn_spread: float = 0.0 ## 生成扩散角度（度）
@export var spawn_at_player: bool = true ## 在玩家位置生成
@export var spawn_at_target: bool = false ## 在目标位置生成
@export var spawn_at_event_position: bool = false ## 在事件位置生成

@export_group("方向配置")
@export var target_nearest_enemy: bool = true ## 瞄准最近的敌人
@export var fixed_direction: Vector2 = Vector2.ZERO ## 固定方向（如果不瞄准敌人）
@export var randomize_direction: bool = false ## 随机方向

func _init() -> void:
	effect_name = "生成投射物效果"
	effect_description = "在指定位置生成投射物"

## 执行效果[br]
## [param target] 目标节点（通常是玩家）[br]
## [param event_args] 事件参数
func execute_effect(target: Node, event_args: Dictionary) -> void:
	if not projectile_resource:
		push_warning("EffectSpawnProjectile: 没有配置投射物资源")
		return
	
	if not target:
		push_warning("EffectSpawnProjectile: 目标节点为空")
		return
	
	# 确定生成位置
	var spawn_position = _get_spawn_position(target, event_args)
	if spawn_position == Vector2.ZERO:
		push_warning("EffectSpawnProjectile: 无法确定生成位置")
		return
	
	# 生成投射物
	for i in range(spawn_count):
		_spawn_single_projectile(target, spawn_position, i, event_args)

## 获取生成位置[br]
## [param target] 目标节点[br]
## [param event_args] 事件参数[br]
## [returns] 生成位置
func _get_spawn_position(target: Node, event_args: Dictionary) -> Vector2:
	if spawn_at_player and target.has_method("get_global_position"):
		return target.global_position
	
	if spawn_at_target:
		var event_target = event_args.get("target")
		if event_target and event_target.has_method("get_global_position"):
			return event_target.global_position
	
	if spawn_at_event_position:
		var position = event_args.get("position")
		if position is Vector2:
			return position
	
	# 默认返回玩家位置
	if target.has_method("get_global_position"):
		return target.global_position
	
	return Vector2.ZERO

## 生成单个投射物[br]
## [param target] 目标节点[br]
## [param spawn_position] 生成位置[br]
## [param index] 投射物索引[br]
## [param event_args] 事件参数
func _spawn_single_projectile(target: Node, spawn_position: Vector2, index: int, event_args: Dictionary) -> void:
	# 获取投射物场景
	var projectile_scene = _get_projectile_scene()
	if not projectile_scene:
		push_warning("EffectSpawnProjectile: 无法获取投射物场景")
		return
	
	# 创建投射物实例
	var projectile = projectile_scene.instantiate()
	if not projectile:
		push_warning("EffectSpawnProjectile: 无法创建投射物实例")
		return
	
	# 添加到场景
	var main_scene = target.get_parent()
	if not main_scene:
		push_warning("EffectSpawnProjectile: 无法获取主场景")
		projectile.queue_free()
		return
	
	main_scene.add_child(projectile)
	projectile.global_position = spawn_position
	
	# 计算方向
	var direction = _get_projectile_direction(target, spawn_position, index, event_args)
	
	# 配置投射物
	if projectile.has_method("setup_from_resource"):
		var equipment = event_args.get("equipment")
		var stats = _get_equipment_stats(equipment)
		projectile.setup_from_resource(equipment, projectile_resource, direction, stats)

## 获取投射物方向[br]
## [param target] 目标节点[br]
## [param spawn_position] 生成位置[br]
## [param index] 投射物索引[br]
## [param event_args] 事件参数[br]
## [returns] 投射物方向
func _get_projectile_direction(target: Node, spawn_position: Vector2, index: int, event_args: Dictionary) -> Vector2:
	var direction = Vector2.RIGHT
	
	if randomize_direction:
		# 随机方向
		var angle = randf() * 2 * PI
		direction = Vector2(cos(angle), sin(angle))
	elif target_nearest_enemy:
		# 瞄准最近的敌人
		direction = _find_nearest_enemy_direction(spawn_position, target)
	elif fixed_direction != Vector2.ZERO:
		# 固定方向
		direction = fixed_direction.normalized()
	
	# 应用扩散
	if spawn_spread > 0.0 and spawn_count > 1:
		var spread_angle = deg_to_rad(spawn_spread)
		var angle_offset = (index - (spawn_count - 1) / 2.0) * spread_angle / max(1, spawn_count - 1)
		direction = direction.rotated(angle_offset)
	
	return direction.normalized()

## 寻找最近敌人的方向[br]
## [param from_position] 起始位置[br]
## [param target] 目标节点（用于获取场景树）[br]
## [returns] 敌人方向
func _find_nearest_enemy_direction(from_position: Vector2, target: Node = null) -> Vector2:
	if not target:
		return Vector2.RIGHT
	
	var enemies = target.get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return Vector2.RIGHT
	
	var nearest_enemy = null
	var nearest_distance = INF
	
	for enemy in enemies:
		if enemy.has_method("get_global_position"):
			var distance = from_position.distance_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_enemy = enemy
	
	if nearest_enemy:
		return (nearest_enemy.global_position - from_position).normalized()
	
	return Vector2.RIGHT

## 获取投射物场景[br]
## [returns] 投射物场景
func _get_projectile_scene() -> PackedScene:
	# 这里需要根据投射物资源获取对应的场景
	# 简化实现：使用手枪投射物场景
	return preload("res://src/equipment/emitter/pistol/projectile/pistol_projectile.tscn")

## 获取装备属性[br]
## [param equipment] 装备实例[br]
## [returns] 装备属性字典
func _get_equipment_stats(equipment: EquipmentBase) -> Dictionary:
	if equipment and equipment.has_method("_get_current_stats"):
		return equipment._get_current_stats()
	
	# 返回默认属性
	return {
		"damage": projectile_resource.base_damage if projectile_resource else 10,
		"speed": projectile_resource.projectile_speed if projectile_resource else 800.0,
		"range": projectile_resource.max_range if projectile_resource else 300.0
	}

## 获取效果信息[br]
## [returns] 效果信息字典
func get_effect_info() -> Dictionary:
	var info = super()
	info["projectile_name"] = projectile_resource.projectile_name if projectile_resource else "无"
	info["spawn_count"] = spawn_count
	info["spawn_spread"] = spawn_spread
	info["target_nearest_enemy"] = target_nearest_enemy
	return info

## 验证效果配置[br]
## [returns] 配置是否有效
func is_valid_effect() -> bool:
	if not super():
		return false
	if not projectile_resource:
		return false
	if spawn_count <= 0:
		return false
	if not spawn_at_player and not spawn_at_target and not spawn_at_event_position:
		return false
	return true 