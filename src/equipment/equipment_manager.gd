extends Node
class_name EquipmentManager

## 装备管理器 - 管理玩家的装备栏和mod[br]
## 处理装备和mod的装备、卸载和使用，支持统一的槽位管理

@export var default_equipments: Array[EquipmentResource] = [] ## 默认装备资源数组
@export var default_mods: Array[ModResource] = [] ## 默认mod资源数组
@export var combat_equipment_resources: Array[EquipmentResource] = [] ## 战斗装备资源数组

var player: Player
var slot_manager: EquipmentSlotManager
var global_mod_effects: Dictionary = {} ## 全局mod效果缓存

signal equipment_changed(slot_index: int, equipment_instance: EquipmentBase)
signal mod_changed(slot_index: int, mod_resource: ModResource)
signal equipment_used(equipment_instance: EquipmentBase)
signal equipment_slot_info_changed(slot_info: Dictionary)
signal mod_slot_info_changed(slot_info: Dictionary)

func _ready() -> void:
	# 初始化槽位管理器
	slot_manager = EquipmentSlotManager.new()
	slot_manager.equipment_slot_changed.connect(_on_equipment_slot_changed)
	slot_manager.mod_slot_changed.connect(_on_mod_slot_changed)
	
func _process(delta: float) -> void:
	# 自动使用装备
	_auto_use_equipment()

## 初始化管理器[br]
## [param owner_player] 装备的拥有者
func initialize(owner_player: Player) -> void:
	player = owner_player
	# 自动装备默认装备
	_equip_default_equipment()
	# 自动装备默认mod
	_equip_default_mods()

## 装备物品[br]
## [param equipment_resource] 要装备的装备资源[br]
## [returns] 装备成功的槽位索引，失败返回-1
func equip_item(equipment_resource: EquipmentResource) -> int:
	if not equipment_resource or not player:
		print("装备失败：装备资源或玩家为空")
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

	# 应用全局mod效果到新装备
	_apply_global_mod_effects_to_equipment(equipment_instance)
	
	return slot_index

## 装备mod[br]
## [param mod_resource] 要装备的mod资源[br]
## [param slot_index] 指定槽位索引，-1表示自动寻找空槽位[br]
## [returns] 装备成功的槽位索引，失败返回-1
func equip_mod(mod_resource: ModResource, slot_index: int = -1) -> int:
	if not mod_resource:
		print("装备mod失败：mod资源为空")
		return -1
	
	# 尝试装备到mod槽位
	var result_slot = slot_manager.try_equip_mod(mod_resource, slot_index)
	if result_slot == -1:
		push_warning("没有可用的mod槽位")
		return -1
	
	# 更新全局mod效果
	_update_global_mod_effects()
	
	return result_slot

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

## 卸载指定槽位的mod[br]
## [param slot_index] 槽位索引[br]
## [returns] 是否成功卸载
func unequip_mod(slot_index: int) -> bool:
	var success = slot_manager.unequip_mod_slot(slot_index)
	if success:
		# 更新全局mod效果
		_update_global_mod_effects()
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

## 获取特定投射物的mod效果[br]
## [returns] 投射物效果数组
func get_projectile_mod_effects() -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	var equipped_mods = slot_manager.get_all_equipped_mods()
	
	for mod_resource in equipped_mods:
		if mod_resource.effect_type == ModResource.ModEffectType.PROJECTILE_EFFECT:
			effects.append({
				"mod_resource": mod_resource,
				"effect_config": mod_resource.effect_config
			})
	
	return effects

## 自动使用装备
func _auto_use_equipment() -> void:
	var equipped_instances = slot_manager.get_all_equipped_instances()
	for equipment_instance in equipped_instances:
		if equipment_instance and equipment_instance.can_use():
			equipment_instance.use_equipment()

## 装备默认装备
func _equip_default_equipment() -> void:
	if default_equipments.size() > 0:
		for equipment_resource in default_equipments:
			equip_item(equipment_resource)
	else:
		print("没有默认装备，使用备用方案")
		# 备用方案：创建默认拳击装备资源
		_create_default_fist_equipment()

## 装备默认mod
func _equip_default_mods() -> void:
	if default_mods.size() > 0:
		print("装备默认mod，数量: ", default_mods.size())
		for mod_resource in default_mods:
			if mod_resource and mod_resource.is_valid():
				var slot_index = equip_mod(mod_resource)
				if slot_index != -1:
					print("成功装备默认mod: ", mod_resource.mod_name, " 到槽位: ", slot_index)
				else:
					print("装备默认mod失败: ", mod_resource.mod_name)
			else:
				print("无效的默认mod资源")
	else:
		print("没有配置默认mod")

