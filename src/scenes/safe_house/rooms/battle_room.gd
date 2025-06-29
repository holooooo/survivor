extends Control
class_name BattleRoom

## 作战室 - 选择角色和目的地，进入战斗场景[br]
## 提供任务选择、角色配置和战斗启动功能

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var content_container: VBoxContainer = $VBoxContainer/ContentContainer
@onready var placeholder_label: Label = $VBoxContainer/ContentContainer/PlaceholderLabel
@onready var enter_battle_button: Button = $VBoxContainer/ContentContainer/EnterBattleButton

# 信号
signal battle_requested()
signal return_to_main_requested() ## 返回主界面信号

func _ready() -> void:
	_setup_ui()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # ESC键
		return_to_main_requested.emit()

## 房间激活时调用
func on_room_activated() -> void:
	print("作战室已激活")

## 设置UI
func _setup_ui() -> void:
	if title_label:
		title_label.text = "作战室"
	
	if placeholder_label:
		placeholder_label.text = "选择你的角色和目标，准备进入战斗！"
	
	if enter_battle_button:
		enter_battle_button.text = "进入战斗"
		enter_battle_button.pressed.connect(_on_enter_battle_pressed)

## 进入战斗按钮响应
func _on_enter_battle_pressed() -> void:
	battle_requested.emit()
	print("请求进入战斗场景") 