extends HitEffectResource
class_name ExplosionHitEffect

## 爆炸命中效果 - 命中敌人时在原地生成快速引爆的炸弹投射物[br]
## 使用炸弹投射物系统，支持可配置的爆炸参数

@export_group("爆炸配置")
@export var explosion_radius: float = 100.0 ## 爆炸半径
@export var use_damage_ratio: bool = true ## 是否使用伤害比例模式
@export var damage_ratio: float = 0.8 ## 爆炸伤害比例（相对于原伤害）
@export var fixed_damage: int = 50 ## 固定爆炸伤害（非比例模式）
@export var inherit_damage_type: bool = true ## 是否继承原投射物伤害类型
@export var detonation_delay: float = 0.1 ## 引爆延迟时间
@export var explosion_spread_speed: float = 500.0 ## 爆炸扩散速度

@export_group("炸弹投射物配置")
@export var bomb_projectile_scene: PackedScene ## 炸弹投射物场景

func _init():
	effect_name = "爆炸效果"
	effect_id = "explosion"
	
	# 如果没有设置炸弹投射物场景，尝试加载默认场景
	if not bomb_projectile_scene:
		bomb_projectile_scene = load("res://src/equipment/emitter/bomb/projectile/bomb_projectile.tscn")

## 重写执行效果方法[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例[br]
## [param target] 目标节点[br]
## [param hit_info] 命中信息字典
func execute_effect(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, hit_info: Dictionary) -> void:
	if not hit_info.has("hit_position"):
		return
	
	var explosion_position: Vector2 = hit_info.hit_position
	var original_damage: int = hit_info.get("damage", projectile.current_damage)
	var original_damage_type: Constants.DamageType = hit_info.get("damage_type", projectile.damage_type)
	
	# 计算爆炸伤害
	var explosion_damage: int
	if use_damage_ratio:
		explosion_damage = int(original_damage * damage_ratio)
	else:
		explosion_damage = fixed_damage
	
	# 确定爆炸伤害类型
	var explosion_damage_type: Constants.DamageType
	if inherit_damage_type:
		explosion_damage_type = original_damage_type
	else:
		explosion_damage_type = Constants.DamageType.爆炸
	
	# 创建炸弹投射物
	_create_bomb_projectile(explosion_position, explosion_damage, explosion_damage_type, player, equipment)

## 创建炸弹投射物[br]
## [param position] 炸弹位置[br]
## [param damage] 爆炸伤害[br]
## [param damage_type] 爆炸伤害类型[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例
func _create_bomb_projectile(position: Vector2, damage: int, damage_type: Constants.DamageType, player: Player, equipment: EquipmentBase) -> void:
	if not bomb_projectile_scene:
		push_error("爆炸效果：未设置炸弹投射物场景")
		return
	
	# 实例化炸弹投射物
	var bomb_projectile: Node2D = bomb_projectile_scene.instantiate()
	if not bomb_projectile:
		push_error("爆炸效果：无法实例化炸弹投射物")
		return
	
	# 添加到场景树
	var parent_node: Node = _get_projectile_parent(player, equipment)
	if not parent_node:
		bomb_projectile.queue_free()
		return
	call_deferred("_add_bomb", parent_node, bomb_projectile, position, damage, damage_type, equipment)


func _add_bomb(parent_node: Node, bomb_projectile: Node2D, position: Vector2, damage: int, damage_type: Constants.DamageType, equipment: EquipmentBase) -> void:
	parent_node.add_child(bomb_projectile)
	bomb_projectile.global_position = position
	
	# 配置炸弹投射物属性
	if bomb_projectile.has_method("setup_from_resource"):
		var bomb_stats = _create_bomb_stats(damage, damage_type)
		var dummy_resource = _create_dummy_projectile_resource(damage, damage_type)
		bomb_projectile.setup_from_resource(equipment, dummy_resource, Vector2.ZERO, bomb_stats)
	else:
		# 直接设置属性作为备用方案
		_configure_bomb_directly(bomb_projectile, damage, damage_type)


## 获取投射物父节点[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [returns] 父节点
func _get_projectile_parent(player: Player, equipment: EquipmentBase) -> Node:
	# 优先使用装备的父节点
	if equipment.get_parent():
		return equipment.get_parent()
	
	# 备用方案：使用玩家的父节点
	if player.get_parent():
		return player.get_parent()
	
	# 最后备用方案：使用场景树根节点
	if player.get_tree():
		return player.get_tree().current_scene
	
	return null

