extends HitEffectResource
class_name VampireHitEffect

## 吸血命中效果 - 命中敌人时根据造成的伤害恢复玩家生命值[br]
## 基于伤害百分比计算恢复量，无恢复上限

@export_group("吸血配置")
@export var heal_ratio: float = 0.05 ## 吸血比例（默认5%）
@export var apply_to_all_damage_types: bool = true ## 是否适用于所有伤害类型

func _init():
	effect_name = "吸血效果"
	effect_id = "vampire"

## 重写执行效果方法[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例[br]
## [param target] 目标节点[br]
## [param hit_info] 命中信息字典
func execute_effect(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, hit_info: Dictionary) -> void:
	if not player or not hit_info.has("damage"):
		return
	
	var damage_dealt: int = hit_info.damage
	var heal_amount: int = int(damage_dealt * heal_ratio)
	
	if heal_amount > 0:
		# 延迟执行恢复，避免在物理查询期间修改状态
		call_deferred("_apply_heal_deferred", player, heal_amount)

## 延迟应用治疗效果[br]
## [param player] 玩家实例[br]
## [param heal_amount] 恢复量
func _apply_heal_deferred(player: Player, heal_amount: int) -> void:
	if not player or not is_instance_valid(player):
		return
	
	# 恢复玩家生命值
	player.heal(heal_amount)
	
	# 发送吸血信号（可用于统计或其他系统）
	FightEventBus.on_vampire_heal.emit(player, heal_amount)

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
	
	# 检查玩家是否需要治疗（生命值未满）
	if player.current_health >= player.max_health:
		return false
	
	# 检查伤害值是否大于0
	if damage <= 0:
		return false
	
	return true

## 获取效果描述[br]
## [returns] 效果描述文本
func get_description() -> String:
	var desc = "恢复造成伤害 %.0f%% 的生命值" % (heal_ratio * 100)
	if trigger_probability < 1.0:
		desc += "（%.0f%% 概率）" % (trigger_probability * 100)
	if cooldown_time > 0:
		desc += "（冷却 %.1f秒）" % cooldown_time
	return desc 