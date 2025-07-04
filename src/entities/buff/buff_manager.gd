extends Node
class_name BuffManager

## Buff管理器 - 管理角色身上的所有buff实例[br]
## 处理buff的添加、移除、更新、叠加等逻辑

var buff_owner: Actor
var active_buffs: Array = []
var buff_stacks: Dictionary = {}

signal buff_added(buff: Node)
signal buff_removed(buff: Node)

func _ready() -> void:
	buff_owner = get_parent() as Actor
	if not buff_owner:
		push_error("BuffManager必须作为Actor的子节点")

func _process(delta: float) -> void:
	_update_all_buffs(delta)

## 添加buff[br]
## [param buff_resource] buff资源[br]
## [param caster] 施法者[br]
## [returns] 是否成功添加
func add_buff(buff_resource: BuffResource, caster: Actor = null) -> bool:
	if not buff_resource or not buff_resource.is_valid():
		print("buff_resource is not valid")
		return false
	
	# 检查是否已存在相同buff
	if buff_resource.stackable:
		# 可叠加buff，查找现有实例
		for existing_buff in active_buffs:
			if existing_buff.buff_resource.buff_id == buff_resource.buff_id:
				# 找到相同buff，增加层数
				var old_stacks = existing_buff.current_stacks
				existing_buff.add_stacks(1)
				var new_stacks = existing_buff.current_stacks
				
				# 发送层数变化事件
				FightEventBus.buff_stacks_changed.emit(buff_owner, existing_buff, old_stacks, new_stacks)
				FightEventBus.buff_applied.emit(buff_owner, existing_buff)
				
				# 检查特殊buff的触发条件
				_check_special_buff_triggers(existing_buff)
				return true
	else:
		# 不可叠加buff，检查是否已存在
		for existing_buff in active_buffs:
			if existing_buff.buff_resource.buff_id == buff_resource.buff_id:
				# 已存在，刷新持续时间
				if buff_resource.stack_refresh_duration:
					existing_buff.remaining_duration = buff_resource.duration
				# 对于收割标记，即使已存在也要检查全局触发条件
				if buff_resource.buff_id == "harvest_mark":
					_check_global_harvest_triggers()
				return true
	
	# 创建新buff实例
	var new_buff = buff_resource.create_buff_instance(buff_owner, caster, null, null)
	if not new_buff:
		print("creat buff instance failed")
		return false
	
	# 连接信号
	new_buff.buff_expired.connect(_on_buff_expired)
	
	# 添加到管理列表
	active_buffs.append(new_buff)
	
	# 发送事件
	buff_added.emit(new_buff)
	FightEventBus.buff_applied.emit(buff_owner, new_buff)
	
	# 对于收割标记，检查全局触发条件
	if buff_resource.buff_id == "harvest_mark":
		_check_global_harvest_triggers()
	
	return true

## 更新所有buff[br]
## [param delta] 时间增量
func _update_all_buffs(delta: float) -> void:
	var expired_buffs: Array = []
	
	for buff in active_buffs:
		if buff.is_expired:
			expired_buffs.append(buff)
			continue
		
		buff.update(delta)
		
		# 检查特殊buff的触发条件（如生命值变化）
		_check_special_buff_triggers(buff)
		
		if buff.is_expired:
			expired_buffs.append(buff)
	
	# 清理过期buff
	for buff in expired_buffs:
		_remove_buff_from_list(buff)

## 从列表中移除buff[br]
## [param buff] buff实例
func _remove_buff_from_list(buff) -> void:
	var index = active_buffs.find(buff)
	if index >= 0:
		active_buffs.remove_at(index)

## buff过期事件处理[br]
## [param buff] 过期的buff
func _on_buff_expired(buff) -> void:
	buff_removed.emit(buff)
	FightEventBus.buff_removed.emit(buff_owner, buff)
	_remove_buff_from_list(buff)

