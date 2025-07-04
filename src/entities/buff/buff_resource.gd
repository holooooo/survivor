extends Resource
class_name BuffResource

## Buff资源基类 - 定义buff的配置和元数据[br]
## 包含buff的基本属性、触发条件、效果类型等配置信息

@export_group("基本信息")
@export var buff_name: String = "基础Buff" ## buff名称
@export var buff_id: String = "" ## buff唯一标识
@export var buff_description: String = "基础buff描述" ## buff描述
@export var buff_icon: Texture2D ## buff图标

@export_group("类型配置")
@export var buff_type: Constants.BuffType = Constants.BuffType.增益 ## buff类型
@export var effect_type: Constants.BuffEffectType = Constants.BuffEffectType.属性修改 ## 效果类型

@export_group("持续时间")
@export var duration: float = 5.0 ## 持续时间（秒）
@export var is_permanent: bool = false ## 是否永久

@export_group("层数系统")
@export var stackable: bool = false ## 是否可叠加
@export var max_stacks: int = 1 ## 最大层数
@export var stack_refresh_duration: bool = true ## 叠加时是否刷新持续时间

@export_group("触发条件")
@export var trigger_probability: float = 1.0 ## 触发概率
@export var apply_to_damage_types: Array[Constants.DamageType] = [] ## 适用的伤害类型
@export var apply_to_all_damage_types: bool = true ## 适用于所有伤害类型

@export_group("效果配置")
@export var effect_values: Dictionary = {} ## 效果数值配置
@export var effect_scripts: Array[String] = [] ## 自定义效果脚本路径

func _init():
	if buff_id.is_empty():
		buff_id = buff_name.to_lower().replace(" ", "_")

## 验证buff配置是否有效[br]
## [returns] 配置是否有效
func is_valid() -> bool:
	return not buff_name.is_empty() and not buff_id.is_empty()
## 获取buff描述文本[br]
## [param stack_count] 当前层数[br]
## [returns] 描述文本
func get_description(stack_count: int = 1) -> String:
	var desc = buff_description
	if stackable and stack_count > 1:
		desc += " (层数: %d)" % stack_count
	return desc

## 获取效果数值[br]
## [param key] 数值键名[br]
## [param default_value] 默认值[br]
## [returns] 效果数值
func get_effect_value(key: String, default_value = 0.0):
	return effect_values.get(key, default_value)

## 设置效果数值[br]
## [param key] 数值键名[br]
## [param value] 数值
func set_effect_value(key: String, value) -> void:
	effect_values[key] = value

## 检查是否适用于指定伤害类型[br]
## [param damage_type] 伤害类型[br]
## [returns] 是否适用
func applies_to_damage_type(damage_type: Constants.DamageType) -> bool:
	if apply_to_all_damage_types:
		return true
	return damage_type in apply_to_damage_types

## 创建buff实例[br]
## [param target] 目标角色[br]
## [param caster] 施法者[br]
## [param equipment] 所属装备[br]
## [param projectile] 所属投射物[br]
## [returns] buff实例
func create_buff_instance(target: Actor, caster: Actor = null, equipment: EquipmentBase = null, projectile: ProjectileBase = null) -> BuffInstance:
	var instance = BuffInstance.new()
	instance.setup(self, target, caster, equipment, projectile)
	return instance 