extends Control

## 信用点显示UI组件 - 在右上角显示当前信用点数量[br]
## 通过事件总线接收信用点变化信息

@onready var credits_label: Label = $CreditsLabel

func _ready() -> void:
	# 连接事件总线的信用点更新信号
	EventBus.ui_credits_update_requested.connect(_on_credits_update_requested)

	# 设置初始样式
	_setup_credits_label_style()

	# 设置初始显示
	_update_credits_display(0)

## 设置信用点标签样式[br]
## 配置Label的基本外观
func _setup_credits_label_style() -> void:
	if credits_label:
		# 设置文字样式
		credits_label.add_theme_color_override("font_color", Color.GOLD)
		credits_label.add_theme_font_size_override("font_size", 24)

		# 设置文字轮廓
		credits_label.add_theme_color_override("font_outline_color", Color.BLACK)
		credits_label.add_theme_constant_override("outline_size", 2)

## 处理信用点更新请求[br]
## [param credits] 新的信用点数量
func _on_credits_update_requested(credits: int) -> void:
	_update_credits_display(credits)

## 更新信用点显示[br]
## [param credits] 要显示的信用点数量
func _update_credits_display(credits: int) -> void:
	if credits_label:
		credits_label.text = "信用点: " + str(credits)

		# 信用点变化时的简单闪烁效果
		_play_credits_change_effect()

## 播放信用点变化效果[br]
## 简单的闪烁动画效果
func _play_credits_change_effect() -> void:
	if credits_label:
		var tween = create_tween()
		# 先放大再恢复
		tween.tween_property(credits_label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(credits_label, "scale", Vector2(1.0, 1.0), 0.1)