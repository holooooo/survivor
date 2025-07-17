extends Actor
class_name EnemyBase

## 敌人基类 - 所有敌人的基础类[br]
## 提供通用的敌人行为和属性，子类重写AI逻辑

@export var damage: int = 10
@export var off_screen_speed_multiplier: float = GameConstants.ENEMY_OFF_SCREEN_SPEED_MULTIPLIER ## 屏幕外时的速度倍数
@export var credit_reward: int = 10 ## 击杀敌人获得的信用点数量

var player: Actor
var current_speed_multiplier: float = 1.0 ## 当前速度倍数
var is_on_screen: bool = true ## 是否在屏幕内
var last_damage_time: float = 0.0 ## 上次造成伤害的时间
var damage_cooldown: float = 1.0 ## 伤害冷却时间（秒）
var frame_skip_counter: int = 0 ## 帧跳过计数器
var use_physics_movement: bool = false ## 是否使用物理移动（默认使用简单移动）
var movement_disabled: bool = false ## 是否禁用移动（用于击退等效果）

# 距离缓存系统
var cached_distance_to_player: float = 0.0 ## 缓存的与玩家的距离
var distance_cache_counter: int = 0 ## 距离缓存更新计数器
var distance_cache_update_frames: int = 3 ## 每几帧更新一次距离缓存

@export var enemy_type: GameConstants.EnemyType = GameConstants.EnemyType.MELEE

func _ready() -> void:
	super ()
	current_health = max_health

	# 将敌人添加到enemies组，便于其他系统获取敌人引用
	add_to_group("enemies")
	
	# 确保CollisionArea也在enemies组中，用于投射物检测
	call_deferred("_setup_enemy_collision_area")

	player = get_tree().get_first_node_in_group(Constants.GROUP_PLAYER)
	
	# 初始化距离缓存
	if player:
		cached_distance_to_player = global_position.distance_to(player.global_position)

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

	# 距离缓存更新
	distance_cache_counter += 1
	if distance_cache_counter >= distance_cache_update_frames:
		update_distance_cache()
		distance_cache_counter = 0

	update_screen_status()
	
	# 只有在移动未被禁用时才执行AI
	if not movement_disabled:
		enemy_ai(adjusted_delta)
	
	check_distance_damage()
	check_distance_and_respawn()

## 更新距离缓存[br]
## 定期计算与玩家的距离并缓存，提高性能
func update_distance_cache() -> void:
	if player and not is_dead:
		cached_distance_to_player = global_position.distance_to(player.global_position)

## 获取缓存的与玩家的距离[br]
## [returns] 缓存的距离值
func get_cached_distance_to_player() -> float:
	return cached_distance_to_player

## 检查是否在指定距离内[br]
## [param max_distance] 最大距离[br]
## [returns] 是否在距离内
func is_within_distance_of_player(max_distance: float) -> bool:
	return cached_distance_to_player <= max_distance

# 子类需要重写这个方法来实现不同的AI行为
func enemy_ai(delta: float):
	pass

## 受到伤害
## [param damage_amount] 伤害值[br]
## [param damage_type] 伤害类型
func take_damage(damage_amount: int, damage_type: int = 0) -> void:
	super.take_damage(damage_amount, damage_type)

	# 发送伤害事件
	EventBus.enemy_damaged.emit(self, damage_amount)

	# 伤害数字显示现在由投射物根据伤害类型处理，这里不再显示固定颜色的伤害数字

## 敌人死亡处理
func _on_died(actor: Actor) -> void:
	EventBus.enemy_died.emit(self)
	queue_free()

func get_distance_to_player() -> float:
	if player:
		return cached_distance_to_player
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

	var distance_to_player: float = cached_distance_to_player
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
	var distance_to_player: float = cached_distance_to_player
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

## 优化的移动方法 - 使用CharacterBody2D的velocity系统[br]
## [param direction] 移动方向[br]
## [param delta] 时间增量
func move_optimized(direction: Vector2, delta: float) -> void:
	if direction != Vector2.ZERO and not movement_disabled:
		# 使用velocity系统进行移动，考虑当前速度倍数
		velocity = direction * get_effective_speed()
		move_and_slide()
	else:
		# 停止移动
		velocity = Vector2.ZERO

## 应用击退效果[br]
## [param direction] 击退方向[br]
## [param strength] 击退强度
func apply_knockback(direction: Vector2, strength: float) -> void:
	# 禁用移动
	movement_disabled = true
	
	# 使用velocity实现击退效果
	var knockback_velocity = direction * strength * 200.0  # 调整击退速度倍数
	velocity = knockback_velocity
	
	# 创建击退衰减效果
	var tween = create_tween()
	if not tween:
		# 如果无法创建Tween，立即恢复移动
		movement_disabled = false
		velocity = Vector2.ZERO
		return
	
	# 击退velocity逐渐衰减到0
	tween.tween_method(_apply_knockback_velocity, knockback_velocity, Vector2.ZERO, 0.3)
	
	# 击退结束后恢复移动
	tween.tween_callback(func(): 
		movement_disabled = false
		velocity = Vector2.ZERO
	)

## 应用击退速度并移动[br]
## [param kb_velocity] 击退速度向量
func _apply_knockback_velocity(kb_velocity: Vector2) -> void:
	velocity = kb_velocity
	move_and_slide()

## 设置移动禁用状态[br]
## [param disabled] 是否禁用移动
func set_movement_disabled(disabled: bool) -> void:
	movement_disabled = disabled

## 禁用移动
func disable_movement() -> void:
	movement_disabled = true

## 启用移动
func enable_movement() -> void:
	movement_disabled = false

## 设置敌人碰撞区域[br]
## 确保投射物能够正确检测到敌人
func _setup_enemy_collision_area() -> void:
	var collision_area = get_collision_area()
	if collision_area:
		# 确保CollisionArea在enemies组中
		if not collision_area.is_in_group("enemies"):
			collision_area.add_to_group("enemies")
		
		# 设置正确的碰撞层和掩码
		collision_area.collision_layer = 2  # 敌人层
		collision_area.collision_mask = 4   # 武器层（用于被投射物检测）