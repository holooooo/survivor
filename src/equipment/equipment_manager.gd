extends Node
class_name PlayerEquipmentManager

## 装备管理器 - 管理玩家的装备栏[br]
## 处理装备的装备、卸载和使用，支持装备位置分类和槽位管理


@export var default_equipments: Array[EquipmentResource] = [] ## 默认装备资源数组
@export var combat_equipment_resources: Array[EquipmentResource] = [] ## 战斗装备资源数组

var player: Player
var slot_manager: EquipmentSlotManager

signal equipment_changed(slot_index: int, equipment_instance: EquipmentBase, position_type: EquipmentResource.EquipmentPosition)
signal equipment_used(equipment_instance: EquipmentBase)
signal slot_info_changed(slot_info: Dictionary)

func _ready() -> void:
	# 初始化槽位管理器
	slot_manager = EquipmentSlotManager.new()
	slot_manager.slot_changed.connect(_on_slot_changed)
	
func _process(delta: float) -> void:
	# 自动使用装备
	_auto_use_equipment()

## 初始化管理器[br]
## [param owner_player] 装备的拥有者
func initialize(owner_player: Player) -> void:
	player = owner_player
	# 自动装备默认装备
	_equip_default_equipment()

## 装备物品[br]
## [param equipment_resource] 要装备的装备资源[br]
## [returns] 装备成功的槽位索引，失败返回-1
func equip_item(equipment_resource: EquipmentResource) -> int:
	if not equipment_resource or not player:
		return -1
	
	# 验证装备资源
	if not equipment_resource.is_valid():
		push_error("无效的装备资源: " + equipment_resource.equipment_name)
		return -1
	
	# 使用装备资源创建装备实例
	var equipment_instance: EquipmentBase = equipment_resource.create_equipment_instance(player)
	if not equipment_instance:
		push_error("无法创建装备实例: " + equipment_resource.equipment_name)
		return -1
	
	add_child(equipment_instance)
	
	# 尝试装备到槽位
	var slot_index = slot_manager.try_equip_equipment(equipment_resource, equipment_instance)
	if slot_index == -1:
		# 装备失败，清理实例
		equipment_instance.queue_free()
		push_warning("没有可用槽位装备: " + equipment_resource.equipment_name)
		return -1
	
	# 连接装备信号
	equipment_instance.equipment_used.connect(_on_equipment_used)
	
	return slot_index

## 卸载指定槽位的装备[br]
## [param slot_index] 槽位索引[br]
## [returns] 是否成功卸载
func unequip_item(slot_index: int) -> bool:
	var equipment_instance = slot_manager.get_equipment_at_slot(slot_index)
	if not equipment_instance:
		return false
	
	# 断开信号连接
	if equipment_instance.equipment_used.is_connected(_on_equipment_used):
		equipment_instance.equipment_used.disconnect(_on_equipment_used)
	
	# 从槽位管理器中卸载
	var success = slot_manager.unequip_slot(slot_index)
	if success:
		equipment_instance.queue_free()
		
		# 如果没有任何装备，自动装备默认装备
		if slot_manager.get_all_equipped_instances().is_empty():
			_equip_default_equipment()
	
	return success

## 根据装备位置类型卸载装备[br]
## [param position_type] 装备位置类型[br]
## [param unequip_all] 是否卸载该类型的所有装备[br]
## [returns] 卸载的装备数量
func unequip_by_position_type(position_type: EquipmentResource.EquipmentPosition, unequip_all: bool = false) -> int:
	var unequipped_count = 0
	var slot_count = slot_manager.slots.size()
	
	for i in range(slot_count):
		var slot_data = slot_manager.slots[i]
		if slot_data.position_type == position_type and slot_data.equipment_instance:
			if unequip_item(i):
				unequipped_count += 1
				if not unequip_all:
					break
	
	return unequipped_count

## 获取指定槽位的装备实例[br]
## [param slot_index] 槽位索引[br]
## [returns] 装备实例
func get_equipment_instance(slot_index: int) -> EquipmentBase:
	return slot_manager.get_equipment_at_slot(slot_index)

## 获取指定槽位的装备[br]
## [param slot_index] 槽位索引[br]
## [returns] 装备实例
func get_equipment(slot_index: int) -> EquipmentBase:
	return get_equipment_instance(slot_index)

## 获取所有装备实例
## [returns] 装备实例数组
func get_all_equipment_instances() -> Array:
	return slot_manager.get_all_equipped_instances()

## 获取指定类型的装备数量[br]
## [param position_type] 装备位置类型[br]
## [returns] 装备数量
func get_equipped_count_by_type(position_type: EquipmentResource.EquipmentPosition) -> int:
	return slot_manager.get_equipped_count_by_type(position_type)

## 获取槽位信息[br]
## [returns] 槽位信息字典
func get_slot_info() -> Dictionary:
	return slot_manager.get_slot_info()

## 检查是否可以装备指定类型的装备[br]
## [param position_type] 装备位置类型[br]
## [returns] 是否可以装备
func can_equip_position_type(position_type: EquipmentResource.EquipmentPosition) -> bool:
	var slot_info = slot_manager.get_slot_info()
	var type_info = slot_info.get(position_type, {})
	return type_info.get("available", 0) > 0

## 自动使用装备
func _auto_use_equipment() -> void:
	var equipped_instances = slot_manager.get_all_equipped_instances()
	for equipment_instance in equipped_instances:
		if equipment_instance and equipment_instance.has_method("can_use") and equipment_instance.can_use():
			equipment_instance.use_equipment()

## 装备默认装备
func _equip_default_equipment() -> void:
	if default_equipments.size() > 0:
		# 装备所有默认装备
		for equipment_resource in default_equipments:
			if equipment_resource:
				equip_item(equipment_resource)
	else:
		# 备用方案：创建默认拳击装备资源
		_create_default_fist_equipment()

## 创建默认装备
func _create_default_fist_equipment() -> void:
	var fist_equipment_resource: EquipmentResource = _create_fallback_fist_resource()
	if fist_equipment_resource:
		equip_item(fist_equipment_resource)
	else:
		push_error("无法创建拳击装备资源")

## 创建备用拳击装备资源[br]
## [returns] 拳击装备资源
func _create_fallback_fist_resource() -> EquipmentResource:
	# 直接加载新的Emitter装备资源文件
	var fist_resource: EquipmentResource = load("res://src/equipment/output/fist/fist_emitter_equipment_resource.tres")
	if fist_resource:
		return fist_resource
	return null

## 槽位变化回调
func _on_slot_changed(slot_index: int, equipment_instance: EquipmentBase, position_type: EquipmentResource.EquipmentPosition) -> void:
	equipment_changed.emit(slot_index, equipment_instance, position_type)
	slot_info_changed.emit(slot_manager.get_slot_info())


## 装备使用回调
func _on_equipment_used(equipment_instance) -> void:
	equipment_used.emit(equipment_instance)
