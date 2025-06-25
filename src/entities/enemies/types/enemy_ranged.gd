extends EnemyBase

## 远程敌人 - 会射击子弹攻击玩家[br]
## 保持距离并发射子弹

@export var attack_range: float = 300.0
@export var min_distance: float = 150.0
@export var bullet_speed: float = 200.0
var bullet_scene = preload("res://src/scenes/common/prefabs/bullet.tscn")
var active_bullets: int = 0 ## 当前活跃子弹数量

var last_shot_time: float = 0.0
var shot_cooldown: float = 2.0

func _ready() -> void:
	super ()
	enemy_type = GameConstants.EnemyType.RANGED
	# 远程敌人奖励更多信用点（因为更难击杀）
	credit_reward = 15

func enemy_ai(delta: float) -> void:
	if not player:
		return

	var distance_to_player = get_distance_to_player()
	var direction_to_player = get_direction_to_player()
	var movement_direction: Vector2 = Vector2.ZERO

	# 如果太靠近玩家，后退
	if distance_to_player < min_distance:
		movement_direction = - direction_to_player
		move_optimized(movement_direction, delta)
	# 如果在攻击范围内，停止移动并攻击
	elif distance_to_player <= attack_range:
		attempt_shoot()
	# 如果太远，接近玩家到攻击范围（使用一半速度）
	else:
		movement_direction = direction_to_player * 0.5
		move_optimized(movement_direction, delta)

func attempt_shoot() -> void:
	var current_time = Time.get_time_dict_from_system()["second"] + Time.get_time_dict_from_system()["minute"] * 60

	if current_time - last_shot_time >= shot_cooldown:
		shoot()
		last_shot_time = current_time

func shoot() -> void:
	if not player:
		return

	# 限制每个敌人的子弹数量
	if active_bullets >= 3:
		return

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position

	var direction = get_direction_to_player()
	bullet.setup(direction, bullet_speed, damage)

	active_bullets += 1

	# 连接子弹销毁信号来减少计数
	bullet.tree_exited.connect(_on_bullet_destroyed)

## 子弹销毁时的回调[br]
## 减少活跃子弹计数
func _on_bullet_destroyed() -> void:
	active_bullets = max(0, active_bullets - 1)