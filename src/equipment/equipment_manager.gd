extends Node
class_name EquipmentManager

## 装备管理器 - 管理玩家的装备栏和mod[br]
## 处理装备和mod的装备、卸载和使用，支持统一的槽位管理

@export var default_equipments: Array[EquipmentResource] = [] ## 默认装备资源数组

@onready var slot_manager: EquipmentSlotManager = %EquipmentSlotManager
@onready var player: Player = %Player

var global_mod_effects: Dictionary = {} ## 全局mod效果缓存

signal equipment_changed(slot_index: int, equipment_instance: EquipmentBase)
signal equipment_used(equipment_instance: EquipmentBase)
signal equipment_slot_info_changed(slot_info: Dictionary)

func _ready() -> void:
	# 初始化槽位管理器
	slot_manager.equipment_slot_changed.connect(_on_equipment_slot_changed)
	# 自动装备默认装备
	_equip_default_equipment()

func _process(delta: float) -> void:
	# 自动使用装备
	_auto_use_equipment()

## 装备物品[br]
## [param equipment_resource] 要装备的装备资源[br]
## [returns] 装备成功的槽位索引，失败返回-1
func equip_item(equipment_resource: EquipmentResource) -> int:
	if not _validate_equipment_input(equipment_resource):
		return -1
	
	var equipment_instance = _create_equipment_instance_safe(equipment_resource)
	if not equipment_instance:
		return -1
	
	return _equip_to_slot(equipment_resource, equipment_instance)

## 验证装备输入[br]
func _validate_equipment_input(equipment_resource: EquipmentResource) -> bool:
	if not equipment_resource or not player:
		print("装备失败：装备资源或玩家为空")
		return false
	
	if not equipment_resource.is_valid():
		push_error("无效的装备资源: " + equipment_resource.equipment_name)
		return false
	
	return true

## 安全创建装备实例[br]
func _create_equipment_instance_safe(equipment_resource: EquipmentResource) -> EquipmentBase:
	var equipment_instance: EquipmentBase = equipment_resource.create_equipment_instance(player)
	if not equipment_instance:
		push_error("无法创建装备实例: " + equipment_resource.equipment_name)
		return null
	
	add_child(equipment_instance)
	return equipment_instance

## 装备到槽位[br]
func _equip_to_slot(equipment_resource: EquipmentResource, equipment_instance: EquipmentBase) -> int:
	var slot_index = slot_manager.try_equip_equipment(equipment_resource, equipment_instance)
	if slot_index == -1:
		equipment_instance.queue_free()
		push_warning("没有可用槽位装备: " + equipment_resource.equipment_name)
		return -1
	
	return slot_index

## 卸载指定槽位的装备[br]
## [param slot_index] 槽位索引[br]
## [returns] 是否成功卸载
func unequip_item(slot_index: int) -> bool:
	var equipment_instance = slot_manager.get_equipment_at_slot(slot_index)
	if not equipment_instance:
		return false

	# 从槽位管理器中卸载
	var success = slot_manager.unequip_equipment_slot(slot_index)
	if success:
		equipment_instance.queue_free()

		# 如果没有任何装备，自动装备默认装备
		if slot_manager.get_all_equipped_instances().is_empty():
			_equip_default_equipment()
	
	return success

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

## 获取指定槽位的mod[br]
## [param slot_index] 槽位索引[br]
## [returns] mod资源
func get_mod(slot_index: int) -> ModResource:
	return slot_manager.get_mod_at_slot(slot_index)

## 获取所有装备实例[br]
## [returns] 装备实例数组
func get_all_equipment_instances() -> Array:
	return slot_manager.get_all_equipped_instances()

## 获取所有已装备的mod[br]
## [returns] mod资源数组
func get_all_equipped_mods() -> Array:
	return slot_manager.get_all_equipped_mods()

## 获取装备槽位信息[br]
## [returns] 装备槽位信息字典
func get_equipment_slot_info() -> Dictionary:
	return slot_manager.get_equipment_slot_info()

