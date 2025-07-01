extends EquipmentResource
class_name EmitterEquipmentResource

## 发射器装备资源 - 统一发射类装备的配置[br]
## 简化配置，只保留实际使用的核心变量[br]
## 移除无效和重复的配置项

@export_group("发射器配置")
@export var emit_count: int = 1 ## 单次发射数量
@export var emit_interval: float = 0.1 ## 发射间隔（秒）
@export var base_damage: int = 10 ## 基础伤害
@export var attack_range: float = 300.0 ## 攻击距离（只有在此距离内有敌人时才进行攻击）
@export var range_check_enabled: bool = true ## 是否启用攻击距离检查
@export var target_type: Constants.TargetType = Constants.TargetType.最近敌人 ## 发射目标类型
@export var continuous_attack: bool = false ## 持续攻击：没有目标时是否继续攻击

@export_group("弹药系统")
@export var magazine_capacity: int = 0 ## 弹夹容量（0=无限弹药）
@export var reload_time: float = 2.0 ## 装弹时间（秒）
@export var reload_mode: ReloadMode = ReloadMode.换弹 ## 装弹模式
@export var reload_amount: int = 1 ## 单次装弹量（仅充能型使用）

@export_group("命中效果")
@export var hit_effects: Array[HitEffectResource] = [] ## 投射物命中时的特殊效果

## 装弹模式枚举
enum ReloadMode {
	换弹, ## 换弹型：弹药耗尽后换弹，换弹期间无法攻击
	充能, ## 充能型：弹药未满时持续充能，充能期间可以攻击
}

## 获取发射器配置信息[br]
## [returns] 发射器配置字典
func get_emitter_config() -> Dictionary:
	return {
		"emit_count": emit_count,
		"emit_interval": emit_interval,
		"base_damage": base_damage,
		"attack_range": attack_range,
		"range_check_enabled": range_check_enabled,
		"magazine_capacity": magazine_capacity,
		"reload_time": reload_time,
		"reload_mode": reload_mode,
		"reload_amount": reload_amount,
		"target_type": target_type,
		"continuous_attack": continuous_attack,
		"hit_effects": hit_effects
	}

## 应用发射器配置到装备实例[br]
## [param instance] 装备实例
func _apply_emitter_config_to_instance(instance: EquipmentBase) -> void:
	# 应用基础配置
	super._apply_config_to_instance(instance)
	
	# 应用发射器特定配置
	if instance.has_method("set_emitter_config"):
		instance.set_emitter_config(get_emitter_config())

## 重写应用配置方法[br]
## [param instance] 装备实例
func _apply_config_to_instance(instance: EquipmentBase) -> void:
	_apply_emitter_config_to_instance(instance)

## 验证发射器装备资源的完整性[br]
## [returns] 是否有效
func is_valid() -> bool:
	if not super.is_valid():
		return false
	
	# 通用验证
	if emit_count <= 0:
		return false
	if emit_interval < 0:
		return false
	if base_damage <= 0:
		return false
	
	# 弹药系统验证
	if magazine_capacity < 0:
		return false
	if magazine_capacity > 0 and reload_time <= 0:
		return false
	if reload_amount <= 0:
		return false
	
	return true

## 获取装备信息字典（重写以包含发射器信息）[br]
## [returns] 装备信息
func get_equipment_info() -> Dictionary:
	var base_info: Dictionary = super.get_equipment_info()
	base_info["equipment_type"] = "Emitter"
	base_info["emitter_config"] = get_emitter_config()
	return base_info
