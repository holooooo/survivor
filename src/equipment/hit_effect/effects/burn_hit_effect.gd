extends HitEffectResource
class_name BurnHitEffect

## 灼烧命中效果 - 命中敌人时施加灼烧debuff[br]
## 灼烧效果持续5秒，每秒造成火焰伤害，最多叠加5层

@export_group("灼烧配置")
@export var burn_buff_resource: BuffResource ## 灼烧buff资源
@export var burn_damage_per_tick: int = 5 ## 每次tick伤害
@export var burn_duration: float = 5.0 ## 持续时间
@export var max_stacks: int = 5 ## 最大叠加层数

func _init():
	effect_name = "灼烧效果"
	effect_id = "burn"
	trigger_probability = 1.0
	
## 重写执行效果方法[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例[br]
## [param target] 目标节点[br]
## [param hit_info] 命中信息字典
func execute_effect(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, hit_info: Dictionary) -> void:
	if not player or not target:
		return
	
	# 检查目标是否是Actor（有buff系统）
	if not target is Actor:
		return
	
	var target_actor = target as Actor
	
	# 延迟执行，避免在物理查询期间修改状态
	_apply_burn_buff_deferred(player, target_actor, hit_info)

## 延迟应用灼烧buff[br]
## [param caster] 施法者（玩家）[br]
## [param target] 目标actor[br]
## [param hit_info] 命中信息
func _apply_burn_buff_deferred(caster: Actor, target: Actor, hit_info: Dictionary) -> void:
	if not caster or not target or not is_instance_valid(caster) or not is_instance_valid(target):
		return
	
	# 检查目标是否已死亡
	if target.is_dead:
		return
	
	# 获取或创建灼烧buff资源
	var buff_resource = burn_buff_resource
	if not buff_resource:
		buff_resource = _create_burn_buff_resource()
	
	# 应用灼烧buff
	var success = target.add_buff(buff_resource, caster)
	
	if success:
		# 发送灼烧效果触发信号
		var buff_manager = target.get_buff_manager()
		if buff_manager and buff_manager.has_method("active_buffs") and not buff_manager.active_buffs.is_empty():
			FightEventBus.buff_applied.emit(target, buff_manager.active_buffs[-1])
		
		# 显示灼烧效果文字
		_show_burn_effect_text(target)
		
		print("对 %s 施加了灼烧效果" % target.name)

## 创建灼烧buff资源[br]
## [returns] 灼烧buff资源
func _create_burn_buff_resource() -> BuffResource:
	var buff = BuffResource.new()
	
	buff.buff_name = "灼烧"
	buff.buff_id = "burn_dot"
	buff.buff_description = "每秒受到%d点火焰伤害，最多叠加%d层" % [burn_damage_per_tick, max_stacks]
	buff.buff_type = Constants.BuffType.减益
	buff.effect_type = Constants.BuffEffectType.持续伤害
	buff.duration = burn_duration
	buff.is_permanent = false
	buff.stackable = true
	buff.max_stacks = max_stacks
	buff.stack_refresh_duration = false
	buff.trigger_probability = 1.0
	buff.apply_to_all_damage_types = true
	
	# 设置效果值
	buff.set_effect_value("damage_per_tick", burn_damage_per_tick)
	buff.set_effect_value("damage_type", Constants.DamageType.火焰)
	buff.set_effect_value("tick_interval", 1.0)
	
	return buff

## 显示灼烧效果文字[br]
## [param target] 目标
func _show_burn_effect_text(target: Actor) -> void:
	# 不显示伤害数字，灼烧状态提示由其他方式处理
	# 真正的灼烧伤害会在DOTBuffEffect的tick中显示
	pass

## 重写触发条件检查[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例[br]
## [param target] 目标节点[br]
## [param damage] 造成的伤害[br]
## [param damage_type] 伤害类型[br]
## [param is_critical] 是否暴击[br]
## [param is_kill] 是否击杀[br]
## [returns] 是否可以触发
func can_trigger(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, damage: int, damage_type: Constants.DamageType, is_critical: bool = false, is_kill: bool = false) -> bool:
	# 先检查基类条件
	if not super.can_trigger(player, equipment, projectile, target, damage, damage_type, is_critical, is_kill):
		return false
	
	# 检查目标是否是Actor
	if not target is Actor:
		return false
	
	var target_actor = target as Actor
	
	# 检查目标是否已死亡
	if target_actor.is_dead:
		return false
	
	# 检查目标是否已经有最大层数的灼烧buff
	var current_stacks = _get_burn_stack_count(target_actor)
	if current_stacks >= max_stacks:
		return false
	
	return true

## 获取目标当前的灼烧层数[br]
## [param target] 目标actor[br]
## [returns] 当前灼烧层数
func _get_burn_stack_count(target: Actor) -> int:
	var buff_manager = target.get_buff_manager()
	if not buff_manager or not buff_manager.has_method("active_buffs"):
		return 0
	
	var stack_count = 0
	for buff in buff_manager.active_buffs:
		if buff.buff_resource.buff_id == "burn_dot":
			stack_count += 1
	
	return stack_count

## 获取效果描述[br]
## [returns] 效果描述文本
func get_description() -> String:
	var desc = "施加灼烧：每秒造成%d点火焰伤害，持续%.1f秒，最多%d层" % [burn_damage_per_tick, burn_duration, max_stacks]
	if trigger_probability < 1.0:
		desc += "（%.0f%% 概率）" % (trigger_probability * 100)
	if cooldown_time > 0:
		desc += "（冷却 %.1f秒）" % cooldown_time
	return desc

## 验证配置的有效性[br]
## [returns] 是否有效
func is_valid() -> bool:
	if not super.is_valid():
		return false
	
	if burn_damage_per_tick <= 0:
		return false
	
	if burn_duration <= 0:
		return false
	
	if max_stacks <= 0:
		return false
	
	return true