## 获取mod槽位信息[br]
## [returns] mod槽位信息字典
func get_mod_slot_info() -> Dictionary:
	return slot_manager.get_mod_slot_info()

## 检查是否可以装备更多装备[br]
## [returns] 是否可以装备
func can_equip_more_equipment() -> bool:
	var slot_info = slot_manager.get_equipment_slot_info()
	return slot_info.get("available_slots", 0) > 0

## 检查是否可以装备更多mod[br]
## [returns] 是否可以装备
func can_equip_more_mods() -> bool:
	var slot_info = slot_manager.get_mod_slot_info()
	return slot_info.get("available_slots", 0) > 0

## 自动使用装备
func _auto_use_equipment() -> void:
	var equipped_instances = slot_manager.get_all_equipped_instances()
	for equipment_instance in equipped_instances:
		if equipment_instance and equipment_instance.can_use():
			equipment_instance.use_equipment()

## 装备默认装备
func _equip_default_equipment() -> void:
	if default_equipments.size() > 0:
		_equip_multiple_resources(default_equipments)
	else:
		_create_and_equip_fallback()

## 装备多个资源[br]
func _equip_multiple_resources(resources: Array[EquipmentResource]) -> void:
	for equipment_resource in resources:
		equip_item(equipment_resource)

## 创建并装备备用装备[br]
func _create_and_equip_fallback() -> void:
	print("没有默认装备，使用备用方案")
	var fallback_resource = _create_fallback_fist_resource()
	if fallback_resource:
		print("成功创建装备资源: ", fallback_resource.equipment_name)
		equip_item(fallback_resource)
	else:
		push_error("无法创建拳击装备资源")

## 创建备用拳击装备资源[br]
## [returns] 拳击装备资源
func _create_fallback_fist_resource() -> EquipmentResource:
	# 如果有默认装备配置，优先使用
	if default_equipments.size() > 0:
		return default_equipments[0]
	
	# 尝试通过加载已知的默认装备资源
	var fallback_paths = [
		"res://src/equipment/emitter/fist/fist_emitter_equipment_resource.tres",
		"res://src/equipment/emitter/pistol/pistol_emitter_equipment_resource.tres",
		"res://src/equipment/emitter/laser_gun/laser_gun_equipment_resource.tres",
		"res://src/equipment/armor/energy_armor_equipment_resource.tres",
		"res://src/equipment/emitter/polymer_wire/polymer_wire_equipment_resource.tres"
	]
	
	for path in fallback_paths:
		var resource = load(path) as EquipmentResource
		if resource:
			return resource
	
	push_error("无法找到任何可用的默认装备资源")
	return null


## 装备槽位变化回调
func _on_equipment_slot_changed(slot_index: int, equipment_instance: EquipmentBase) -> void:
	equipment_changed.emit(slot_index, equipment_instance)
	equipment_slot_info_changed.emit(slot_manager.get_equipment_slot_info())
	
	# 重新计算总护甲值
	recalculate_total_armor()


## 重新计算所有装备属性（当玩家属性变化时调用）[br]
func recalculate_equipment_stats() -> void:
	var equipped_instances = slot_manager.get_all_equipped_instances()
	for equipment_instance in equipped_instances:
		if equipment_instance and equipment_instance.has_method("recalculate_stats"):
			equipment_instance.recalculate_stats()

## 计算总护甲值[br]
## [returns] 来自所有装备的总护甲值
func calculate_total_armor() -> int:
	var total_armor = 0
	var equipped_instances = slot_manager.get_all_equipped_instances()
	
	for equipment_instance in equipped_instances:
		if equipment_instance and equipment_instance.has_method("get_armor_value"):
			total_armor += equipment_instance.get_armor_value()
	
	return total_armor

## 重新计算总护甲值并应用到玩家[br]
func recalculate_total_armor() -> void:
	if not player:
		return
	
	var total_armor = calculate_total_armor()
	player.update_equipment_armor(total_armor)

## 玩家属性变化回调[br]
func on_player_stats_changed() -> void:
	recalculate_equipment_stats()
	recalculate_total_armor()
