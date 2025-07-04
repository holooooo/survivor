extends RefCounted
class_name BuffInstance

## Buff实例类 - 管理运行时的buff状态和效果[br]
## 包含buff的生命周期管理、效果应用、层数处理等功能

var buff_resource: BuffResource
var target: Actor
var caster: Actor
var equipment: EquipmentBase
var projectile: ProjectileBase

# 状态管理
var instance_id: String
var current_stacks: int = 1
var remaining_duration: float = 0.0
var is_expired: bool = false
var is_paused: bool = false

# 效果系统
var buff_effects: Array = []
var applied_modifiers: Dictionary = {} ## 已应用的属性修改器

# 计时器
var duration_timer: float = 0.0
var tick_timer: float = 0.0
var tick_interval: float = 1.0 ## 每秒触发一次tick

signal buff_expired(buff_instance: BuffInstance)
signal buff_stacks_changed(buff_instance: BuffInstance, old_stacks: int, new_stacks: int)
signal buff_tick(buff_instance: BuffInstance)

func _init():
	instance_id = str(Time.get_ticks_msec()) + "_" + str(randi())

## 设置buff实例[br]
## [param resource] buff资源[br]
## [param target_actor] 目标角色[br]
## [param caster_actor] 施法者[br]
## [param source_equipment] 源装备[br]
## [param source_projectile] 源投射物
func setup(resource: BuffResource, target_actor: Actor, caster_actor: Actor = null, source_equipment: EquipmentBase = null, source_projectile: ProjectileBase = null) -> void:
	buff_resource = resource
	target = target_actor
	caster = caster_actor
	equipment = source_equipment
	projectile = source_projectile
	
	remaining_duration = buff_resource.duration
	_create_buff_effects()
	_apply_effects()

## 更新buff状态[br]
## [param delta] 时间增量
func update(delta: float) -> void:
	if is_expired or is_paused:
		return
	
	duration_timer += delta
	remaining_duration -= delta
	
	# 检查是否到期
	if remaining_duration <= 0.0 and not buff_resource.is_permanent:
		_expire()
		return
	
	# 处理tick效果
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_on_tick()

## 处理tick事件[br]
func _on_tick() -> void:
	buff_tick.emit(self)
	
	# 通知所有效果进行tick处理
	for effect in buff_effects:
		if effect.has_method("on_tick"):
			effect.on_tick()

## 添加层数[br]
## [param stacks] 要添加的层数
func add_stacks(stacks: int = 1) -> void:
	if not buff_resource.stackable:
		# 不可叠加的buff，刷新持续时间
		if buff_resource.stack_refresh_duration:
			remaining_duration = buff_resource.duration
		return
	
	var old_stacks = current_stacks
	current_stacks = min(current_stacks + stacks, buff_resource.max_stacks)
	
	if current_stacks != old_stacks:
		buff_stacks_changed.emit(self, old_stacks, current_stacks)
	
	# 刷新持续时间
	if buff_resource.stack_refresh_duration:
		remaining_duration = buff_resource.duration

## 强制过期[br]
func expire_immediately() -> void:
	_expire()

## 处理过期[br]
func _expire() -> void:
	if is_expired:
		return
	
	is_expired = true
	_remove_effects()
	buff_expired.emit(self)

## 创建buff效果[br]
func _create_buff_effects() -> void:
	buff_effects.clear()
	
	# 基于效果类型创建对应的效果实例 - 使用简化版本先
	match buff_resource.effect_type:
		Constants.BuffEffectType.属性修改:
			var effect = load("res://src/entities/buff/effects/attribute_modifier_buff_effect.gd").new()
			if effect.has_method("initialize"):
				effect.initialize(self)
			buff_effects.append(effect)
		
		Constants.BuffEffectType.持续伤害:
			var effect = load("res://src/entities/buff/effects/dot_buff_effect.gd").new()
			if effect.has_method("initialize"):
				effect.initialize(self)
			buff_effects.append(effect)
		
		Constants.BuffEffectType.控制效果:
			var effect = load("res://src/entities/buff/effects/control_buff_effect.gd").new()
			if effect.has_method("initialize"):
				effect.initialize(self)
			buff_effects.append(effect)
		
		Constants.BuffEffectType.特殊效果:
			var effect = load("res://src/entities/buff/effects/special_buff_effect.gd").new()
			if effect.has_method("initialize"):
				effect.initialize(self)
			buff_effects.append(effect)

## 应用效果[br]
func _apply_effects() -> void:
	for effect in buff_effects:
		if effect.has_method("apply"):
			effect.apply()

## 移除效果[br]
func _remove_effects() -> void:
	for effect in buff_effects:
		if effect.has_method("remove"):
			effect.remove()

## 检查是否为同一buff[br]
## [param other] 另一个buff实例[br]
## [returns] 是否为同一buff
func is_same_buff(other: BuffInstance) -> bool:
	return buff_resource.buff_id == other.buff_resource.buff_id

## 获取buff信息[br]
## [returns] buff信息字典
func get_buff_info() -> Dictionary:
	return {
		"id": buff_resource.buff_id,
		"name": buff_resource.buff_name,
		"description": buff_resource.get_description(current_stacks),
		"type": buff_resource.buff_type,
		"stacks": current_stacks,
		"remaining_duration": remaining_duration,
		"is_permanent": buff_resource.is_permanent,
		"is_expired": is_expired,
		"is_paused": is_paused
	} 