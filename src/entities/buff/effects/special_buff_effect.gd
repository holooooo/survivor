extends RefCounted
class_name SpecialBuffEffect

## 特殊buff效果 - 处理特殊机制效果[br]
## 支持收割标记、特殊触发条件等复杂效果

var buff_instance
var target: Actor
var is_applied: bool = false
var effect_type: String = ""
var effect_data: Dictionary = {}

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
	if not is_applied:
		return
	
	_on_tick()

func get_effect_value(key: String, default_value = 0.0):
	if buff_instance and buff_instance.buff_resource:
		return buff_instance.buff_resource.get_effect_value(key, default_value)
	return default_value

## 应用特殊效果[br]
func _on_apply() -> void:
	effect_type = get_effect_value("effect_type", "")
	
	match effect_type:
		"harvest_mark":
			_apply_harvest_mark()
		"collection_mark":
			_apply_collection_mark()
		_:
			_apply_generic_special_effect()

## 移除特殊效果[br]
func _on_remove() -> void:
	match effect_type:
		"harvest_mark":
			_remove_harvest_mark()
		"collection_mark":
			_remove_collection_mark()
		_:
			_remove_generic_special_effect()

## 处理tick事件[br]
func _on_tick() -> void:
	match effect_type:
		"harvest_mark":
			_tick_harvest_mark()

## 应用收割标记效果[br]
func _apply_harvest_mark() -> void:
	if not target:
		return
	
	# 添加视觉标记
	_add_visual_mark("harvest")
	
	# 存储收割相关数据
	effect_data["harvest_damage"] = get_effect_value("harvest_damage", 75)
	effect_data["max_marks"] = get_effect_value("max_marks", 5)
	
	print("应用收割标记到: ", target.name)

## 移除收割标记效果[br]
func _remove_harvest_mark() -> void:
	if not target:
		return
	
	# 触发收割伤害
	_trigger_harvest_damage()
	
	# 移除视觉标记
	_remove_visual_mark("harvest")
	
	print("移除收割标记: ", target.name)

## 收割标记tick处理[br]
func _tick_harvest_mark() -> void:
	# 收割标记的触发条件现在由BuffManager统一管理
	# 这里只需要检查生命值条件，全局计数由BuffManager处理
	pass

## 触发收割伤害[br]
func _trigger_harvest_damage() -> void:
	if not target:
		return
	
	var harvest_damage = get_effect_value("harvest_damage", 75)
	
	# 应用玩家属性加成
	var final_damage = harvest_damage
	if buff_instance.caster and buff_instance.caster.has_method("get_stats_manager"):
		var stats_manager = buff_instance.caster.get_stats_manager()
		if stats_manager:
			var damage_multiplier = stats_manager.get_damage_multiplier(Constants.DamageType.能量)
			final_damage = int(final_damage * damage_multiplier)
	
	# 造成收割伤害
	target.take_damage(final_damage)
	
	# 显示伤害数字
	var damage_color = Constants.get_damage_type_color(Constants.DamageType.能量)
	EventBus.show_damage_number(final_damage, target.global_position, damage_color)
	
	# 发送收割事件
	if buff_instance.caster:
		FightEventBus.on_projectile_hit.emit(
			buff_instance.caster,
			null, # 没有具体装备
			null, # 没有投射物
			target,
			final_damage,
			Constants.DamageType.能量
		)
	
	# 发送buff特殊事件
	FightEventBus.buff_triggered.emit(target, buff_instance, "harvest_triggered")
	
	print("触发收割伤害: %d点" % final_damage)

## 应用收集标记效果[br]
func _apply_collection_mark() -> void:
	_add_visual_mark("collection")

## 移除收集标记效果[br]
func _remove_collection_mark() -> void:
	_remove_visual_mark("collection")

## 应用通用特殊效果[br]
func _apply_generic_special_effect() -> void:
	print("应用通用特殊效果: ", effect_type)

## 移除通用特殊效果[br]
func _remove_generic_special_effect() -> void:
	print("移除通用特殊效果: ", effect_type)

## 添加视觉标记[br]
## [param mark_type] 标记类型
func _add_visual_mark(mark_type: String) -> void:
	if not target:
		return
	
	var mark_name = mark_type + "_mark"
	
	# 检查是否已经有标记
	if target.get_node_or_null(mark_name):
		return
	
	# 创建标记图标
	var mark_icon = Sprite2D.new()
	mark_icon.name = mark_name
	mark_icon.texture = load("res://icon.svg")
	mark_icon.scale = Vector2(0.2, 0.2)
	mark_icon.position = Vector2(0, -30)
	
	# 根据标记类型设置颜色
	match mark_type:
		"harvest":
			mark_icon.modulate = Color.MAGENTA
		"collection":
			mark_icon.modulate = Color.CYAN
		_:
			mark_icon.modulate = Color.YELLOW
	
	target.add_child(mark_icon)
	
	# 添加闪烁效果
	var tween = mark_icon.create_tween()
	tween.set_loops(-1)
	tween.tween_property(mark_icon, "modulate:a", 0.5, 0.5)
	tween.tween_property(mark_icon, "modulate:a", 1.0, 0.5)

## 移除视觉标记[br]
## [param mark_type] 标记类型
func _remove_visual_mark(mark_type: String) -> void:
	if not target:
		return
	
	var mark_name = mark_type + "_mark"
	var mark_icon = target.get_node_or_null(mark_name)
	if mark_icon:
		mark_icon.queue_free() 