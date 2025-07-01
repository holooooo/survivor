extends Node
class_name HitEffectManager

## 命中效果管理器 - 通过事件总线处理投射物命中效果[br]
## 监听投射物命中事件，根据装备配置触发相应的命中效果

# 冷却时间管理
var player_effect_cooldowns: Dictionary = {} ## 玩家级别的效果冷却（全局冷却）
var equipment_effect_cooldowns: Dictionary = {} ## 装备级别的效果冷却
var projectile_states: Dictionary = {} ## 投射物状态追踪

func _ready() -> void:
	# 订阅命中相关事件
	FightEventBus.on_projectile_hit.connect(_on_projectile_hit)
	FightEventBus.on_projectile_destroy.connect(_on_projectile_destroyed)
	FightEventBus.on_projectile_kill.connect(_on_projectile_kill)

## 投射物命中事件处理[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例[br]
## [param target] 目标节点[br]
## [param damage] 造成的伤害[br]
## [param damage_type] 伤害类型
func _on_projectile_hit(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, damage: int, damage_type: Constants.DamageType) -> void:
	if not player or not equipment or not projectile or not target:
		return
	
	# 获取装备的命中效果配置
	var hit_effects = _get_equipment_hit_effects(equipment)
	if hit_effects.is_empty():
		return
	
	# 检查是否为暴击（可能需要扩展投射物基类来支持）
	var is_critical = _check_if_critical_hit(projectile, damage)
	
	# 构建命中信息
	var hit_info = {
		"hit_position": target.global_position,
		"projectile_direction": _get_projectile_direction(projectile),
		"damage": damage,
		"damage_type": damage_type,
		"is_critical": is_critical
	}
	
	# 处理每个命中效果
	for effect in hit_effects:
		if not effect is HitEffectResource:
			continue
		
		if _can_trigger_effect(effect, player, equipment, projectile, target, damage, damage_type, is_critical, false):
			_execute_effect(effect, player, equipment, projectile, target, hit_info)

## 投射物击杀事件处理[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例[br]
## [param target] 目标节点[br]
## [param damage] 造成的伤害[br]
## [param damage_type] 伤害类型
func _on_projectile_kill(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, damage: int, damage_type: Constants.DamageType) -> void:
	if not player or not equipment or not projectile or not target:
		return
	
	# 获取装备的命中效果配置
	var hit_effects = _get_equipment_hit_effects(equipment)
	if hit_effects.is_empty():
		return
	
	# 检查是否为暴击
	var is_critical = _check_if_critical_hit(projectile, damage)
	
	# 构建命中信息
	var hit_info = {
		"hit_position": target.global_position,
		"projectile_direction": _get_projectile_direction(projectile),
		"damage": damage,
		"damage_type": damage_type,
		"is_critical": is_critical,
		"is_kill": true
	}
	
	# 处理每个命中效果（击杀触发）
	for effect in hit_effects:
		if not effect is HitEffectResource:
			continue
		
		if _can_trigger_effect(effect, player, equipment, projectile, target, damage, damage_type, is_critical, true):
			_execute_effect(effect, player, equipment, projectile, target, hit_info)

## 投射物销毁事件处理（清理状态）[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例
func _on_projectile_destroyed(player: Player, equipment: EquipmentBase, projectile: ProjectileBase) -> void:
	if projectile:
		var projectile_id = str(projectile.get_instance_id())
		projectile_states.erase(projectile_id)

## 获取装备的命中效果配置[br]
## [param equipment] 装备实例[br]
## [returns] 命中效果数组
func _get_equipment_hit_effects(equipment: EquipmentBase) -> Array:
	var effects: Array = []
	
	# 从装备配置中获取
	if equipment.has_method("get_hit_effects"):
		effects = equipment.get_hit_effects()
	elif equipment.resource and equipment.resource.has_method("get_hit_effects"):
		effects = equipment.resource.get_hit_effects()
	elif equipment.has_method("get_config") and equipment.get_config().has("hit_effects"):
		effects = equipment.get_config().hit_effects
	
	return effects

