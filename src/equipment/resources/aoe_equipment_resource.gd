extends EquipmentResource
class_name AOEEquipmentResource

## AOE装备资源 - 区域攻击类装备的专门配置[br]
## 用于拳击、法术爆发等持续范围伤害装备[br]
## 注意：duration参数会自动同步到投射物的lifetime

@export_group("AOE配置")
@export var duration: float = 0.5 ## 持续时间（秒），等同于投射物的lifetime
@export var damage_interval: float = 0.1 ## 伤害间隔（秒）
@export var max_damage_ticks: int = 5 ## 最大伤害次数
@export var aoe_radius: float = 50.0 ## AOE范围半径
@export var base_damage: int = 3 ## 基础伤害

@export_group("AOE视觉效果")
@export var effect_color: Color = Color.YELLOW ## 效果颜色
@export var effect_scale: Vector2 = Vector2(1.0, 1.0) ## 效果缩放
@export var fade_out: bool = true ## 是否渐隐效果

## 获取AOE配置信息[br]
## [returns] AOE配置字典
func get_aoe_config() -> Dictionary:
	return {
		"duration": duration,
		"damage_interval": damage_interval,
		"max_damage_ticks": max_damage_ticks,
		"aoe_radius": aoe_radius,
		"base_damage": base_damage,
		"effect_color": effect_color,
		"effect_scale": effect_scale,
		"fade_out": fade_out
	}

## 应用AOE配置到装备实例[br]
## [param instance] 装备实例
func _apply_aoe_config_to_instance(instance: EquipmentBase) -> void:
	# 应用基础配置
	super._apply_config_to_instance(instance)
	
	# 应用AOE特定配置
	if instance.has_method("set_aoe_config"):
		instance.set_aoe_config(get_aoe_config())
	
	# 为投射物资源设置AOE参数，确保duration和lifetime统一
	if projectile_resource:
		if projectile_resource.has_method("set_aoe_parameters"):
			projectile_resource.set_aoe_parameters(duration, damage_interval, max_damage_ticks, aoe_radius, base_damage)
		else:
			# 直接设置基础投射物参数，确保duration=lifetime
			projectile_resource.lifetime = duration
			projectile_resource.damage_interval = damage_interval
			projectile_resource.damage_ticks = max_damage_ticks
			projectile_resource.detection_range = aoe_radius
			projectile_resource.damage_per_tick = base_damage

## 重写应用配置方法[br]
## [param instance] 装备实例
func _apply_config_to_instance(instance: EquipmentBase) -> void:
	_apply_aoe_config_to_instance(instance)

## 验证AOE装备资源的完整性[br]
## [returns] 是否有效
func is_valid() -> bool:
	if not super.is_valid():
		return false
	
	# AOE特定验证
	if duration <= 0:
		return false
	if damage_interval <= 0:
		return false
	if max_damage_ticks <= 0:
		return false
	if aoe_radius <= 0:
		return false
	if base_damage <= 0:
		return false
	
	return true

## 获取装备信息字典（重写以包含AOE信息）[br]
## [returns] 装备信息
func get_equipment_info() -> Dictionary:
	var base_info: Dictionary = super.get_equipment_info()
	base_info["equipment_type"] = "AOE"
	base_info["aoe_config"] = get_aoe_config()
	return base_info 