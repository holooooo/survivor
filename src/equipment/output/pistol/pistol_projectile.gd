extends ProjectileNodeBase
class_name PistolProjectile

## 手枪子弹投射物 - 直线飞行的子弹[br]
## 以直线方式飞向目标，具备穿透和伤害衰减能力

const TRAIL_LENGTH: int = 0 ## 拖尾长度
const TRAIL_INTERVAL: float = 0.02 ## 拖尾更新间隔

var direction: Vector2 = Vector2.RIGHT ## 飞行方向
var current_speed: float = 800.0 ## 当前飞行速度
var pierce_left: int = 1 ## 剩余穿透次数
var trail_timer: float = 0.0 ## 拖尾更新计时器

@onready var trail: Line2D = $Trail

## 实现抽象方法：初始化特定逻辑[br]
## [param direction] 初始方向
func _initialize_specific(fly_direction: Vector2) -> void:
	direction = fly_direction.normalized()
	
	# 初始化参数，优先使用装备修改后的属性
	pierce_left = equipment_stats.get("pierce_count", projectile_resource.pierce_count)
	current_speed = equipment_stats.get("projectile_speed", projectile_resource.projectile_speed)
	
	# 设置子弹朝向
	if direction != Vector2.ZERO:
		rotation = direction.angle()
	
	# 设置拖尾
	if trail:
		trail.width_curve = _create_trail_curve()
		trail.default_color = projectile_resource.trail_color

## 实现抽象方法：更新移动逻辑[br]
## [param delta] 时间增量
func _update_movement(delta: float) -> void:
	# 直线移动
	global_position += direction * current_speed * delta
	_update_trail(delta)

## 实现抽象方法：获取投射物类型[br]
## [returns] 类型标识
func _get_projectile_type() -> String:
	return "bullet"

## 重写目标进入处理 - 手枪子弹的穿透逻辑[br]
## [param target] 进入的目标
func _on_target_entered(target: Node) -> void:
	# 检查资源是否已初始化
	if not projectile_resource:
		print("警告：投射物资源未初始化，跳过伤害处理")
		return
	
	var current_pierce = projectile_resource.pierce_count - pierce_left
	var damage = _calculate_pierce_damage(current_damage, current_pierce)
	
	# 对敌人造成伤害
	_deal_damage_to_target(target, damage)
	
	# 减少穿透次数
	pierce_left -= 1
	
	if pierce_left < 0:
		_destroy_projectile()
	else:
		# 更新穿透后的速度
		current_speed = projectile_resource.get_pierce_speed(current_pierce + 1)

## 更新拖尾[br]
## [param delta] 每一帧的时间
func _update_trail(delta: float) -> void:
	if not trail:
		return
	
	trail_timer += delta
	if trail_timer < TRAIL_INTERVAL:
		return
	trail_timer = 0.0
	
	trail.global_position = Vector2.ZERO
	trail.global_rotation = 0.0
	
	# 添加新点
	trail.add_point(global_position)
	
	# 移除旧点
	while trail.get_point_count() > TRAIL_LENGTH:
		trail.remove_point(0)

## 创建拖尾曲线[br]
## [returns] 拖尾的宽度曲线
func _create_trail_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.2, 1.0))
	curve.add_point(Vector2(1.0, 1.0))
	return curve

## 计算当前穿透后的伤害[br]
## [param base_damage] 基础伤害[br]
## [param current_pierce] 当前穿透次数[br]
## [returns] 计算后的伤害值
func _calculate_pierce_damage(base_damage: int, current_pierce: int) -> int:
	if current_pierce <= 0:
		return base_damage
	
	var pierce_damage_reduction = equipment_stats.get("pierce_damage_reduction", projectile_resource.pierce_damage_reduction)
	var damage_multiplier: float = 1.0 - (pierce_damage_reduction * current_pierce)
	damage_multiplier = max(damage_multiplier, 0.1) # 最少保留10%伤害
	
	return int(base_damage * damage_multiplier)

## 设置飞行方向[br]
## [param new_direction] 新的飞行方向
func _set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	if direction != Vector2.ZERO:
		rotation = direction.angle()

## 获取当前飞行方向[br]
## [returns] 当前飞行方向
func _get_direction() -> Vector2:
	return direction