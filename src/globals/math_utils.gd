extends Node

## 数学工具类单例
## 提供游戏中常用的数学计算函数

## 获取屏幕边缘的随机生成位置[br]
## [param screen_size] 屏幕尺寸[br]
## [param spawn_distance] 距离屏幕边缘的距离[br]
## 返回屏幕边缘外的随机位置
func get_random_spawn_position(screen_size: Vector2, spawn_distance: float = 100.0) -> Vector2:
	var spawn_position := Vector2()
	var edge := randi() % 4
	
	match edge:
		0: # 上边
			spawn_position = Vector2(randf_range(0, screen_size.x), -spawn_distance)
		1: # 下边
			spawn_position = Vector2(randf_range(0, screen_size.x), screen_size.y + spawn_distance)
		2: # 左边  
			spawn_position = Vector2(-spawn_distance, randf_range(0, screen_size.y))
		3: # 右边
			spawn_position = Vector2(screen_size.x + spawn_distance, randf_range(0, screen_size.y))
			
	return spawn_position

## 获取带偏移的随机位置[br]
## [param base_position] 基础位置[br]
## [param offset_range] 偏移范围[br]
## 返回在基础位置周围随机偏移的位置
func get_random_offset_position(base_position: Vector2, offset_range: float) -> Vector2:
	var offset := Vector2(
		randf_range(-offset_range, offset_range),
		randf_range(-offset_range, offset_range)
	)
	return base_position + offset

## 限制向量的长度[br]
## [param vector] 要限制的向量[br]
## [param max_length] 最大长度[br]
## 返回长度不超过最大值的向量
func clamp_vector_length(vector: Vector2, max_length: float) -> Vector2:
	if vector.length() > max_length:
		return vector.normalized() * max_length
	return vector 

## 获取相对于玩家位置的屏幕外重生位置[br]
## [param player_position] 玩家当前位置[br]
## [param spawn_distance] 距离屏幕边缘的距离[br]
## 返回以玩家为中心的屏幕边缘外的随机位置，确保敌人在视野外生成
func get_respawn_position_around_player(player_position: Vector2, spawn_distance: float = 300.0) -> Vector2:
	var viewport: Viewport = Engine.get_main_loop().current_scene.get_viewport()
	var screen_size: Vector2 = viewport.get_visible_rect().size
	
	# 计算屏幕中心相对于玩家的偏移
	var camera: Camera2D = viewport.get_camera_2d()
	var screen_center: Vector2
	if camera:
		screen_center = camera.global_position
	else:
		screen_center = player_position
	
	# 计算屏幕边界相对于玩家位置
	var half_screen: Vector2 = screen_size * 0.5
	var screen_bounds: Rect2 = Rect2(
		screen_center - half_screen,
		screen_size
	)
	
	# 选择随机边缘
	var edge: int = randi() % 4
	var spawn_position: Vector2
	
	match edge:
		0: # 上边
			spawn_position = Vector2(
				randf_range(screen_bounds.position.x, screen_bounds.position.x + screen_bounds.size.x),
				screen_bounds.position.y - spawn_distance
			)
		1: # 下边
			spawn_position = Vector2(
				randf_range(screen_bounds.position.x, screen_bounds.position.x + screen_bounds.size.x),
				screen_bounds.position.y + screen_bounds.size.y + spawn_distance
			)
		2: # 左边
			spawn_position = Vector2(
				screen_bounds.position.x - spawn_distance,
				randf_range(screen_bounds.position.y, screen_bounds.position.y + screen_bounds.size.y)
			)
		3: # 右边
			spawn_position = Vector2(
				screen_bounds.position.x + screen_bounds.size.x + spawn_distance,
				randf_range(screen_bounds.position.y, screen_bounds.position.y + screen_bounds.size.y)
			)
	
	return spawn_position 
