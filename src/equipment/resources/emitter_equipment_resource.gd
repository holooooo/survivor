extends EquipmentResource
class_name EmitterEquipmentResource

## 发射器装备资源 - 统一发射类装备的配置[br]
## 支持投射物发射、范围攻击、光束等多种发射模式[br]
## 使用枚举类型管理不同的发射器模式

@export_group("发射器基础配置")
@export var emitter_type: EmitterType = EmitterType.PROJECTILE ## 发射器类型
@export var emit_count: int = 1 ## 单次发射数量
@export var emit_interval: float = 0.1 ## 发射间隔（秒）
@export var base_damage: int = 10 ## 基础伤害
@export var attack_range: float = 300.0 ## 攻击距离（只有在此距离内有敌人时才进行攻击）
@export var range_check_enabled: bool = true ## 是否启用攻击距离检查

@export_group("弹药系统")
@export var magazine_capacity: int = 0 ## 弹夹容量（0=无限弹药）
@export var reload_time: float = 2.0 ## 装弹时间（秒）
@export var auto_reload: bool = true ## 自动装弹

@export_group("持续效果配置")
@export var duration: float = 1.0 ## 效果持续时间（仅AOE/BEAM类型）
@export var damage_interval: float = 0.1 ## 伤害间隔（持续伤害类型）
@export var max_damage_ticks: int = 10 ## 最大伤害次数

@export_group("轨迹配置")
@export var projectile_speed: float = 800.0 ## 投射物速度
@export var pierce_count: int = 0 ## 穿透数量
@export var pierce_damage_reduction: float = 0.2 ## 穿透伤害衰减
@export var gravity_affected: bool = false ## 是否受重力影响

@export_group("范围配置")
@export var effect_radius: float = 50.0 ## 效果半径（AOE/BEAM类型）
@export var follow_caster: bool = true ## 是否跟随施法者（AOE类型）

@export_group("视觉效果")
@export var effect_color: Color = Color.WHITE ## 效果颜色
@export var muzzle_flash: bool = true ## 枪口闪光效果
@export var trail_effect: bool = true ## 轨迹效果
@export var range_indicator: bool = false ## 范围指示器

## 发射器类型枚举
enum EmitterType {
	PROJECTILE, ## 投射物发射
	AOE, ## 范围持续攻击
	BEAM, ## 光束攻击
	AUTO_TARGETING, ## 自动锁定攻击
}

## 获取发射器配置信息[br]
## [returns] 发射器配置字典
func get_emitter_config() -> Dictionary:
	return {
		"emitter_type": emitter_type,
		"emit_count": emit_count,
		"emit_interval": emit_interval,
		"base_damage": base_damage,
		"attack_range": attack_range,
		"range_check_enabled": range_check_enabled,
		"magazine_capacity": magazine_capacity,
		"reload_time": reload_time,
		"auto_reload": auto_reload,
		"duration": duration,
		"damage_interval": damage_interval,
		"max_damage_ticks": max_damage_ticks,
		"projectile_speed": projectile_speed,
		"pierce_count": pierce_count,
		"pierce_damage_reduction": pierce_damage_reduction,
		"gravity_affected": gravity_affected,
		"effect_radius": effect_radius,
		"follow_caster": follow_caster,
		"effect_color": effect_color,
		"muzzle_flash": muzzle_flash,
		"trail_effect": trail_effect,
		"range_indicator": range_indicator
	}



## 应用发射器配置到装备实例[br]
## [param instance] 装备实例
func _apply_emitter_config_to_instance(instance: EquipmentBase) -> void:
	# 应用基础配置
	super._apply_config_to_instance(instance)
	
	# 应用发射器特定配置
	if instance.has_method("set_emitter_config"):
		instance.set_emitter_config(get_emitter_config())
	
	# 应用发射器特定配置到装备实例
	# 不再提供兼容接口，统一使用 emitter_config
	
	# 配置投射物资源
	_configure_projectile_resource()

## 配置投射物资源[br]
func _configure_projectile_resource() -> void:
	if not projectile_resource:
		return
	
	# 投射物资源应该直接配置为 EmitterProjectileResource
	# 不再支持旧的投射物资源类型

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
	
	# 类型特定验证
	match emitter_type:
		EmitterType.PROJECTILE:
			if projectile_speed <= 0:
				return false
			if pierce_count < 0:
				return false
			if pierce_damage_reduction < 0 or pierce_damage_reduction > 1:
				return false
		EmitterType.AOE:
			if duration <= 0:
				return false
			if damage_interval <= 0:
				return false
			if max_damage_ticks <= 0:
				return false
			if effect_radius <= 0:
				return false
		EmitterType.AUTO_TARGETING:
			if base_damage <= 0:
				return false
			# 弹药系统验证
			if magazine_capacity <= 0:
				return false
			if reload_time <= 0:
				return false
	
	return true

## 获取装备信息字典（重写以包含发射器信息）[br]
## [returns] 装备信息
func get_equipment_info() -> Dictionary:
	var base_info: Dictionary = super.get_equipment_info()
	base_info["equipment_type"] = "Emitter"
	base_info["emitter_config"] = get_emitter_config()
	return base_info

 