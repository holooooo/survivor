extends Node
class_name ModManager

## 模组管理器 - 管理装备的模组系统[br]
## 处理模组的安装卸载、兼容性检查和效果计算

const MAX_MOD_SLOTS: int = 10 ## 最大模组槽位数量

var equipment_owner: EquipmentBase ## 装备拥有者
var mod_slots: Array[ModResource] = [] ## 模组槽位数组
var base_stats: Dictionary = {} ## 基础属性缓存
var modified_stats: Dictionary = {} ## 修改后的属性

signal mod_applied(mod_resource: ModResource, slot_index: int)
signal mod_removed(mod_resource: ModResource, slot_index: int)
signal stats_updated(new_stats: Dictionary)

func _init():
	# 初始化槽位
	mod_slots.resize(MAX_MOD_SLOTS)
	for i in range(MAX_MOD_SLOTS):
		mod_slots[i] = null

## 初始化mod管理器[br]
## [param owner] 装备拥有者
func initialize(owner: EquipmentBase) -> void:
	equipment_owner = owner

## 安装模组到指定槽位[br]
## [param mod_resource] 要安装的模组资源[br]
## [param slot_index] 槽位索引，-1表示自动寻找空槽位[br]
## [returns] 安装成功的槽位索引，失败返回-1
func install_mod(mod_resource: ModResource, slot_index: int = -1) -> int:
	if not mod_resource or not mod_resource.is_valid():
		print("错误: 无效的模组资源")
		return -1
	
	
	# 寻找目标槽位
	var target_slot: int = slot_index
	if target_slot == -1:
		target_slot = _find_empty_slot()
		if target_slot == -1:
			push_warning("没有可用的模组槽位")
			return -1
	
	# 检查槽位是否有效
	if target_slot < 0 or target_slot >= MAX_MOD_SLOTS:
		push_error("无效的槽位索引: " + str(target_slot))
		return -1
	
	# 卸载已有模组
	if mod_slots[target_slot] != null:
		uninstall_mod(target_slot)
	
	# 安装新模组
	mod_slots[target_slot] = mod_resource
	_apply_mod_effects()
	mod_applied.emit(mod_resource, target_slot)
	
	return target_slot

