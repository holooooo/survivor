extends RefCounted
class_name EquipmentSlotManager

## 装备槽位管理器 - 管理不同类型的装备槽位分配[br]
## 支持特定类型槽位和通用槽位的动态分配

## 槽位数据结构
class SlotData:
	var position_type: EquipmentResource.EquipmentPosition
	var equipment_instance: EquipmentBase
	var is_universal_slot: bool = false
	
	func _init(pos_type: EquipmentResource.EquipmentPosition, is_universal: bool = false):
		position_type = pos_type
		is_universal_slot = is_universal

## 装备槽位配置
const SLOT_CONFIG = {
	EquipmentResource.EquipmentPosition.OUTPUT: 3,    ## 输出槽位数量
	EquipmentResource.EquipmentPosition.MOBILITY: 3,  ## 移动槽位数量
	EquipmentResource.EquipmentPosition.TRANSFORM: 3, ## 转化槽位数量
	EquipmentResource.EquipmentPosition.DEFENSE: 3,   ## 防御槽位数量
	EquipmentResource.EquipmentPosition.UNIVERSAL: 2  ## 通用槽位数量
}

var slots: Array[SlotData] = []
var position_slot_count: Dictionary = {}

signal slot_changed(slot_index: int, equipment_instance: EquipmentBase, position_type: EquipmentResource.EquipmentPosition)

func _init():
	_initialize_slots()

## 初始化槽位[br]
## 根据配置创建不同类型的槽位
func _initialize_slots() -> void:
	slots.clear()
	position_slot_count.clear()
	
	# 初始化各类型槽位计数
	for pos_type in EquipmentResource.EquipmentPosition.values():
		position_slot_count[pos_type] = 0
	
	# 创建特定类型槽位
	for position_type in SLOT_CONFIG:
		if position_type == EquipmentResource.EquipmentPosition.UNIVERSAL:
			continue
		
		var slot_count = SLOT_CONFIG[position_type]
		for i in range(slot_count):
			var slot_data = SlotData.new(position_type)
			slots.append(slot_data)
	
	# 创建通用槽位
	var universal_count = SLOT_CONFIG[EquipmentResource.EquipmentPosition.UNIVERSAL]
	for i in range(universal_count):
		var slot_data = SlotData.new(EquipmentResource.EquipmentPosition.UNIVERSAL, true)
		slots.append(slot_data)

## 尝试装备物品[br]
## [param equipment_resource] 要装备的装备资源[br]
## [returns] 装备成功的槽位索引，失败返回-1
func try_equip_equipment(equipment_resource: EquipmentResource, equipment_instance: EquipmentBase) -> int:
	if not equipment_resource or not equipment_instance:
		return -1
	
	var target_position = equipment_resource.equipment_position
	
	# 先尝试使用对应类型的空槽位
	var slot_index = _find_empty_slot_by_type(target_position)
	if slot_index != -1:
		_equip_to_slot(slot_index, equipment_instance)
		return slot_index
	
	# 如果没有对应类型的空槽位，尝试使用通用槽位
	slot_index = _find_empty_universal_slot()
	if slot_index != -1:
		# 将通用槽位指定为目标类型
		slots[slot_index].position_type = target_position
		_equip_to_slot(slot_index, equipment_instance)
		return slot_index
	
	return -1 # 没有可用槽位

## 卸载指定槽位的装备[br]
## [param slot_index] 槽位索引[br]
## [returns] 是否成功卸载
func unequip_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	
	var slot_data = slots[slot_index]
	if not slot_data.equipment_instance:
		return false
	
	var old_equipment = slot_data.equipment_instance
	var position_type = slot_data.position_type
	
	# 清空槽位
	slot_data.equipment_instance = null
	
	# 如果是通用槽位，重置为通用类型
	if slot_data.is_universal_slot:
		slot_data.position_type = EquipmentResource.EquipmentPosition.UNIVERSAL
	
	# 更新计数
	position_slot_count[position_type] -= 1
	
	slot_changed.emit(slot_index, null, position_type)
	return true

## 获取指定槽位的装备[br]
## [param slot_index] 槽位索引[br]
## [returns] 装备实例
func get_equipment_at_slot(slot_index: int) -> EquipmentBase:
	if slot_index < 0 or slot_index >= slots.size():
		return null
	return slots[slot_index].equipment_instance

## 获取所有已装备的装备实例[br]
## [returns] 装备实例数组
func get_all_equipped_instances() -> Array[EquipmentBase]:
	var equipped: Array[EquipmentBase] = []
	for slot_data in slots:
		if slot_data.equipment_instance:
			equipped.append(slot_data.equipment_instance)
	return equipped

## 获取指定类型的装备数量[br]
## [param position_type] 装备位置类型[br]
## [returns] 装备数量
func get_equipped_count_by_type(position_type: EquipmentResource.EquipmentPosition) -> int:
	return position_slot_count.get(position_type, 0)

## 获取可用槽位信息[br]
## [returns] 槽位信息字典
func get_slot_info() -> Dictionary:
	var info = {}
	for position_type in EquipmentResource.EquipmentPosition.values():
		var total_slots = _get_total_slots_for_type(position_type)
		var used_slots = position_slot_count.get(position_type, 0)
		info[position_type] = {
			"total": total_slots,
			"used": used_slots,
			"available": total_slots - used_slots
		}
	return info

## 查找指定类型的空槽位[br]
## [param position_type] 装备位置类型[br]
## [returns] 槽位索引，没找到返回-1
func _find_empty_slot_by_type(position_type: EquipmentResource.EquipmentPosition) -> int:
	for i in range(slots.size()):
		var slot_data = slots[i]
		if slot_data.position_type == position_type and not slot_data.equipment_instance and not slot_data.is_universal_slot:
			return i
	return -1

## 查找空的通用槽位[br]
## [returns] 槽位索引，没找到返回-1
func _find_empty_universal_slot() -> int:
	for i in range(slots.size()):
		var slot_data = slots[i]
		if slot_data.is_universal_slot and not slot_data.equipment_instance:
			return i
	return -1

## 装备到指定槽位[br]
## [param slot_index] 槽位索引[br]
## [param equipment_instance] 装备实例
func _equip_to_slot(slot_index: int, equipment_instance: EquipmentBase) -> void:
	var slot_data = slots[slot_index]
	slot_data.equipment_instance = equipment_instance
	
	# 更新计数
	var position_type = slot_data.position_type
	position_slot_count[position_type] = position_slot_count.get(position_type, 0) + 1
	
	slot_changed.emit(slot_index, equipment_instance, position_type)

## 获取指定类型的总槽位数（包括可用的通用槽位）[br]
## [param position_type] 装备位置类型[br]
## [returns] 总槽位数
func _get_total_slots_for_type(position_type: EquipmentResource.EquipmentPosition) -> int:
	if position_type == EquipmentResource.EquipmentPosition.UNIVERSAL:
		return SLOT_CONFIG[EquipmentResource.EquipmentPosition.UNIVERSAL]
	
	var specific_slots = SLOT_CONFIG.get(position_type, 0)
	var available_universal = SLOT_CONFIG[EquipmentResource.EquipmentPosition.UNIVERSAL] - position_slot_count.get(EquipmentResource.EquipmentPosition.UNIVERSAL, 0)
	return specific_slots + available_universal 