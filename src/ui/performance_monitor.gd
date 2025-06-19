extends Control
class_name PerformanceMonitor

## 性能监控UI组件[br]
## 显示FPS、角色数量和飞行物数量等性能指标

@onready var fps_label: Label = $VBox/FPSLabel
@onready var entities_label: Label = $VBox/EntitiesLabel

var update_timer: float = 0.0
var update_interval: float = 0.5  ## 更新间隔（秒）

func _ready() -> void:
	# 设置UI位置到右上角
	anchors_preset = Control.PRESET_TOP_RIGHT
	position = Vector2(-10, 10)
	
	# 设置背景和样式
	modulate = Color(1, 1, 1, 0.8)
	
	# 只在需要时显示
	visible = GameConstants.SHOW_PERFORMANCE_MONITOR

func _process(delta: float) -> void:
	if not visible:
		return
		
	update_timer += delta
	if update_timer >= update_interval:
		update_performance_display()
		update_timer = 0.0

## 更新性能显示[br]
## 获取并显示最新的性能数据
func update_performance_display() -> void:
	# 更新FPS
	var fps: int = Engine.get_frames_per_second()
	fps_label.text = "FPS: %d" % fps
	
	# 获取场景中的实体数量
	var character_count: int = get_character_count()
	var projectile_count: int = get_projectile_count()
	
	entities_label.text = "角色: %d | 飞行物: %d" % [character_count, projectile_count]

## 获取角色数量[br]
## [returns] 场景中的角色数量（玩家+敌人）
func get_character_count() -> int:
	var count: int = 0
	
	# 计算玩家数量
	count += get_tree().get_nodes_in_group("player").size()
	
	# 尝试从敌人生成器获取敌人数量
	var spawner: Node = get_tree().current_scene.find_child("EnemySpawner")
	if spawner and spawner.has_method("get_current_enemy_count"):
		count += spawner.get_current_enemy_count()
	else:
		# 备用方案：遍历场景查找敌人
		for node in get_tree().current_scene.find_children("*"):
			if node is EnemyBase:
				count += 1
	
	return count

## 获取飞行物数量[br]
## [returns] 场景中的飞行物数量（子弹、投射物等）
func get_projectile_count() -> int:
	var count: int = 0
	
	# 查找所有子弹和投射物节点
	for node in get_tree().current_scene.find_children("*"):
		# 通过类型识别（最准确）
		if node is Bullet:
			count += 1
		# 通过节点名称识别
		elif (node.name.begins_with("Bullet") or 
			node.name.begins_with("Projectile") or
			node.name.to_lower().contains("bullet") or
			node.name.to_lower().contains("projectile")):
			count += 1
		# 通过脚本特征识别（有setup或set_direction方法的通常是子弹）
		elif (node.has_method("setup") or node.has_method("set_direction")) and node is Area2D:
			count += 1
		# 通过类名识别
		elif node.get_script() and str(node.get_script()).contains("bullet"):
			count += 1
	
	return count

## 设置可见性[br]
## [param is_visible] 是否可见
func set_monitor_visible(is_visible: bool) -> void:
	visible = is_visible

## 设置更新间隔[br]
## [param interval] 更新间隔（秒）
func set_update_interval(interval: float) -> void:
	update_interval = max(0.1, interval) 