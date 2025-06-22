extends Node
class_name PlayerEquipmentManager

## 装备管理器 - 管理玩家的装备栏[br]
## 处理装备的装备、卸载和使用

@export var max_equipment_slots: int = 1
@export var default_equipments: Array[EquipmentResource] = [] ## 默认装备资源数组
@export var combat_equipment_resources: Array[EquipmentResource] = [] ## 战斗装备资源数组
@export var equipped_instances: Array[EquipmentBase] = [] ## 装备实例数组

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
## [param equipment_resource] 要装备的装备资源[br]
## [returns] 是否成功装备
func equip_item(slot_index: int, equipment_resource: EquipmentResource) -> bool:
	if slot_index < 0 or slot_index >= max_equipment_slots:
		return false
	
	if not equipment_resource or not player:
		return false
	
	# 验证装备资源
	if not equipment_resource.is_valid():
		push_error("无效的装备资源: " + equipment_resource.equipment_name)
		return false
	
	# 卸载当前装备
	if equipped_instances[slot_index]:
		unequip_item(slot_index)
	
	# 使用装备资源创建装备实例
	var equipment_instance: EquipmentBase = equipment_resource.create_equipment_instance(player)
	if not equipment_instance:
		push_error("无法创建装备实例: " + equipment_resource.equipment_name)
		return false
	
	add_child(equipment_instance)
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

## 创建默认装备
func _create_default_fist_equipment() -> void:
	print("装备所有默认装备...")
	if default_equipments.size() > 0:
		# 装备所有默认装备
		for i in range(min(default_equipments.size(), max_equipment_slots)):
			if default_equipments[i]:
				print("装备槽位 ", i, " 的默认装备: ", default_equipments[i])
				equip_item(i, default_equipments[i])
	else:
		print("使用备用拳击装备...")
		# 备用方案：创建默认拳击装备资源
		var fist_equipment_resource: EquipmentResource = _create_fallback_fist_resource()
		if fist_equipment_resource:
			print("成功创建拳击装备资源: ", fist_equipment_resource.equipment_name)
			equip_item(0, fist_equipment_resource)
		else:
			print("错误：无法创建拳击装备资源")

## 检查所有槽位是否为空[br]
## [returns] 是否所有槽位都为空
func _is_all_slots_empty() -> bool:
	for equipment_instance in equipped_instances:
		if equipment_instance:
			return false
	return true

## 切换到手枪装备[br]
func switch_to_pistol() -> void:
	var pistol_equipment_resource: EquipmentResource = _create_fallback_pistol_resource()
	if pistol_equipment_resource:
		equip_item(0, pistol_equipment_resource)

## 切换到拳头装备[br]
func switch_to_fist() -> void:
	var fist_equipment_resource: EquipmentResource = _create_fallback_fist_resource()
	if fist_equipment_resource:
		equip_item(0, fist_equipment_resource)

## 创建备用拳击装备资源[br]
## [returns] 拳击装备资源
func _create_fallback_fist_resource() -> EquipmentResource:
	# 尝试创建AOE装备资源，失败则使用基础资源
	var aoe_script: Script = load("res://src/equipment/resources/aoe_equipment_resource.gd")
	var fist_resource: EquipmentResource
	
	if aoe_script:
		fist_resource = aoe_script.new()
		# AOE专属配置（duration和lifetime是同一概念）
		fist_resource.duration = 0.5
		fist_resource.damage_interval = 0.1
		fist_resource.max_damage_ticks = 5
		fist_resource.aoe_radius = 50.0
		fist_resource.base_damage = 3
		fist_resource.effect_color = Color.YELLOW
	else:
		fist_resource = EquipmentResource.new()
	
	# 基础装备属性
	fist_resource.equipment_name = "基础拳击"
	fist_resource.equipment_id = "fist_basic"
	fist_resource.cooldown_time = 1.0
	fist_resource.operation_radius = 100.0
	fist_resource.equipment_scene = preload("res://src/equipment/fist/fist_equipment.tscn")
	fist_resource.projectile_scene = preload("res://src/equipment/fist/fist_projectile.tscn")
	fist_resource.projectile_resource = preload("res://src/equipment/fist/fist_projectile_resource.tres")
	fist_resource.description = "基础的拳击攻击装备"
	
	return fist_resource

## 创建备用手枪装备资源[br]
## [returns] 手枪装备资源
func _create_fallback_pistol_resource() -> EquipmentResource:
	# 尝试创建枪械装备资源，失败则使用基础资源
	var firearm_script: Script = load("res://src/equipment/resources/firearm_equipment_resource.gd")
	var pistol_resource: EquipmentResource
	
	if firearm_script:
		pistol_resource = firearm_script.new()
		# 枪械专属配置
		if pistol_resource.has_method("set_bullets_per_shot"):
			pistol_resource.bullets_per_shot = 3
			pistol_resource.bullet_interval = 0.1
			pistol_resource.bullet_damage = 10
			pistol_resource.max_range = 500.0
			pistol_resource.bullet_speed = 800.0
			pistol_resource.magazine_capacity = 9
			pistol_resource.reload_time = 2.0
			pistol_resource.pierce_count = 1
			pistol_resource.pierce_damage_reduction = 0.2
	else:
		pistol_resource = EquipmentResource.new()
	
	# 基础装备属性
	pistol_resource.equipment_name = "基础手枪"
	pistol_resource.equipment_id = "pistol_basic"
	pistol_resource.cooldown_time = 0.5
	pistol_resource.operation_radius = 200.0
	pistol_resource.equipment_scene = preload("res://src/equipment/pistol/pistol_equipment.tscn")
	pistol_resource.projectile_scene = preload("res://src/equipment/pistol/pistol_projectile.tscn")
	pistol_resource.projectile_resource = preload("res://src/equipment/pistol/pistol_projectile_resource.tres")
	pistol_resource.description = "基础的手枪射击装备"
	
	return pistol_resource

## 装备使用回调
func _on_equipment_used(equipment_instance) -> void:
	equipment_used.emit(equipment_instance)
