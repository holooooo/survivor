extends EmitterEquipmentBase
class_name ArcTowerEquipment

## 电弧塔装备 - 自动锁定攻击装备[br]
## 会自动对进入攻击范围的敌人发起攻击，每秒最多触发5次[br]
## 具备智能目标选择和冷却管理机制

var detection_interval: float = 0.1 ## 目标检测间隔（缩短以支持快速连续攻击）
var detection_timer: float = 0.0 ## 检测计时器
var current_targets: Array[Node2D] = [] ## 当前范围内的目标

func _ready() -> void:
	super._ready()
	_setup_range_detection()

## 自定义更新逻辑 - 电弧塔的自动攻击系统[br]
## [param delta] 时间增量
func _custom_update(delta: float) -> void:
	# 跟随玩家移动
	if owner_player:
		global_position = owner_player.global_position
	
	# 更新检测计时器
	detection_timer += delta
	
	# 定期检测目标
	if detection_timer >= detection_interval:
		detection_timer = 0.0
		_detect_targets()
	
	# 尝试自动攻击目标
	_try_auto_attack()



## 检查特定使用条件 - 电弧塔自动攻击条件[br]
## [returns] 是否满足特定条件
func _can_use_specific() -> bool:
	# 电弧塔只要有目标就可以攻击，不需要传统的范围检查
	return not current_targets.is_empty()

## 设置范围检测区域
func _setup_range_detection() -> void:
	# 延迟到 _ready 之后执行，确保配置已经应用
	call_deferred("_create_detection_area")

## 创建检测区域（延迟执行）
func _create_detection_area() -> void:
	# 创建检测区域
	var detection_area = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	
	circle_shape.radius = attack_range
	collision_shape.shape = circle_shape
	
	detection_area.add_child(collision_shape)
	add_child(detection_area)
	
	# 设置碰撞层级
	detection_area.collision_layer = 0
	detection_area.collision_mask = 2  # 敌人层
	
	# 连接信号
	detection_area.area_entered.connect(_on_enemy_entered_range)
	detection_area.area_exited.connect(_on_enemy_exited_range)

## 检测当前范围内的目标
func _detect_targets() -> void:
	if not owner_player:
		return
	
	
	# 更新目标列表，移除无效或已死亡的目标
	current_targets = current_targets.filter(func(target): return is_instance_valid(target) and not target.is_dead)
	
	# 主动搜索范围内的敌人（备用方法，确保能找到敌人）
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in all_enemies:
		if enemy and is_instance_valid(enemy) and not enemy.is_dead:
			var distance = owner_player.global_position.distance_to(enemy.global_position)
			
			if distance <= attack_range:
				if enemy not in current_targets:
					current_targets.append(enemy)
			else:
				if enemy in current_targets:
					current_targets.erase(enemy)


## 尝试自动攻击目标
func _try_auto_attack() -> void:
	# 检查是否有弹药（这个检查会在can_use中再次检查，但提前检查可以避免不必要的计算）
	if current_ammo <= 0:
		return
	
	# 检查是否有可攻击的目标
	if current_targets.is_empty():
		return
		
	# 连续攻击所有目标（直到弹药耗尽或没有目标）
	var attacks_this_frame = 0
	var max_attacks_per_frame = min(current_ammo, current_targets.size(), 3)  # 限制每帧最多3次攻击，避免卡顿
	
	while current_ammo > 0 and not current_targets.is_empty() and attacks_this_frame < max_attacks_per_frame:
		var target = _select_nearest_target()
		if target:
			# 使用基类的完整攻击系统，这会正确消耗弹药
			if use_equipment():
				attacks_this_frame += 1
				# 发射信号
				target_acquired.emit(target)
			else:
				break  # 无法攻击（冷却中或其他原因），退出循环
		else:
			break


## 选择最近的目标[br]
## [returns] 最近的敌人目标
func _select_nearest_target() -> Node2D:
	if current_targets.is_empty() or not owner_player:
		return null
	
	var nearest_target: Node2D = null
	var nearest_distance: float = INF
	
	for target in current_targets:
		if is_instance_valid(target):
			var distance = owner_player.global_position.distance_to(target.global_position)
			if distance < nearest_distance and distance <= attack_range:
				nearest_distance = distance
				nearest_target = target
	
	return nearest_target

## 配置投射物特定属性 - 电弧塔的目标锁定[br]
## [param projectile] 投射物实例
func _configure_projectile_specific(projectile: Node2D) -> void:
	var target = _select_nearest_target()
	if not target:
		return
	
	# 设置投射物目标 - 优先使用电弧攻击方法
	if projectile.has_method("setup_arc_attack"):
		projectile.setup_arc_attack(owner_player.global_position, target.global_position, projectile_resource)

## 敌人进入范围回调
func _on_enemy_entered_range(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy and enemy.is_in_group("enemies") and enemy not in current_targets:
		current_targets.append(enemy)

## 敌人离开范围回调
func _on_enemy_exited_range(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy in current_targets:
		current_targets.erase(enemy)

