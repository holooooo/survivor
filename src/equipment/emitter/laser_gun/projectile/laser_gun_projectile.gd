extends ProjectileBase
class_name LaserGunProjectile

## 激光枪投射物 - 直线长方形激光柱[br]
## 存在期间每0.08秒对范围内敌人造成5点能量伤害

var laser_direction: Vector2 = Vector2.RIGHT
var laser_range: float = 300.0
var laser_width: float = 60.0
var damage_interval: float = 0.08
var tick_damage: int = 5
var damage_timer: float = 0.0
var move_speed: float = 200.0  ## 移动速度
var player: Player

## 实现抽象方法：初始化特定逻辑[br]
## [param direction] 初始方向
func _initialize_specific(direction: Vector2) -> void:
	player = equipment.owner_player
	global_position = player.global_position
	laser_direction = equipment._get_target_direction()
	rotation = laser_direction.angle()
	# 从投射物资源获取配置
	if projectile_resource:
		damage_interval = projectile_resource.damage_interval
		tick_damage = projectile_resource.base_damage
	
	# 设置碰撞形状为长方形
	_setup_laser_collision()

## 实现抽象方法：更新移动逻辑[br]
## [param delta] 时间增量
func _update_movement(delta: float) -> void:
	# 持续跟随玩家并移动到最佳位置
	global_position = player.global_position
	laser_direction = equipment._get_target_direction()
	
	# 基于delta平滑处理角度变化
	var target_angle: float = laser_direction.angle()
	var current_angle: float = rotation
	var angle_diff: float = angle_difference(current_angle, target_angle)
	var rotation_speed: float = 8.0  # 旋转速度系数
	
	rotation += angle_diff * rotation_speed * delta



## 实现抽象方法：获取投射物类型[br]
## [returns] 类型标识
func _get_projectile_type() -> String:
	return "laser_gun"

## 重写自定义更新逻辑 - 持续伤害处理[br]
## [param delta] 时间增量
func _update_custom(delta: float) -> void:
	damage_timer += delta
	
	# 定期对碰撞中的敌人造成伤害
	if damage_timer >= damage_interval:
		_deal_damage_to_colliding_targets()
		damage_timer = 0.0

## 重写目标进入处理 - 激光不立即造成伤害[br]
## [param target] 进入的目标
func _on_target_entered(target: Node) -> void:
	# 激光依靠持续伤害系统，目标进入时不立即造成伤害
	pass

## 设置激光束参数[br]
## [param direction] 激光方向[br]
## [param range] 激光射程
func setup_laser_beam(direction: Vector2, range: float) -> void:
	laser_direction = direction.normalized()
	laser_range = range
	
	# 重新设置碰撞形状和视觉效果
	call_deferred("_setup_laser_collision")
	call_deferred("_update_laser_visual")

## 设置激光碰撞形状
func _setup_laser_collision() -> void:
	if not collision_shape:
		return
	
	# 创建长方形碰撞形状
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(laser_range, laser_width)
	collision_shape.shape = rect_shape
	
## 更新激光视觉效果
func _update_laser_visual() -> void:
	collision_shape.shape.size = Vector2(laser_range, laser_width)

## 对碰撞中的目标造成伤害
func _deal_damage_to_colliding_targets() -> void:
	# 清理无效目标
	colliding_targets = colliding_targets.filter(func(target): return is_instance_valid(target))
	
	for target in colliding_targets:
		_deal_damage_to_target(target, tick_damage) 