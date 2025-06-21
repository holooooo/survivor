extends Node
class_name PlayerEquipmentManager

## 装备管理器 - 管理玩家的装备栏[br]
## 处理装备的装备、卸载和使用

@export var max_equipment_slots: int = 1
@export var default_equipment: PackedScene
@export var combat_equipment_resources: Array[PackedScene] = [] ## 战斗装备场景数组

var equipped_instances: Array[EquipmentBase] = [] ## 装备实例数组
var player: Player

signal equipment_changed(slot_index: int, equipment_instance: EquipmentBase)
signal equipment_used(equipment_instance: EquipmentBase)

func _ready() -> void:
	# 初始化装备栏数组
	equipped_instances.resize(max_equipment_slots)
	
	
func _process(delta: float) -> void:
	# 自动使用装备
	_auto_use_equipment()

## 初始化管理器[br]
## [param owner_player] 装备的拥有者
func initialize(owner_player: Player) -> void:
	player = owner_player
	# 自动装备默认装备
	_equip_default_equipment()

## 装备物品到指定槽位[br]
## [param slot_index] 槽位索引[br]
## [param equipment_scene] 要装备的装备场景[br]
## [returns] 是否成功装备
func equip_item(slot_index: int, equipment_scene: PackedScene) -> bool:
	if slot_index < 0 or slot_index >= max_equipment_slots:
		return false
	
	if not equipment_scene or not player:
		return false
	
	# 卸载当前装备
	if equipped_instances[slot_index]:
		unequip_item(slot_index)
	
	# 创建新装备实例
	var equipment_instance: EquipmentBase = equipment_scene.instantiate()
	add_child(equipment_instance)
	equipment_instance.initialize(player)
	print("装备实例创建成功: ", equipment_instance, " 名称: ", equipment_instance.equipment_name, " 图标: ", equipment_instance.icon_texture)
	
	# 装备新装备
	equipped_instances[slot_index] = equipment_instance
	equipment_instance.equipment_used.connect(_on_equipment_used)
	
	equipment_changed.emit(slot_index, equipment_instance)
	print("装备变化信号已发送，槽位: ", slot_index, " 装备: ", equipment_instance)
	return true

## 卸载指定槽位的装备[br]
## [param slot_index] 槽位索引[br]
## [returns] 被卸载的装备实例
func unequip_item(slot_index: int):
	if slot_index < 0 or slot_index >= max_equipment_slots:
		return null
	
	var old_instance = equipped_instances[slot_index]
	if old_instance:
		if old_instance.equipment_used.is_connected(_on_equipment_used):
			old_instance.equipment_used.disconnect(_on_equipment_used)
		old_instance.queue_free()
	
	equipped_instances[slot_index] = null
	equipment_changed.emit(slot_index, null)
	
	# 如果没有任何装备，自动装备默认装备
	if _is_all_slots_empty():
		_equip_default_equipment()
	
	return old_instance

## 获取指定槽位的装备实例[br]
## [param slot_index] 槽位索引[br]
## [returns] 装备实例
func get_equipment_instance(slot_index: int) -> EquipmentBase:
	if slot_index < 0 or slot_index >= max_equipment_slots:
		return null
	return equipped_instances[slot_index]

## 获取指定槽位的装备[br]
## [param slot_index] 槽位索引[br]
## [returns] 装备实例
func get_equipment(slot_index: int) -> EquipmentBase:
	return get_equipment_instance(slot_index)

## 获取所有装备实例
## [returns] 装备实例数组
func get_all_equipment_instances() -> Array:
	return equipped_instances.duplicate()

## 自动使用装备
func _auto_use_equipment() -> void:
	for equipment_instance in equipped_instances:
		if equipment_instance and equipment_instance.has_method("can_use") and equipment_instance.can_use():
			equipment_instance.use_equipment()

## 装备默认装备
func _equip_default_equipment() -> void:
	_create_default_fist_equipment()

## 创建默认拳击装备
func _create_default_fist_equipment() -> void:
	print("创建默认拳击装备...")
	if default_equipment:
		print("使用配置的默认装备: ", default_equipment)
		equip_item(0, default_equipment)
	else:
		print("使用备用拳击装备...")
		# 备用方案：加载默认拳击装备
		var fist_equipment_scene: PackedScene = preload("res://src/equipment/fist/fist_equipment.tscn")
		if fist_equipment_scene:
			print("成功加载拳击装备场景: ", fist_equipment_scene)
			equip_item(0, fist_equipment_scene)
		else:
			print("错误：无法加载拳击装备场景")

## 检查所有槽位是否为空[br]
## [returns] 是否所有槽位都为空
func _is_all_slots_empty() -> bool:
	for equipment_instance in equipped_instances:
		if equipment_instance:
			return false
	return true

## 装备使用回调
func _on_equipment_used(equipment_instance) -> void:
	equipment_used.emit(equipment_instance)
