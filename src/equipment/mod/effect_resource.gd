extends Resource
class_name EffectResource

## 效果资源基类 - 定义Mod效果的基础接口[br]
## 所有具体的效果都应继承此类并实现execute_effect方法

@export_group("效果配置")
@export var effect_name: String = "基础效果" ## 效果名称
@export var effect_description: String = "基础效果描述" ## 效果描述
@export var effect_duration: float = 0.0 ## 效果持续时间（秒，0=瞬间效果）

## 执行效果[br]
## [param target] 目标节点（通常是玩家）[br]
## [param event_args] 事件参数字典[br]
## [br]
## 事件参数字典可能包含以下键值：[br]
## - event_type: String - 事件类型[br]
## - player: Player - 玩家节点[br]
## - equipment: EquipmentBase - 装备实例[br]
## - projectile: ProjectileBase - 投射物实例[br]
## - target: Node - 目标节点[br]
## - damage: int - 伤害值[br]
## - damage_type: Constants.DamageType - 伤害类型[br]
## - position: Vector2 - 位置[br]
## - 其他特定事件的参数
func execute_effect(target: Node, event_args: Dictionary) -> void:
	push_error("EffectResource.execute_effect() 必须在子类中实现")


## 获取效果信息[br]
## [returns] 效果信息字典
func get_effect_info() -> Dictionary:
	return {
		"name": effect_name,
		"description": effect_description,
		"duration": effect_duration,
		"type": get_script().get_global_name() if get_script() else "EffectResource"
	}


## 验证效果配置[br]
## [returns] 配置是否有效
func is_valid_effect() -> bool:
	if effect_name.is_empty():
		return false
	if effect_duration < 0.0:
		return false
	return true 