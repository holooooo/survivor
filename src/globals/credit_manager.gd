extends Node

## 信用点管理器 - 管理玩家的信用点系统[br]
## 负责信用点的获取、消费和存储

var current_credits: int = 0 ## 当前信用点数量

func _ready() -> void:
	# 连接敌人死亡事件
	EventBus.enemy_died.connect(_on_enemy_died)
	# 连接游戏重置事件
	EventBus.game_started.connect(_on_game_started)

## 增加信用点[br]
## [param amount] 要增加的信用点数量
func add_credits(amount: int) -> void:
	current_credits += amount
	EventBus.player_credits_changed.emit(current_credits)
	EventBus.ui_credits_update_requested.emit(current_credits)

## 消费信用点[br]
## [param amount] 要消费的信用点数量[br]
## [returns] 是否成功消费（信用点足够）
func spend_credits(amount: int) -> bool:
	if current_credits >= amount:
		current_credits -= amount
		EventBus.player_credits_changed.emit(current_credits)
		EventBus.ui_credits_update_requested.emit(current_credits)
		return true
	return false

## 获取当前信用点数量[br]
## [returns] 当前信用点数量
func get_credits() -> int:
	return current_credits

## 重置信用点（游戏开始时）
func reset_credits() -> void:
	current_credits = 0
	EventBus.player_credits_changed.emit(current_credits)
	EventBus.ui_credits_update_requested.emit(current_credits)

## 敌人死亡处理[br]
## [param enemy] 死亡的敌人节点
func _on_enemy_died(enemy: Node2D) -> void:
	if enemy and enemy.has_method("get") and enemy.get("credit_reward") != null:
		var credits: int = enemy.get("credit_reward")
		add_credits(credits)

## 游戏开始处理
func _on_game_started() -> void:
	reset_credits()