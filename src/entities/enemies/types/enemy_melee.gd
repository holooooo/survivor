extends EnemyBase
class_name EnemyMelee

## 近战敌人 - 直接冲向玩家进行攻击[br]
## 使用基类的距离检测系统进行伤害判定

func _ready():
	super._ready()
	enemy_type = GameConstants.EnemyType.MELEE
	# 近战敌人的伤害冷却时间较短
	damage_cooldown = 0.5

func enemy_ai(delta: float):
	# 追击玩家，使用优化的移动方法
	var direction = get_direction_to_player()
	move_optimized(direction, delta)
