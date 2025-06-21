extends Control
class_name EquipmentUI

## 装备栏UI - 显示和管理装备栏界面[br]
## 在左下角显示玩家的装备栏状态，现在使用EquipmentSlot组件

@onready var equipment_container: HBoxContainer = $EquipmentContainer
var equipment_slots: Array[EquipmentSlot] = []
var equipment_manager

# 预加载装备槽场景
const EQUIPMENT_SLOT_SCENE = preload("res://src/ui/equipment_slot.tscn")

func _ready() -> void:
	# 查找装备管理器
	_find_equipment_manager()
	
	# 初始化装备槽UI
	_initialize_equipment_slots()

## 查找装备管理器
func _find_equipment_manager() -> void:
	# 延迟查找，确保玩家已经初始化
	await get_tree().process_frame
	
	var player: Node = get_tree().get_first_node_in_group("player")
	print("查找玩家: ", player)
	if player and player.has_node("PlayerEquipmentManager"):
		equipment_manager = player.get_node("PlayerEquipmentManager")
		print("找到装备管理器: ", equipment_manager)
		equipment_manager.equipment_changed.connect(_on_equipment_changed)
		print("已连接装备变化信号")
		
		# 初始化完成后立即更新一次UI
		_update_all_equipment_slots()
	else:
		print("错误：未找到玩家或装备管理器")

## 初始化装备槽UI
func _initialize_equipment_slots() -> void:
	if not equipment_manager:
		print("装备管理器未找到，延迟初始化...")
		# 延迟重试
		await get_tree().create_timer(0.1).timeout
		_find_equipment_manager()
		if not equipment_manager:
			print("错误：仍然无法找到装备管理器")
			return
	
	print("初始化装备槽UI，槽位数量: ", equipment_manager.max_equipment_slots)
	
	# 清除现有槽位
	for child in equipment_container.get_children():
		child.queue_free()
	equipment_slots.clear()
	
	# 创建装备槽
	for i in range(equipment_manager.max_equipment_slots):
		var slot: EquipmentSlot = _create_equipment_slot(i)
		equipment_container.add_child(slot)
		equipment_slots.append(slot)
		print("创建装备槽 ", i)

## 创建单个装备槽[br]
## [param slot_index] 槽位索引[br]
## [returns] 创建的EquipmentSlot实例
func _create_equipment_slot(slot_index: int) -> EquipmentSlot:
	var slot: EquipmentSlot = EQUIPMENT_SLOT_SCENE.instantiate()
	slot.custom_minimum_size = Vector2(80, 80)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return slot

## 更新所有装备槽显示（仅在装备变化时调用）
func _update_all_equipment_slots() -> void:
	if not equipment_manager:
		return
	
	for i in range(equipment_slots.size()):
		var slot: EquipmentSlot = equipment_slots[i]
		var equipment_instance = equipment_manager.get_equipment_instance(i)
		slot.set_equipment_instance(equipment_instance)

## 装备变化回调[br]
## [param slot_index] 槽位索引[br]
## [param equipment_instance] 新装备实例
func _on_equipment_changed(slot_index: int, equipment_instance) -> void:
	print("装备变化回调 - 槽位: ", slot_index, " 装备: ", equipment_instance)
	# 立即更新指定槽位的UI
	if slot_index >= 0 and slot_index < equipment_slots.size():
		var slot: EquipmentSlot = equipment_slots[slot_index]
		slot.set_equipment_instance(equipment_instance)
	elif slot_index == -1:
		# 槽位索引为-1时，更新所有槽位（用于批量更新）
		_update_all_equipment_slots()