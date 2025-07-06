extends Resource
class_name TriggerResource

## 触发器资源基类 - 定义Mod触发条件的基础接口[br]
## 所有具体的触发器都应继承此类并实现check_trigger方法

@export_group("触发器配置")
@export var trigger_name: String = "基础触发器" ## 触发器名称
@export var trigger_description: String = "基础触发器描述" ## 触发器描述

## 检查触发条件是否满足[br]
## [param event_args] 事件参数字典[br]
## [returns] 是否满足触发条件[br]
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
func check_trigger(event_args: Dictionary) -> bool:
	push_error("TriggerResource.check_trigger() 必须在子类中实现")
	return false


## 获取触发器信息[br]
## [returns] 触发器信息字典
func get_trigger_info() -> Dictionary:
	return {
		"name": trigger_name,
		"description": trigger_description,
		"type": get_script().get_global_name() if get_script() else "TriggerResource"
	}


## 验证触发器配置[br]
## [returns] 配置是否有效
func is_valid_trigger() -> bool:
	if trigger_name.is_empty():
		return false
	return true 