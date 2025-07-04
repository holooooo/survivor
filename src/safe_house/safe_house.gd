extends Control
class_name SafeHouse

## 安全屋主场景 - 局外培养和进入战斗的核心场景[br]
## 协调各个房间组件，提供完整的安全屋功能

@onready var navigation_bar: Control = $VBoxContainer/NavigationBar
@onready var room_container: Control = $VBoxContainer/RoomContainer
@onready var safe_house_manager: Node = $SafeHouseManager

# 房间节点引用
@onready var main_room: Control = $VBoxContainer/RoomContainer/MainRoom
@onready var battle_room: Control = $VBoxContainer/RoomContainer/BattleRoom
@onready var recruit_room: Control = $VBoxContainer/RoomContainer/RecruitRoom
@onready var upgrade_room: Control = $VBoxContainer/RoomContainer/UpgradeRoom
@onready var research_room: Control = $VBoxContainer/RoomContainer/ResearchRoom
@onready var brand_room: Control = $VBoxContainer/RoomContainer/BrandRoom

func _ready() -> void:
	_initialize_safe_house()

## 初始化安全屋系统
func _initialize_safe_house() -> void:
	# 设置管理器
	if safe_house_manager and room_container:
		safe_house_manager.set_room_container(room_container)
	
	# 设置导航栏
	if navigation_bar and safe_house_manager:
		navigation_bar.set_safe_house_manager(safe_house_manager)
		navigation_bar.room_button_pressed.connect(_on_room_button_pressed)
	
	# 设置各房间的管理器引用
	_setup_room_references()
	
	# 连接房间信号
	_connect_room_signals()
	
	print("安全屋初始化完成")

## 设置各房间的管理器引用
func _setup_room_references() -> void:
	if main_room and safe_house_manager:
		main_room.set_safe_house_manager(safe_house_manager)

## 连接房间信号
func _connect_room_signals() -> void:
	# 连接主房间的预览按钮信号
	if main_room:
		main_room.preview_button_pressed.connect(_on_preview_button_pressed)
	
	# 连接作战室信号
	if battle_room:
		battle_room.battle_requested.connect(_on_battle_requested)
		if battle_room.has_signal("return_to_main_requested"):
			battle_room.return_to_main_requested.connect(_on_return_to_main_requested)
	
	# 连接其他房间的返回主界面信号
	if recruit_room and recruit_room.has_signal("return_to_main_requested"):
		recruit_room.return_to_main_requested.connect(_on_return_to_main_requested)
	if upgrade_room and upgrade_room.has_signal("return_to_main_requested"):
		upgrade_room.return_to_main_requested.connect(_on_return_to_main_requested)
	if research_room and research_room.has_signal("return_to_main_requested"):
		research_room.return_to_main_requested.connect(_on_return_to_main_requested)
	if brand_room and brand_room.has_signal("return_to_main_requested"):
		brand_room.return_to_main_requested.connect(_on_return_to_main_requested)

## 导航栏按钮响应
func _on_room_button_pressed(room_type: int) -> void:
	if safe_house_manager:
		safe_house_manager.switch_to_room(room_type)

## 主房间预览按钮响应
func _on_preview_button_pressed(room_type: int) -> void:
	if safe_house_manager:
		safe_house_manager.switch_to_room(room_type)

## 战斗请求响应
func _on_battle_requested() -> void:
	print("切换到战斗场景")
	# 这里将来会实现场景切换到战斗场景
	get_tree().change_scene_to_file("res://src/scenes/fight/fight.tscn")

## 返回主界面响应
func _on_return_to_main_requested() -> void:
	if safe_house_manager:
		safe_house_manager.switch_to_room(0) # 返回主界面 (MAIN = 0)
	
## 返回主菜单[br]
## 提供一个返回主菜单的方法供外部调用
func return_to_main_menu() -> void:
	print("返回主菜单")
	# 这里将来会实现返回主菜单的逻辑 