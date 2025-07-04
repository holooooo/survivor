extends RefCounted
class_name ControlBuffEffect

## 控制buff效果 - 控制角色行为[br]
## 支持禁锢、无敌、沉默等控制效果

var buff_instance
var target: Actor
var is_applied: bool = false
var control_type: String = ""
var original_values: Dictionary = {}

func initialize(instance) -> void:
	buff_instance = instance
	target = instance.target

func apply() -> void:
	if is_applied:
		return
	
	is_applied = true
	_on_apply()

func remove() -> void:
	if not is_applied:
		return
	
	is_applied = false
	_on_remove()

func on_tick() -> void:
	pass

func get_effect_value(key: String, default_value = 0.0):
	if buff_instance and buff_instance.buff_resource:
		return buff_instance.buff_resource.get_effect_value(key, default_value)
	return default_value

## 应用控制效果[br]
func _on_apply() -> void:
	control_type = get_effect_value("control_type", "")
	
	match control_type:
		"immobilize":
			_apply_immobilize()
		"invincible":
			_apply_invincible()
		"silence":
			_apply_silence()
		"knockback":
			_apply_knockback()

## 移除控制效果[br]
func _on_remove() -> void:
	match control_type:
		"immobilize":
			_remove_immobilize()
		"invincible":
			_remove_invincible()
		"silence":
			_remove_silence()
		"knockback":
			_remove_knockback()

## 应用禁锢效果[br]
func _apply_immobilize() -> void:
	if not target:
		return
	
	# 禁用目标移动
	if target.has_method("set_movement_disabled"):
		target.set_movement_disabled(true)
	elif target.has_method("disable_movement"):
		target.disable_movement()
	elif target.has_property("can_move"):
		original_values["can_move"] = target.can_move
		target.can_move = false
	elif target.has_property("movement_disabled"):
		original_values["movement_disabled"] = target.movement_disabled
		target.movement_disabled = true
	elif target.has_property("speed"):
		original_values["speed"] = target.speed
		target.speed = 0

## 移除禁锢效果[br]
func _remove_immobilize() -> void:
	if not target:
		return
	
	# 恢复目标移动
	if target.has_method("set_movement_disabled"):
		target.set_movement_disabled(false)
	elif target.has_method("enable_movement"):
		target.enable_movement()
	elif target.has_property("can_move") and original_values.has("can_move"):
		target.can_move = original_values["can_move"]
	elif target.has_property("movement_disabled") and original_values.has("movement_disabled"):
		target.movement_disabled = original_values["movement_disabled"]
	elif target.has_property("speed") and original_values.has("speed"):
		target.speed = original_values["speed"]

## 应用无敌效果[br]
func _apply_invincible() -> void:
	if not target:
		return
	
	# 通过buff管理器设置无敌状态
	if target.has_method("set_invincible"):
		target.set_invincible(true)
	else:
		# 如果目标没有set_invincible方法，我们通过buff管理器来标记无敌状态
		# 这里不需要直接设置属性，因为Actor.is_invincible()方法会检查buff管理器
		pass

## 移除无敌效果[br]
func _remove_invincible() -> void:
	if not target:
		return
	
	# 恢复正常受伤
	if target.has_method("set_invincible"):
		target.set_invincible(false)
	else:
		# 无敌状态通过buff管理器自动管理，无需手动恢复
		pass

## 应用沉默效果[br]
func _apply_silence() -> void:
	if not target:
		return
	
	# 禁用技能使用
	if target.has_method("set_silenced"):
		target.set_silenced(true)
	else:
		# 沉默状态通过buff管理器自动管理
		pass

## 移除沉默效果[br]
func _remove_silence() -> void:
	if not target:
		return
	
	# 恢复技能使用
	if target.has_method("set_silenced"):
		target.set_silenced(false)
	else:
		# 沉默状态通过buff管理器自动管理
		pass

## 应用击退效果[br]
func _apply_knockback() -> void:
	if not target:
		return
	
	var knockback_direction = get_effect_value("knockback_direction", Vector2.ZERO)
	var knockback_strength = get_effect_value("knockback_strength", 200.0)
	
	# 先禁用移动
	_apply_immobilize()
	
	# 执行击退动画
	if target.has_method("apply_knockback"):
		target.apply_knockback(knockback_direction, knockback_strength)
	else:
		_apply_generic_knockback(knockback_direction, knockback_strength)

## 移除击退效果[br]
func _remove_knockback() -> void:
	# 恢复移动能力
	_remove_immobilize()

## 应用通用击退效果[br]
## [param direction] 击退方向[br]
## [param strength] 击退强度
func _apply_generic_knockback(direction: Vector2, strength: float) -> void:
	if not target.has_method("create_tween"):
		return
	
	var tween = target.create_tween()
	if not tween:
		return
	
	var start_position = target.global_position
	var target_position = start_position + direction * strength
	var duration = get_effect_value("knockback_duration", 0.3)
	
	tween.tween_property(target, "global_position", target_position, duration)
	
	# 发送击退信号
	FightEventBus.on_knockback_applied.emit(target, direction, strength) 