## 创建默认装备
func _create_default_fist_equipment() -> void:
	print("创建默认装备...")
	var fist_equipment_resource: EquipmentResource = _create_fallback_fist_resource()
	if fist_equipment_resource:
		print("成功创建装备资源: ", fist_equipment_resource.equipment_name)
		equip_item(fist_equipment_resource)
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
		"res://src/equipment/impls/fist/fist_emitter_equipment_resource.tres",
		"res://src/equipment/impls/pistol/pistol_emitter_equipment_resource.tres"
	]
	
	for path in fallback_paths:
		var resource = load(path) as EquipmentResource
		if resource:
			return resource
	
	push_error("无法找到任何可用的默认装备资源")
	return null

## 更新全局mod效果
func _update_global_mod_effects() -> void:
	global_mod_effects.clear()
	var equipped_mods = slot_manager.get_all_equipped_mods()
	
	# 收集所有属性修改mod效果
	for mod_resource in equipped_mods:
		if mod_resource.effect_type == ModResource.ModEffectType.ATTRIBUTE_MODIFIER:
			var stat_name: String = mod_resource.get_effect_config("stat_name", "")
			if not stat_name.is_empty():
				if not global_mod_effects.has(stat_name):
					global_mod_effects[stat_name] = []
				global_mod_effects[stat_name].append(mod_resource)
	
	# 对所有装备应用全局mod效果
	var equipped_instances = slot_manager.get_all_equipped_instances()
	for equipment_instance in equipped_instances:
		_apply_global_mod_effects_to_equipment(equipment_instance)

## 对装备应用全局mod效果[br]
## [param equipment_instance] 装备实例
func _apply_global_mod_effects_to_equipment(equipment_instance: EquipmentBase) -> void:
	if not equipment_instance:
		return
	
	# 获取所有已装备的mod
	var equipped_mods = slot_manager.get_all_equipped_mods()
	if equipped_mods.is_empty():
		# 如果没有mod，清空外部效果
		if equipment_instance.has_method("apply_external_mod_effects"):
			equipment_instance.apply_external_mod_effects({})
		return
	
	# 创建一个临时的mod管理器来处理全局效果
	var temp_mod_manager = ModManager.new()
	add_child(temp_mod_manager) # 必须添加到场景树中才能正常工作
	temp_mod_manager.initialize(equipment_instance)
	
	# 设置装备的基础属性到mod管理器
	if equipment_instance.has_method("_get_current_stats"):
		var base_stats = equipment_instance._get_current_stats()
		temp_mod_manager.set_base_stats(base_stats)
	
	# 将所有全局mod安装到临时mod管理器中
	for mod_resource in equipped_mods:
		if mod_resource and mod_resource.is_valid():
			temp_mod_manager.install_mod(mod_resource)
	
	# 获取修改后的属性并应用到装备
	if equipment_instance.has_method("apply_external_mod_effects"):
		var modified_stats = temp_mod_manager.get_modified_stats()
		equipment_instance.apply_external_mod_effects(modified_stats)
		print("应用全局mod效果到装备 ", equipment_instance.equipment_name, "，修改属性: ", modified_stats.keys())
	
	# 清理临时mod管理器
	temp_mod_manager.queue_free()

## 装备槽位变化回调
func _on_equipment_slot_changed(slot_index: int, equipment_instance: EquipmentBase) -> void:
	equipment_changed.emit(slot_index, equipment_instance)
	equipment_slot_info_changed.emit(slot_manager.get_equipment_slot_info())

## mod槽位变化回调
func _on_mod_slot_changed(slot_index: int, mod_resource: ModResource) -> void:
	mod_changed.emit(slot_index, mod_resource)
	mod_slot_info_changed.emit(slot_manager.get_mod_slot_info())

## 重新计算所有装备属性（当玩家属性变化时调用）[br]
func recalculate_equipment_stats() -> void:
	var equipped_instances = slot_manager.get_all_equipped_instances()
	for equipment_instance in equipped_instances:
		if equipment_instance and equipment_instance.has_method("recalculate_stats"):
			equipment_instance.recalculate_stats()

## 玩家属性变化回调[br]
func on_player_stats_changed() -> void:
	recalculate_equipment_stats()
