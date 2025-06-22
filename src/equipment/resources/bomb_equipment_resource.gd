extends EquipmentResource
class_name BombEquipmentResource

## 炸弹装备资源 - 爆炸类装备的专门配置[br]
## 用于配置炸弹的爆炸范围、引爆时间、伤害等属性

@export_group("炸弹配置")
@export var base_damage: int = 20 ## 基础伤害
@export var projectiles_per_shot: int = 3 ## 单次投射个数
@export var detonation_time: float = 2.0 ## 引爆时间（秒）
@export var explosion_radius: float = 100.0 ## 爆炸范围半径
@export var explosion_spread_speed: float = 500.0 ## 爆炸扩散速度 (pixels/sec)
@export var max_throw_distance: float = 400.0 ## 最远投射距离
@export var min_throw_distance: float = 100.0 ## 最近投射距离

## 获取炸弹配置信息[br]
## [returns] 炸弹配置字典
func get_bomb_config() -> Dictionary:
	return {
		"base_damage": base_damage,
		"projectiles_per_shot": projectiles_per_shot,
		"detonation_time": detonation_time,
		"explosion_radius": explosion_radius,
		"explosion_spread_speed": explosion_spread_speed,
		"max_throw_distance": max_throw_distance,
		"min_throw_distance": min_throw_distance
	}


## 重写应用配置方法[br]
## [param instance] 装备实例
func _apply_config_to_instance(instance: EquipmentBase) -> void:
	super._apply_config_to_instance(instance)

	# 应用炸弹特定配置
	if instance.has_method("set_bomb_config"):
		instance.set_bomb_config(get_bomb_config())


## 验证炸弹装备资源的完整性[br]
## [returns] 是否有效
func is_valid() -> bool:
	if not super.is_valid():
		return false

	# 炸弹特定验证
	if base_damage <= 0:
		return false
	if projectiles_per_shot <= 0:
		return false
	if detonation_time < 0:
		return false
	if explosion_radius <= 0:
		return false
	if explosion_spread_speed <= 0:
		return false
	if max_throw_distance <= 0:
		return false
	if min_throw_distance < 0:
		return false
	if min_throw_distance > max_throw_distance:
		return false

	return true


## 获取装备信息字典（重写以包含炸弹信息）[br]
## [returns] 装备信息
func get_equipment_info() -> Dictionary:
	var base_info: Dictionary = super.get_equipment_info()
	base_info["equipment_type"] = "炸弹"
	base_info["bomb_config"] = get_bomb_config()
	return base_info 