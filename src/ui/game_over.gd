extends Control

## 游戏结束界面控制器[br]
## 显示游戏结果信息并提供重新开始和退出选项

@onready var restart_button: Button = $VBoxContainer/ButtonContainer/RestartButton
@onready var quit_button: Button = $VBoxContainer/ButtonContainer/QuitButton
@onready var score_label: Label = $VBoxContainer/ScoreContainer/ScoreLabel
@onready var survival_time_label: Label = $VBoxContainer/ScoreContainer/SurvivalTimeLabel
@onready var credits_label: Label = $VBoxContainer/ScoreContainer/CreditsLabel

func _ready() -> void:
	# 连接按钮信号
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# 设置按钮焦点
	restart_button.grab_focus()

	# 连接 EventBus 信号获取游戏数据
	if EventBus.game_over.is_connected(_on_game_over_received):
		EventBus.game_over.disconnect(_on_game_over_received)
	EventBus.game_over.connect(_on_game_over_received)

	# 从 GameManager 获取游戏数据
	update_game_stats()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		_on_restart_pressed()
	elif event.is_action_pressed("ui_select"):
		_on_quit_pressed()

## 重新开始游戏
func _on_restart_pressed() -> void:
	# 重置游戏管理器状态
	GameManager.reset_game()
	# 安全地跳转到主游戏场景
	EventBus.change_scene_safely("res://src/fight/fight.tscn")

## 退出游戏
func _on_quit_pressed() -> void:
	if get_tree():
		get_tree().quit()
	else:
		print("错误：无法获取场景树")

## 更新游戏统计数据显示
func update_game_stats() -> void:
	# 获取最终得分（如果有得分系统的话）
	var final_score: int = 0
	if GameManager.has_method("get_score"):
		final_score = GameManager.get_score()

	# 获取生存时间
	var survival_time: float = 0.0
	if GameManager.has_method("get_survival_time"):
		survival_time = GameManager.get_survival_time()

	# 获取最终信用点数量
	var final_credits: int = 0
	if CreditManager.has_method("get_credits"):
		final_credits = CreditManager.get_credits()

	# 更新标签显示
	score_label.text = "最终得分: " + str(final_score)
	survival_time_label.text = "生存时间: " + format_time(survival_time)
	credits_label.text = "获得信用点: " + str(final_credits)

## 格式化时间显示[br]
## [param time_seconds] 时间（秒）[br]
## [return] 格式化的时间字符串 (MM:SS)
func format_time(time_seconds: float) -> String:
	var minutes: int = int(time_seconds) / 60
	var seconds: int = int(time_seconds) % 60
	return "%02d:%02d" % [minutes, seconds]

## 处理从事件总线接收到的游戏结束数据
func _on_game_over_received() -> void:
	update_game_stats()