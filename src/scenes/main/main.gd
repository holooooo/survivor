extends Node2D

## 主场景控制器 - 游戏的主要入口点[br]
## 负责初始化各个系统并启动游戏

@export var enemy_scenes: Array[PackedScene] = []
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var performance_monitor: Control = $UI/PerformanceMonitor

func _ready() -> void:
	# 设置敌人生成器的场景列表
	if enemy_spawner and not enemy_scenes.is_empty():
		enemy_spawner.enemy_scenes = enemy_scenes
	
	# 启动游戏
	GameManager.start_game()

func _input(event: InputEvent) -> void:
	# 暂停/恢复游戏
	if event.is_action_pressed("ui_cancel"):
		if GameManager.current_state == GameConstants.GameState.PLAYING:
			GameManager.pause_game()
		elif GameManager.current_state == GameConstants.GameState.PAUSED:
			GameManager.resume_game()
	
	# 切换性能监控显示（F3键）
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_F3 and event.pressed):
		if performance_monitor:
			performance_monitor.visible = not performance_monitor.visible
	
	# 装备切换（数字键1和2）
	if event is InputEventKey and event.pressed:
		var player: Node = get_tree().get_first_node_in_group("player")
		if player and player.has_node("PlayerEquipmentManager"):
			var equipment_manager = player.get_node("PlayerEquipmentManager")
			if event.keycode == KEY_1:
				equipment_manager.switch_to_fist()
			elif event.keycode == KEY_2:
				equipment_manager.switch_to_pistol()
