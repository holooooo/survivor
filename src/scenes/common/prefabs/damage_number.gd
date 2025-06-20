extends Label

## 浮动伤害数字显示组件[br]
## 在触发位置显示伤害数值，缓慢向上飘动并淡出[br]
## 此节点由对象池管理，可重复使用。

var fade_duration: float = 0.5
var float_distance: float = 60.0
var _tween: Tween

func _ready() -> void:
	# 设置伤害数字显示
	# add_theme_font_size_override("font_size", 48)
	
	# 设置文字居中对齐
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	hide()


## 开始飘动和淡出动画
func start_animation() -> void:
	# 如果存在正在运行的动画，先停止它
	if _tween and _tween.is_valid():
		_tween.kill()

	show()
	# 创建缓慢向上飘动和淡出动画
	_tween = create_tween()
	_tween.set_parallel(true)
	# 缓慢向上飘动
	var target_position: Vector2 = global_position + Vector2(0, -float_distance)
	_tween.tween_property(self, "global_position", target_position, fade_duration)
	# 淡出效果
	_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	# _tween.tween_interval(fade_duration)

	# 动画结束后隐藏节点，以便重用
	_tween.chain().tween_callback(_on_tween_all_finished)


## 在指定位置显示伤害数字[br]
## [param damage] 伤害数值[br]
## [param color] 显示颜色[br]
## [param position] 显示的全局位置
func show_at_position(damage: int, color: Color, pos: Vector2) -> void:
	text = str(damage)
	global_position = pos
	
	# 重置节点状态
	modulate = Color.WHITE
	add_theme_color_override("font_color", color)
	
	start_animation()

func _on_tween_all_finished() -> void:
	hide()
