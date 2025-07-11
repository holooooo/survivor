extends Control
class_name EquipmentSlot

## 装备槽位UI组件 - 管理单个槽位的显示[br]
## 支持装备和mod的显示，使用灰色遮罩显示冷却和装填进度

@onready var icon: TextureRect = $Panel/VBoxContainer/Icon
@onready var name_label: Label = $Panel/VBoxContainer/Name
@onready var cooldown_mask: ColorRect = $Panel/CooldownMask
@onready var type_label: Label = $Panel/PositionLabel

var equipment_instance: EquipmentBase
var mod_resource: ModResource
var progress_timer: Timer
var slot_index: int = -1
var slot_type: String = ""  # "equipment" 或 "mod"

func _ready() -> void:
	# 创建进度更新定时器
	_setup_progress_timer()
	
	# 初始化遮罩状态
	if cooldown_mask:
		cooldown_mask.visible = false

## 设置进度更新定时器
func _setup_progress_timer() -> void:
	progress_timer = Timer.new()
	progress_timer.wait_time = 0.05  # 每0.05秒更新一次进度，保证动画流畅
	progress_timer.timeout.connect(_update_progress_display)
	progress_timer.autostart = true
	add_child(progress_timer)

## 设置槽位基本信息[br]
## [param index] 槽位索引[br]
## [param type] 槽位类型
func setup_slot(index: int, type: String) -> void:
	slot_index = index
	slot_type = type
	_update_type_label()

## 设置装备实例并更新显示[br]
## [param new_equipment_instance] 新的装备实例，null表示清空槽位
func set_equipment_instance(new_equipment_instance: EquipmentBase) -> void:
	equipment_instance = new_equipment_instance
	mod_resource = null  # 清空mod引用
	_update_display()

## 设置mod资源并更新显示[br]
## [param new_mod_resource] 新的mod资源，null表示清空槽位
func set_mod_resource(new_mod_resource: ModResource) -> void:
	mod_resource = new_mod_resource
	equipment_instance = null  # 清空装备引用
	_update_display()

## 更新显示（图标和名称）
func _update_display() -> void:
	if equipment_instance:
		_show_equipment()
	elif mod_resource:
		_show_mod()
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

## 显示mod信息
func _show_mod() -> void:
	# 设置mod图标（如果有的话）
	if mod_resource.has_method("get_icon") and mod_resource.get_icon():
		icon.texture = mod_resource.get_icon()
		icon.modulate = Color.MAGENTA
	else:
		# 使用默认mod图标
		var default_texture: Texture2D = load("res://icon.svg")
		if default_texture:
			icon.texture = default_texture
			icon.modulate = Color.MAGENTA
	
	# 设置mod名称
	name_label.text = mod_resource.mod_name

## 更新类型标签
func _update_type_label() -> void:
	if not type_label:
		return
	
	match slot_type:
		"equipment":
			type_label.text = "装备"
			type_label.modulate = Color.CYAN
		"mod":
			type_label.text = "Mod"
			type_label.modulate = Color.MAGENTA
		_:
			type_label.text = "空"
			type_label.modulate = Color.GRAY

## 清空显示
func _clear_display() -> void:
	icon.texture = null
	name_label.text = ""
	if cooldown_mask:
		cooldown_mask.visible = false
	_update_type_label()

## 更新进度显示（定时器调用）[br]
## 使用灰色遮罩从顶部往下逐渐消失来显示冷却或装填进度[br]
## 只对装备有效，mod无进度显示
func _update_progress_display() -> void:
	if not equipment_instance or not cooldown_mask or slot_type != "equipment":
		if cooldown_mask:
			cooldown_mask.visible = false
		return
	
	var progress: float = 0.0
	var has_progress: bool = false
	
	# 检查是否是手枪装备，获取装填进度
	if equipment_instance.has_method("get_status_info"):
		var status = equipment_instance.get_status_info()
		if status.has("is_reloading") and status.is_reloading:
			# 正在装填 - 显示装填进度
			progress = status.get("reload_progress", 0.0)
			has_progress = true
	
	# 如果没有装填进度，检查冷却进度
	if not has_progress:
		var remaining_cooldown: float = equipment_instance.get_remaining_cooldown()
		var total_cooldown: float = equipment_instance.cooldown_time
		
		if remaining_cooldown > 0.0 and total_cooldown > 0.0:
			# 冷却中 - 显示冷却进度（从1.0到0.0）
			progress = remaining_cooldown / total_cooldown
			has_progress = true
	
	# 更新遮罩显示
	if has_progress and progress > 0.0:
		_show_progress_mask(progress)
	else:
		_hide_progress_mask()

## 显示进度遮罩[br]
## [param progress] 进度值（0.0-1.0），1.0表示完全遮罩，0.0表示无遮罩
func _show_progress_mask(progress: float) -> void:
	if not cooldown_mask:
		return
	
	cooldown_mask.visible = true
	
	# 计算遮罩高度（从顶部往下，progress越小遮罩越少）
	var total_height: float = size.y
	var mask_height: float = total_height * progress
	
	# 使用锚点和偏移量来实现从顶部开始的遮罩效果
	cooldown_mask.anchor_top = 0.0
	cooldown_mask.anchor_bottom = progress
	cooldown_mask.offset_top = 0.0
	cooldown_mask.offset_bottom = 0.0
	cooldown_mask.anchor_left = 0.0
	cooldown_mask.anchor_right = 1.0
	cooldown_mask.offset_left = 0.0
	cooldown_mask.offset_right = 0.0

## 隐藏进度遮罩
func _hide_progress_mask() -> void:
	if cooldown_mask:
		cooldown_mask.visible = false

## 获取当前装备实例[br]
## [returns] 当前装备实例
func get_equipment_instance() -> EquipmentBase:
	return equipment_instance

## 获取当前mod资源[br]
## [returns] 当前mod资源
func get_mod_resource() -> ModResource:
	return mod_resource 