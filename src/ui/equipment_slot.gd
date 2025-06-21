extends Control
class_name EquipmentSlot

## 装备槽位UI组件 - 管理单个装备槽的显示[br]
## 通过设置equipment_instance来更新显示内容

@onready var icon: TextureRect = $Panel/VBoxContainer/Icon
@onready var name_label: Label = $Panel/VBoxContainer/Name
@onready var cooldown_label: Label = $Panel/VBoxContainer/Cooldown

var equipment_instance: EquipmentBase
var cooldown_timer: Timer

func _ready() -> void:
	# 创建冷却时间更新定时器
	_setup_cooldown_timer()

## 设置冷却时间更新定时器
func _setup_cooldown_timer() -> void:
	cooldown_timer = Timer.new()
	cooldown_timer.wait_time = 0.1  # 每0.1秒更新一次冷却时间
	cooldown_timer.timeout.connect(_update_cooldown_display)
	cooldown_timer.autostart = true
	add_child(cooldown_timer)

## 设置装备实例并更新显示[br]
## [param new_equipment_instance] 新的装备实例，null表示清空槽位
func set_equipment_instance(new_equipment_instance: EquipmentBase) -> void:
	equipment_instance = new_equipment_instance
	_update_display()

## 更新装备显示（图标和名称）
func _update_display() -> void:
	if equipment_instance:
		_show_equipment()
	else:
		_clear_display()

## 显示装备信息
func _show_equipment() -> void:
	# 设置图标
	if equipment_instance.icon_texture:
		icon.texture = equipment_instance.icon_texture
		icon.modulate = Color.WHITE
	else:
		# 使用默认图标
		var default_texture: Texture2D = load("res://icon.svg")
		if default_texture:
			icon.texture = default_texture
			icon.modulate = Color.YELLOW
	
	# 设置装备名称
	name_label.text = equipment_instance.equipment_name

## 清空显示
func _clear_display() -> void:
	icon.texture = null
	name_label.text = ""
	cooldown_label.text = ""

## 更新冷却时间显示（定时器调用）
func _update_cooldown_display() -> void:
	if not equipment_instance:
		cooldown_label.text = ""
		return
	
	var remaining_cooldown: float = equipment_instance.get_remaining_cooldown()
	if remaining_cooldown > 0.0:
		cooldown_label.text = "%.1f" % remaining_cooldown
	else:
		cooldown_label.text = ""

## 获取当前装备实例[br]
## [returns] 当前装备实例
func get_equipment_instance() -> EquipmentBase:
	return equipment_instance 