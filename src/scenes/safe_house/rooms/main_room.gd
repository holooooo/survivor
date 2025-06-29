extends Control
class_name MainRoom

## 安全屋主房间 - 显示游戏状态和各房间预览[br]
## 作为安全屋的核心界面，提供总览功能

@onready var welcome_label: Label = $VBoxContainer/WelcomeLabel
@onready var game_info_container: VBoxContainer = $VBoxContainer/GameInfoContainer
@onready var week_label: Label = $VBoxContainer/GameInfoContainer/WeekLabel
@onready var time_label: Label = $VBoxContainer/GameInfoContainer/TimeLabel
@onready var room_preview_container: GridContainer = $VBoxContainer/RoomPreviewContainer

# 各房间预览按钮
@onready var battle_preview: Button = $VBoxContainer/RoomPreviewContainer/BattlePreview
@onready var recruit_preview: Button = $VBoxContainer/RoomPreviewContainer/RecruitPreview
@onready var upgrade_preview: Button = $VBoxContainer/RoomPreviewContainer/UpgradePreview
@onready var research_preview: Button = $VBoxContainer/RoomPreviewContainer/ResearchPreview
@onready var brand_preview: Button = $VBoxContainer/RoomPreviewContainer/BrandPreview

# 游戏数据
var current_week: int = 1
var safe_house_manager: Node

# 信号
signal preview_button_pressed(room_type: int)

func _ready() -> void:
	_setup_ui()
	_setup_preview_buttons()

## 房间激活时调用
func on_room_activated() -> void:
	_update_display()

## 设置安全屋管理器引用[br]
## [param manager] 安全屋管理器
func set_safe_house_manager(manager: Node) -> void:
	safe_house_manager = manager
	if safe_house_manager and safe_house_manager.has_signal("game_week_changed"):
		safe_house_manager.game_week_changed.connect(_on_game_week_changed)
	_update_display()

## 设置UI初始状态
func _setup_ui() -> void:
	if welcome_label:
		welcome_label.text = "欢迎回到安全屋\n提示：在任何房间按ESC键可返回主界面"
	
	# 设置房间预览容器为网格布局
	if room_preview_container:
		room_preview_container.columns = 2

## 设置预览按钮
func _setup_preview_buttons() -> void:
	if battle_preview:
		battle_preview.text = "作战室\n选择任务和角色"
		battle_preview.pressed.connect(_on_battle_preview_pressed)
	
	if recruit_preview:
		recruit_preview.text = "招募室\n招募新的角色"
		recruit_preview.pressed.connect(_on_recruit_preview_pressed)
	
	if upgrade_preview:
		upgrade_preview.text = "改造室\n提升角色能力"
		upgrade_preview.pressed.connect(_on_upgrade_preview_pressed)
	
	if research_preview:
		research_preview.text = "研究室\n开发新技术"
		research_preview.pressed.connect(_on_research_preview_pressed)
	
	if brand_preview:
		brand_preview.text = "品牌室\n合作与交易"
		brand_preview.pressed.connect(_on_brand_preview_pressed)

## 更新显示信息
func _update_display() -> void:
	# 更新游戏周期
	if safe_house_manager and safe_house_manager.has_method("get_game_week"):
		current_week = safe_house_manager.get_game_week()
	
	if week_label:
		week_label.text = "当前周期: 第 " + str(current_week) + " 周"
	
	# 更新当前时间
	if time_label:
		var datetime = Time.get_datetime_dict_from_system()
		time_label.text = "当前时间: " + str(datetime.hour).pad_zeros(2) + ":" + str(datetime.minute).pad_zeros(2)

## 游戏周期变化回调
func _on_game_week_changed(week: int) -> void:
	current_week = week
	_update_display()

# 预览按钮响应函数
func _on_battle_preview_pressed() -> void:
	preview_button_pressed.emit(1) # BATTLE = 1

func _on_recruit_preview_pressed() -> void:
	preview_button_pressed.emit(2) # RECRUIT = 2

func _on_upgrade_preview_pressed() -> void:
	preview_button_pressed.emit(3) # UPGRADE = 3

func _on_research_preview_pressed() -> void:
	preview_button_pressed.emit(4) # RESEARCH = 4

func _on_brand_preview_pressed() -> void:
	preview_button_pressed.emit(5) # BRAND = 5 