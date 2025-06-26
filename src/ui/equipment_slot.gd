extends Control
class_name EquipmentSlot

## 装备槽位UI组件 - 管理单个装备槽的显示[br]
## 通过设置equipment_instance来更新显示内容，使用灰色遮罩显示冷却和装填进度

@onready var icon: TextureRect = $Panel/VBoxContainer/Icon
@onready var name_label: Label = $Panel/VBoxContainer/Name
@onready var cooldown_mask: ColorRect = $Panel/CooldownMask
@onready var position_label: Label = $Panel/PositionLabel

var equipment_instance: EquipmentBase
var progress_timer: Timer
var slot_position_type: int = -1  ## 槽位位置类型

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

## 设置装备实例并更新显示[br]
## [param new_equipment_instance] 新的装备实例，null表示清空槽位[br]
## [param position_type] 槽位位置类型
func set_equipment_instance(new_equipment_instance: EquipmentBase, position_type: int = -1) -> void:
	equipment_instance = new_equipment_instance
	if position_type != -1:
		slot_position_type = position_type
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
	
	# 设置位置类型标签
	_update_position_label()

## 更新位置类型标签
func _update_position_label() -> void:
	if not position_label:
		return
	
	var position_name: String = _get_position_type_name(slot_position_type)
	position_label.text = position_name
	
	# 根据位置类型设置颜色
	match slot_position_type:
		0: position_label.modulate = Color.RED     # 输出 - 红色
		1: position_label.modulate = Color.GREEN   # 移动 - 绿色  
		2: position_label.modulate = Color.BLUE    # 转化 - 蓝色
		3: position_label.modulate = Color.YELLOW  # 防御 - 黄色
		4: position_label.modulate = Color.WHITE   # 通用 - 白色
		_: position_label.modulate = Color.GRAY    # 未知 - 灰色

## 获取位置类型名称[br]
## [param position_type] 位置类型枚举值[br]
## [returns] 位置类型名称
func _get_position_type_name(position_type: int) -> String:
	match position_type:
		0: return "输出"
		1: return "移动"
		2: return "转化"
		3: return "防御"
		4: return "通用"
		_: return "空"

## 清空显示
func _clear_display() -> void:
	icon.texture = null
	name_label.text = ""
	if cooldown_mask:
		cooldown_mask.visible = false
	if position_label:
		position_label.text = _get_position_type_name(slot_position_type)

## 更新进度显示（定时器调用）[br]
## 使用灰色遮罩从顶部往下逐渐消失来显示冷却或装填进度
func _update_progress_display() -> void:
	if not equipment_instance or not cooldown_mask:
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