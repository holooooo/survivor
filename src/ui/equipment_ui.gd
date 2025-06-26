extends Control
class_name EquipmentUI

## 装备栏UI - 分行显示不同类型的装备槽位[br]
## 通用槽位默认隐藏，只在对应类型槽位用完时才显示在该行后方

@onready var equipment_container: VBoxContainer = $EquipmentContainer

# 装备位置类型行容器
var position_rows: Dictionary = {}
# 存储每种类型的槽位组件
var equipment_slots_by_type: Dictionary = {}
# 通用槽位组件
var universal_slots: Array[EquipmentSlot] = []

var equipment_manager

# 预加载装备槽场景
const EQUIPMENT_SLOT_SCENE = preload("res://src/ui/equipment_slot.tscn")

# 位置类型信息
const POSITION_INFO = {
	0: {"name": "输出装备", "color": Color.RED},
	1: {"name": "移动装备", "color": Color.GREEN},
	2: {"name": "转化装备", "color": Color.BLUE},
	3: {"name": "防御装备", "color": Color.YELLOW}
}

func _ready() -> void:
	# 查找装备管理器
	_find_equipment_manager()
	
	# 初始化装备槽UI
	_initialize_equipment_rows()

## 查找装备管理器
func _find_equipment_manager() -> void:
	# 延迟查找，确保玩家已经初始化
	await get_tree().process_frame
	
	var player: Node = get_tree().get_first_node_in_group("player")
	print("查找玩家: ", player)
	if player and player.has_node("PlayerEquipmentManager"):
		equipment_manager = player.get_node("PlayerEquipmentManager")
		print("找到装备管理器: ", equipment_manager)
		if not equipment_manager.equipment_changed.is_connected(_on_equipment_changed):
			equipment_manager.equipment_changed.connect(_on_equipment_changed)
			equipment_manager.slot_info_changed.connect(_on_slot_info_changed)
			print("已连接装备变化信号")
		
		# 初始化完成后立即更新一次UI
		_update_all_equipment_slots()
	else:
		print("错误：未找到玩家或装备管理器")

## 初始化装备行
func _initialize_equipment_rows() -> void:
	if not equipment_manager:
		print("装备管理器未找到，延迟初始化...")
		await get_tree().create_timer(0.1).timeout
		_find_equipment_manager()
		if not equipment_manager:
			print("错误：仍然无法找到装备管理器")
			return
	
	print("初始化装备槽位行")
	
	# 清除现有内容
	for child in equipment_container.get_children():
		child.queue_free()
	position_rows.clear()
	equipment_slots_by_type.clear()
	universal_slots.clear()
	
	# 为每种装备类型创建行
	for position_type in POSITION_INFO:
		_create_position_row(position_type)
	
	# 创建通用槽位（默认隐藏）
	_create_universal_slots()
	
	# 更新显示
	_update_all_equipment_slots()

## 创建装备位置类型行[br]
## [param position_type] 装备位置类型
func _create_position_row(position_type: int) -> void:
	# 创建行容器
	var row_container = VBoxContainer.new()
	equipment_container.add_child(row_container)
	
	# 创建标题标签
	var title_label = Label.new()
	title_label.text = POSITION_INFO[position_type].name
	title_label.modulate = POSITION_INFO[position_type].color
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row_container.add_child(title_label)
	
	# 创建槽位容器
	var slots_container = HBoxContainer.new()
	slots_container.alignment = BoxContainer.ALIGNMENT_CENTER
	row_container.add_child(slots_container)
	
	# 存储行信息
	position_rows[position_type] = {
		"row_container": row_container,
		"slots_container": slots_container,
		"title_label": title_label
	}
	
	# 创建该类型的槽位
	_create_slots_for_type(position_type, slots_container)

## 为指定类型创建槽位[br]
## [param position_type] 装备位置类型[br]
## [param container] 槽位容器
func _create_slots_for_type(position_type: int, container: HBoxContainer) -> void:
	if not equipment_manager or not equipment_manager.slot_manager:
		return
	
	var slots_for_type: Array[EquipmentSlot] = []
	
	# 查找该类型的槽位
	for i in range(equipment_manager.slot_manager.slots.size()):
		var slot_data = equipment_manager.slot_manager.slots[i]
		if slot_data.position_type == position_type and not slot_data.is_universal_slot:
			var slot = _create_equipment_slot(i, position_type)
			container.add_child(slot)
			slots_for_type.append(slot)
	
	equipment_slots_by_type[position_type] = slots_for_type

