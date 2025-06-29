extends Control
class_name NavigationBar

## 安全屋导航栏组件 - 提供房间间快速切换功能[br]
## 显示各房间按钮和当前房间信息

# 按钮节点引用（移除主界面按钮）
@onready var battle_button: Button = $VBoxContainer/HBoxContainer/BattleButton
@onready var recruit_button: Button = $VBoxContainer/HBoxContainer/RecruitButton
@onready var upgrade_button: Button = $VBoxContainer/HBoxContainer/UpgradeButton
@onready var research_button: Button = $VBoxContainer/HBoxContainer/ResearchButton
@onready var brand_button: Button = $VBoxContainer/HBoxContainer/BrandButton
@onready var current_room_label: Label = $VBoxContainer/InfoContainer/CurrentRoomLabel
@onready var game_week_label: Label = $VBoxContainer/InfoContainer/GameWeekLabel

# 安全屋管理器引用
var safe_house_manager: Node

# 信号
signal room_button_pressed(room_type: int)

func _ready() -> void:
	_setup_buttons()

## 设置安全屋管理器[br]
## [param manager] 安全屋管理器实例
func set_safe_house_manager(manager: Node) -> void:
	safe_house_manager = manager
	if safe_house_manager:
		safe_house_manager.room_changed.connect(_on_room_changed)
		safe_house_manager.game_week_changed.connect(_on_game_week_changed)
		_update_display()

## 设置按钮连接
func _setup_buttons() -> void:
	if battle_button:
		battle_button.pressed.connect(_on_battle_button_pressed)
	if recruit_button:
		recruit_button.pressed.connect(_on_recruit_button_pressed)
	if upgrade_button:
		upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	if research_button:
		research_button.pressed.connect(_on_research_button_pressed)
	if brand_button:
		brand_button.pressed.connect(_on_brand_button_pressed)

## 更新显示信息
func _update_display() -> void:
	if not safe_house_manager:
		return
	
	# 更新当前房间显示
	if current_room_label:
		var room_name = safe_house_manager.get_room_name(safe_house_manager.get_current_room())
		current_room_label.text = "当前位置: " + room_name
	
	# 更新游戏周期显示
	if game_week_label:
		game_week_label.text = "第 " + str(safe_house_manager.get_game_week()) + " 周"
	
	# 更新按钮状态
	_update_button_states()

## 更新按钮状态
func _update_button_states() -> void:
	if not safe_house_manager:
		return
	
	var current_room = safe_house_manager.get_current_room()
	
	# 设置按钮禁用状态（当前房间的按钮禁用）
	# 0=MAIN, 1=BATTLE, 2=RECRUIT, 3=UPGRADE, 4=RESEARCH, 5=BRAND
	if battle_button:
		battle_button.disabled = (current_room == 1)
	if recruit_button:
		recruit_button.disabled = (current_room == 2)
	if upgrade_button:
		upgrade_button.disabled = (current_room == 3)
	if research_button:
		research_button.disabled = (current_room == 4)
	if brand_button:
		brand_button.disabled = (current_room == 5)

## 房间切换回调
func _on_room_changed(new_room: int) -> void:
	_update_display()

## 游戏周期变化回调
func _on_game_week_changed(week: int) -> void:
	if game_week_label:
		game_week_label.text = "第 " + str(week) + " 周"

# 各按钮的响应函数
func _on_battle_button_pressed() -> void:
	room_button_pressed.emit(1) # BATTLE

func _on_recruit_button_pressed() -> void:
	room_button_pressed.emit(2) # RECRUIT

func _on_upgrade_button_pressed() -> void:
	room_button_pressed.emit(3) # UPGRADE

func _on_research_button_pressed() -> void:
	room_button_pressed.emit(4) # RESEARCH

func _on_brand_button_pressed() -> void:
	room_button_pressed.emit(5) # BRAND 