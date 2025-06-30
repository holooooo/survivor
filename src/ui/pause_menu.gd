extends Control

## 暂停界面控制器[br]
## 负责显示游戏暂停时的界面，包括存活时长、装备信息等[br]
## 处理继续游戏和退出游戏的交互

@onready var survival_time_label: Label = %SurvivalTimeLabel
@onready var current_wave_label: Label = %CurrentWaveLabel
@onready var score_label: Label = %ScoreLabel
@onready var resume_button: Button = %ResumeButton
@onready var equipment_container: VBoxContainer = %EquipmentContainer

signal resume_requested

func _ready() -> void:
	# 设置处理模式，让暂停界面在游戏暂停时仍能工作
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# 连接按钮信号
	if resume_button:
		resume_button.pressed.connect(_on_resume_button_pressed)
	
	# 连接事件总线信号
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_resumed.connect(_on_game_resumed)
	
	# 初始状态隐藏
	visible = false

func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	# ESC键恢复游戏
	if event.is_action_pressed("ui_cancel"):
		_resume_game()
		get_viewport().set_input_as_handled()

## 更新界面显示信息
func _update_display() -> void:
	if not visible:
		return
		
	# 更新存活时长
	if survival_time_label:
		var time = GameManager.get_survival_time()
		var minutes = int(time) / 60
		var seconds = int(time) % 60
		survival_time_label.text = "存活时长: %02d:%02d" % [minutes, seconds]
	
	# 更新当前波次
	if current_wave_label:
		current_wave_label.text = "当前波次: %d" % GameManager.current_wave
	
	# 更新分数
	if score_label:
		score_label.text = "分数: %d" % GameManager.get_score()
	
	# 更新装备信息
	_update_equipment_display()

## 更新装备显示
func _update_equipment_display() -> void:
	if not equipment_container:
		return
		
	# 清空现有装备显示
	for child in equipment_container.get_children():
		child.queue_free()
	
	# 获取玩家装备管理器
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
		
	var equipment_manager = player.get_node("EquipmentManager")
	if not equipment_manager or not equipment_manager.slot_manager:
		return
	
	# 显示装备信息
	var equipment_title_label = Label.new()
	equipment_title_label.text = "当前装备:"
	equipment_title_label.add_theme_font_size_override("font_size", 18)
	equipment_container.add_child(equipment_title_label)
	
	# 显示装备槽位
	var equipment_slot_info = equipment_manager.get_equipment_slot_info()
	var equipment_info_label = Label.new()
	equipment_info_label.text = "装备槽位: %d/%d" % [equipment_slot_info.used_slots, equipment_slot_info.total_slots]
	equipment_container.add_child(equipment_info_label)
	
	# 显示已装备的装备
	var equipped_instances = equipment_manager.get_all_equipment_instances()
	for i in range(equipped_instances.size()):
		var equipment = equipped_instances[i]
		var equipment_label = Label.new()
		equipment_label.text = "  装备 %d: %s" % [i + 1, equipment.equipment_name]
		equipment_container.add_child(equipment_label)
	
	# 添加分隔符
	var separator_label = Label.new()
	separator_label.text = ""
	equipment_container.add_child(separator_label)
	
	# 显示mod信息
	var mod_title_label = Label.new()
	mod_title_label.text = "当前Mod:"
	mod_title_label.add_theme_font_size_override("font_size", 18)
	equipment_container.add_child(mod_title_label)
	
	# 显示mod槽位
	var mod_slot_info = equipment_manager.get_mod_slot_info()
	var mod_info_label = Label.new()
	mod_info_label.text = "Mod槽位: %d/%d" % [mod_slot_info.used_slots, mod_slot_info.total_slots]
	equipment_container.add_child(mod_info_label)
	
	# 显示已装备的mod
	var equipped_mods = equipment_manager.get_all_equipped_mods()
	if equipped_mods.is_empty():
		var no_mod_label = Label.new()
		no_mod_label.text = "  无已装备的Mod"
		equipment_container.add_child(no_mod_label)
	else:
		for i in range(equipped_mods.size()):
			var mod = equipped_mods[i]
			var mod_label = Label.new()
			mod_label.text = "  Mod %d: %s" % [i + 1, mod.mod_name]
			equipment_container.add_child(mod_label)

## 游戏暂停时的处理
func _on_game_paused() -> void:
	visible = true
	_update_display()
	
	# 启动定时更新
	_start_update_timer()

## 游戏恢复时的处理
func _on_game_resumed() -> void:
	visible = false
	_stop_update_timer()

## 恢复游戏按钮点击处理
func _on_resume_button_pressed() -> void:
	print("继续游戏按钮被点击")
	_resume_game()

## 恢复游戏
func _resume_game() -> void:
	print("调用GameManager.resume_game()")
	GameManager.resume_game()

var update_timer: Timer

## 启动更新定时器
func _start_update_timer() -> void:
	if update_timer:
		update_timer.queue_free()
	
	update_timer = Timer.new()
	update_timer.wait_time = 0.1  # 每0.1秒更新一次
	update_timer.timeout.connect(_update_display)
	add_child(update_timer)
	update_timer.start()

## 停止更新定时器
func _stop_update_timer() -> void:
	if update_timer:
		update_timer.queue_free()
		update_timer = null 