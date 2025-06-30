extends Resource
class_name EquipmentResource

## 装备资源 - 存储装备的基础信息和场景引用[br]
## 支持装备实例化和配置管理

## 装备品质
## 装备品质影响装备的属性、效果
## 分为民用级企业级专业级军用级和传说级
enum EquipmentQuality {
	COMMERCIAL,
	ENTERPRISE,
	PROFESSIONAL,
	ARMY,
	LEGENDARY
}


@export var equipment_name: String = "基础装备" ## 装备名称
@export var equipment_id: String = "" ## 装备唯一标识
@export var equipment_quality: EquipmentQuality = EquipmentQuality.COMMERCIAL ## 装备品质
@export var icon_texture: Texture2D ## 装备图标
@export var cooldown_time: float = 1.0 ## 冷却时间（秒）
@export var equipment_scene: PackedScene ## 装备场景引用
@export var projectile_scene: PackedScene ## 发射的投射物场景
@export var projectile_resource: EmitterProjectileResource ## 投射物配置资源
@export var description: String = "" ## 装备描述

## 创建装备实例[br]
## [param player] 装备的拥有者[br]
## [returns] 装备实例，失败返回null
func create_equipment_instance(player: Player) -> EquipmentBase:
	if not equipment_scene:
		push_error("装备资源缺少场景引用: " + equipment_name)
		return null
	
	# 实例化装备场景
	var equipment_instance: EquipmentBase = equipment_scene.instantiate()
	if not equipment_instance:
		push_error("无法实例化装备场景: " + equipment_name)
		return null
	
	# 应用资源配置到装备实例
	_apply_config_to_instance(equipment_instance)
	
	# 初始化装备
	equipment_instance.initialize(player)
	
	return equipment_instance

## 应用配置到装备实例[br]
## [param instance] 装备实例
func _apply_config_to_instance(instance: EquipmentBase) -> void:
	if not instance:
		return
	
	# 设置基础属性
	instance.equipment_name = equipment_name
	instance.equipment_quality = equipment_quality
	instance.equipment_id = equipment_id
	instance.icon_texture = icon_texture
	instance.cooldown_time = cooldown_time
	
	# 设置投射物相关
	if projectile_scene:
		instance.projectile_scene = projectile_scene
	if projectile_resource:
		instance.projectile_resource = projectile_resource

## 验证装备资源的完整性[br]
## [returns] 是否有效
func is_valid() -> bool:
	if equipment_name.is_empty():
		return false
	if not equipment_scene:
		return false
	if cooldown_time < 0:
		return false
	return true

## 获取装备信息字典[br]
## [returns] 装备信息
func get_equipment_info() -> Dictionary:
	return {
		"name": equipment_name,
		"id": equipment_id,
		"description": description,
		"cooldown": cooldown_time,
		"has_projectile": projectile_scene != null
	}