extends Resource
class_name ModResource

## Mod资源 - 定义一个Mod的基础数据[br]
## 通过组合触发器和效果来实现不同的Mod功能

@export_group("基础信息")
@export var mod_name: String = "未命名Mod" ## Mod名称
@export var mod_description: String = "无描述" ## Mod描述
@export var mod_icon: Texture2D ## Mod图标
@export var mod_rarity: int = 1 ## Mod稀有度（1-5）

@export_group("功能配置")
@export var trigger_resource: TriggerResource ## 触发器资源
@export var effect_resource: EffectResource ## 效果资源
@export var cooldown_time: float = 0.0 ## 冷却时间（秒）
@export var max_triggers: int = 0 ## 最大触发次数（0=无限制）

## 运行时数据（不导出）
var current_triggers: int = 0 ## 当前触发次数
var last_trigger_time: float = 0.0 ## 上次触发时间（使用Engine.get_process_time()）


## 检查Mod是否可以触发[br]
## [param event_args] 事件参数[br]
## [returns] 是否可以触发
func can_trigger(event_args: Dictionary) -> bool:
	# 检查触发器资源是否存在
	if not trigger_resource:
		return false
	
	# 检查冷却时间
	var current_time = Time.get_ticks_msec()
	if cooldown_time > 0.0 and (current_time - last_trigger_time) < cooldown_time:
		return false
	
	# 检查触发次数限制
	if max_triggers > 0 and current_triggers >= max_triggers:
		return false
	
	# 检查触发器条件
	return trigger_resource.check_trigger(event_args)


## 执行Mod效果[br]
## [param target] 目标节点（通常是玩家）[br]
## [param event_args] 事件参数
func execute_effect(target: Node, event_args: Dictionary) -> void:
	if not effect_resource:
		push_warning("Mod %s 没有效果资源" % mod_name)
		return
	
	# 更新触发数据
	current_triggers += 1
	last_trigger_time = Time.get_ticks_msec()
	
	# 执行效果
	effect_resource.execute_effect(target, event_args)


## 重置Mod状态[br]
## 用于重新开始游戏或重置Mod状态
func reset_mod_state() -> void:
	current_triggers = 0
	last_trigger_time = 0.0


## 获取Mod信息[br]
## [returns] Mod信息字典
func get_mod_info() -> Dictionary:
	return {
		"name": mod_name,
		"description": mod_description,
		"rarity": mod_rarity,
		"cooldown_time": cooldown_time,
		"max_triggers": max_triggers,
		"current_triggers": current_triggers,
		"has_trigger": trigger_resource != null,
		"has_effect": effect_resource != null
	}


## 验证Mod配置的有效性[br]
## [returns] 是否有效
func is_valid_mod() -> bool:
	if mod_name.is_empty():
		return false
	if not trigger_resource:
		return false
	if not effect_resource:
		return false
	if cooldown_time < 0.0:
		return false
	if max_triggers < 0:
		return false
	
	return true

func _init():
	pass
