extends EquipmentResource
class_name FirearmEquipmentResource

## 枪械装备资源 - 枪械类装备的专门配置[br]
## 用于手枪、步枪、机枪等射击类装备

@export_group("射击配置")
@export var bullets_per_shot: int = 3 ## 单次发射子弹数
@export var bullet_interval: float = 0.1 ## 连发子弹间隔（秒）
@export var bullet_damage: int = 10 ## 单发子弹伤害
@export var max_range: float = 500.0 ## 最大射程
@export var bullet_speed: float = 800.0 ## 子弹飞行速度

@export_group("弹夹系统")
@export var magazine_capacity: int = 9 ## 弹夹容量
@export var reload_time: float = 2.0 ## 填弹时间（秒）
@export var auto_reload: bool = true ## 自动填弹

@export_group("穿透系统")
@export var pierce_count: int = 1 ## 穿透数量（0=不穿透）
@export var pierce_damage_reduction: float = 0.2 ## 穿透伤害衰减（每次穿透减少的伤害比例）

@export_group("枪械视觉效果")
@export var muzzle_flash: bool = true ## 枪口闪光效果
@export var bullet_trail: bool = true ## 子弹轨迹效果
@export var bullet_color: Color = Color.WHITE ## 子弹颜色

## 获取枪械配置信息[br]
## [returns] 枪械配置字典
func get_firearm_config() -> Dictionary:
	return {
		"bullets_per_shot": bullets_per_shot,
		"bullet_interval": bullet_interval,
		"bullet_damage": bullet_damage,
		"max_range": max_range,
		"bullet_speed": bullet_speed,
		"magazine_capacity": magazine_capacity,
		"reload_time": reload_time,
		"auto_reload": auto_reload,
		"pierce_count": pierce_count,
		"pierce_damage_reduction": pierce_damage_reduction,
		"muzzle_flash": muzzle_flash,
		"bullet_trail": bullet_trail,
		"bullet_color": bullet_color
	}

## 应用枪械配置到装备实例[br]
## [param instance] 装备实例
func _apply_firearm_config_to_instance(instance: EquipmentBase) -> void:
	# 应用基础配置
	super._apply_config_to_instance(instance)
	
	# 应用枪械特定配置
	if instance.has_method("set_firearm_config"):
		instance.set_firearm_config(get_firearm_config())
	
	# 为投射物资源设置枪械参数
	if projectile_resource and projectile_resource.has_method("set_bullet_parameters"):
		projectile_resource.set_bullet_parameters(
			bullet_damage, 
			max_range, 
			bullet_speed, 
			pierce_count, 
			pierce_damage_reduction
		)

## 重写应用配置方法[br]
## [param instance] 装备实例
func _apply_config_to_instance(instance: EquipmentBase) -> void:
	_apply_firearm_config_to_instance(instance)

## 验证枪械装备资源的完整性[br]
## [returns] 是否有效
func is_valid() -> bool:
	if not super.is_valid():
		return false
	
	# 枪械特定验证
	if bullets_per_shot <= 0:
		return false
	if bullet_interval < 0:
		return false
	if bullet_damage <= 0:
		return false
	if max_range <= 0:
		return false
	if bullet_speed <= 0:
		return false
	if magazine_capacity <= 0:
		return false
	if reload_time <= 0:
		return false
	if pierce_count < 0:
		return false
	if pierce_damage_reduction < 0 or pierce_damage_reduction > 1:
		return false
	
	return true

## 获取装备信息字典（重写以包含枪械信息）[br]
## [returns] 装备信息
func get_equipment_info() -> Dictionary:
	var base_info: Dictionary = super.get_equipment_info()
	base_info["equipment_type"] = "Firearm"
	base_info["firearm_config"] = get_firearm_config()
	return base_info 