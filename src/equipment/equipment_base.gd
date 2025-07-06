extends Node2D
class_name EquipmentBase

## 装备基类 - 所有装备的基础节点类[br]
## 提供通用的装备属性和配置，子类实现具体的装备逻辑

@export var equipment_name: String = "基础装备"
@export var equipment_id: String = ""
@export var equipment_quality: Constants.EquipmentQuality = Constants.EquipmentQuality.民用 ## 装备品质
@export var icon_texture: Texture2D
@export var cooldown_time: float = 1.0 ## 冷却时间（秒）
@export var projectile_scene: PackedScene ## 发射的投射物场景
@export var projectile_resource: EmitterProjectileResource ## 投射物配置资源
@export var damage_type: Constants.DamageType = Constants.DamageType.枪械 ## 装备伤害类型
@export var attached_buffs: Array[BuffResource] = [] ## 装备附带的buff效果


var resource: EquipmentResource
var emitter_config: Dictionary = {}

# 属性系统
var base_stats: Dictionary = {} ## 基础属性


var owner_player: Player
var last_use_time: float = 0.0

func _ready() -> void:
	_setup_base_stats()
	_setup_damage_type()

## 初始化装备[br]
## [param player] 装备拥有者
func initialize(player: Player) -> void:
	owner_player = player
	name = equipment_name + "_Instance"
	_setup_base_stats()
	_setup_damage_type()
	
	# 装备管理器会稍后设置mod管理器
	FightEventBus.on_equip.emit(player, self)
	
	# 装备时施加附带的buff
	_apply_attached_buffs()


## 设置基础属性
func _setup_base_stats() -> void:
	base_stats = {
		"cooldown_time": cooldown_time,
		"attack_range": emitter_config.get("attack_range", 300.0),
		"base_damage": emitter_config.get("base_damage", 10),
		"magazine_capacity": emitter_config.get("magazine_capacity", 0),
		"damage_type": damage_type
	}

## 设置装备伤害类型[br]
## 根据装备标签自动设置合适的伤害类型
func _setup_damage_type() -> void:
	# 更新基础属性中的伤害类型
	base_stats["damage_type"] = damage_type

## 应用所有效果到装备属性
func _apply_all_effects() -> void:
	# 从基础属性开始
	var final_stats = base_stats.duplicate()
	
	# 更新装备属性
	if final_stats.has("cooldown_time"):
		cooldown_time = final_stats.cooldown_time
	
	# 更新配置中的属性
	if final_stats.has("attack_range"):
		emitter_config["attack_range"] = final_stats.attack_range
	if final_stats.has("base_damage"):
		emitter_config["base_damage"] = final_stats.base_damage
	if final_stats.has("magazine_capacity"):
		emitter_config["magazine_capacity"] = final_stats.magazine_capacity

## 使用装备[br]
## [returns] 是否成功使用
func use_equipment() -> bool:
	if not can_use():
		return false

	last_use_time = Time.get_ticks_msec() / 1000.0
	FightEventBus.on_equipment_cooldown_start.emit(owner_player, self, last_use_time, cooldown_time)
	FightEventBus.on_equipment_used.emit(owner_player, self)
	_execute_equipment_effect()
	return true

## 检查是否可以使用装备[br]
## [returns] 是否可以使用
func can_use() -> bool:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	return current_time - last_use_time >= cooldown_time

## 执行装备效果 - 基础实现，创建投射物
func _execute_equipment_effect() -> void:
	if not owner_player:
		return
	
	# 获取投射物场景
	if not projectile_scene:
		return
	
	# 创建投射物
	var projectile: Node2D = projectile_scene.instantiate()
	add_child(projectile)
	projectile.global_position = _get_projectile_spawn_position()

	# 如果投射物有设置方法，配置参数
	if projectile.has_method("setup_from_resource") and projectile_resource:
		var target_direction: Vector2 = _get_target_direction()
		# 传递装备当前的属性到投射物
		var equipment_stats = _get_current_stats()
		projectile.setup_from_resource(self, projectile_resource, target_direction, equipment_stats)