## 检查是否可以触发效果[br]
## [param effect] 效果资源[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例[br]
## [param target] 目标节点[br]
## [param damage] 伤害值[br]
## [param damage_type] 伤害类型[br]
## [param is_critical] 是否暴击[br]
## [param is_kill] 是否击杀[br]
## [returns] 是否可以触发
func _can_trigger_effect(effect: HitEffectResource, player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, damage: int, damage_type: Constants.DamageType, is_critical: bool, is_kill: bool) -> bool:
	# 效果自身的触发条件检查
	if not effect.can_trigger(player, equipment, projectile, target, damage, damage_type, is_critical, is_kill):
		return false
	
	# 冷却时间检查
	if not _check_effect_cooldown(effect, player, equipment):
		return false
	
	return true

## 检查效果冷却时间[br]
## [param effect] 效果资源[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [returns] 是否不在冷却中
func _check_effect_cooldown(effect: HitEffectResource, player: Player, equipment: EquipmentBase) -> bool:
	if effect.cooldown_time <= 0:
		return true
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var effect_id = effect.get_effect_id()
	var player_id = str(player.get_instance_id())
	var equipment_id = str(equipment.get_instance_id())
	
	# 检查玩家级别冷却（如果配置为全局冷却）
	var player_cooldown_key = player_id + "_" + effect_id
	if player_effect_cooldowns.has(player_cooldown_key):
		var last_trigger = player_effect_cooldowns[player_cooldown_key]
		if current_time - last_trigger < effect.cooldown_time:
			return false
	
	# 检查装备级别冷却
	var equipment_cooldown_key = equipment_id + "_" + effect_id
	if equipment_effect_cooldowns.has(equipment_cooldown_key):
		var last_trigger = equipment_effect_cooldowns[equipment_cooldown_key]
		if current_time - last_trigger < effect.cooldown_time:
			return false
	
	return true

## 执行效果[br]
## [param effect] 效果资源[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例[br]
## [param target] 目标节点[br]
## [param hit_info] 命中信息
func _execute_effect(effect: HitEffectResource, player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, hit_info: Dictionary) -> void:
	# 记录触发时间
	_record_effect_trigger(effect, player, equipment)
	
	# 发送效果触发信号
	FightEventBus.on_hit_effect_triggered.emit(player, equipment, projectile, target, effect.effect_name)
	
	# 执行具体效果
	effect.execute_effect(player, equipment, projectile, target, hit_info)

## 记录效果触发时间[br]
## [param effect] 效果资源[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例
func _record_effect_trigger(effect: HitEffectResource, player: Player, equipment: EquipmentBase) -> void:
	if effect.cooldown_time <= 0:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var effect_id = effect.get_effect_id()
	var player_id = str(player.get_instance_id())
	var equipment_id = str(equipment.get_instance_id())
	
	# 记录装备级别冷却（默认行为）
	var equipment_cooldown_key = equipment_id + "_" + effect_id
	equipment_effect_cooldowns[equipment_cooldown_key] = current_time
	
	# 如果需要全局冷却，也可以记录玩家级别冷却
	# var player_cooldown_key = player_id + "_" + effect_id
	# player_effect_cooldowns[player_cooldown_key] = current_time

## 检查是否为暴击（需要根据具体实现调整）[br]
## [param projectile] 投射物实例[br]
## [param damage] 伤害值[br]
## [returns] 是否暴击
func _check_if_critical_hit(projectile: ProjectileBase, damage: int) -> bool:
	# 简单的实现：检查投射物是否有暴击标记
	if projectile.has_method("is_critical_hit"):
		return projectile.is_critical_hit()
	
	# 或者通过比较伤害值与基础伤害
	if projectile.has_method("get_base_damage"):
		var base_damage = projectile.get_base_damage()
		return damage > base_damage
	
	# 默认返回false
	return false

## 获取投射物方向[br]
## [param projectile] 投射物实例[br]
## [returns] 飞行方向
func _get_projectile_direction(projectile: ProjectileBase) -> Vector2:
	if projectile.has_method("_get_direction"):
		return projectile._get_direction()
	elif projectile.has_method("get_direction"):
		return projectile.get_direction()
	
	# 默认方向
	return Vector2.RIGHT 