extends Node2D
class_name EquipmentBase

## 装备基类 - 所有装备的基础节点类[br]
## 提供通用的装备属性和配置，子类实现具体的装备逻辑

@export var equipment_name: String = "基础装备"
@export var equipment_id: String = ""
@export var equipment_position: EquipmentResource.EquipmentPosition = EquipmentResource.EquipmentPosition.OUTPUT ## 装备位置类型
@export var icon_texture: Texture2D
@export var cooldown_time: float = 1.0 ## 冷却时间（秒）
@export var projectile_scene: PackedScene ## 发射的投射物场景
@export var projectile_resource: ProjectileBase ## 投射物配置资源

# 装备配置存储
var aoe_config: Dictionary = {}
var firearm_config: Dictionary = {}
var bomb_config: Dictionary = {}
var emitter_config: Dictionary = {}

var owner_player: Player
var last_use_time: float = 0.0

signal equipment_used(equipment_instance)

func _ready() -> void:
	pass

## 初始化装备[br]
## [param player] 装备拥有者
func initialize(player: Player) -> void:
	owner_player = player
	name = equipment_name + "_Instance"

## 使用装备[br]
## [returns] 是否成功使用
func use_equipment() -> bool:
	if not can_use():
		return false
	
	last_use_time = Time.get_ticks_msec() / 1000.0
	_execute_equipment_effect()
	equipment_used.emit(self)
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
	
	# 获取主场景
	var main_scene: Node2D = owner_player.get_parent()
	if main_scene:
		main_scene.add_child(projectile)
		
		# 设置投射物位置 - 基础实现在玩家位置
		projectile.global_position = _get_projectile_spawn_position()
		
		# 如果投射物有设置方法，配置参数
		if projectile.has_method("setup_from_resource") and projectile_resource:
			var target_direction: Vector2 = _get_target_direction()
			projectile.setup_from_resource(projectile_resource, target_direction)

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

## 设置AOE配置[br]
## [param config] AOE配置字典
func set_aoe_config(config: Dictionary) -> void:
	aoe_config = config

## 设置枪械配置[br]
## [param config] 枪械配置字典
func set_firearm_config(config: Dictionary) -> void:
	firearm_config = config

## 设置炸弹配置[br]
## [param config] 炸弹配置字典
func set_bomb_config(config: Dictionary) -> void:
	bomb_config = config

## 设置发射器配置[br]
## [param config] 发射器配置字典
func set_emitter_config(config: Dictionary) -> void:
	emitter_config = config

## 获取AOE配置[br]
## [returns] AOE配置字典
func get_aoe_config() -> Dictionary:
	return aoe_config

## 获取枪械配置[br]
## [returns] 枪械配置字典
func get_firearm_config() -> Dictionary:
	return firearm_config

## 获取炸弹配置[br]
## [returns] 炸弹配置字典
func get_bomb_config() -> Dictionary:
	return bomb_config

## 获取发射器配置[br]
## [returns] 发射器配置字典
func get_emitter_config() -> Dictionary:
	return emitter_config

## 检查攻击距离内是否有敌人[br]
## [returns] 是否有敌人在攻击距离内
func has_enemies_in_attack_range() -> bool:
	if not owner_player:
		return false
	
	# 检查是否启用攻击距离检查
	var range_check_enabled: bool = emitter_config.get("range_check_enabled", true)
	if not range_check_enabled:
		return true  # 如果未启用检查，始终返回true
	var attack_range: float = emitter_config.get("attack_range", 300.0)
	if attack_range <= 0:
		return true  # 如果攻击距离无效，始终返回true
	
	# 检查场景树是否可用
	var scene_tree = owner_player.get_tree()
	if not scene_tree:
		return false
	
	# 查找所有敌人
	var enemies: Array[Node] = scene_tree.get_nodes_in_group("enemies")
	if enemies.is_empty():
		return false
	
	# 检查是否有敌人在攻击距离内
	var player_pos: Vector2 = owner_player.global_position
	for enemy in enemies:
		if enemy is Node2D and is_instance_valid(enemy):
			var distance: float = player_pos.distance_to(enemy.global_position)
			if distance <= attack_range:
				return true
	
	return false

## 获取攻击距离内最近的敌人[br]
## [returns] 最近的敌人节点，如果没有则返回null
func get_nearest_enemy_in_attack_range() -> Node2D:
	if not owner_player:
		return null
	
	var attack_range: float = emitter_config.get("attack_range", 300.0)
	if attack_range <= 0:
		return _get_nearest_enemy()  # 如果攻击距离无效，返回最近敌人
	
	# 检查场景树是否可用
	var scene_tree = owner_player.get_tree()
	if not scene_tree:
		return null
	
	# 查找所有敌人
	var enemies: Array[Node] = scene_tree.get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	
	# 找到攻击距离内最近的敌人
	var nearest_enemy: Node2D = null
	var nearest_distance: float = INF
	var player_pos: Vector2 = owner_player.global_position
	
	for enemy in enemies:
		if enemy is Node2D and is_instance_valid(enemy):
			var distance: float = player_pos.distance_to(enemy.global_position)
			if distance <= attack_range and distance < nearest_distance:
				nearest_distance = distance
				nearest_enemy = enemy
	
	return nearest_enemy

## 获取最近的敌人（无距离限制）[br]
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
	
	# 找到最近的敌人
	var nearest_enemy: Node2D = null
	var nearest_distance: float = INF
	var player_pos: Vector2 = owner_player.global_position
	
	for enemy in enemies:
		if enemy is Node2D and is_instance_valid(enemy):
			var distance: float = player_pos.distance_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_enemy = enemy
	
	return nearest_enemy

## 创建装备实例 - 复制当前装备用于游戏中[br]
## [param player] 装备的拥有者[br]
## [returns] 装备实例节点
func create_instance(player: Player) -> EquipmentBase:
	var instance: EquipmentBase = duplicate()
	instance.initialize(player)
	return instance