## 获取当前有效的属性[br]
## [returns] 当前属性字典
func _get_current_stats() -> Dictionary:
	var current_stats = base_stats.duplicate()
	
	# 应用玩家属性加成
	if owner_player and owner_player.stats_manager:
		var player_stats = owner_player.stats_manager
		var equipment_damage_type = get_damage_type()
		
		# 应用冷却时间缩减
		if current_stats.has("cooldown_time"):
			var reduction = player_stats.get_cooldown_reduction(equipment_damage_type)
			current_stats.cooldown_time *= (1.0 - reduction)
		
		# 应用伤害倍率
		if current_stats.has("base_damage"):
			var multiplier = player_stats.get_damage_multiplier(equipment_damage_type)
			current_stats.base_damage = int(current_stats.base_damage * multiplier)
		
		# 应用攻击范围加成
		if current_stats.has("attack_range"):
			var bonus = player_stats.get_attack_range_bonus(equipment_damage_type)
			current_stats.attack_range *= (1.0 + bonus)
	
	return current_stats

## 获取目标方向 - 根据配置的目标类型选择目标[br]
## [returns] 目标方向向量
func _get_target_direction() -> Vector2:
	if not owner_player:
		return Vector2.RIGHT
	
	var target_type: Constants.TargetType = emitter_config.get("target_type", Constants.TargetType.最近敌人)
	var continuous_attack: bool = emitter_config.get("continuous_attack", false)
	
	var target_direction: Vector2 = Vector2.ZERO
	
	match target_type:
		Constants.TargetType.最近敌人:
			target_direction = _get_direction_to_nearest_enemy()
		Constants.TargetType.最低生命值敌人:
			target_direction = _get_direction_to_lowest_health_enemy()
		Constants.TargetType.随机敌人:
			target_direction = _get_direction_to_random_enemy()
		Constants.TargetType.随机位置:
			target_direction = _get_random_direction_in_range()
	
	# 如果没有找到目标且启用了持续攻击，使用默认方向
	if target_direction == Vector2.ZERO and continuous_attack:
		target_direction = Vector2.RIGHT
	
	return target_direction

## 获取投射物生成位置 - 子类可重写此方法[br]
## [returns] 投射物生成的世界坐标
func _get_projectile_spawn_position() -> Vector2:
	if owner_player:
		return owner_player.global_position
	return Vector2.ZERO

## 获取剩余冷却时间[br]
## [returns] 剩余冷却时间（秒）
func get_remaining_cooldown() -> float:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	var remaining: float = cooldown_time - (current_time - last_use_time)
	return max(0.0, remaining)

## 设置发射器配置[br]
## [param config] 发射器配置字典
func set_emitter_config(config: Dictionary) -> void:
	emitter_config = config

## 获取发射器配置[br]
## [returns] 发射器配置字典
func get_emitter_config() -> Dictionary:
	return emitter_config

## 检查攻击距离内是否有敌人[br]
## 使用敌人缓存的距离信息提高性能[br]
## [returns] 是否有敌人在攻击距离内
func has_enemies_in_attack_range() -> bool:
	if not owner_player:
		return false
	
	# 检查是否启用攻击距离检查
	var range_check_enabled: bool = emitter_config.get("range_check_enabled", true)
	if not range_check_enabled:
		return true # 如果未启用检查，始终返回true
	
	var attack_range: float = max(emitter_config.get("attack_range", 300.0), 0.0)

	# 检查场景树是否可用
	var scene_tree = owner_player.get_tree()
	if not scene_tree:
		return false
	
	# 查找所有敌人
	var enemies: Array[Node] = scene_tree.get_nodes_in_group("enemies")
	if enemies.is_empty():
		return false
	
	# 检查是否有敌人在攻击距离内，使用敌人缓存的距离信息
	for enemy in enemies:
		if enemy is EnemyBase and is_instance_valid(enemy):
			if enemy.is_within_distance_of_player(attack_range):
				return true
	
	return false

