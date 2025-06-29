extends Control
class_name RecruitRoom

## 招募室 - 招募、查看、开除角色[br]
## 管理角色队伍的组成和人员变动

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var placeholder_label: Label = $VBoxContainer/ContentContainer/PlaceholderLabel

# 信号
signal return_to_main_requested() ## 返回主界面信号

func _ready() -> void:
	_setup_ui()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # ESC键
		return_to_main_requested.emit()

## 房间激活时调用
func on_room_activated() -> void:
	print("招募室已激活")

## 设置UI
func _setup_ui() -> void:
	if title_label:
		title_label.text = "招募室"
	
	if placeholder_label:
		placeholder_label.text = "在这里招募新的角色，组建你的团队！" 