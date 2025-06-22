extends EquipmentBase

## 炸弹装备 - 实现炸弹投射逻辑[br]
## 在指定范围内随机投掷多个炸弹


func _execute_equipment_effect() -> void:
	if not owner_player or bomb_config.is_empty():
		push_warning("炸弹装备缺少所有者或配置")
		return

	var projectile_count: int = bomb_config.get("projectiles_per_shot", 1)
	for _i in range(projectile_count):
		_spawn_bomb_projectile()


## 生成单个炸弹投射物
func _spawn_bomb_projectile() -> void:
	# 直接创建 BombProjectile 实例
	var projectile := BombProjectile.new()

	# 确保获取到有效的父节点
	var main_scene: Node = owner_player.get_tree().current_scene
	if not main_scene:
		push_error("无法获取主场景来添加炸弹投射物")
		projectile.queue_free()
		return

	main_scene.add_child(projectile)
	projectile.global_position = _get_random_spawn_position()
	
	# 直接调用 setup 方法
	projectile.setup(bomb_config)


## 获取随机生成位置[br]
## 在玩家周围的一个环形区域内随机选择一个点
## [returns] 随机生成的世界坐标
func _get_random_spawn_position() -> Vector2:
	if not owner_player:
		return Vector2.ZERO

	var min_dist: float = bomb_config.get("min_throw_distance", 50.0)
	var max_dist: float = bomb_config.get("max_throw_distance", 200.0)

	var random_angle: float = randf_range(0, 2 * PI)
	var random_distance: float = randf_range(min_dist, max_dist)

	var offset: Vector2 = Vector2.from_angle(random_angle) * random_distance
	return owner_player.global_position + offset 