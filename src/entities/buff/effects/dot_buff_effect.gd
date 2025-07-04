extends RefCounted
class_name DOTBuffEffect

## 持续伤害buff效果 - 每秒对目标造成伤害[br]
## 支持不同伤害类型，可触发FightEventBus事件

var buff_instance
var target: Actor
var is_applied: bool = false
var damage_per_tick: int = 0
var damage_type: Constants.DamageType = Constants.DamageType.毒素

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
		var value = buff_instance.buff_resource.get_effect_value(key, default_value)
		print("获取效果值 - key: %s, value: %s, default: %s" % [key, str(value), str(default_value)])
		return value
	print("获取效果值失败 - buff_instance或buff_resource为空，返回默认值: %s" % str(default_value))
	return default_value

## 应用持续伤害效果[br]
func _on_apply() -> void:
	damage_per_tick = int(get_effect_value("damage_per_tick", 10))
	damage_type = get_effect_value("damage_type", Constants.DamageType.毒素)
	print("DOT效果初始化 - damage_per_tick: %d, damage_type: %d" % [damage_per_tick, damage_type])

## 移除持续伤害效果[br]
func _on_remove() -> void:
	# 持续伤害效果无需特殊清理
	pass

## 处理tick事件 - 每秒造成伤害[br]
func _on_tick() -> void:
	if not target or target.is_dead:
		return
	
	# 计算最终伤害（考虑层数）
	var final_damage = damage_per_tick * buff_instance.current_stacks
	
	print("DOT tick - damage_per_tick: %d, stacks: %d, final_damage: %d" % [damage_per_tick, buff_instance.current_stacks, final_damage])
	
	# 只有伤害大于0时才造成伤害和显示数字
	if final_damage > 0:
		# 对目标造成伤害
		target.take_damage(final_damage)
		
		# 显示伤害数字
		var damage_color = Constants.get_damage_type_color(damage_type)
		EventBus.show_damage_number(final_damage, target.global_position, damage_color)
		
		# 发送持续伤害事件
		_trigger_damage_event(final_damage)
	else:
		print("警告：DOT伤害为0，跳过伤害处理")

## 处理层数变化[br]
## [param new_stacks] 新的层数
func _on_stacks_changed(new_stacks: int) -> void:
	# 持续伤害效果会在下次tick时自动使用新的层数
	pass

## 触发伤害事件[br]
## [param damage] 造成的伤害
func _trigger_damage_event(damage: int) -> void:
	# 构造虚拟投射物用于事件触发
	var virtual_projectile = null
	if buff_instance.projectile:
		virtual_projectile = buff_instance.projectile
	
	# 触发投射物命中事件
	if buff_instance.equipment and buff_instance.caster:
		FightEventBus.on_projectile_hit.emit(
			buff_instance.caster, 
			buff_instance.equipment, 
			virtual_projectile, 
			target, 
			damage, 
			damage_type
		)
	
	# 触发buff特殊事件
	FightEventBus.buff_triggered.emit(target, buff_instance, "dot_damage") 