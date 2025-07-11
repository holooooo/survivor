extends Control
class_name UpgradeRoom

## 改造室 - 改造角色能力和装备[br]
## 提升角色的各项属性和技能

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
	print("改造室已激活")

## 设置UI
func _setup_ui() -> void:
	if title_label:
		title_label.text = "改造室"
	
	if placeholder_label:
		placeholder_label.text = "升级你的角色能力和装备！" 