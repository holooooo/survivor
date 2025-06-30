extends ProjectileBase
class_name FistProjectile

## 拳击投射物 - 使用发射器投射物资源配置的投射物[br]
## 在存在期间定期对范围内敌人造成伤害

var remaining_damage_ticks: int = 5
var damage_timer: float = 0.0
var player: Player  ## 投射物关联的玩家
var orbit_radius: float = 100.0  ## 操作半径，与装备的orbit_radius保持一致
var move_speed: float = 200.0  ## 移动速度

## 实现抽象方法：初始化特定逻辑[br]
## [param direction] 初始方向（拳击投射物会智能跟随）
func _initialize_specific(direction: Vector2) -> void:
	# 设置参数
	remaining_damage_ticks = projectile_resource.damage_ticks

## 实现抽象方法：更新移动逻辑[br]
## [param delta] 时间增量
func _update_movement(delta: float) -> void:
	# 持续跟随玩家并移动到最佳位置
	_update_position(delta)

## 实现抽象方法：获取投射物类型[br]
## [returns] 类型标识
func _get_projectile_type() -> String:
	return "fist"

## 重写自定义更新逻辑 - 持续伤害处理[br]
## [param delta] 时间增量
func _update_custom(delta: float) -> void:
	damage_timer += delta
	
	# 定期对碰撞中的敌人造成伤害 - 拳击投射物始终进行持续伤害
	if damage_timer >= projectile_resource.damage_interval and remaining_damage_ticks > 0:
		_deal_damage_to_colliding_targets()
		damage_timer = 0.0
		remaining_damage_ticks -= 1
		
		# 如果伤害次数耗尽，销毁投射物
		if remaining_damage_ticks <= 0:
			_destroy_projectile()
			return

## 重写目标进入处理 - 拳击投射物不立即造成伤害[br]
## [param target] 进入的目标
func _on_target_entered(target: Node) -> void:
	# 拳击投射物依靠持续伤害系统，目标进入时不立即造成伤害
	pass

## 设置投射物的玩家引用和操作半径[br]
## [param owner_player] 关联的玩家[br]
## [param radius] 操作半径
func set_player_reference(owner_player: Player, orbit_radius: float) -> void:
	player = owner_player
	
	# 立即调整到正确的距离
	if player:
		var player_pos: Vector2 = player.global_position
		var current_direction: Vector2 = (global_position - player_pos).normalized()
		if current_direction == Vector2.ZERO:
			current_direction = Vector2.RIGHT
		global_position = player_pos + current_direction * orbit_radius
		
		# 设置初始旋转角度
		_update_rotation()

## 对碰撞中的目标造成伤害
func _deal_damage_to_colliding_targets() -> void:
	if not projectile_resource:
		return
	
	# 清理无效目标
	colliding_targets = colliding_targets.filter(func(target): return is_instance_valid(target))
	
	for target in colliding_targets:
		_deal_damage_to_target(target, projectile_resource.damage_ticks)

## 更新投射物位置 - 跟随玩家并移动到最接近敌人的位置[br]
## [param delta] 时间增量
func _update_position(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return
	
	# 获取目标位置（玩家周围圆周上最接近敌人的位置）
	var target_position: Vector2 = _get_optimal_position_around_player()
	
	# 平滑移动到目标位置
	var current_pos: Vector2 = global_position
	var direction_to_target: Vector2 = (target_position - current_pos)
	var distance_to_target: float = direction_to_target.length()
	
	# 如果距离很近，直接设置位置，否则平滑移动
	if distance_to_target < move_speed * delta:
		global_position = target_position
	else:
		var move_direction: Vector2 = direction_to_target.normalized()
		global_position += move_direction * move_speed * delta
	
	_enforce_distance_constraint()
	_update_rotation()

## 获取玩家周围最优位置 - 在固定半径圆周上最接近敌人的位置[br]
## [returns] 最优的世界坐标位置
func _get_optimal_position_around_player() -> Vector2:
	if not player:
		return global_position
	
	var player_pos: Vector2 = player.global_position
	
	var scene_tree = get_tree()
	if not scene_tree:
		return player_pos + Vector2.RIGHT * orbit_radius
	
	var enemies: Array[Node] = scene_tree.get_nodes_in_group("enemies")
	if enemies.is_empty():
		return player_pos + Vector2.RIGHT * orbit_radius
	
	# 找到最近的敌人
	var nearest_enemy: Node2D = null
	var nearest_distance: float = INF
	
	for enemy in enemies:
		if enemy is Node2D and is_instance_valid(enemy):
			var distance: float = player_pos.distance_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_enemy = enemy
	
	if nearest_enemy:
		var direction_to_enemy: Vector2 = (nearest_enemy.global_position - player_pos).normalized()
		return player_pos + direction_to_enemy * orbit_radius
	else:
		return player_pos + Vector2.RIGHT * orbit_radius

## 强制确保与玩家的距离约束[br]
## 确保投射物始终在距离玩家operation_radius的圆周上
func _enforce_distance_constraint() -> void:
	if not player or not is_instance_valid(player):
		return
	
	var player_pos: Vector2 = player.global_position
	var current_pos: Vector2 = global_position
	var distance_to_player: float = player_pos.distance_to(current_pos)
	
	# 如果距离不等于operation_radius，强制调整到圆周上
	if abs(distance_to_player - orbit_radius) > 0.1:  # 允许小误差
		var direction_from_player: Vector2 = (current_pos - player_pos).normalized()
		if direction_from_player == Vector2.ZERO:
			# 如果投射物与玩家位置完全重叠，使用默认方向
			direction_from_player = Vector2.RIGHT
		global_position = player_pos + direction_from_player * orbit_radius

## 更新投射物旋转角度 - 让投射物像时钟分针一样指向其相对玩家的方向[br]
func _update_rotation() -> void:
	if not player or not is_instance_valid(player):
		return
	
	var direction_from_player: Vector2 = (global_position - player.global_position).normalized()
	var angle_rad: float = direction_from_player.angle()
	rotation = angle_rad

