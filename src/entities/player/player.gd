extends Actor

## 玩家控制器 - 处理玩家移动、血量管理和战斗逻辑[br]
## 使用事件系统与其他模块通信，避免直接依赖

func _ready() -> void:
	super ()
	current_health = max_health
	
	# 将玩家添加到player组，便于其他系统获取玩家引用
	add_to_group("player")
	
	
	# 连接Actor的信号到事件总线
	health_changed.connect(_on_health_changed)
	died.connect(_on_died)
	
	# 使用事件总线发送血量变化
	EventBus.emit_player_health_changed(current_health, max_health)

func _physics_process(delta):
	var direction = Vector2.ZERO
	
	# WASD 控制
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	
	# 使用Actor基类的移动方法
	if direction != Vector2.ZERO:
		move_by_direction(direction, delta)
	
	# 更新物理优化器的玩家位置
	if has_node("/root/PhysicsOptimizer"):
		get_node("/root/PhysicsOptimizer").update_player_position(global_position)

## 重写Actor的受伤方法，添加伤害数字显示
func take_damage(damage: int) -> void:
	super (damage)
	# 通过 EventBus 显示伤害数字，玩家伤害使用橙色显示
	EventBus.show_damage_number(damage, global_position, Color.ORANGE)

## 重写Actor的死亡回调
func _on_death() -> void:
	print("玩家死亡!")
	# 当生命值为0时跳转到游戏结束场景
	if current_health <= 0:
		EventBus.change_scene_safely("res://src/ui/game_over.tscn")

## 血量变化处理
func _on_health_changed(new_health: int, max_hp: int) -> void:
	EventBus.emit_player_health_changed(new_health, max_hp)

## 玩家死亡处理
func _on_died(actor: Actor) -> void:
	EventBus.player_died.emit()

## 治疗[br]
## [param amount] 治疗数值
func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	EventBus.emit_player_health_changed(current_health, max_health)
