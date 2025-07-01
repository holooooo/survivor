extends Resource
class_name HitEffectResource

## 命中效果资源基类 - 定义投射物命中时的特殊效果[br]
## 通过事件总线系统实现，与投射物逻辑解耦

@export_group("基础配置")
@export var effect_name: String = "基础命中效果" ## 效果名称
@export var effect_id: String = "" ## 效果唯一标识（用于冷却管理）
@export var enabled: bool = true ## 是否启用此效果
@export var trigger_probability: float = 1.0 ## 触发概率（0.0-1.0）
@export var cooldown_time: float = 0.0 ## 冷却时间（秒）

@export_group("触发条件")
@export var require_critical_hit: bool = false ## 仅暴击时触发
@export var require_kill: bool = false ## 仅击杀时触发
@export var min_damage_threshold: int = 0 ## 最小伤害阈值
@export var valid_damage_types: Array[Constants.DamageType] = [] ## 有效的伤害类型（空数组表示所有类型）

## 获取效果的唯一标识符[br]
## [returns] 效果标识符
func get_effect_id() -> String:
	if effect_id.is_empty():
		return resource_path + "_" + effect_name
	return effect_id

## 检查是否可以触发效果[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例[br]
## [param target] 目标节点[br]
## [param damage] 造成的伤害[br]
## [param damage_type] 伤害类型[br]
## [param is_critical] 是否暴击[br]
## [param is_kill] 是否击杀[br]
## [returns] 是否可以触发
func can_trigger(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, damage: int, damage_type: Constants.DamageType, is_critical: bool = false, is_kill: bool = false) -> bool:
	# 基础检查
	if not enabled:
		return false
	
	# 暴击条件
	if require_critical_hit and not is_critical:
		return false
	
	# 击杀条件
	if require_kill and not is_kill:
		return false
	
	# 伤害阈值
	if damage < min_damage_threshold:
		return false
	
	# 伤害类型检查
	if not valid_damage_types.is_empty() and damage_type not in valid_damage_types:
		return false
	
	# 概率判定
	if randf() > trigger_probability:
		return false
	
	return true

## 执行效果 - 子类必须重写[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例[br]
## [param target] 目标节点[br]
## [param hit_info] 命中信息字典
func execute_effect(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, hit_info: Dictionary) -> void:
	push_warning("HitEffectResource.execute_effect() 需要被子类重写")

## 获取效果描述[br]
## [returns] 效果描述文本
func get_description() -> String:
	var desc = effect_name
	if trigger_probability < 1.0:
		desc += "（%.0f%% 概率）" % (trigger_probability * 100)
	if cooldown_time > 0:
		desc += "（冷却 %.1f秒）" % cooldown_time
	return desc

## 验证配置的有效性[br]
## [returns] 是否有效
func is_valid() -> bool:
	if effect_name.is_empty():
		return false
	if trigger_probability < 0.0 or trigger_probability > 1.0:
		return false
	if cooldown_time < 0.0:
		return false
	return true 