## 获取buff修改器[br]
## [returns] 属性修改器字典
func get_buff_modifiers() -> Dictionary:
	var modifiers: Dictionary = {}
	
	for buff in active_buffs:
		if buff.is_expired:
			continue
		
		# 合并buff的属性修改器
		if buff.has("applied_modifiers"):
			for key in buff.applied_modifiers:
				if not modifiers.has(key):
					modifiers[key] = 0.0
				modifiers[key] += buff.applied_modifiers[key]
	
	return modifiers

## 检查是否有指定buff[br]
## [param buff_id] buff ID[br]
## [return] 是否存在
func has_buff(buff_id: String) -> bool:
	for buff in active_buffs:
		if buff.buff_resource.buff_id == buff_id:
			return true
	return false

## 检查是否有指定控制效果[br]
## [param control_type] 控制类型[br]
## [return] 是否存在
func has_control_effect(control_type: String) -> bool:
	for buff in active_buffs:
		if buff.buff_resource.effect_type == Constants.BuffEffectType.控制效果:
			var control_buff_type = buff.buff_resource.get_effect_value("control_type", "")
			if control_buff_type == control_type:
				return true
	return false

## 应用伤害修正[br]
## [param damage] 原始伤害[br]
## [param damage_type] 伤害类型[br]
## [return] 修正后的伤害
func apply_damage_modifiers(damage: int, damage_type: int = 0) -> int:
	var final_damage = damage
	
	for buff in active_buffs:
		if buff.buff_resource.effect_type == Constants.BuffEffectType.属性修改:
			var damage_multiplier = buff.buff_resource.get_effect_value("damage_multiplier", 1.0)
			final_damage = int(final_damage * damage_multiplier)
	
	return final_damage

## 移除指定buff[br]
## [param buff_id] buff ID[br]
## [return] 是否成功移除
func remove_buff(buff_id: String) -> bool:
	for buff in active_buffs:
		if buff.buff_resource.buff_id == buff_id:
			buff.expire_immediately()
			return true
	return false

## 检查特殊buff的触发条件[br]
## [param buff] buff实例
func _check_special_buff_triggers(buff) -> void:
	if not buff or not buff.buff_resource:
		return
	
	# 检查收割标记的触发条件
	if buff.buff_resource.buff_id == "harvest_mark":
		var harvest_damage = buff.buff_resource.get_effect_value("harvest_damage", 75)
		
		# 条件：敌人生命值小于harvest_damage
		if buff_owner and buff_owner.current_health < harvest_damage:
			print("敌人生命值过低: %d < %d，触发收割" % [buff_owner.current_health, harvest_damage])
			buff.expire_immediately()

## 检查全局收割标记触发条件[br]
func _check_global_harvest_triggers() -> void:
	# 统计全局收割标记数量
	var total_harvest_marks = _count_global_harvest_marks()
	var harvest_threshold = 5
	
	print("当前全局收割标记数量: %d" % total_harvest_marks)
	
	# 如果全局标记数量 > 5，触发所有收割标记
	if total_harvest_marks > harvest_threshold:
		print("全局收割标记数量超过阈值: %d > %d，触发所有收割" % [total_harvest_marks, harvest_threshold])
		_trigger_all_harvest_marks()

## 统计全局收割标记数量[br]
## [returns] 全局收割标记总数
func _count_global_harvest_marks() -> int:
	var count = 0
	
	# 获取所有敌人
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in all_enemies:
		if enemy and is_instance_valid(enemy) and not enemy.is_dead:
			if enemy.has_buff("harvest_mark"):
				count += 1
	
	return count

## 触发所有收割标记[br]
func _trigger_all_harvest_marks() -> void:
	# 获取所有敌人
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in all_enemies:
		if enemy and is_instance_valid(enemy) and not enemy.is_dead:
			if enemy.has_buff("harvest_mark"):
				enemy.remove_buff("harvest_mark")

## 获取buff层数[br]
## [param buff_id] buff ID[br]
## [return] buff层数，没有则返回0
func get_buff_stacks(buff_id: String) -> int:
	for buff in active_buffs:
		if buff.buff_resource.buff_id == buff_id:
			return buff.current_stacks
	return 0 