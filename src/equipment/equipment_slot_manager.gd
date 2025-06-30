extends RefCounted
class_name EquipmentSlotManager

## 装备槽位管理器 - 管理装备和mod的槽位分配[br]
## 支持装备槽位和mod槽位的统一管理

## 槽位数据结构
class SlotData:
	var equipment_instance: EquipmentBase
	var mod_resource: ModResource
	var slot_type: String  # "equipment" 或 "mod"
	
	func _init(type: String):
		slot_type = type

## 装备和mod槽位配置
const EQUIPMENT_SLOTS: int = 8   ## 装备槽位数量
const MOD_SLOTS: int = 10        ## mod槽位数量

var equipment_slots: Array[SlotData] = []
var mod_slots: Array[SlotData] = []

signal equipment_slot_changed(slot_index: int, equipment_instance: EquipmentBase)
signal mod_slot_changed(slot_index: int, mod_resource: ModResource)

func _init():
	_initialize_slots()

## 初始化槽位[br]
## 创建装备槽位和mod槽位
func _initialize_slots() -> void:
	equipment_slots.clear()
	mod_slots.clear()
	
	# 创建装备槽位
	for i in range(EQUIPMENT_SLOTS):
		var slot_data = SlotData.new("equipment")
		equipment_slots.append(slot_data)
	
	# 创建mod槽位
	for i in range(MOD_SLOTS):
		var slot_data = SlotData.new("mod")
		mod_slots.append(slot_data)

## 尝试装备物品[br]
## [param equipment_resource] 要装备的装备资源[br]
## [param equipment_instance] 装备实例[br]
## [returns] 装备成功的槽位索引，失败返回-1
func try_equip_equipment(equipment_resource: EquipmentResource, equipment_instance: EquipmentBase) -> int:
	if not equipment_resource or not equipment_instance:
		return -1
	
	# 寻找空的装备槽位
	var slot_index = _find_empty_equipment_slot()
	if slot_index == -1:
		return -1
	
	# 装备到槽位
	equipment_slots[slot_index].equipment_instance = equipment_instance
	equipment_slot_changed.emit(slot_index, equipment_instance)
	return slot_index

## 尝试装备mod[br]
## [param mod_resource] 要装备的mod资源[br]
## [param slot_index] 指定槽位索引，-1表示自动寻找空槽位[br]
## [returns] 装备成功的槽位索引，失败返回-1
func try_equip_mod(mod_resource: ModResource, slot_index: int = -1) -> int:
	if not mod_resource:
		return -1
	
	var target_slot: int = slot_index
	if target_slot == -1:
		target_slot = _find_empty_mod_slot()
		if target_slot == -1:
			return -1
	
	# 检查槽位是否有效
	if target_slot < 0 or target_slot >= MOD_SLOTS:
		return -1
	
	# 卸载已有mod
	if mod_slots[target_slot].mod_resource != null:
		unequip_mod_slot(target_slot)
	
	# 装备新mod
	mod_slots[target_slot].mod_resource = mod_resource
	mod_slot_changed.emit(target_slot, mod_resource)
	return target_slot

## 卸载指定装备槽位[br]
## [param slot_index] 槽位索引[br]
## [returns] 是否成功卸载
func unequip_equipment_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= equipment_slots.size():
		return false
	
	var slot_data = equipment_slots[slot_index]
	if not slot_data.equipment_instance:
		return false
	
	# 清空槽位
	slot_data.equipment_instance = null
	equipment_slot_changed.emit(slot_index, null)
	return true

## 卸载指定mod槽位[br]
## [param slot_index] 槽位索引[br]
## [returns] 是否成功卸载
func unequip_mod_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= mod_slots.size():
		return false
	
	var slot_data = mod_slots[slot_index]
	if not slot_data.mod_resource:
		return false
	
	var removed_mod = slot_data.mod_resource
	slot_data.mod_resource = null
	mod_slot_changed.emit(slot_index, null)
	return true

## 获取指定装备槽位的装备[br]
## [param slot_index] 槽位索引[br]
## [returns] 装备实例
func get_equipment_at_slot(slot_index: int) -> EquipmentBase:
	if slot_index < 0 or slot_index >= equipment_slots.size():
		return null
	return equipment_slots[slot_index].equipment_instance

## 获取指定mod槽位的mod[br]
## [param slot_index] 槽位索引[br]
## [returns] mod资源
func get_mod_at_slot(slot_index: int) -> ModResource:
	if slot_index < 0 or slot_index >= mod_slots.size():
		return null
	return mod_slots[slot_index].mod_resource

## 获取所有已装备的装备实例[br]
## [returns] 装备实例数组
func get_all_equipped_instances() -> Array[EquipmentBase]:
	var equipped: Array[EquipmentBase] = []
	for slot_data in equipment_slots:
		if slot_data.equipment_instance:
			equipped.append(slot_data.equipment_instance)
	return equipped

## 获取所有已装备的mod[br]
## [returns] mod资源数组
func get_all_equipped_mods() -> Array[ModResource]:
	var equipped_mods: Array[ModResource] = []
	for slot_data in mod_slots:
		if slot_data.mod_resource:
			equipped_mods.append(slot_data.mod_resource)
	return equipped_mods

## 获取装备槽位信息[br]
## [returns] 装备槽位信息字典
func get_equipment_slot_info() -> Dictionary:
	var used_slots: int = 0
	for slot_data in equipment_slots:
		if slot_data.equipment_instance:
			used_slots += 1
	
	return {
		"total_slots": EQUIPMENT_SLOTS,
		"used_slots": used_slots,
		"available_slots": EQUIPMENT_SLOTS - used_slots
	}

## 获取mod槽位信息[br]
## [returns] mod槽位信息字典
func get_mod_slot_info() -> Dictionary:
	var used_slots: int = 0
	for slot_data in mod_slots:
		if slot_data.mod_resource:
			used_slots += 1
	
	return {
		"total_slots": MOD_SLOTS,
		"used_slots": used_slots,
		"available_slots": MOD_SLOTS - used_slots
	}

## 查找空的装备槽位[br]
## [returns] 槽位索引，没找到返回-1
func _find_empty_equipment_slot() -> int:
	for i in range(equipment_slots.size()):
		if not equipment_slots[i].equipment_instance:
			return i
	return -1

## 查找空的mod槽位[br]
## [returns] 槽位索引，没找到返回-1
func _find_empty_mod_slot() -> int:
	for i in range(mod_slots.size()):
		if not mod_slots[i].mod_resource:
			return i
	return -1 