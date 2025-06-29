extends Resource
class_name ModResource

## 模组资源 - 装备强化模组的配置资源[br]
## 定义模组的效果类型、兼容性和优先级系统

enum ModEffectType {
	ATTRIBUTE_MODIFIER,  ## 属性修改（如攻击力+10%、攻击范围+20%）
	PROJECTILE_EFFECT,   ## 投射物效果（如弹射、分裂、穿透）
	SPECIAL_EFFECT       ## 特殊效果（如无限弹药、生命偷取）
}

@export_group("基础信息")
@export var mod_name: String = "基础模组" ## 模组名称
@export var mod_id: String = "" ## 模组唯一标识
@export var description: String = "" ## 模组描述
@export var icon_texture: Texture2D ## 模组图标

@export_group("兼容性配置")
@export var compatible_tags: Array[EquipmentTags.Tag] = [] ## 兼容的装备标签数组
@export var priority: int = 0 ## 优先级，数字越大优先级越高

@export_group("效果配置")
@export var effect_type: ModEffectType = ModEffectType.ATTRIBUTE_MODIFIER ## 效果类型
@export var effect_config: Dictionary = {} ## 效果配置参数

## 检查模组是否与装备兼容[br]
## [param equipment_tags_param] 装备的标签数组[br]
## [returns] 是否兼容
func is_compatible_with_equipment(equipment_tags_param: Array[EquipmentTags.Tag]) -> bool:
	if compatible_tags.is_empty():
		print("模组 ", mod_name, " 兼容标签为空")
		return false
	
	print("检查模组 ", mod_name, " 兼容性:")
	print("  模组标签: ", compatible_tags)
	print("  装备标签: ", equipment_tags_param)
	
	# 检查通配符兼容性（使用枚举值）
	const UNIVERSAL = EquipmentTags.Tag.通用
	if UNIVERSAL in compatible_tags or UNIVERSAL in equipment_tags_param:
		print("  ✓ 通配符匹配")
		return true
	
	# 检查标签交集
	for tag in compatible_tags:
		if tag in equipment_tags_param:
			print("  ✓ 标签匹配: ", tag)
			return true
	
	print("  ✗ 无匹配标签")
	return false

## 获取效果配置的安全访问方法[br]
## [param key] 配置键名[br]
## [param default_value] 默认值[br]
## [returns] 配置值
func get_effect_config(key: String, default_value = null):
	return effect_config.get(key, default_value)

## 验证模组资源的完整性[br]
## [returns] 是否有效
func is_valid() -> bool:
	if mod_name.is_empty():
		return false
	
	if compatible_tags.is_empty():
		return false
	
	# 根据效果类型验证必要的配置
	match effect_type:
		ModEffectType.ATTRIBUTE_MODIFIER:
			if not effect_config.has("stat_name"):
				return false
			if not effect_config.has("modifier_type"):
				return false
			if not effect_config.has("value"):
				return false
		ModEffectType.PROJECTILE_EFFECT:
			if not effect_config.has("effect_name"):
				return false
		ModEffectType.SPECIAL_EFFECT:
			if not effect_config.has("effect_name"):
				return false
	
	return true

## 获取模组信息字典[br]
## [returns] 模组信息
func get_mod_info() -> Dictionary:
	return {
		"name": mod_name,
		"id": mod_id,
		"description": description,
		"effect_type": effect_type,
		"compatible_tags": compatible_tags,
		"priority": priority,
		"effect_config": effect_config
	}

## === 模组效果执行接口 ===

## 应用模组效果到投射物[br]
## [param projectile] 目标投射物[br]
## 子类可重写此方法来实现模组的初始化逻辑
func apply_to_projectile(projectile: Node) -> void:
	# 默认实现：将effect_config设置到projectile的meta中
	if effect_type == ModEffectType.PROJECTILE_EFFECT:
		var effect_name = effect_config.get("effect_name", "")
		if not effect_name.is_empty():
			projectile.set_meta(effect_name + "_mod", self)
			projectile.set_meta(effect_name + "_data", _get_initial_mod_data())

## 处理投射物命中事件[br]
## [param projectile] 投射物[br]
## [param target] 命中的目标[br]
## [returns] 是否应该继续处理后续逻辑
func on_projectile_hit(projectile: Node, target: Node) -> bool:
	# 子类重写此方法来实现命中时的效果
	return true

## 获取初始模组数据[br]
## [returns] 初始数据字典[br]
## 子类可重写此方法来提供自定义的初始数据
func _get_initial_mod_data() -> Dictionary:
	return effect_config.duplicate()

## 修改其他模组的数据[br]
## [param projectile] 投射物[br]
## [param other_mod_id] 其他模组的ID[br]
## [param modifications] 要应用的修改[br]
## 用于实现模组间的相互影响
func modify_other_mod(projectile: Node, other_mod_id: String, modifications: Dictionary) -> void:
	var other_mod_data_key = other_mod_id + "_data"
	if projectile.has_meta(other_mod_data_key):
		var other_data = projectile.get_meta(other_mod_data_key, {})
		for key in modifications:
			other_data[key] = modifications[key]
		projectile.set_meta(other_mod_data_key, other_data) 