extends Node2D

## 高性能伤害数字对象池[br]
## 支持每秒上万次调用，使用网格系统避免位置重叠[br]
## 预计算偏移值，最小化运行时计算开销

# 对象池配置
@export var max_damage_numbers: int = 200  # 增加池大小应对高频调用
var damage_number_scene: PackedScene = preload("res://src/scenes/common/prefabs/damage_number.tscn")

# 对象池数据
var _damage_number_pool: Array[Label] = []
var _pool_index: int = 0

# 高性能位置管理系统
const GRID_SIZE: int = 32  # 网格单元大小
const MAX_POSITIONS_PER_GRID: int = 8  # 每个网格最多允许的伤害数字数量
const POSITION_TIMEOUT: float = 0.5  # 位置占用超时时间（秒）

# 预计算的偏移位置数组
var _precomputed_offsets: Array[Vector2] = []
var _offset_index: int = 0

# 网格位置管理
var _grid_positions: Dictionary = {}  # 键: Vector2i(网格坐标), 值: Array[PositionData]
var _current_time: float = 0.0

# 位置数据结构
class PositionData:
	var position: Vector2
	var timestamp: float
	
	func _init(pos: Vector2, time: float) -> void:
		position = pos
		timestamp = time

func _ready() -> void:
	_precompute_offsets()
	_initialize_pool()
	register_pool()

## 预计算偏移位置数组，避免运行时计算
func _precompute_offsets() -> void:
	const OFFSET_COUNT: int = 64  # 预计算64个不同的偏移位置
	const MAX_OFFSET: float = GameConstants.DAMAGE_NUMBER_OFFSET_RANGE
	
	_precomputed_offsets.clear()
	_precomputed_offsets.resize(OFFSET_COUNT)
	
	# 使用螺旋分布确保位置分散
	for i in OFFSET_COUNT:
		var angle: float = i * 2.39996323  # 黄金角（弧度），确保均匀分布
		var radius: float = MAX_OFFSET * sqrt(float(i) / OFFSET_COUNT)
		var offset: Vector2 = Vector2(cos(angle) * radius, sin(angle) * radius)
		_precomputed_offsets[i] = offset

## 初始化对象池
func _initialize_pool() -> void:
	_damage_number_pool.clear()
	_damage_number_pool.resize(max_damage_numbers)
	
	for i in max_damage_numbers:
		var damage_number: Label = damage_number_scene.instantiate()
		_damage_number_pool[i] = damage_number
		add_child(damage_number)

## 注册信号处理
func register_pool() -> void:
	EventBus.damage_number_requested.connect(create_damage_number)

func _process(delta: float) -> void:
	_current_time += delta
	
	# 定期清理过期的位置数据（每秒清理一次）
	if fmod(_current_time, 1.0) < delta:
		_cleanup_expired_positions()

## 清理过期的位置数据
func _cleanup_expired_positions() -> void:
	var cutoff_time: float = _current_time - POSITION_TIMEOUT
	
	for grid_coord in _grid_positions.keys():
		var positions: Array = _grid_positions[grid_coord]
		# 从后往前遍历，安全删除过期项
		for i in range(positions.size() - 1, -1, -1):
			var pos_data: PositionData = positions[i]
			if pos_data.timestamp < cutoff_time:
				positions.remove_at(i)
		
		# 如果网格为空，删除整个网格记录
		if positions.is_empty():
			_grid_positions.erase(grid_coord)

## 获取下一个可用的伤害数字实例[br]
## 使用循环索引实现高效的对象池管理
func _get_next_damage_number() -> Label:
	var damage_number: Label = _damage_number_pool[_pool_index]
	_pool_index = (_pool_index + 1) % max_damage_numbers
	return damage_number

## 获取下一个预计算的偏移位置[br]
## 避免运行时的随机数生成开销
func _get_next_offset() -> Vector2:
	var offset: Vector2 = _precomputed_offsets[_offset_index]
	_offset_index = (_offset_index + 1) % _precomputed_offsets.size()
	return offset

## 将世界坐标转换为网格坐标
func _world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / GRID_SIZE),
		int(world_pos.y / GRID_SIZE)
	)

## 检查位置是否在摄像机可见范围内[br]
## [param world_position] 世界坐标位置[br]
## [returns] 是否在可见范围内
func _is_position_visible(world_position: Vector2) -> bool:
	var viewport: Viewport = get_viewport()
	if not viewport:
		return true  # 无法获取视口时，默认显示
	
	# 获取屏幕大小
	var screen_size: Vector2 = viewport.get_visible_rect().size
	var screen_rect: Rect2
	
	# 如果有相机，基于相机位置计算屏幕区域
	var camera: Camera2D = viewport.get_camera_2d()
	if camera:
		var camera_pos: Vector2 = camera.global_position
		screen_rect = Rect2(
			camera_pos - screen_size * 0.5,
			screen_size
		)
	else:
		# 没有相机时，使用默认屏幕区域
		screen_rect = Rect2(Vector2.ZERO, screen_size)
	
	# 添加一定的边距，确保边缘伤害数字也能显示
	var screen_margin: float = 100.0
	var expanded_screen: Rect2 = screen_rect.grow(screen_margin)
	
	return expanded_screen.has_point(world_position)

