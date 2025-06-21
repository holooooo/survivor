extends Area2D
class_name FistProjectile

## 拳击投射物 - 使用资源配置的投射物[br]
## 在存在期间定期对范围内敌人造成伤害

var projectile_resource: ProjectileBase
var remaining_damage_ticks: int = 5
var damage_timer: float = 0.0
var lifetime_timer: float = 0.0
var player: Player  ## 投射物关联的玩家
var operation_radius: float = 100.0  ## 操作半径，与装备的operation_radius保持一致
var move_speed: float = 200.0  ## 移动速度

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# 设置碰撞检测
	collision_layer = 4 # 武器层
	collision_mask = 2  # 敌人层
	
	# 添加到投射物组，便于性能监控
	add_to_group("projectiles")

func _physics_process(delta: float) -> void:
	if not projectile_resource:
		return
	
	lifetime_timer += delta
	damage_timer += delta
	
	# 生存时间到期时销毁
	if lifetime_timer >= projectile_resource.lifetime:
		queue_free()
		return
	
	# 持续跟随玩家并移动到最佳位置
	_update_position(delta)
	
	# 定期造成伤害
	if damage_timer >= projectile_resource.damage_interval and remaining_damage_ticks > 0:
		_deal_damage_to_enemies()
		damage_timer = 0.0
		remaining_damage_ticks -= 1

## 从资源配置投射物[br]
## [param resource] 投射物资源[br]
## [param direction] 移动方向（保留接口，但拳击投射物会智能跟随）
func setup_from_resource(resource: Resource, direction: Vector2) -> void:
	projectile_resource = resource
	if not projectile_resource:
		return
	
	# 设置参数
	remaining_damage_ticks = projectile_resource.damage_ticks
	
	# 设置外观
	if sprite and projectile_resource.projectile_texture:
		sprite.texture = projectile_resource.projectile_texture
		sprite.modulate = projectile_resource.projectile_color
		sprite.scale = projectile_resource.projectile_scale
	elif sprite:
		# 使用默认外观
		var default_texture: Texture2D = load("res://icon.svg")
		if default_texture:
			sprite.texture = default_texture
			sprite.modulate = projectile_resource.projectile_color if projectile_resource else Color.YELLOW
			sprite.scale = projectile_resource.projectile_scale if projectile_resource else Vector2(0.8, 0.8)

## 设置投射物的玩家引用和操作半径[br]
## [param owner_player] 关联的玩家[br]
## [param radius] 操作半径
func set_player_reference(owner_player: Player, radius: float = 100.0) -> void:
	player = owner_player
	operation_radius = radius
	
	# 立即调整到正确的距离
	if player:
		var player_pos: Vector2 = player.global_position
		var current_direction: Vector2 = (global_position - player_pos).normalized()
		if current_direction == Vector2.ZERO:
			current_direction = Vector2.RIGHT
		global_position = player_pos + current_direction * operation_radius
		
		# 设置初始旋转角度
		_update_rotation()

## 设置投射物参数（兼容旧接口）[br]
## [param direction] 移动方向[br]
## [param damage] 每次伤害数值[br]
## [param damage_ticks] 造成伤害的次数[br]
## [param proj_lifetime] 投射物存在时间
func setup(direction: Vector2, damage: int, damage_ticks: int, proj_lifetime: float) -> void:
	# 创建临时资源用于兼容
	var temp_resource = preload("res://src/equipment/projectile_base.gd").new()
	temp_resource.damage_per_tick = damage
	temp_resource.damage_ticks = damage_ticks
	temp_resource.lifetime = proj_lifetime
	temp_resource.projectile_color = Color.YELLOW
	temp_resource.projectile_scale = Vector2(0.8, 0.8)
	temp_resource.detection_range = 50.0
	temp_resource.damage_interval = 0.1
	
	setup_from_resource(temp_resource, direction)

## 对范围内的敌人造成伤害
func _deal_damage_to_enemies() -> void:
	if not projectile_resource:
		return
	
	# 检查场景树是否可用
	var scene_tree = get_tree()
	if not scene_tree:
		return
	
	# 查找范围内的敌人
	var enemies: Array[Node] = scene_tree.get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy is Node2D and is_instance_valid(enemy):
			var distance: float = global_position.distance_to(enemy.global_position)
			if distance <= projectile_resource.detection_range:
				# 对敌人造成伤害
				if enemy.has_method("take_damage"):
					enemy.take_damage(projectile_resource.damage_per_tick)

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
	
	# 强制确保与玩家的距离始终为operation_radius
	_enforce_distance_constraint()
	
	# 更新旋转角度，使投射物指向其相对玩家的方向
	_update_rotation()

## 获取玩家周围最优位置 - 在固定半径圆周上最接近敌人的位置[br]
## [returns] 最优的世界坐标位置
func _get_optimal_position_around_player() -> Vector2:
	if not player:
		return global_position
	
	var player_pos: Vector2 = player.global_position
	
	# 检查场景树是否可用
	var scene_tree = get_tree()
	if not scene_tree:
		return player_pos + Vector2.RIGHT * operation_radius
	
	# 查找所有敌人
	var enemies: Array[Node] = scene_tree.get_nodes_in_group("enemies")
	if enemies.is_empty():
		# 没有敌人时，保持在玩家右侧的圆周上
		return player_pos + Vector2.RIGHT * operation_radius
	
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
		# 计算从玩家到敌人的方向
		var direction_to_enemy: Vector2 = (nearest_enemy.global_position - player_pos).normalized()
		# 严格在距离玩家operation_radius的圆周上
		return player_pos + direction_to_enemy * operation_radius
	else:
		# 备用方案 - 在圆周上
		return player_pos + Vector2.RIGHT * operation_radius

## 强制确保与玩家的距离约束[br]
## 确保投射物始终在距离玩家operation_radius的圆周上
func _enforce_distance_constraint() -> void:
	if not player or not is_instance_valid(player):
		return
	
	var player_pos: Vector2 = player.global_position
	var current_pos: Vector2 = global_position
	var distance_to_player: float = player_pos.distance_to(current_pos)
	
	# 如果距离不等于operation_radius，强制调整到圆周上
	if abs(distance_to_player - operation_radius) > 0.1:  # 允许小误差
		var direction_from_player: Vector2 = (current_pos - player_pos).normalized()
		if direction_from_player == Vector2.ZERO:
			# 如果投射物与玩家位置完全重叠，使用默认方向
			direction_from_player = Vector2.RIGHT
		global_position = player_pos + direction_from_player * operation_radius

## 更新投射物旋转角度 - 让投射物像时钟分针一样指向其相对玩家的方向[br]
func _update_rotation() -> void:
	if not player or not is_instance_valid(player):
		return
	
	# 计算投射物相对玩家的方向向量
	var direction_from_player: Vector2 = (global_position - player.global_position).normalized()
	
	# 将方向向量转换为角度（弧度）
	# atan2 返回的角度是以 Vector2.RIGHT (1, 0) 为0度的角度
	var angle_rad: float = direction_from_player.angle()
	
	# 设置旋转角度（Godot使用弧度）
	rotation = angle_rad

func _on_tree_exiting() -> void:
	# 从投射物组中移除
	if is_in_group("projectiles"):
		remove_from_group("projectiles") 