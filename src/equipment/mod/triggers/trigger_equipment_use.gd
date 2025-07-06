extends TriggerResource
class_name TriggerEquipmentUse

## 装备使用触发器 - 特定装备使用指定次数后触发[br]
## 支持指定装备类型或任意装备使用

@export_group("装备配置")
@export var required_uses: int = 1 ## 所需使用次数
@export var target_equipment_class: String = "" ## 目标装备类名（空字符串表示任意装备）
@export var reset_on_cooldown: bool = false ## 装备进入冷却时是否重置计数

## 内部状态
var current_uses: int = 0
var tracked_equipment: WeakRef ## 被跟踪的装备实例

func _init() -> void:
	trigger_name = "装备使用触发器"
	if target_equipment_class.is_empty():
		trigger_description = "任意装备使用%d次后触发" % required_uses
	else:
		trigger_description = "%s使用%d次后触发" % [target_equipment_class, required_uses]

## 检查触发条件[br]
## [param event_args] 事件参数[br]
## [returns] 是否满足触发条件
func check_trigger(event_args: Dictionary) -> bool:
	var event_type = event_args.get("event_type", "")
	
	# 处理装备使用事件
	if event_type == "equipment_used":
		var equipment = event_args.get("equipment")
		if not equipment:
			return false
		
		# 检查是否是目标装备类型
		if not target_equipment_class.is_empty():
			var equipment_class = equipment.get_script().get_global_name()
			if equipment_class != target_equipment_class:
				return false
		
		# 增加使用计数
		current_uses += 1
		tracked_equipment = weakref(equipment)
		
		# 检查是否达到触发条件
		if current_uses >= required_uses:
			current_uses = 0  # 重置使用计数
			return true
	
	# 处理装备冷却事件（如果启用了重置）
	elif event_type == "equipment_cooldown_start" and reset_on_cooldown:
		var equipment = event_args.get("equipment")
		if equipment and tracked_equipment and tracked_equipment.get_ref() == equipment:
			current_uses = 0
	
	return false

## 重置触发器状态[br]
func reset_trigger() -> void:
	current_uses = 0
	tracked_equipment = null

## 获取当前使用进度[br]
## [returns] 使用进度字典
func get_use_progress() -> Dictionary:
	return {
		"current": current_uses,
		"required": required_uses,
		"target_class": target_equipment_class,
		"has_tracked_equipment": tracked_equipment != null and tracked_equipment.get_ref() != null
	}

## 验证触发器配置[br]
## [returns] 配置是否有效
func is_valid_trigger() -> bool:
	if not super():
		return false
	if required_uses <= 0:
		return false
	return true 