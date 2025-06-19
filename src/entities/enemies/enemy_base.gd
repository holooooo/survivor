extends Actor
class_name EnemyBase

## 敌人基类 - 所有敌人的基础类[br]
## 提供通用的敌人行为和属性，子类重写AI逻辑

@export var damage: int = 10
@export var off_screen_speed_multiplier: float = GameConstants.ENEMY_OFF_SCREEN_SPEED_MULTIPLIER ## 屏幕外时的速度倍数

var player: Actor
var current_speed_multiplier: float = 1.0 ## 当前速度倍数
var is_on_screen: bool = true ## 是否在屏幕内
var last_damage_time: float = 0.0 ## 上次造成伤害的时间
var damage_cooldown: float = 1.0 ## 伤害冷却时间（秒）
var frame_skip_counter: int = 0 ## 帧跳过计数器
var use_physics_movement: bool = false ## 是否使用物理移动（默认使用简单移动）

@export var enemy_type: GameConstants.EnemyType = GameConstants.EnemyType.MELEE

func _ready() -> void:
	super ()
	current_health = max_health
	
	# 连接Actor的信号
	died.connect(_on_died)
	
	player = get_tree().get_root().find_child("Player", true, false)
func _physics_process(delta):
	if not player or is_dead:
		return
	
	# 帧跳过优化 - 减少更新频率
	frame_skip_counter += 1
	if frame_skip_counter < GameConstants.ENEMY_UPDATE_SKIP_FRAMES:
		return
	frame_skip_counter = 0
	
	# 调整delta以补偿跳帧
	var adjusted_delta: float = delta * GameConstants.ENEMY_UPDATE_SKIP_FRAMES
	
	update_screen_status()
	enemy_ai(adjusted_delta)
	check_distance_damage()
	check_distance_and_respawn()

# 子类需要重写这个方法来实现不同的AI行为
func enemy_ai(delta: float):
	pass

## 重写Actor的受伤方法，添加伤害数字显示和事件发送
func take_damage(damage_amount: int) -> void:
	super (damage_amount)
	
	# 发送伤害事件
	EventBus.enemy_damaged.emit(self, damage_amount)
	
	# 通过 EventBus 显示伤害数字
	EventBus.show_damage_number(damage_amount, global_position, Color.RED, self)

## 重写Actor的死亡回调
func _on_death() -> void:
	pass

## 敌人死亡处理
func _on_died(actor: Actor) -> void:
	EventBus.enemy_died.emit(self)
	queue_free()

func get_distance_to_player() -> float:
	if player:
		return global_position.distance_to(player.global_position)
	return 0.0

func get_direction_to_player() -> Vector2:
	if player:
		return (player.global_position - global_position).normalized()
	return Vector2.ZERO

## 检查与玩家的距离并在距离足够近时造成伤害[br]
## 使用角色半径而不是物理碰撞来检测接触
func check_distance_damage() -> void:
	if not player or player.is_dead:
		return
	
	var distance_to_player: float
	if GameConstants.DISTANCE_CHECK_OPTIMIZATION:
		# 优化：先使用简单的曼哈顿距离快速筛选
		var diff: Vector2 = player.global_position - global_position
		var manhattan_distance: float = abs(diff.x) + abs(diff.y)
		var contact_distance: float = GameConstants.PLAYER_RADIUS + GameConstants.ENEMY_RADIUS
		
		# 如果曼哈顿距离太远，跳过精确计算
		if manhattan_distance > contact_distance * 1.5:
			return
			
		# 需要精确距离时才计算
		distance_to_player = get_distance_to_player()
	else:
		distance_to_player = get_distance_to_player()
	
	var contact_distance: float = GameConstants.PLAYER_RADIUS + GameConstants.ENEMY_RADIUS
	
	# 如果距离小于角色半径之和，则造成伤害
	if distance_to_player <= contact_distance:
		attempt_damage_player()

## 尝试对玩家造成伤害（带冷却时间）[br]
## 防止过于频繁的伤害
func attempt_damage_player() -> void:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - last_damage_time >= damage_cooldown:
		if player and not player.is_dead:
			player.take_damage(damage)
			last_damage_time = current_time

## 检查与玩家的距离并在必要时重新刷新位置[br]
## 当敌人距离玩家超过最大距离时，将其重新定位到屏幕外周围
func check_distance_and_respawn() -> void:
	var distance_to_player: float = get_distance_to_player()
	if distance_to_player > GameConstants.ENEMY_MAX_DISTANCE_FROM_PLAYER:
		respawn_around_screen()

## 将敌人重新刷新到屏幕外周围[br]
## 使用MathUtils获取新的重生位置
func respawn_around_screen() -> void:
	if player:
		var new_position: Vector2 = MathUtils.get_respawn_position_around_player(
			player.global_position,
			GameConstants.ENEMY_RESPAWN_DISTANCE_FROM_SCREEN
		)
		global_position = new_position
		
		# 发送敌人重生事件（可选，用于调试或其他系统）
		EventBus.enemy_respawned.emit(self)

## 更新屏幕状态并调整移动速度[br]
## 检查敌人是否在屏幕内，并相应调整移动速度
func update_screen_status() -> void:
	var viewport: Viewport = get_viewport()
	if not viewport:
		return
	
	# 获取屏幕大小
	var screen_size: Vector2 = viewport.get_visible_rect().size
	var screen_rect: Rect2
	
	# 如果有相机，基于相机位置计算屏幕区域
	var camera: Camera2D = viewport.get_camera_2d()
	if camera:
		var camera_pos: Vector2 = camera.global_position
		screen_rect = Rect2(
			camera_pos - screen_size * 0.5,
			screen_size
		)
	else:
		# 没有相机时，基于玩家位置估算屏幕区域
		if player:
			screen_rect = Rect2(
				player.global_position - screen_size * 0.5,
				screen_size
			)
		else:
			# 备用方案
			screen_rect = Rect2(Vector2.ZERO, screen_size)
	
	# 检查敌人是否在屏幕内（包含边距）
	var screen_margin: float = 100.0 # 增加边距，避免频繁切换
	var expanded_screen: Rect2 = screen_rect.grow(screen_margin)
	var was_on_screen: bool = is_on_screen
	is_on_screen = expanded_screen.has_point(global_position)
	
	# 根据屏幕状态调整速度倍数
	if is_on_screen:
		current_speed_multiplier = 1.0
	else:
		current_speed_multiplier = off_screen_speed_multiplier

## 获取当前有效移动速度[br]
## [returns] 考虑速度倍数后的实际移动速度
func get_effective_speed() -> float:
	return speed * current_speed_multiplier

## 优化的移动方法 - 使用Area2D的移动逻辑[br]
## [param direction] 移动方向[br]
## [param delta] 时间增量
func move_optimized(direction: Vector2, delta: float) -> void:
	if direction != Vector2.ZERO:
		# 使用Actor基类的移动方法，考虑当前速度倍数
		var target_position = global_position + direction * get_effective_speed() * delta
		global_position = target_position