## 获取攻击距离内最近的敌人[br]
## 使用敌人缓存的距离信息提高性能[br]
## [returns] 最近的敌人节点，如果没有则返回null
func get_nearest_enemy_in_attack_range() -> Node2D:
	if not owner_player:
		return null
	
	var attack_range: float = max(emitter_config.get("attack_range", 300.0), 0.0)
	
	# 检查场景树是否可用
	var scene_tree = owner_player.get_tree()
	if not scene_tree:
		return null
	
	# 查找所有敌人
	var enemies: Array[Node] = scene_tree.get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	
	# 找到攻击距离内最近的敌人，使用敌人缓存的距离信息
	var nearest_enemy: Node2D = null
	var nearest_distance: float = INF
	
	for enemy in enemies:
		if enemy is EnemyBase and is_instance_valid(enemy):
			# 使用敌人缓存的距离信息
			if enemy.is_within_distance_of_player(attack_range):
				var cached_distance: float = enemy.get_cached_distance_to_player()
				if cached_distance < nearest_distance:
					nearest_distance = cached_distance
					nearest_enemy = enemy
	
	return nearest_enemy

## 获取最近的敌人（无距离限制）[br]
## 使用敌人缓存的距离信息提高性能[br]
## [returns] 最近的敌人节点，如果没有则返回null
func _get_nearest_enemy() -> Node2D:
	if not owner_player:
		return null
	
	# 检查场景树是否可用
	var scene_tree = owner_player.get_tree()
	if not scene_tree:
		return null
	
	# 查找所有敌人
	var enemies: Array[Node] = scene_tree.get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	
	# 找到最近的敌人，使用敌人缓存的距离信息
	var nearest_enemy: Node2D = null
	var nearest_distance: float = INF
	
	for enemy in enemies:
		if enemy is EnemyBase and is_instance_valid(enemy):
			var cached_distance: float = enemy.get_cached_distance_to_player()
			if cached_distance < nearest_distance:
				nearest_distance = cached_distance
				nearest_enemy = enemy
	
	return nearest_enemy

## 获取指向最近敌人的方向[br]
## [returns] 目标方向向量
func _get_direction_to_nearest_enemy() -> Vector2:
	var nearest_enemy: Node2D = get_nearest_enemy_in_attack_range()
	
	if nearest_enemy:
		return (nearest_enemy.global_position - owner_player.global_position).normalized()
	
	# 如果攻击距离内没有敌人，检查是否禁用了距离检查
	var range_check_enabled: bool = emitter_config.get("range_check_enabled", true)
	if not range_check_enabled:
		var any_enemy: Node2D = _get_nearest_enemy()
		if any_enemy:
			return (any_enemy.global_position - owner_player.global_position).normalized()
	
	return Vector2.ZERO

## 获取指向生命值最低敌人的方向[br]
## [returns] 目标方向向量
func _get_direction_to_lowest_health_enemy() -> Vector2:
	var lowest_health_enemy: Node2D = _get_lowest_health_enemy_in_range()
	
	if lowest_health_enemy:
		return (lowest_health_enemy.global_position - owner_player.global_position).normalized()
	
	return Vector2.ZERO

## 获取指向随机敌人的方向[br]
## [returns] 目标方向向量
func _get_direction_to_random_enemy() -> Vector2:
	var random_enemy: Node2D = _get_random_enemy_in_range()
	
	if random_enemy:
		return (random_enemy.global_position - owner_player.global_position).normalized()
	
	return Vector2.ZERO

## 获取攻击范围内的随机方向[br]
## [returns] 目标方向向量
func _get_random_direction_in_range() -> Vector2:
	# 生成随机角度
	var random_angle: float = randf() * TAU
	return Vector2.from_angle(random_angle)

