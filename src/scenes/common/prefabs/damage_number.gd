extends Label

## 浮动伤害数字显示组件[br]
## 在触发位置显示伤害数值，缓慢向上飘动并淡出

var damage_value: int
var float_distance: float = 60.0  # 向上飘动的距离
var fade_duration: float = 0.5

func _ready() -> void:
	# 设置伤害数字显示
	text = str(damage_value)
	add_theme_font_size_override("font_size", 48)
	
	# 设置文字居中对齐
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 延迟一帧后开始动画，确保position已经正确设置
	await get_tree().process_frame
	start_animation()

## 开始飘动和淡出动画
func start_animation() -> void:
	# 创建缓慢向上飘动和淡出动画
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	
	# 缓慢向上飘动
	var target_position: Vector2 = global_position + Vector2(0, -float_distance)
	tween.tween_property(self, "global_position", target_position, fade_duration)
	
	# 淡出效果
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	
	# 0.3秒后删除节点
	tween.tween_callback(queue_free).set_delay(fade_duration)

## 设置伤害数值[br]
## [param value] 伤害数值
func set_damage(value: int) -> void:
	damage_value = value

## 设置伤害数字颜色[br]
## [param color] 显示颜色
func set_color(color: Color) -> void:
	add_theme_color_override("font_color", color) 