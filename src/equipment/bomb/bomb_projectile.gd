extends Area2D
class_name BombProjectile

## 炸弹投射物 - 处理单颗炸弹的生命周期[br]
## 包括引爆计时、爆炸效果和范围伤害

var bomb_config: Dictionary
var detonation_timer: Timer
var blinking_tween: Tween

var sprite: Sprite2D
var collision_shape: CollisionShape2D


func _ready() -> void:
	# 设置碰撞层和遮罩
	collision_layer = 0  # 炸弹本身不属于任何层
	collision_mask = 2   # 只检测第2层 (敌人)

	# 动态创建子节点
	sprite = Sprite2D.new()
	sprite.texture = load("res://icon.svg") # 使用默认图标
	add_child(sprite)

	collision_shape = CollisionShape2D.new()
	collision_shape.shape = CircleShape2D.new()
	add_child(collision_shape)

	# 初始时禁用碰撞检测，直到爆炸发生
	collision_shape.disabled = true
	# 连接到 "area_entered" 信号来检测敌人 (Area2D)
	area_entered.connect(_on_area_entered)


## 设置炸弹参数并启动引爆计时器[br]
## [param config] 炸弹配置字典
func setup(config: Dictionary) -> void:
	bomb_config = config

	# 创建并配置引爆计时器
	detonation_timer = Timer.new()
	add_child(detonation_timer)
	detonation_timer.wait_time = bomb_config.get("detonation_time", 2.0)
	detonation_timer.one_shot = true
	detonation_timer.timeout.connect(_explode)
	detonation_timer.start()

	# 添加一个引爆前的闪烁效果
	blinking_tween = create_tween().set_loops()
	blinking_tween.tween_property(sprite, "modulate:a", 0.5, 0.25)
	blinking_tween.tween_property(sprite, "modulate:a", 1.0, 0.25)


## 爆炸逻辑
func _explode() -> void:
	var radius: float = bomb_config.get("explosion_radius", 100.0)
	var spread_speed: float = bomb_config.get("explosion_spread_speed", 500.0)
	var duration: float = radius / spread_speed if spread_speed > 0 else 0.1

	# 停止引爆前的闪烁动画
	if blinking_tween:
		blinking_tween.kill()
	sprite.modulate.a = 1.0

	# 启用碰撞区域
	collision_shape.disabled = false
	(collision_shape.shape as CircleShape2D).radius = 0.0

	# 创建爆炸扩散的动画
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	
	# 动画1: 放大碰撞区域 (并行)
	tween.tween_property(collision_shape.shape, "radius", radius, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 动画2: 放大视觉效果 (并行)
	if sprite.texture:
		tween.tween_property(sprite, "scale", Vector2.ONE * (radius / sprite.texture.get_width() * 2), duration)
	
	# 切换回串行，在并行结束后执行
	tween.set_parallel(false)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)


## 对进入爆炸范围的区域造成伤害
func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		var damage: int = bomb_config.get("base_damage", 20)
		area.take_damage(damage)

		# 考虑为爆炸添加击退效果
		if area.has_method("apply_knockback"):
			var knockback_direction: Vector2 = (area.global_position - global_position).normalized()
			var knockback_strength: float = 150.0 # 可配置
			area.apply_knockback(knockback_direction, knockback_strength) 