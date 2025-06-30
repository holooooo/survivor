extends ProjectileBase
class_name BombProjectile

## 炸弹投射物 - 延时爆炸的范围伤害投射物[br]
## 落地后等待引爆时间，然后产生范围爆炸效果

# 炸弹特有配置
var detonation_time: float = 2.0 ## 引爆时间
var explosion_radius: float = 100.0 ## 爆炸半径
var explosion_spread_speed: float = 500.0 ## 爆炸扩散速度

# 状态管理
var detonation_timer: Timer
var blinking_tween: Tween
var has_exploded: bool = false ## 是否已爆炸

## 实现抽象方法：初始化特定逻辑[br]
## [param direction] 初始方向（炸弹不使用方向）
func _initialize_specific(direction: Vector2) -> void:
	# 从装备属性获取炸弹配置
	detonation_time = equipment_stats.get("detonation_time", 2.0)
	explosion_radius = equipment_stats.get("explosion_radius", 100.0)
	explosion_spread_speed = equipment_stats.get("explosion_spread_speed", 500.0)
	
	_setup_detonation_timer()
	_setup_blinking_effect()

## 实现抽象方法：更新移动逻辑[br]
## [param delta] 时间增量
func _update_movement(delta: float) -> void:
	# 炸弹落地后不移动，只等待爆炸
	pass

## 实现抽象方法：获取投射物类型[br]
## [returns] 类型标识
func _get_projectile_type() -> String:
	return "bomb"

## 重写碰撞检测 - 炸弹只在爆炸时造成伤害[br]
## [param target] 进入的目标
func _on_target_entered(target: Node) -> void:
	# 炸弹在爆炸前不造成伤害
	if not has_exploded:
		return
	
	# 爆炸时对目标造成伤害
	_deal_damage_to_target(target, current_damage)
	
	# 添加击退效果
	if target.has_method("apply_knockback"):
		var knockback_direction: Vector2 = (target.global_position - global_position).normalized()
		var knockback_strength: float = 200.0
		target.apply_knockback(knockback_direction, knockback_strength)

## 重写生命周期检查 - 炸弹使用引爆计时而不是标准生命周期[br]
## [returns] 是否应该销毁
func _should_destroy() -> bool:
	# 炸弹的生命周期由爆炸完成来决定，不使用标准的lifetime检查
	return false

## 设置引爆计时器[br]
func _setup_detonation_timer() -> void:
	detonation_timer = Timer.new()
	add_child(detonation_timer)
	detonation_timer.wait_time = detonation_time
	detonation_timer.one_shot = true
	detonation_timer.timeout.connect(_explode)
	detonation_timer.start()

## 设置闪烁效果[br]
func _setup_blinking_effect() -> void:
	# 炸弹引爆前的闪烁警告效果
	blinking_tween = create_tween().set_loops()
	blinking_tween.tween_property(sprite, "modulate:a", 0.5, 0.25)
	blinking_tween.tween_property(sprite, "modulate:a", 1.0, 0.25)

## 爆炸逻辑[br]
func _explode() -> void:
	if has_exploded:
		return
	
	has_exploded = true
	
	# 停止闪烁效果
	if blinking_tween:
		blinking_tween.kill()
	
	if sprite:
		sprite.modulate.a = 1.0
	
	# 创建爆炸扩散动画
	_create_explosion_animation()

## 创建爆炸扩散动画[br]
func _create_explosion_animation() -> void:
	var duration: float = explosion_radius / explosion_spread_speed if explosion_spread_speed > 0 else 0.1
	
	# 启用碰撞检测
	if collision_shape and collision_shape.shape is CircleShape2D:
		var shape: CircleShape2D = collision_shape.shape as CircleShape2D
		shape.radius = 0.0
		
		# 创建爆炸扩散动画
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		
		# 动画1: 扩大碰撞区域
		tween.tween_property(shape, "radius", explosion_radius, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		# 动画2: 扩大视觉效果
		if sprite and sprite.texture:
			var final_scale: float = explosion_radius / (sprite.texture.get_width() * 0.5)
			tween.tween_property(sprite, "scale", Vector2.ONE * final_scale, duration)
		
		# 动画3: 渐隐效果
		tween.set_parallel(false)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
		tween.tween_callback(_destroy_projectile)

## 重写销毁前处理[br]
func _before_destroy() -> void:
	# 清理计时器和动画
	if detonation_timer and is_instance_valid(detonation_timer):
		detonation_timer.queue_free()
	
	if blinking_tween:
		blinking_tween.kill() 