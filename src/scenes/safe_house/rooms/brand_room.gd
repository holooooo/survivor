extends Control
class_name BrandRoom

## 品牌室 - 购买品牌通行证、联系新品牌等[br]
## 管理与各品牌的合作关系

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
	print("品牌室已激活")

## 设置UI
func _setup_ui() -> void:
	if title_label:
		title_label.text = "品牌室"
	
	if placeholder_label:
		placeholder_label.text = "与各大品牌建立合作关系，获取独特资源！" 