## 查找无重叠的显示位置[br]
## [param base_position] 基础位置[br]
## 返回避免重叠的最终显示位置
func _find_non_overlapping_position(base_position: Vector2) -> Vector2:
	var grid_coord: Vector2i = _world_to_grid(base_position)
	
	# 检查当前网格是否已满
	if not _grid_positions.has(grid_coord):
		_grid_positions[grid_coord] = []
	
	var positions: Array = _grid_positions[grid_coord]
	
	# 如果网格未满，尝试添加位置
	if positions.size() < MAX_POSITIONS_PER_GRID:
		var final_position: Vector2 = base_position + _get_next_offset()
		var pos_data: PositionData = PositionData.new(final_position, _current_time)
		positions.append(pos_data)
		return final_position
	
	# 网格已满，寻找相邻网格
	for x_offset in range(-1, 2):
		for y_offset in range(-1, 2):
			if x_offset == 0 and y_offset == 0:
				continue
			
			var neighbor_coord: Vector2i = grid_coord + Vector2i(x_offset, y_offset)
			if not _grid_positions.has(neighbor_coord):
				_grid_positions[neighbor_coord] = []
			
			var neighbor_positions: Array = _grid_positions[neighbor_coord]
			if neighbor_positions.size() < MAX_POSITIONS_PER_GRID:
				var neighbor_base: Vector2 = Vector2(neighbor_coord.x * GRID_SIZE, neighbor_coord.y * GRID_SIZE)
				var final_position: Vector2 = neighbor_base + _get_next_offset()
				var pos_data: PositionData = PositionData.new(final_position, _current_time)
				neighbor_positions.append(pos_data)
				return final_position
	
	# 如果所有相邻网格都满了，直接使用原位置（极端情况）
	return base_position + _get_next_offset()

## 从对象池获取并显示伤害数字[br]
## [param damage] 伤害数值[br]
## [param world_position] 世界坐标位置[br]
## [param color] 伤害数字颜色
func create_damage_number(damage: int, world_position: Vector2, color: Color) -> void:
	# 检查位置是否在摄像机可见范围内，不可见则直接返回
	if not _is_position_visible(world_position):
		return
	
	# 高效获取对象池实例
	var damage_number: Label = _get_next_damage_number()
	
	# 计算避免重叠的显示位置
	var base_position: Vector2 = world_position + Vector2(0, -30)
	var display_position: Vector2 = _find_non_overlapping_position(base_position)
	
	# 显示伤害数字
	damage_number.show_at_position(damage, color, display_position)

## 性能测试函数 - 模拟高频伤害数字生成[br]
## [param test_count] 测试调用次数[br]
## [param test_area_size] 测试区域大小
func _performance_test(test_count: int = 10000, test_area_size: float = 500.0) -> void:
	print("开始伤害数字池性能测试...")
	print("测试参数: %d 次调用, 测试区域: %.1f x %.1f" % [test_count, test_area_size, test_area_size])
	
	var start_time: float = Time.get_time_dict_from_system().values()[0]
	var colors: Array[Color] = [Color.RED, Color.YELLOW, Color.WHITE, Color.ORANGE, Color.CYAN]
	
	# 模拟高频调用
	for i in test_count:
		var random_pos: Vector2 = Vector2(
			randf_range(-test_area_size, test_area_size),
			randf_range(-test_area_size, test_area_size)
		)
		var damage: int = randi_range(10, 999)
		var color: Color = colors[randi() % colors.size()]
		
		create_damage_number(damage, random_pos, color)
	
	var end_time: float = Time.get_time_dict_from_system().values()[0]
	var duration: float = end_time - start_time
	
	print("性能测试完成!")
	print("耗时: %.3f 秒" % duration)
	print("平均每次调用: %.6f 秒" % (duration / test_count))
	print("理论最大TPS: %.0f" % (test_count / duration))
	print("活跃网格数量: %d" % _grid_positions.size())

## 获取当前池状态信息
func get_pool_stats() -> Dictionary:
	var active_grids: int = _grid_positions.size()
	var total_positions: int = 0
	
	for positions in _grid_positions.values():
		total_positions += positions.size()
	
	return {
		"pool_size": max_damage_numbers,
		"current_pool_index": _pool_index,
		"active_grids": active_grids,
		"total_tracked_positions": total_positions,
		"precomputed_offsets": _precomputed_offsets.size(),
		"current_offset_index": _offset_index
	}
