extends Node2D
class_name EquipmentBase

## 装备基类 - 所有装备的基础节点类[br]
## 提供通用的装备属性和配置，子类实现具体的装备逻辑

@export var equipment_name: String = "基础装备"
@export var equipment_id: String = ""
@export var equipment_quality: EquipmentResource.EquipmentQuality = EquipmentResource.EquipmentQuality.COMMERCIAL ## 装备品质
@export var icon_texture: Texture2D
@export var cooldown_time: float = 1.0 ## 冷却时间（秒）
@export var projectile_scene: PackedScene ## 发射的投射物场景
@export var projectile_resource: EmitterProjectileResource ## 投射物配置资源
@export var damage_type: Constants.DamageType = Constants.DamageType.枪械 ## 装备伤害类型


var emitter_config: Dictionary = {}

# 属性系统
var base_stats: Dictionary = {} ## 基础属性
var external_mod_effects: Dictionary = {} ## 外部mod效果


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

## 应用外部mod效果[br]
## [param mod_effects] 从装备管理器传来的mod效果
func apply_external_mod_effects(mod_effects: Dictionary) -> void:
	external_mod_effects = mod_effects
	_apply_all_effects()

## 应用所有效果到装备属性
func _apply_all_effects() -> void:
	# 从基础属性开始
	var final_stats = base_stats.duplicate()
	
	# 应用外部mod效果
	for stat_name in external_mod_effects:
		if base_stats.has(stat_name):
			final_stats[stat_name] = external_mod_effects[stat_name]
	
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
	
	# 应用外部mod效果
	for stat_name in external_mod_effects:
		if current_stats.has(stat_name):
			current_stats[stat_name] = external_mod_effects[stat_name]
	
	return current_stats

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
		# 如果攻击距离内没有敌人，检查是否禁用了距离检查
		var range_check_enabled: bool = emitter_config.get("range_check_enabled", true)
		if not range_check_enabled:
			# 距离检查被禁用，返回最近敌人的方向
			var any_enemy: Node2D = _get_nearest_enemy()
			if any_enemy:
				return (any_enemy.global_position - owner_player.global_position).normalized()
		
		return Vector2.RIGHT

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

## 获取装备伤害类型[br]
## [returns] 伤害类型
func get_damage_type() -> Constants.DamageType:
	return damage_type

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
	return instance

## 重新计算装备属性（由装备管理器调用）[br]
func recalculate_stats() -> void:
	# 重新应用玩家属性到装备
	_apply_all_effects()
