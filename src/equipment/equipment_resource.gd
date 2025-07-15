extends Resource
class_name EquipmentResource

## 装备资源 - 存储装备的基础信息和场景引用[br]
## 支持装备实例化和配置管理



@export var equipment_name: String = "基础装备" ## 装备名称
@export var equipment_id: String = "" ## 装备唯一标识
@export var equipment_quality: Constants.EquipmentQuality = Constants.EquipmentQuality.民用 ## 装备品质
@export var equipment_type: Constants.EquipmentType = Constants.EquipmentType.近战武器 ## 装备类型
@export var equipment_producer: Constants.EquipmentProducer = Constants.EquipmentProducer.无名作坊 ## 装备生产商
@export var icon_texture: Texture2D ## 装备图标
@export var cooldown_time: float = 1.0 ## 冷却时间（秒）
@export var equipment_scene: PackedScene ## 装备场景引用
@export var projectile_scene: PackedScene ## 发射的投射物场景
@export var projectile_resource: EmitterProjectileResource ## 投射物配置资源
@export var description: String = "" ## 装备描述
@export var attached_buffs: Array[BuffResource] = [] ## 装备附带的buff效果

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
	equipment_instance.resource = self
	
	return equipment_instance

## 应用配置到装备实例[br]
## [param instance] 装备实例
func _apply_config_to_instance(instance: EquipmentBase) -> void:
	if not instance:
		return
	
	_apply_base_config(instance)
	_apply_projectile_config(instance)
	_apply_buff_config(instance)

## 应用基础配置[br]
func _apply_base_config(instance: EquipmentBase) -> void:
	instance.equipment_name = equipment_name
	instance.equipment_quality = equipment_quality
	instance.equipment_id = equipment_id
	instance.icon_texture = icon_texture
	instance.cooldown_time = cooldown_time

## 应用投射物配置[br]
func _apply_projectile_config(instance: EquipmentBase) -> void:
	if projectile_scene:
		instance.projectile_scene = projectile_scene
	if projectile_resource:
		instance.projectile_resource = projectile_resource

## 应用buff配置[br]
func _apply_buff_config(instance: EquipmentBase) -> void:
	if attached_buffs.size() > 0:
		instance.attached_buffs = attached_buffs

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