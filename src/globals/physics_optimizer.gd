extends Node

## 物理性能优化管理器[br]
## 专门用于解决integrate force等物理性能问题[br]
## 通过智能管理物理对象来提升整体性能

var physics_objects: Array[Node2D] = []
var culling_enabled: bool = true
var player_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 设置定期清理
	var cleanup_timer: Timer = Timer.new()
	cleanup_timer.wait_time = 1.0  # 每秒清理一次
	cleanup_timer.timeout.connect(_perform_physics_cleanup)
	cleanup_timer.autostart = true
	add_child(cleanup_timer)

## 注册物理对象以便优化管理[br]
## [param obj] 要管理的物理对象
func register_physics_object(obj: Node2D) -> void:
	if obj not in physics_objects:
		physics_objects.append(obj)

## 注销物理对象[br]
## [param obj] 要移除的物理对象
func unregister_physics_object(obj: Node2D) -> void:
	physics_objects.erase(obj)

## 更新玩家位置用于剔除计算[br]
## [param pos] 玩家当前位置
func update_player_position(pos: Vector2) -> void:
	player_position = pos

## 执行物理清理和优化
func _perform_physics_cleanup() -> void:
	if not culling_enabled:
		return
	
	var objects_to_remove: Array[Node2D] = []
	
	for obj in physics_objects:
		if not is_instance_valid(obj):
			objects_to_remove.append(obj)
			continue
		
		# 距离剔除
		var distance: float = obj.global_position.distance_to(player_position)
		if distance > GameConstants.PHYSICS_CULLING_DISTANCE:
			if obj.has_method("queue_free"):
				obj.queue_free()
			objects_to_remove.append(obj)
			continue
		
		# Area2D优化
		if obj is Area2D and GameConstants.AREA2D_OPTIMIZATION:
			_optimize_area2d(obj as Area2D, distance)

	# 清理无效对象
	for obj in objects_to_remove:
		physics_objects.erase(obj)

## 优化Area2D性能[br]
## [param area] Area2D对象[br]
## [param distance] 距离玩家的距离
func _optimize_area2d(area: Area2D, distance: float) -> void:
	# 根据距离调整监控设置
	if distance > 500.0:
		# 远距离时降低监控频率
		area.monitoring = false
		area.monitorable = false
	else:
		# 近距离时启用监控
		area.monitoring = true
		area.monitorable = true

## 启用/禁用剔除功能[br]
## [param enabled] 是否启用
func set_culling_enabled(enabled: bool) -> void:
	culling_enabled = enabled

## 获取当前管理的物理对象数量[br]
## [returns] 物理对象数量
func get_physics_object_count() -> int:
	return physics_objects.size()

## 强制清理所有已注册的物理对象
func force_cleanup_all() -> void:
	for obj in physics_objects.duplicate():
		if is_instance_valid(obj) and obj.has_method("queue_free"):
			obj.queue_free()
	physics_objects.clear() 