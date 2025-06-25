extends EnemyBase
class_name EnemySpecial

@export var teleport_range: float = 200.0
@export var teleport_cooldown: float = 3.0
@export var teleport_damage: int = 25

var last_teleport_time: float = 0.0
var is_teleporting: bool = false

func _ready():
	super._ready()
	enemy_type = GameConstants.EnemyType.SPECIAL
	# 特殊敌人有更多生命值
	max_health = 100
	current_health = max_health
	# 特殊敌人的普通攻击冷却时间
	damage_cooldown = 1.5
	# 特殊敌人奖励最多信用点（最难击杀）
	credit_reward = 25

func enemy_ai(delta: float):
	var distance = get_distance_to_player()

	# 如果距离太远且可以传送，则传送到玩家附近
	if distance > teleport_range and can_teleport():
		teleport_to_player()
	elif distance > 80.0:
		# 正常追击
		var direction = get_direction_to_player()
		move_optimized(direction, delta)
	else:
		# 距离较近时减速移动
		var direction = get_direction_to_player()
		move_optimized(direction * 0.3, delta)

func can_teleport() -> bool:
	var current_time = Time.get_ticks_msec() / 1000.0
	return current_time - last_teleport_time >= teleport_cooldown and not is_teleporting

func teleport_to_player():
	if not player or is_teleporting:
		return

	is_teleporting = true
	last_teleport_time = Time.get_ticks_msec() / 1000.0

	# 传送效果 - 消失
	modulate.a = 0.3

	# 计算传送位置（玩家周围随机位置）
	var angle = randf() * 2 * PI
	var teleport_distance = randf_range(60.0, 100.0)
	var teleport_pos = player.global_position + Vector2(cos(angle), sin(angle)) * teleport_distance

	# 延迟传送
	await get_tree().create_timer(0.5).timeout

	global_position = teleport_pos

	# 恢复显示
	modulate.a = 1.0
	is_teleporting = false

	# 传送后立即重置伤害冷却，允许立即攻击
	last_damage_time = 0.0