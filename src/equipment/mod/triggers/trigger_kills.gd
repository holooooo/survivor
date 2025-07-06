extends TriggerResource
class_name TriggerKills

## 击杀计数触发器 - 每击杀指定数量的敌人时触发[br]
## 支持总击杀数和连续击杀数两种模式

@export_group("击杀配置")
@export var required_kills: int = 1 ## 所需击杀数量
@export var use_consecutive_kills: bool = false ## 是否使用连续击杀模式
@export var reset_on_damage: bool = false ## 受到伤害时是否重置计数

## 内部状态
var current_kills: int = 0
var consecutive_kills: int = 0

func _init() -> void:
	trigger_name = "击杀触发器"
	trigger_description = "每击杀%d个敌人时触发" % required_kills

## 检查触发条件[br]
## [param event_args] 事件参数[br]
## [returns] 是否满足触发条件
func check_trigger(event_args: Dictionary) -> bool:
	var event_type = event_args.get("event_type", "")
	
	# 处理击杀事件
	if event_type == "projectile_kill":
		if use_consecutive_kills:
			consecutive_kills += 1
			if consecutive_kills >= required_kills:
				consecutive_kills = 0  # 重置连续击杀计数
				return true
		else:
			current_kills += 1
			if current_kills >= required_kills:
				current_kills = 0  # 重置击杀计数
				return true
	
	# 处理受伤事件（如果启用了重置）
	elif event_type == "player_damage" and reset_on_damage:
		if use_consecutive_kills:
			consecutive_kills = 0
		# 总击杀数不会因为受伤而重置
	
	return false

## 重置触发器状态[br]
func reset_trigger() -> void:
	current_kills = 0
	consecutive_kills = 0

## 获取当前击杀进度[br]
## [returns] 击杀进度字典
func get_kill_progress() -> Dictionary:
	if use_consecutive_kills:
		return {
			"current": consecutive_kills,
			"required": required_kills,
			"mode": "consecutive"
		}
	else:
		return {
			"current": current_kills,
			"required": required_kills,
			"mode": "total"
		}

## 验证触发器配置[br]
## [returns] 配置是否有效
func is_valid_trigger() -> bool:
	if not super():
		return false
	if required_kills <= 0:
		return false
	return true 