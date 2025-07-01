extends HitEffectResource
class_name KnockbackHitEffect

## 击退命中效果 - 命中敌人时使其向投射物运动方向击退[br]
## 继承自现有Bomb投射物的击退实现

@export_group("击退配置")
@export var knockback_strength: float = 200.0 ## 击退力度
@export var knockback_duration: float = 0.3 ## 击退持续时间
@export var apply_to_all_damage_types: bool = true ## 是否适用于所有伤害类型

func _init():
	effect_name = "击退效果"
	effect_id = "knockback"

## 重写执行效果方法[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例[br]
## [param target] 目标节点[br]
## [param hit_info] 命中信息字典
func execute_effect(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, hit_info: Dictionary) -> void:
	if not target or not player:
		return
	
	# 计算击退方向：从玩家指向敌人的方向
	var knockback_direction: Vector2 = (target.global_position - player.global_position).normalized()
	
	# 延迟执行击退效果，避免在物理查询期间修改状态
	call_deferred("_apply_knockback_deferred", target, knockback_direction)

## 延迟应用击退效果[br]
## [param target] 目标节点[br]
## [param knockback_direction] 击退方向
func _apply_knockback_deferred(target: Node, knockback_direction: Vector2) -> void:
	if not target:
		return
	
	# 如果目标有击退方法，直接使用
	if target.has_method("apply_knockback"):
		target.apply_knockback(knockback_direction, knockback_strength)
		
		# 发送击退信号
		FightEventBus.on_knockback_applied.emit(target, knockback_direction, knockback_strength)
		return
	
	# 通用击退实现（适用于没有专门击退方法的目标）
	_apply_generic_knockback(target, knockback_direction)

## 应用通用击退效果[br]
## [param target] 目标节点[br]
## [param direction] 击退方向
func _apply_generic_knockback(target: Node, direction: Vector2) -> void:
	# 检查目标是否有位置属性
	if not target.has_method("get_global_position") and not target.has_property("global_position"):
		return
	
	# 禁用敌人移动（如果目标有相关方法）
	_disable_target_movement(target)
	
	# 使用Tween实现击退动画
	var tween = target.create_tween()
	if not tween:
		# 如果无法创建Tween，恢复移动能力
		_enable_target_movement(target)
		return
	
	var start_position = target.global_position
	var target_position = start_position + direction * knockback_strength
	
	# 击退动画：只向远离玩家方向移动，不回弹
	tween.tween_property(target, "global_position", target_position, knockback_duration)
	
	# 击退结束后恢复敌人移动能力
	tween.tween_callback(func(): _enable_target_movement(target))
	
	# 发送击退信号
	FightEventBus.on_knockback_applied.emit(target, direction, knockback_strength)

## 禁用目标移动[br]
## [param target] 目标节点
func _disable_target_movement(target: Node) -> void:
	# 检查目标是否有禁用移动的方法
	if target.has_method("set_movement_disabled"):
		target.set_movement_disabled(true)
	elif target.has_method("disable_movement"):
		target.disable_movement()
	elif target.has_property("can_move"):
		target.can_move = false
	elif target.has_property("movement_disabled"):
		target.movement_disabled = true
	# 如果目标有速度属性，可以临时保存并设为0
	elif target.has_property("speed"):
		if not target.has_meta("original_speed"):
			target.set_meta("original_speed", target.speed)
		target.speed = 0

## 恢复目标移动[br]
## [param target] 目标节点
func _enable_target_movement(target: Node) -> void:
	# 检查目标是否有恢复移动的方法
	if target.has_method("set_movement_disabled"):
		target.set_movement_disabled(false)
	elif target.has_method("enable_movement"):
		target.enable_movement()
	elif target.has_property("can_move"):
		target.can_move = true
	elif target.has_property("movement_disabled"):
		target.movement_disabled = false
	# 恢复原始速度
	elif target.has_property("speed") and target.has_meta("original_speed"):
		target.speed = target.get_meta("original_speed")
		target.remove_meta("original_speed")

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
	
	# 检查目标是否支持击退
	if not _can_target_be_knocked_back(target):
		return false
	
	return true

## 检查目标是否可以被击退[br]
## [param target] 目标节点[br]
## [returns] 是否可以击退
func _can_target_be_knocked_back(target: Node) -> bool:
	# 检查目标是否有击退方法
	if target.has_method("apply_knockback"):
		return true
	
	# 检查目标是否有位置属性（用于通用击退）
	if target.has_method("get_global_position") or target.has_property("global_position"):
		return true
	
	return false

## 获取效果描述[br]
## [returns] 效果描述文本
func get_description() -> String:
	var desc = "向远离玩家方向击退敌人 %.0f 像素，禁用移动 %.1f 秒" % [knockback_strength, knockback_duration]
	if trigger_probability < 1.0:
		desc += "（%.0f%% 概率）" % (trigger_probability * 100)
	if cooldown_time > 0:
		desc += "（冷却 %.1f秒）" % cooldown_time
	return desc 