## 卸载指定槽位的模组[br]
## [param slot_index] 槽位索引[br]
## [returns] 是否成功卸载
func uninstall_mod(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_MOD_SLOTS:
		return false
	
	var removed_mod = mod_slots[slot_index]
	if removed_mod == null:
		return false
	
	mod_slots[slot_index] = null
	_apply_mod_effects()
	
	mod_removed.emit(removed_mod, slot_index)
	return true

## 获取指定槽位的模组[br]
## [param slot_index] 槽位索引[br]
## [returns] 模组资源
func get_mod(slot_index: int) -> ModResource:
	if slot_index < 0 or slot_index >= MAX_MOD_SLOTS:
		return null
	return mod_slots[slot_index]

## 获取所有已安装的模组[br]
## [returns] 模组资源数组
func get_all_installed_mods() -> Array[ModResource]:
	var installed_mods: Array[ModResource] = []
	for mod_resource in mod_slots:
		if mod_resource != null:
			installed_mods.append(mod_resource)
	return installed_mods

## 获取槽位信息[br]
## [returns] 槽位信息字典
func get_slot_info() -> Dictionary:
	var used_slots: int = 0
	var empty_slots: int = 0
	
	for mod_resource in mod_slots:
		if mod_resource != null:
			used_slots += 1
		else:
			empty_slots += 1
	
	return {
		"total_slots": MAX_MOD_SLOTS,
		"used_slots": used_slots,
		"empty_slots": empty_slots,
		"slots": mod_slots
	}

## 设置基础属性[br]
## [param stats] 基础属性字典
func set_base_stats(stats: Dictionary) -> void:
	base_stats = stats.duplicate()
	_apply_mod_effects()

## 获取修改后的属性[br]
## [returns] 修改后的属性字典
func get_modified_stats() -> Dictionary:
	return modified_stats.duplicate()

## 获取特定投射物的模组效果[br]
## [returns] 投射物效果数组
func get_projectile_effects() -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	
	for i in range(MAX_MOD_SLOTS):
		var mod_resource = mod_slots[i]
		if mod_resource != null:
			if mod_resource.effect_type == ModResource.ModEffectType.PROJECTILE_EFFECT:
				effects.append({
					"mod_resource": mod_resource,
					"effect_config": mod_resource.effect_config
				})
	
	return effects

## 获取特殊效果[br]
## [returns] 特殊效果数组
func get_special_effects() -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	
	for mod_resource in mod_slots:
		if mod_resource != null and mod_resource.effect_type == ModResource.ModEffectType.SPECIAL_EFFECT:
			effects.append({
				"mod_resource": mod_resource,
				"effect_config": mod_resource.effect_config
			})
	
	return effects

## 获取Hook效果[br]
## [param hook_type] Hook类型[br]
## [returns] 匹配的mod资源数组
func get_hook_effects(hook_type: ModResource.HookType) -> Array[ModResource]:
	var hook_mods: Array[ModResource] = []
	
	for mod_resource in mod_slots:
		if mod_resource != null and mod_resource.effect_type == ModResource.ModEffectType.HOOK_EFFECT:
			var mod_hook_type = mod_resource.get_effect_config("hook_type", -1)
			if mod_hook_type == hook_type:
				hook_mods.append(mod_resource)
	
	return hook_mods

## 获取所有Hook效果[br]
## [returns] 所有Hook效果的字典，键为hook类型，值为mod数组
func get_all_hook_effects() -> Dictionary:
	var all_hooks: Dictionary = {}
	
	for mod_resource in mod_slots:
		if mod_resource != null and mod_resource.effect_type == ModResource.ModEffectType.HOOK_EFFECT:
			var hook_type = mod_resource.get_effect_config("hook_type", -1)
			if hook_type != -1:
				if not all_hooks.has(hook_type):
					all_hooks[hook_type] = []
				all_hooks[hook_type].append(mod_resource)
	
	return all_hooks

## 检查是否有特定Hook[br]
## [param hook_type] Hook类型[br]
## [returns] 是否存在该类型的Hook效果
func has_hook_effect(hook_type: ModResource.HookType) -> bool:
	return get_hook_effects(hook_type).size() > 0

## 寻找空的槽位[br]
## [returns] 空槽位索引，没有则返回-1
func _find_empty_slot() -> int:
	for i in range(MAX_MOD_SLOTS):
		if mod_slots[i] == null:
			return i
	return -1

## 应用所有模组效果
func _apply_mod_effects() -> void:
	# 重置为基础属性
	modified_stats = base_stats.duplicate()
	
	# 收集所有属性修改模组
	var attribute_mods: Array[ModResource] = []
	
	for mod_resource in mod_slots:
		if mod_resource != null and mod_resource.effect_type == ModResource.ModEffectType.ATTRIBUTE_MODIFIER:
			attribute_mods.append(mod_resource)
	
	# 按优先级排序
	attribute_mods.sort_custom(_compare_mod_priority)
	
	# 应用属性修改
	_apply_attribute_modifiers(attribute_mods)
	
	# 发射统计更新信号
	stats_updated.emit(modified_stats)

## 应用属性修改模组[br]
## [param mods] 属性修改模组数组
func _apply_attribute_modifiers(mods: Array[ModResource]) -> void:
	var percentage_modifiers: Dictionary = {} ## 百分比修改累积
	var flat_modifiers: Dictionary = {} ## 固定值修改累积
	var exclusive_modifiers: Dictionary = {} ## 互斥效果（高优先级覆盖）
	
	for mod_resource in mods:
		var stat_name: String = mod_resource.get_effect_config("stat_name", "")
		var modifier_type: String = mod_resource.get_effect_config("modifier_type", "")
		var value = mod_resource.get_effect_config("value", 0)
		
		if stat_name.is_empty():
			continue
		
		match modifier_type:
			"percentage":
				# 百分比修改累加
				percentage_modifiers[stat_name] = percentage_modifiers.get(stat_name, 0.0) + value
			"flat":
				# 固定值修改累加
				flat_modifiers[stat_name] = flat_modifiers.get(stat_name, 0.0) + value
			"exclusive":
				# 互斥效果，高优先级覆盖
				if not exclusive_modifiers.has(stat_name) or mod_resource.priority > exclusive_modifiers[stat_name].priority:
					exclusive_modifiers[stat_name] = {
						"value": value,
						"priority": mod_resource.priority
					}
	
	# 应用修改到属性
	_apply_modifiers_to_stats(percentage_modifiers, flat_modifiers, exclusive_modifiers)

## 应用修改器到属性[br]
## [param percentage_mods] 百分比修改字典[br]
## [param flat_mods] 固定值修改字典[br]
## [param exclusive_mods] 互斥修改字典
func _apply_modifiers_to_stats(percentage_mods: Dictionary, flat_mods: Dictionary, exclusive_mods: Dictionary) -> void:
	# 应用互斥效果（最高优先级）
	for stat_name in exclusive_mods:
		var base_value = base_stats.get(stat_name, 0)
		modified_stats[stat_name] = base_value + exclusive_mods[stat_name].value
	
	# 应用固定值修改
	for stat_name in flat_mods:
		var current_value = modified_stats.get(stat_name, base_stats.get(stat_name, 0))
		modified_stats[stat_name] = current_value + flat_mods[stat_name]
	
	# 应用百分比修改
	for stat_name in percentage_mods:
		var current_value = modified_stats.get(stat_name, base_stats.get(stat_name, 0))
		var base_value = base_stats.get(stat_name, 0)
		var multiplier = 1.0 + percentage_mods[stat_name]
		modified_stats[stat_name] = base_value * multiplier

## 模组优先级比较函数[br]
## [param a] 模组A[br]
## [param b] 模组B[br]
## [returns] 是否A的优先级更高
func _compare_mod_priority(a: ModResource, b: ModResource) -> bool:
	return a.priority > b.priority