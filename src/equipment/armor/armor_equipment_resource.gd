extends EquipmentResource
class_name ArmorEquipmentResource

## 护甲装备资源 - 统一护甲类装备的配置[br]
## 提供护甲值、回复机制等核心配置参数[br]
## 简化配置，只保留实际使用的核心变量

@export_group("护甲配置")
@export var armor_value: int = 50 ## 提供的护甲值
@export var armor_regeneration_rate: float = 5.0 ## 护甲回复速度（每秒回复的护甲值）
@export var no_damage_delay: float = 5.0 ## 无伤害延迟（秒）
@export var regeneration_interval: float = 1.0 ## 回复间隔（秒）

@export_group("护甲特效")
@export var armor_effects: Array[String] = [] ## 护甲特殊效果（预留扩展）

## 获取护甲配置信息[br]
## [returns] 护甲配置字典
func get_armor_config() -> Dictionary:
	return {
		"armor_value": armor_value,
		"armor_regeneration_rate": armor_regeneration_rate,
		"no_damage_delay": no_damage_delay,
		"regeneration_interval": regeneration_interval,
		"armor_effects": armor_effects
	}

## 应用护甲配置到装备实例[br]
## [param instance] 装备实例
func _apply_armor_config_to_instance(instance: EquipmentBase) -> void:
	# 应用基础配置
	super._apply_config_to_instance(instance)
	
	# 应用护甲特定配置
	if instance.has_method("set_armor_config"):
		instance.set_armor_config(get_armor_config())

## 重写应用配置方法[br]
## [param instance] 装备实例
func _apply_config_to_instance(instance: EquipmentBase) -> void:
	_apply_armor_config_to_instance(instance)

## 验证护甲装备资源的完整性[br]
## [returns] 是否有效
func is_valid() -> bool:
	if not super.is_valid():
		return false
	
	# 护甲值验证
	if armor_value <= 0:
		return false
	
	# 回复系统验证
	if armor_regeneration_rate <= 0:
		return false
	if no_damage_delay < 0:
		return false
	if regeneration_interval <= 0:
		return false
	
	return true

## 获取装备信息字典（重写以包含护甲信息）[br]
## [returns] 装备信息
func get_equipment_info() -> Dictionary:
	var base_info: Dictionary = super.get_equipment_info()
	base_info["equipment_type"] = "Armor"
	base_info["armor_config"] = get_armor_config()
	return base_info 