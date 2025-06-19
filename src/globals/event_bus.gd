extends Node

## 全局事件总线单例
## 用于处理游戏中的跨模块事件通信[br]
## 避免模块间的直接依赖，提供松耦合的通信方式

# 玩家相关事件
signal player_health_changed(current_health: int, max_health: int)
signal player_died
signal player_level_up(new_level: int)

# 敌人相关事件  
signal enemy_spawned(enemy: Node2D)
signal enemy_died(enemy: Node2D)
signal enemy_damaged(enemy: Node2D, damage: int)
signal enemy_respawned(enemy: Node2D)

# 游戏状态事件
signal game_started
signal game_paused
signal game_resumed
signal game_over
signal wave_completed(wave_number: int)

# UI事件
signal ui_health_update_requested(current_health: int, max_health: int)
signal ui_score_update_requested(new_score: int)
signal performance_update_requested(fps: int, characters: int, projectiles: int)

# 武器/战斗事件
signal weapon_fired(weapon_type: String, position: Vector2)
signal damage_dealt(target: Node2D, damage: int, position: Vector2)

# 伤害数字显示事件
signal damage_number_requested(damage: int, world_position: Vector2, color: Color, parent: Node)

# 伤害数字场景预加载
var damage_number_scene: PackedScene = preload("res://src/scenes/common/prefabs/damage_number.tscn")

## 发射伤害事件并在指定位置显示伤害数字[br]
## [param target] 受伤目标[br]
## [param damage] 伤害数值[br] 
## [param world_position] 世界坐标位置
func emit_damage_dealt(target: Node2D, damage: int, world_position: Vector2) -> void:
	damage_dealt.emit(target, damage, world_position)

## 发射玩家血量变化事件[br]
## [param current] 当前血量[br]
## [param maximum] 最大血量
func emit_player_health_changed(current: int, maximum: int) -> void:
	player_health_changed.emit(current, maximum)
	ui_health_update_requested.emit(current, maximum) 

## 显示伤害数字 - 统一的伤害数字显示逻辑[br]
## [param damage] 伤害数值[br]
## [param world_position] 世界坐标位置[br]
## [param color] 伤害数字颜色，默认为红色
## [param parent] 父节点，用于添加伤害数字
func show_damage_number(damage: int, world_position: Vector2, color: Color = Color.RED, parent: Node = null) -> void:
	# 发射信号，让主场景或其他监听者处理具体的显示逻辑
	damage_number_requested.emit(damage, world_position, color, parent)

## 实际创建伤害数字节点的方法[br]
## [param damage] 伤害数值[br]
## [param world_position] 世界坐标位置[br]
## [param color] 伤害数字颜色[br]
## [param parent] 父节点，用于添加伤害数字
func create_damage_number(damage: int, world_position: Vector2, color: Color, parent: Node) -> void:
	var damage_number: Label = damage_number_scene.instantiate()
	damage_number.set_damage(damage)
	damage_number.set_color(color)
	parent.add_child(damage_number)
	
	# 添加随机偏移避免重叠
	var random_offset: Vector2 = MathUtils.get_random_offset_position(Vector2.ZERO, GameConstants.DAMAGE_NUMBER_OFFSET_RANGE)
	damage_number.global_position = world_position + Vector2(0, -30) + random_offset

## 安全地切换场景[br]
## [param scene_path] 场景文件路径[br]
## [param delay] 延迟时间（秒），默认0.1秒
func change_scene_safely(scene_path: String, delay: float = 0.1) -> void:
	# 延迟执行场景切换，确保当前帧完成
	await get_tree().create_timer(delay).timeout
	
	if get_tree():
		var result = get_tree().change_scene_to_file(scene_path)
		if result != OK:
			print("场景切换失败: ", scene_path, " 错误代码: ", result)
	else:
		print("错误：无法获取场景树，无法切换场景: ", scene_path) 