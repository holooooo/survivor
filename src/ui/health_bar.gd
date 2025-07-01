extends Control

## 血条UI组件 - 显示玩家当前血量[br]
## 通过事件总线接收血量变化信息，跟随玩家位置显示

@onready var health_bar: ProgressBar = $HealthBar
@onready var armor_bar: ProgressBar = $ArmorBar
var player: CharacterBody2D

func _ready() -> void:
	# 连接事件总线的血量和护甲更新信号
	EventBus.ui_health_update_requested.connect(_on_health_update_requested)
	EventBus.ui_armor_update_requested.connect(_on_armor_update_requested)
	# 设置初始样式
	_setup_health_bar_style()
	_setup_armor_bar_style()

## 设置血条样式[br]
## 配置ProgressBar的基本外观
func _setup_health_bar_style() -> void:
	# 创建背景样式
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	health_bar.add_theme_stylebox_override("background", bg_style)

## 设置护甲条样式[br]
## 配置护甲ProgressBar的基本外观
func _setup_armor_bar_style() -> void:
	if not armor_bar:
		return
	
	# 创建背景样式
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	armor_bar.add_theme_stylebox_override("background", bg_style)
	
	# 创建护甲前景样式（黄色）
	var fg_style := StyleBoxFlat.new()
	fg_style.bg_color = Color.YELLOW
	fg_style.corner_radius_top_left = 4
	fg_style.corner_radius_top_right = 4
	fg_style.corner_radius_bottom_left = 4
	fg_style.corner_radius_bottom_right = 4
	armor_bar.add_theme_stylebox_override("fill", fg_style)

## 处理血量更新请求[br]
## [param current_health] 当前血量[br]
## [param max_health] 最大血量
func _on_health_update_requested(current_health: int, max_health: int) -> void:
	_update_health_bar(current_health, max_health)

## 处理护甲更新请求[br]
## [param current_armor] 当前护甲[br]
## [param max_armor] 最大护甲
func _on_armor_update_requested(current_armor: int, max_armor: int) -> void:
	_update_armor_bar(current_armor, max_armor)

## 更新血条显示[br]
## [param current] 当前血量[br]
## [param maximum] 最大血量
func _update_health_bar(current: int, maximum: int) -> void:
	var health_percentage: float = float(current) / float(maximum)
	health_bar.value = health_percentage * 100
	
	# 根据血量百分比设置颜色
	# 60-100%: 绿色, 20-60%: 黄色, 0-20%: 红色
	var health_color: Color
	if health_percentage >= 0.6:
		health_color = Color.GREEN
	elif health_percentage >= 0.2:
		health_color = Color.YELLOW
	else:
		health_color = Color.RED
	
	# 使用StyleBoxFlat设置前景颜色
	var fg_style := StyleBoxFlat.new()
	fg_style.bg_color = health_color
	fg_style.corner_radius_top_left = 4
	fg_style.corner_radius_top_right = 4
	fg_style.corner_radius_bottom_left = 4
	fg_style.corner_radius_bottom_right = 4
	health_bar.add_theme_stylebox_override("fill", fg_style)
	
	# 当生命值为0时触发游戏结束
	if current <= 0:
		EventBus.change_scene_safely("res://src/ui/game_over.tscn")

## 更新护甲条显示[br]
## [param current] 当前护甲[br]
## [param maximum] 最大护甲
func _update_armor_bar(current: int, maximum: int) -> void:
	if not armor_bar:
		return
	
	# 如果没有护甲，隐藏护甲条
	if maximum <= 0:
		armor_bar.visible = false
		return
	
	armor_bar.visible = true
	var armor_percentage: float = float(current) / float(maximum)
	armor_bar.value = armor_percentage * 100