## 创建炸弹统计数据[br]
## [param damage] 爆炸伤害[br]
## [param damage_type] 爆炸伤害类型[br]
## [returns] 统计数据字典
func _create_bomb_stats(damage: int, damage_type: Constants.DamageType) -> Dictionary:
	return {
		"base_damage": damage,
		"damage_type": damage_type,
		"pierce_count": 999, # 爆炸可以穿透所有目标
		"attack_range": explosion_radius,
		"detonation_time": detonation_delay,
		"explosion_radius": explosion_radius,
		"explosion_spread_speed": explosion_spread_speed
	}

## 创建临时投射物资源[br]
## [param damage] 爆炸伤害[br]
## [param damage_type] 爆炸伤害类型[br]
## [returns] 临时投射物资源
func _create_dummy_projectile_resource(damage: int, damage_type: Constants.DamageType) -> EmitterProjectileResource:
	# 创建一个发射器投射物资源用于配置炸弹
	var dummy_resource = EmitterProjectileResource.new()
	dummy_resource.projectile_name = "爆炸炸弹"
	dummy_resource.base_damage = damage
	dummy_resource.damage_type = damage_type
	dummy_resource.projectile_speed = 0.0 # 炸弹不移动
	dummy_resource.lifetime = detonation_delay + 2.0 # 确保有足够时间完成爆炸
	dummy_resource.pierce_count = 999 # 爆炸可以穿透所有目标
	dummy_resource.detection_radius = explosion_radius
	dummy_resource.affected_groups = ["enemies"] as Array[String]
	dummy_resource.projectile_color = Color.ORANGE
	dummy_resource.projectile_scale = Vector2(0.5, 0.5)
	
	# 通过元数据传递炸弹特有的配置
	dummy_resource.set_meta("detonation_time", detonation_delay)
	dummy_resource.set_meta("explosion_radius", explosion_radius)
	dummy_resource.set_meta("explosion_spread_speed", explosion_spread_speed)
	return dummy_resource

## 直接配置炸弹属性（备用方案）[br]
## [param bomb_projectile] 炸弹投射物实例[br]
## [param damage] 爆炸伤害[br]
## [param damage_type] 爆炸伤害类型
func _configure_bomb_directly(bomb_projectile: Node2D, damage: int, damage_type: Constants.DamageType) -> void:
	# 直接设置炸弹属性
	if bomb_projectile.has_method("set") and bomb_projectile.get("current_damage"):
		bomb_projectile.current_damage = damage
	
	if bomb_projectile.has_method("set") and bomb_projectile.get("damage_type"):
		bomb_projectile.damage_type = damage_type
	
	if bomb_projectile.has_method("set") and bomb_projectile.get("detonation_time"):
		bomb_projectile.detonation_time = detonation_delay
	
	if bomb_projectile.has_method("set") and bomb_projectile.get("explosion_radius"):
		bomb_projectile.explosion_radius = explosion_radius
	
	if bomb_projectile.has_method("set") and bomb_projectile.get("explosion_spread_speed"):
		bomb_projectile.explosion_spread_speed = explosion_spread_speed

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
	
	# 检查爆炸半径是否有效
	if explosion_radius <= 0:
		return false
	
	# 检查是否有炸弹投射物场景
	if not bomb_projectile_scene:
		return false
	
	return true

## 获取效果描述[br]
## [returns] 效果描述文本
func get_description() -> String:
	var desc: String
	if use_damage_ratio:
		desc = "在命中点投放炸弹，造成 %.0f%% 伤害，半径 %.0f" % [damage_ratio * 100, explosion_radius]
	else:
		desc = "在命中点投放炸弹，造成 %d 固定伤害，半径 %.0f" % [fixed_damage, explosion_radius]
	
	if detonation_delay > 0:
		desc += "（延迟 %.1f秒）" % detonation_delay
	
	if trigger_probability < 1.0:
		desc += "（%.0f%% 概率）" % (trigger_probability * 100)
	if cooldown_time > 0:
		desc += "（冷却 %.1f秒）" % cooldown_time
	return desc