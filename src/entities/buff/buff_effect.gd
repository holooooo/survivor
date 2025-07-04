extends RefCounted
class_name BuffEffect

## Buff效果基类 - 定义buff效果的通用接口[br]
## 子类实现具体的效果逻辑

var buff_instance: BuffInstance
var target: Actor
var is_applied: bool = false

## 初始化效果[br]
## [param instance] buff实例
func initialize(instance: BuffInstance) -> void:
	buff_instance = instance
	target = instance.target

## 应用效果[br]
func apply() -> void:
	if is_applied:
		return
	
	is_applied = true
	_on_apply()

## 移除效果[br]
func remove() -> void:
	if not is_applied:
		return
	
	is_applied = false
	_on_remove()

## 处理tick事件[br]
func on_tick() -> void:
	if not is_applied:
		return
	
	_on_tick()

## 处理暂停[br]
func on_pause() -> void:
	_on_pause()

## 处理恢复[br]
func on_resume() -> void:
	_on_resume()

## 处理层数变化[br]
## [param new_stacks] 新的层数
func on_stacks_changed(new_stacks: int) -> void:
	_on_stacks_changed(new_stacks)

## 子类重写的应用逻辑[br]
func _on_apply() -> void:
	pass

## 子类重写的移除逻辑[br]
func _on_remove() -> void:
	pass

## 子类重写的tick逻辑[br]
func _on_tick() -> void:
	pass

## 子类重写的暂停逻辑[br]
func _on_pause() -> void:
	pass

## 子类重写的恢复逻辑[br]
func _on_resume() -> void:
	pass

## 子类重写的层数变化逻辑[br]
## [param new_stacks] 新的层数
func _on_stacks_changed(new_stacks: int) -> void:
	pass

## 获取效果配置值[br]
## [param key] 配置键[br]
## [param default_value] 默认值[br]
## [returns] 配置值
func get_effect_value(key: String, default_value = 0.0):
	if buff_instance and buff_instance.buff_resource:
		return buff_instance.buff_resource.get_effect_value(key, default_value)
	return default_value 