extends EffectResource
class_name EffectApplyBuff

## 应用Buff效果 - 给目标添加指定的Buff[br]
## 支持自定义Buff持续时间和层数

@export_group("Buff配置")
@export var buff_resource: BuffResource ## 要应用的Buff资源
@export var override_duration: float = 0.0 ## 覆盖持续时间（0=使用Buff默认时间）
@export var buff_stacks: int = 1 ## 应用的Buff层数
@export var apply_to_self: bool = true ## 应用到自己（玩家）
@export var apply_to_target: bool = false ## 应用到目标（如果事件包含目标）

func _init() -> void:
	effect_name = "应用Buff效果"
	effect_description = "给目标添加指定的Buff"

## 执行效果[br]
## [param target] 目标节点（通常是玩家）[br]
## [param event_args] 事件参数
func execute_effect(target: Node, event_args: Dictionary) -> void:
	if not buff_resource:
		push_warning("EffectApplyBuff: 没有配置Buff资源")
		return
	
	var targets_to_apply: Array[Node] = []
	
	# 确定要应用Buff的目标
	if apply_to_self and target is Actor:
		targets_to_apply.append(target)
	
	if apply_to_target:
		var event_target = event_args.get("target")
		if event_target and event_target is Actor and event_target != target:
			targets_to_apply.append(event_target)
	
	# 应用Buff到所有目标
	for buff_target in targets_to_apply:
		_apply_buff_to_target(buff_target, target, event_args)

## 应用Buff到指定目标[br]
## [param buff_target] Buff目标[br]
## [param caster] 施法者[br]
## [param event_args] 事件参数
func _apply_buff_to_target(buff_target: Actor, caster: Actor, event_args: Dictionary) -> void:
	if not buff_target.has_method("get_buff_manager"):
		push_warning("EffectApplyBuff: 目标没有BuffManager")
		return
	
	var buff_manager = buff_target.get_buff_manager()
	if not buff_manager:
		push_warning("EffectApplyBuff: 无法获取BuffManager")
		return
	
	# 创建Buff实例
	var equipment = event_args.get("equipment")
	var projectile = event_args.get("projectile")
	var buff_instance = buff_resource.create_buff_instance(buff_target, caster, equipment, projectile)
	
	# 覆盖持续时间（如果指定）
	if override_duration > 0.0:
		buff_instance.duration = override_duration
	
	# 应用Buff
	for i in range(buff_stacks):
		buff_manager.apply_buff(buff_instance)
	
	print("EffectApplyBuff: 应用Buff '%s' 到 %s，层数: %d" % [buff_resource.buff_name, buff_target.name, buff_stacks])

## 获取效果信息[br]
## [returns] 效果信息字典
func get_effect_info() -> Dictionary:
	var info = super()
	info["buff_name"] = buff_resource.buff_name if buff_resource else "无"
	info["buff_stacks"] = buff_stacks
	info["override_duration"] = override_duration
	info["apply_to_self"] = apply_to_self
	info["apply_to_target"] = apply_to_target
	return info

## 验证效果配置[br]
## [returns] 配置是否有效
func is_valid_effect() -> bool:
	if not super():
		return false
	if not buff_resource:
		return false
	if buff_stacks <= 0:
		return false
	if not apply_to_self and not apply_to_target:
		return false
	return true 