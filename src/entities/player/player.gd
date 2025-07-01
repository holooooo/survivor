extends Actor
class_name Player

## 玩家控制器 - 处理玩家移动、血量管理和战斗逻辑[br]
## 使用事件系统与其他模块通信，避免直接依赖
@onready var equipment_manager: EquipmentManager = %EquipmentManager
@onready var mod_manager: ModManager = %ModManager
@onready var stats_manager: PlayerStatsManager = %PlayerStatsManager

func _ready() -> void:
	super ()
	current_health = max_health
	
	# 将玩家添加到player组，便于其他系统获取玩家引用
	add_to_group(Constants.GROUP_PLAYER)
	
	# 初始化属性管理器
	stats_manager.initialize(self)
	stats_manager.stats_changed.connect(_on_damage_type_stats_changed)
	stats_manager.base_stats_changed.connect(_on_base_stats_changed)
	
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

## 伤害类型属性变化处理[br]
## [param damage_type] 伤害类型[br]
## [param stat_name] 属性名称[br]
## [param old_value] 旧值[br]
## [param new_value] 新值
func _on_damage_type_stats_changed(damage_type: Constants.DamageType, stat_name: String, old_value: float, new_value: float) -> void:
	# 通知装备管理器重新计算属性
	if equipment_manager:
		equipment_manager.recalculate_equipment_stats()

## 基础属性变化处理[br]
## [param stat_name] 属性名称[br]
## [param old_value] 旧值[br]
## [param new_value] 新值
func _on_base_stats_changed(stat_name: String, old_value, new_value) -> void:
	# 处理基础属性变化
	match stat_name:
		"max_health_bonus":
			_update_max_health()
		"move_speed_multiplier":
			_update_movement_speed()

## 更新最大生命值[br]
func _update_max_health() -> void:
	if stats_manager:
		var health_bonus = stats_manager.get_base_stat("max_health_bonus")
		var new_max_health = int(max_health * (1.0 + health_bonus))
		if new_max_health != max_health:
			var health_ratio = float(current_health) / float(max_health)
			max_health = new_max_health
			current_health = int(max_health * health_ratio)
			EventBus.emit_player_health_changed(current_health, max_health)

## 更新移动速度[br]
func _update_movement_speed() -> void:
	if stats_manager:
		var speed_multiplier = stats_manager.get_base_stat("move_speed_multiplier")
		# 这里可以应用速度修改，需要根据Actor基类的实现来决定具体方式
		pass
