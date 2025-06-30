extends ModResource
class_name LifeStealOnKillMod

## 击杀回复模组 - Hook系统示例[br]
## 当装备击杀敌人时，恢复玩家生命值

## 重写击杀敌人时的Hook[br]
## [param context] 上下文数据
func _on_kill_hook(context: Dictionary) -> void:
	super._on_kill_hook(context)
	
	var equipment = context.get("equipment", null)
	var target = context.get("target", null)
	
	if not equipment or not equipment.owner_player:
		return
	
	var heal_amount = effect_config.get("heal_amount", 10)
	var player = equipment.owner_player
	
	# 检查玩家是否有治疗方法
	if player.has_method("heal"):
		player.heal(heal_amount)
		print("击杀敌人！恢复生命值: ", heal_amount)
	elif player.has_method("add_health"):
		player.add_health(heal_amount)
		print("击杀敌人！增加生命值: ", heal_amount)
	else:
		print("击杀敌人！但玩家没有生命值系统")

## 重写装备时的Hook[br]
## [param context] 上下文数据
func _on_equip_hook(context: Dictionary) -> void:
	super._on_equip_hook(context)
	print("装备击杀回复mod，每次击杀敌人将恢复 ", effect_config.get("heal_amount", 10), " 点生命值") 