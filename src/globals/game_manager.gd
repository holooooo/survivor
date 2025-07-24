extends Node

## 游戏管理器 - 负责管理游戏的整体状态和流程[br]
## 包括游戏状态切换、分数管理等核心功能

var current_state: GameConstants.GameState = GameConstants.GameState.MENU
var score: int = 0

# 生存时间追踪
var survival_time: float = 0.0
var game_start_time: float = 0.0

signal state_changed(new_state: GameConstants.GameState)

func _ready() -> void:
	# 连接事件总线信号
	EventBus.player_died.connect(_on_player_died)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.game_started.connect(_on_game_started)

func _process(delta: float) -> void:
	# 更新生存时间（只在游戏进行时）
	if current_state == GameConstants.GameState.PLAYING:
		survival_time += delta

## 开始游戏[br]
## 初始化游戏状态并发送游戏开始事件
func start_game() -> void:
	current_state = GameConstants.GameState.PLAYING
	score = 0
	survival_time = 0.0
	game_start_time = Time.get_time_dict_from_system()["hour"] * 3600 + Time.get_time_dict_from_system()["minute"] * 60 + Time.get_time_dict_from_system()["second"]
	state_changed.emit(current_state)
	EventBus.game_started.emit()

## 暂停游戏
func pause_game() -> void:
	if current_state == GameConstants.GameState.PLAYING:
		current_state = GameConstants.GameState.PAUSED
		get_tree().paused = true
		state_changed.emit(current_state)
		EventBus.game_paused.emit()

## 恢复游戏  
func resume_game() -> void:
	print("GameManager.resume_game() 被调用，当前状态: ", current_state)
	if current_state == GameConstants.GameState.PAUSED:
		current_state = GameConstants.GameState.PLAYING
		get_tree().paused = false
		state_changed.emit(current_state)
		EventBus.game_resumed.emit()
		print("游戏已恢复，状态切换为: ", current_state)
	else:
		print("游戏未处于暂停状态，无法恢复")

## 结束游戏
func end_game() -> void:
	current_state = GameConstants.GameState.GAME_OVER
	get_tree().paused = false
	state_changed.emit(current_state)
	EventBus.game_over.emit()

## 重置游戏状态[br]
## 用于重新开始游戏时清理所有状态
func reset_game() -> void:
	current_state = GameConstants.GameState.MENU
	score = 0
	survival_time = 0.0
	game_start_time = 0.0
	get_tree().paused = false

## 增加分数[br]
## [param points] 要增加的分数值
func add_score(points: int) -> void:
	score += points
	EventBus.ui_score_update_requested.emit(score)

## 获取当前分数
func get_score() -> int:
	return score

## 获取生存时间[br]
## [return] 生存时间（秒）
func get_survival_time() -> float:
	return survival_time

## 玩家死亡处理
func _on_player_died() -> void:
	end_game()

## 敌人死亡处理[br]
## [param enemy] 死亡的敌人节点
func _on_enemy_died(enemy: Node2D) -> void:
	add_score(10)  # 每个敌人10分

## 游戏开始处理
func _on_game_started() -> void:
	print("游戏开始！") 