## 创建通用槽位[br]
func _create_universal_slots() -> void:
	if not equipment_manager or not equipment_manager.slot_manager:
		return
	
	# 查找通用槽位
	for i in range(equipment_manager.slot_manager.slots.size()):
		var slot_data = equipment_manager.slot_manager.slots[i]
		if slot_data.is_universal_slot:
			var slot = _create_equipment_slot(i, 4)  # 4 = 通用类型
			slot.visible = false  # 默认隐藏
			universal_slots.append(slot)

## 创建单个装备槽[br]
## [param slot_index] 槽位索引[br]
## [param position_type] 位置类型[br]
## [returns] 创建的EquipmentSlot实例
func _create_equipment_slot(slot_index: int, position_type: int) -> EquipmentSlot:
	var slot: EquipmentSlot = EQUIPMENT_SLOT_SCENE.instantiate()
	slot.custom_minimum_size = Vector2(80, 80)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.slot_position_type = position_type
	slot.name = "Slot_" + str(slot_index)
	return slot

## 更新所有装备槽显示
func _update_all_equipment_slots() -> void:
	if not equipment_manager or not equipment_manager.slot_manager:
		return
	
	# 更新各类型槽位
	for position_type in equipment_slots_by_type:
		var slots = equipment_slots_by_type[position_type]
		_update_slots_for_type(position_type, slots)
	
	# 更新通用槽位显示
	_update_universal_slots_visibility()

## 更新指定类型的槽位[br]
## [param position_type] 装备位置类型[br]
## [param slots] 槽位数组
func _update_slots_for_type(position_type: int, slots: Array[EquipmentSlot]) -> void:
	var slot_manager = equipment_manager.slot_manager
	var specific_slot_index = 0
	
	for i in range(slot_manager.slots.size()):
		var slot_data = slot_manager.slots[i]
		if slot_data.position_type == position_type and not slot_data.is_universal_slot:
			if specific_slot_index < slots.size():
				var slot = slots[specific_slot_index]
				slot.set_equipment_instance(slot_data.equipment_instance, position_type)
				specific_slot_index += 1

## 更新通用槽位可见性
func _update_universal_slots_visibility() -> void:
	if not equipment_manager:
		return
	
	var slot_info = equipment_manager.get_slot_info()
	
	# 重置所有通用槽位的可见性
	for slot in universal_slots:
		slot.visible = false
		if slot.get_parent():
			slot.get_parent().remove_child(slot)
	
	# 检查每种类型是否需要显示通用槽位
	for position_type in POSITION_INFO:
		var type_info = slot_info.get(position_type, {})
		var used_universal = _count_universal_slots_used_for_type(position_type)
		
		if used_universal > 0:
			_show_universal_slots_for_type(position_type, used_universal)

## 计算指定类型使用的通用槽位数量[br]
## [param position_type] 装备位置类型[br]
## [returns] 使用的通用槽位数量
func _count_universal_slots_used_for_type(position_type: int) -> int:
	var count = 0
	var slot_manager = equipment_manager.slot_manager
	
	for slot_data in slot_manager.slots:
		if slot_data.is_universal_slot and slot_data.position_type == position_type and slot_data.equipment_instance:
			count += 1
	
	return count

## 为指定类型显示通用槽位[br]
## [param position_type] 装备位置类型[br]
## [param count] 需要显示的数量
func _show_universal_slots_for_type(position_type: int, count: int) -> void:
	if not position_rows.has(position_type):
		return
	
	var slots_container = position_rows[position_type].slots_container
	var universal_index = 0
	var slot_manager = equipment_manager.slot_manager
	
	# 找到该类型使用的通用槽位并显示
	for i in range(slot_manager.slots.size()):
		var slot_data = slot_manager.slots[i]
		if slot_data.is_universal_slot and slot_data.position_type == position_type:
			if universal_index < universal_slots.size():
				var slot = universal_slots[universal_index]
				slot.visible = true
				slots_container.add_child(slot)
				slot.set_equipment_instance(slot_data.equipment_instance, position_type)
				universal_index += 1
				if universal_index >= count:
					break

## 装备变化回调
func _on_equipment_changed(slot_index: int, equipment_instance, position_type) -> void:
	print("装备变化回调 - 槽位: ", slot_index, " 装备: ", equipment_instance, " 位置: ", position_type)
	_update_all_equipment_slots()

## 槽位信息变化回调
func _on_slot_info_changed(slot_info: Dictionary) -> void:
	print("槽位信息变化: ", slot_info)
	_update_universal_slots_visibility()