## 获取攻击范围内生命值最低的敌人[br]
## [returns] 生命值最低的敌人节点，如果没有则返回null
func _get_lowest_health_enemy_in_range() -> Node2D:
	if not owner_player:
		return null
	
	var attack_range: float = max(emitter_config.get("attack_range", 300.0), 0.0)
	var range_check_enabled: bool = emitter_config.get("range_check_enabled", true)
	
	# 检查场景树是否可用
	var scene_tree = owner_player.get_tree()
	if not scene_tree:
		return null
	
	# 查找所有敌人
	var enemies: Array[Node] = scene_tree.get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	
	# 找到攻击范围内生命值最低的敌人
	var lowest_health_enemy: Node2D = null
	var lowest_health: int = INF
	
	for enemy in enemies:
		if enemy is EnemyBase and is_instance_valid(enemy):
			# 检查距离（如果启用距离检查）
			if range_check_enabled and not enemy.is_within_distance_of_player(attack_range):
				continue
			
			if enemy.current_health < lowest_health:
				lowest_health = enemy.current_health
				lowest_health_enemy = enemy
	
	return lowest_health_enemy

## 获取攻击范围内的随机敌人[br]
## [returns] 随机敌人节点，如果没有则返回null
func _get_random_enemy_in_range() -> Node2D:
	if not owner_player:
		return null
	
	var attack_range: float = max(emitter_config.get("attack_range", 300.0), 0.0)
	var range_check_enabled: bool = emitter_config.get("range_check_enabled", true)
	
	# 检查场景树是否可用
	var scene_tree = owner_player.get_tree()
	if not scene_tree:
		return null
	
	# 查找所有敌人
	var enemies: Array[Node] = scene_tree.get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	
	# 收集攻击范围内的敌人
	var enemies_in_range: Array[Node2D] = []
	
	for enemy in enemies:
		if enemy is EnemyBase and is_instance_valid(enemy):
			# 检查距离（如果启用距离检查）
			if range_check_enabled and not enemy.is_within_distance_of_player(attack_range):
				continue
			
			enemies_in_range.append(enemy)
	
	# 随机选择一个敌人
	if enemies_in_range.size() > 0:
		var random_index: int = randi() % enemies_in_range.size()
		return enemies_in_range[random_index]
	
	return null

## 获取装备伤害类型[br]
## [returns] 伤害类型
func get_damage_type() -> Constants.DamageType:
	return damage_type

## 获取装备的命中效果[br]
## [returns] 命中效果数组
func get_hit_effects() -> Array:
	if emitter_config.has("hit_effects"):
		return emitter_config.hit_effects
	return []

## 获取装备配置[br]
## [returns] 装备配置字典
func get_config() -> Dictionary:
	return emitter_config

## 设置装备伤害类型[br]
## [param new_damage_type] 新的伤害类型
func set_damage_type(new_damage_type: Constants.DamageType) -> void:
	damage_type = new_damage_type
	base_stats["damage_type"] = damage_type

## 创建装备实例 - 复制当前装备用于游戏中[br]
## [param player] 装备的拥有者[br]
## [returns] 装备实例节点
func create_instance(player: Player) -> EquipmentBase:
	var instance: EquipmentBase = duplicate()
	instance.initialize(player)
	instance.resource = resource
	return instance

## 重新计算装备属性（由装备管理器调用）[br]
func recalculate_stats() -> void:
	# 重新应用玩家属性到装备
	_apply_all_effects()

## 施加装备附带的buff[br]
func _apply_attached_buffs() -> void:
	if not owner_player or attached_buffs.is_empty():
		return
	
	for buff_resource in attached_buffs:
		if buff_resource:
			owner_player.add_buff(buff_resource, owner_player)
			print("装备 %s 施加buff: %s" % [equipment_name, buff_resource.buff_name])

## 移除装备附带的buff[br]
func _remove_attached_buffs() -> void:
	if not owner_player or attached_buffs.is_empty():
		return
	
	for buff_resource in attached_buffs:
		if buff_resource:
			owner_player.remove_buff(buff_resource.buff_id)
			print("装备 %s 移除buff: %s" % [equipment_name, buff_resource.buff_name])

## 装备卸载时的清理[br]
func _exit_tree() -> void:
	# 注意：根据需求，装备卸载时不移除buff，让buff自行到期
	# 如果需要立即移除，可以取消注释下面的行
	# _remove_attached_buffs()
	pass
