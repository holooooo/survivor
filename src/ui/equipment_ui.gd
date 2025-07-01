extends Control
class_name EquipmentUI

## 装备栏UI - 显示装备槽位和mod槽位[br]
## 简洁的统一槽位管理界面

@onready var equipment_container: VBoxContainer = $EquipmentContainer

# 存储槽位组件
var equipment_slots: Array[EquipmentSlot] = []
var mod_slots: Array[EquipmentSlot] = []

@onready var equipment_manager: EquipmentManager = %EquipmentManager
@onready var mod_manager: ModManager = %ModManager

# 预加载装备槽场景
const EQUIPMENT_SLOT_SCENE = preload("res://src/ui/equipment_slot.tscn")

func _ready() -> void:
	# 查找装备管理器
	_find_equipment_manager()
	
	# 初始化装备槽UI
	_initialize_equipment_ui()

## 查找装备管理器
func _find_equipment_manager() -> void:
	# 延迟查找，确保玩家已经初始化
	await get_tree().process_frame
	
	var player: Node = get_tree().get_first_node_in_group(Constants.GROUP_PLAYER)
	print("查找玩家: ", player)
	if player and player.has_node("EquipmentManager"):
		print("找到装备管理器: ", equipment_manager)
		if not equipment_manager.equipment_changed.is_connected(_on_equipment_changed):
			equipment_manager.equipment_changed.connect(_on_equipment_changed)
			equipment_manager.equipment_slot_info_changed.connect(_on_equipment_slot_info_changed)
			mod_manager.mod_changed.connect(_on_mod_changed)
			mod_manager.mod_slot_info_changed.connect(_on_mod_slot_info_changed)
			print("已连接装备变化信号")
		
		# 初始化完成后立即更新一次UI
		_update_all_slots()
	else:
		print("错误：未找到玩家或装备管理器")

## 初始化装备UI
func _initialize_equipment_ui() -> void:
	if not equipment_manager:
		print("装备管理器未找到，延迟初始化...")
		await get_tree().create_timer(0.1).timeout
		_find_equipment_manager()
		if not equipment_manager:
			print("错误：仍然无法找到装备管理器")
			return
	
	print("初始化装备UI")
	
	# 清除现有内容
	for child in equipment_container.get_children():
		child.queue_free()
	equipment_slots.clear()
	mod_slots.clear()
	
	# 创建装备槽位区域
	_create_equipment_section()
	
	# 创建分隔符
	_create_separator()
	
	# 创建mod槽位区域
	_create_mod_section()
	
	# 更新显示
	_update_all_slots()

## 创建装备槽位区域
func _create_equipment_section() -> void:
	# 创建装备标题
	var equipment_title = Label.new()
	equipment_title.text = "装备槽位"
	equipment_title.add_theme_font_size_override("font_size", 18)
	equipment_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equipment_title.modulate = Color.CYAN
	equipment_container.add_child(equipment_title)
	
	# 创建装备槽位容器
	var equipment_grid = GridContainer.new()
	equipment_grid.columns = 4  # 4列显示
	equipment_grid.add_theme_constant_override("h_separation", 10)
	equipment_grid.add_theme_constant_override("v_separation", 10)
	equipment_container.add_child(equipment_grid)
	
	# 创建8个装备槽位
	for i in range(8):
		var slot = _create_equipment_slot(i, "equipment")
		equipment_grid.add_child(slot)
		equipment_slots.append(slot)

## 创建mod槽位区域
func _create_mod_section() -> void:
	# 创建mod标题
	var mod_title = Label.new()
	mod_title.text = "Mod槽位"
	mod_title.add_theme_font_size_override("font_size", 18)
	mod_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mod_title.modulate = Color.MAGENTA
	equipment_container.add_child(mod_title)
	
	# 创建mod槽位容器
	var mod_grid = GridContainer.new()
	mod_grid.columns = 5  # 5列显示
	mod_grid.add_theme_constant_override("h_separation", 10)
	mod_grid.add_theme_constant_override("v_separation", 10)
	equipment_container.add_child(mod_grid)
	
	# 创建10个mod槽位
	for i in range(10):
		var slot = _create_equipment_slot(i, "mod")
		mod_grid.add_child(slot)
		mod_slots.append(slot)

## 创建分隔符
func _create_separator() -> void:
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 20
	equipment_container.add_child(separator)

## 创建单个槽位[br]
## [param slot_index] 槽位索引[br]
## [param slot_type] 槽位类型 ("equipment" 或 "mod")[br]
## [returns] 创建的EquipmentSlot实例
func _create_equipment_slot(slot_index: int, slot_type: String) -> EquipmentSlot:
	var slot: EquipmentSlot = EQUIPMENT_SLOT_SCENE.instantiate()
	slot.custom_minimum_size = Vector2(80, 80)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.name = slot_type + "_Slot_" + str(slot_index)
	slot.setup_slot(slot_index, slot_type)
	return slot

## 更新所有槽位显示
func _update_all_slots() -> void:
	if not equipment_manager:
		return
	
	_update_equipment_slots()
	_update_mod_slots()

## 更新装备槽位
func _update_equipment_slots() -> void:
	for i in range(equipment_slots.size()):
		var slot = equipment_slots[i]
		var equipment_instance = equipment_manager.get_equipment_instance(i)
		slot.set_equipment_instance(equipment_instance)

## 更新mod槽位
func _update_mod_slots() -> void:
	for i in range(mod_slots.size()):
		var slot = mod_slots[i]
		var mod_resource = equipment_manager.get_mod(i)
		slot.set_mod_resource(mod_resource)

## 装备变化回调
func _on_equipment_changed(slot_index: int, equipment_instance: EquipmentBase) -> void:
	print("装备变化回调 - 槽位: ", slot_index, " 装备: ", equipment_instance)
	if slot_index < equipment_slots.size():
		equipment_slots[slot_index].set_equipment_instance(equipment_instance)

## mod变化回调
func _on_mod_changed(slot_index: int, mod_resource: ModResource) -> void:
	print("Mod变化回调 - 槽位: ", slot_index, " Mod: ", mod_resource)
	if slot_index < mod_slots.size():
		mod_slots[slot_index].set_mod_resource(mod_resource)

## 装备槽位信息变化回调
func _on_equipment_slot_info_changed(slot_info: Dictionary) -> void:
	print("装备槽位信息变化: ", slot_info)

## mod槽位信息变化回调
func _on_mod_slot_info_changed(slot_info: Dictionary) -> void:
	print("Mod槽位信息变化: ", slot_info)