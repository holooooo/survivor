extends Node2D
class_name EnemySpawner

## 敌人生成器 - 负责管理敌人的生成逻辑[br]
## 根据游戏进度和波次动态调整敌人生成

@export var enemy_scenes: Array[PackedScene] = []
@export var base_spawn_interval: float = 2.0
@export var min_spawn_interval: float = 0.5
@export var extra_spawn_distance: float = 50.0  ## 额外的生成距离，避免玩家快速移动时看到敌人出现
@export var enemies_per_spawn: int = 1  ## 每次生成的敌人数量
@export var max_enemies: int = 50  ## 敌人数量上限

var spawn_timer: Timer

var current_spawn_interval: float
var spawn_distance: float = GameConstants.SPAWN_DISTANCE_FROM_SCREEN
var current_enemy_count: int = 0  ## 当前敌人数量

func _ready() -> void:
	current_spawn_interval = base_spawn_interval
	
	# 创建定时器
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	
	spawn_timer.wait_time = current_spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	
	# 连接事件
	EventBus.game_started.connect(_on_game_started)
	EventBus.wave_completed.connect(_on_wave_completed)
	EventBus.enemy_died.connect(_on_enemy_died)

## 开始生成敌人
func start_spawning() -> void:
	spawn_timer.start()

## 停止生成敌人  
func stop_spawning() -> void:
	spawn_timer.stop()

## 生成敌人（可能生成多个）[br]
## 在屏幕边缘外的远距离位置生成敌人，避免玩家看到凭空出现
func spawn_enemy() -> void:
	if enemy_scenes.is_empty():
		push_warning("敌人场景列表为空，无法生成敌人")
		return
	
	# 检查是否达到敌人上限
	if current_enemy_count >= max_enemies:
		return
	
	# 计算本次实际生成数量（不超过上限）
	var enemies_to_spawn: int = min(enemies_per_spawn, max_enemies - current_enemy_count)
	
	# 获取玩家位置用于动态生成计算
	var player: Node = get_tree().get_first_node_in_group("player")
	
	for i in range(enemies_to_spawn):
		# 随机选择敌人类型
		var scene_to_spawn: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
		var new_enemy: Node2D = scene_to_spawn.instantiate()
		
		# 计算生成位置
		var spawn_position: Vector2
		if player:
			# 使用基于玩家位置的动态生成，根据玩家移动速度调整距离
			var dynamic_distance: float = get_dynamic_spawn_distance(player)
			spawn_position = MathUtils.get_respawn_position_around_player(player.global_position, dynamic_distance)
		else:
			# 备用方案：使用传统的屏幕边缘生成
			var screen_size: Vector2 = get_viewport_rect().size
			var total_spawn_distance: float = spawn_distance + extra_spawn_distance
			spawn_position = MathUtils.get_random_spawn_position(screen_size, total_spawn_distance)
		
		new_enemy.global_position = spawn_position
		add_child(new_enemy)
		
		# 更新敌人计数
		current_enemy_count += 1
		
		# 发送敌人生成事件
		EventBus.enemy_spawned.emit(new_enemy)

## 设置生成间隔[br]
## [param interval] 新的生成间隔时间
func set_spawn_interval(interval: float) -> void:
	current_spawn_interval = max(min_spawn_interval, interval)
	spawn_timer.wait_time = current_spawn_interval

## 根据波次调整生成速度[br]
## [param wave_number] 当前波次
func adjust_spawn_rate_for_wave(wave_number: int) -> void:
	# 每波减少生成间隔，但不低于最小值
	var new_interval: float = base_spawn_interval - (wave_number - 1) * 0.1
	set_spawn_interval(new_interval)

## 定时器超时处理
func _on_spawn_timer_timeout() -> void:
	if can_spawn_enemies():
		spawn_enemy()
	else:
		# 如果达到上限，可以选择暂停生成或继续检查
		pass

## 游戏开始处理
func _on_game_started() -> void:
	start_spawning()

## 波次完成处理[br]
## [param wave_number] 完成的波次编号
func _on_wave_completed(wave_number: int) -> void:
	adjust_spawn_rate_for_wave(wave_number + 1)

## 敌人死亡处理[br]
## [param enemy] 死亡的敌人节点
func _on_enemy_died(enemy: Node) -> void:
	current_enemy_count = max(0, current_enemy_count - 1)

## 获取当前敌人数量[br]
## [returns] 当前敌人数量
func get_current_enemy_count() -> int:
	return current_enemy_count

## 获取敌人数量上限[br]
## [returns] 敌人数量上限
func get_max_enemies() -> int:
	return max_enemies

## 检查是否可以生成敌人[br]
## [returns] 是否可以生成敌人
func can_spawn_enemies() -> bool:
	return current_enemy_count < max_enemies

## 根据玩家移动速度动态调整生成距离[br]
## [param player] 玩家节点引用[br]
## [returns] 调整后的生成距离
func get_dynamic_spawn_distance(player: Node) -> float:
	var base_distance: float = spawn_distance + extra_spawn_distance
	
	# Area2D玩家使用速度属性而不是velocity
	if player.has_method("get") and "speed" in player:
		var player_speed: float = player.speed
		
		# 根据玩家移动速度增加生成距离
		var speed_factor: float = player_speed / 200.0  # 基准速度200
		var additional_distance: float = speed_factor * 50.0  # 基于速度属性调整距离
		return base_distance + additional_distance
	
	return base_distance 
