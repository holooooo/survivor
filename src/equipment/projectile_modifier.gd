extends RefCounted
class_name ProjectileModifier

## 投射物修改器 - 处理模组效果在投射物上的应用[br]
## 统一处理弹射、分裂、穿透等投射物特殊效果

static func apply_mod_effects_to_projectile(projectile: Node2D, mod_effects: Array[Dictionary]) -> void:
	"""为投射物应用模组效果"""
	if mod_effects.is_empty():
		print("投射物 ", projectile.name, " 没有模组效果需要应用")
		return
	
	print("投射物 ", projectile.name, " 正在应用 ", mod_effects.size(), " 个模组效果")
	
	# 为投射物添加效果处理器
	for effect_data in mod_effects:
		var effect_config = effect_data.get("effect_config", {})
		var effect_name = effect_config.get("effect_name", "")
		
		print("  应用效果: ", effect_name, " 配置: ", effect_config)
		
		match effect_name:
			"bounce_projectile":
				_setup_bounce_effect(projectile, effect_config)
			"split_projectile":
				_setup_split_effect(projectile, effect_config)
			"pierce_enhance":
				_setup_pierce_effect(projectile, effect_config)
			"homing_projectile":
				_setup_homing_effect(projectile, effect_config)
			_:
				print("    警告: 未知的效果类型: ", effect_name)

## 设置弹射效果[br]
## [param projectile] 投射物[br]
## [param config] 效果配置
static func _setup_bounce_effect(projectile: Node2D, config: Dictionary) -> void:
	var bounce_count = config.get("bounce_count", 3)
	var bounce_range = config.get("bounce_range", 200.0)
	var damage_reduction = config.get("damage_reduction_per_bounce", 0.1)
	
	print("    设置弹射效果: 弹射次数=", bounce_count, " 范围=", bounce_range, " 伤害衰减=", damage_reduction)
	
	# 添加弹射状态
	projectile.set_meta("bounce_effect", {
		"remaining_bounces": bounce_count,
		"bounce_range": bounce_range,
		"damage_reduction": damage_reduction,
		"bounced_enemies": []
	})
	
	# 连接命中信号处理弹射
	if projectile.has_signal("projectile_hit"):
		if not projectile.projectile_hit.is_connected(_on_projectile_bounce_hit):
			projectile.projectile_hit.connect(_on_projectile_bounce_hit.bind(projectile))
			print("    ✓ 弹射效果信号连接成功")
		else:
			print("    ⚠ 弹射效果信号已连接")
	elif projectile.has_method("_on_area_entered"):
		# 如果没有自定义信号，监听碰撞
		_setup_bounce_collision_monitor(projectile)
		print("    ✓ 弹射效果碰撞监听设置成功")
	else:
		print("    ✗ 弹射效果设置失败：没有可用的信号或方法")

## 设置分裂效果[br]
## [param projectile] 投射物[br]
## [param config] 效果配置
static func _setup_split_effect(projectile: Node2D, config: Dictionary) -> void:
	var split_count = config.get("split_count", 3)
	var split_angle = config.get("split_angle_spread", 45.0)
	var inherit_mods = config.get("inherit_mods", false)
	var damage_multiplier = config.get("damage_multiplier", 0.8)
	
	print("    设置分裂效果: 分裂数量=", split_count, " 角度=", split_angle, " 继承模组=", inherit_mods, " 伤害倍数=", damage_multiplier)
	
	# 添加分裂状态
	projectile.set_meta("split_effect", {
		"split_count": split_count,
		"split_angle": split_angle,
		"inherit_mods": inherit_mods,
		"damage_multiplier": damage_multiplier,
		"has_split": false
	})
	
	# 连接命中信号处理分裂
	if projectile.has_signal("projectile_hit"):
		if not projectile.projectile_hit.is_connected(_on_projectile_split_hit):
			projectile.projectile_hit.connect(_on_projectile_split_hit.bind(projectile))
			print("    ✓ 分裂效果信号连接成功")
		else:
			print("    ⚠ 分裂效果信号已连接")
	elif projectile.has_method("_on_area_entered"):
		_setup_split_collision_monitor(projectile)
		print("    ✓ 分裂效果碰撞监听设置成功")
	else:
		print("    ✗ 分裂效果设置失败：没有可用的信号或方法")

## 设置穿透增强效果[br]
## [param projectile] 投射物[br]
## [param config] 效果配置
static func _setup_pierce_effect(projectile: Node2D, config: Dictionary) -> void:
	var additional_pierce = config.get("additional_pierce", 2)
	var reduced_damage_loss = config.get("reduced_damage_loss", 0.5)
	
	# 修改投射物的穿透属性
	if projectile.has_method("get_projectile_resource"):
		var resource = projectile.get_projectile_resource()
		if resource and resource.has_method("get_projectile_config"):
			var projectile_config = resource.get_projectile_config()
			projectile_config["pierce_count"] += additional_pierce
			projectile_config["pierce_damage_reduction"] *= reduced_damage_loss

## 设置追踪效果[br]
## [param projectile] 投射物[br]
## [param config] 效果配置
static func _setup_homing_effect(projectile: Node2D, config: Dictionary) -> void:
	var homing_strength = config.get("homing_strength", 0.5)
	var homing_range = config.get("homing_range", 150.0)
	
	projectile.set_meta("homing_effect", {
		"strength": homing_strength,
		"range": homing_range
	})
	
	# 为投射物添加追踪行为组件
	if projectile.has_method("_physics_process"):
		_add_homing_behavior(projectile)

## 弹射命中处理[br]
## [param projectile] 投射物[br]
## [param hit_target] 命中目标
static func _on_projectile_bounce_hit(projectile: Node2D, hit_target: Node2D) -> void:
	print("弹射效果触发: 投射物=", projectile.name, " 命中=", hit_target.name)
	
	var bounce_data = projectile.get_meta("bounce_effect", {})
	if bounce_data.is_empty():
		print("  弹射数据为空，跳过")
		return
	
	var remaining_bounces = bounce_data.get("remaining_bounces", 0)
	if remaining_bounces <= 0:
		print("  剩余弹射次数为0，跳过")
		return
	
	var bounced_enemies = bounce_data.get("bounced_enemies", [])
	if hit_target in bounced_enemies:
		print("  目标已被弹射过，跳过")
		return
	
	print("  执行弹射逻辑，剩余次数: ", remaining_bounces)
	
	# 记录已弹射的敌人
	bounced_enemies.append(hit_target)
	bounce_data["bounced_enemies"] = bounced_enemies
	bounce_data["remaining_bounces"] = remaining_bounces - 1
	projectile.set_meta("bounce_effect", bounce_data)
	
	# 寻找下一个弹射目标
	var next_target = _find_bounce_target(projectile, hit_target, bounce_data)
	if next_target:
		print("  找到弹射目标: ", next_target.name)
		_create_bounce_projectile(projectile, hit_target, next_target, bounce_data)
	else:
		print("  未找到弹射目标")

## 分裂命中处理[br]
## [param projectile] 投射物[br]
## [param hit_target] 命中目标
static func _on_projectile_split_hit(projectile: Node2D, hit_target: Node2D) -> void:
	print("分裂效果触发: 投射物=", projectile.name, " 命中=", hit_target.name)
	
	var split_data = projectile.get_meta("split_effect", {})
	if split_data.is_empty():
		print("  分裂数据为空，跳过")
		return
	
	if split_data.get("has_split", false):
		print("  已经分裂过，跳过")
		return
	
	print("  执行分裂逻辑")
	split_data["has_split"] = true
	projectile.set_meta("split_effect", split_data)
	
	_create_split_projectiles(projectile, hit_target, split_data)

## 寻找弹射目标[br]
## [param projectile] 当前投射物[br]
## [param current_target] 当前目标[br]
## [param bounce_data] 弹射数据[br]
## [returns] 下一个弹射目标
static func _find_bounce_target(projectile: Node2D, current_target: Node2D, bounce_data: Dictionary) -> Node2D:
	var bounce_range = bounce_data.get("bounce_range", 200.0)
	var bounced_enemies = bounce_data.get("bounced_enemies", [])
	
	var scene_tree = projectile.get_tree()
	if not scene_tree:
		return null
	
	var enemies = scene_tree.get_nodes_in_group("enemies")
	var best_target: Node2D = null
	var closest_distance: float = bounce_range
	
	for enemy in enemies:
		if enemy == current_target or enemy in bounced_enemies:
			continue
		
		if enemy is Node2D and is_instance_valid(enemy):
			var distance = current_target.global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				best_target = enemy
	
	return best_target

## 创建弹射投射物[br]
## [param original] 原始投射物[br]
## [param from_target] 起始目标[br]
## [param to_target] 目标[br]
## [param bounce_data] 弹射数据
static func _create_bounce_projectile(original: Node2D, from_target: Node2D, to_target: Node2D, bounce_data: Dictionary) -> void:
	# 检查原始投射物是否有创建副本的方法
	var new_projectile: Node2D = null
	
	# 方法1：通过类名创建新实例
	if original.has_method("get_script"):
		var script = original.get_script()
		if script:
			# 获取投射物的场景文件（通过类型检查）
			if original is PistolProjectile:
				var pistol_scene = load("res://src/equipment/output/pistol/pistol_projectile.tscn")
				if pistol_scene:
					new_projectile = pistol_scene.instantiate()
	
	# 方法2：通过复制创建（备用方案）
	if not new_projectile:
		new_projectile = original.duplicate()
	
	if not new_projectile:
		push_error("无法创建弹射投射物")
		return
	
	# 添加到主场景
	var main_scene = original.get_parent()
	if main_scene:
		main_scene.add_child(new_projectile)
		
		# 设置位置和方向
		new_projectile.global_position = from_target.global_position
		var direction = (to_target.global_position - from_target.global_position).normalized()
		
		# 复制原始投射物的资源配置
		if original.has_method("get_projectile_resource") and new_projectile.has_method("setup_from_resource"):
			var resource = original.get_projectile_resource()
			if resource:
				new_projectile.setup_from_resource(resource, direction)
		
		# 应用伤害衰减
		var damage_reduction = bounce_data.get("damage_reduction", 0.1)
		_apply_damage_reduction(new_projectile, damage_reduction)
		
		# 继承弹射效果但减少次数
		var remaining_bounces = bounce_data.get("remaining_bounces", 0)
		if remaining_bounces > 0:
			var new_bounce_data = bounce_data.duplicate()
			new_bounce_data["remaining_bounces"] = remaining_bounces
			new_projectile.set_meta("bounce_effect", new_bounce_data)
			
			# 重新连接弹射信号
			if new_projectile.has_signal("projectile_hit"):
				if not new_projectile.projectile_hit.is_connected(_on_projectile_bounce_hit):
					new_projectile.projectile_hit.connect(_on_projectile_bounce_hit.bind(new_projectile))

## 创建分裂投射物[br]
## [param original] 原始投射物[br]
## [param hit_position] 命中位置[br]
## [param split_data] 分裂数据
static func _create_split_projectiles(original: Node2D, hit_target: Node2D, split_data: Dictionary) -> void:
	var split_count = split_data.get("split_count", 3)
	var split_angle = split_data.get("split_angle_spread", 45.0)
	var damage_multiplier = split_data.get("damage_multiplier", 0.8)
	var inherit_mods = split_data.get("inherit_mods", false)
	
	var main_scene = original.get_parent()
	if not main_scene:
		return
	
	# 计算分裂角度
	var base_angle = 0.0
	var angle_step = split_angle / max(1, split_count - 1)
	var start_angle = -split_angle * 0.5
	
	for i in range(split_count):
		var new_projectile: Node2D = null
		
		# 通过类型创建新的投射物实例
		if original is PistolProjectile:
			var pistol_scene = load("res://src/equipment/output/pistol/pistol_projectile.tscn")
			if pistol_scene:
				new_projectile = pistol_scene.instantiate()
		
		# 备用方案：通过复制创建
		if not new_projectile:
			new_projectile = original.duplicate()
		
		if not new_projectile:
			continue
		
		main_scene.add_child(new_projectile)
		
		# 设置位置
		new_projectile.global_position = hit_target.global_position
		
		# 计算分裂方向
		var angle = start_angle + (angle_step * i)
		var direction = Vector2.RIGHT.rotated(deg_to_rad(angle))
		
		# 设置投射物配置
		if original.has_method("get_projectile_resource") and new_projectile.has_method("setup_from_resource"):
			var resource = original.get_projectile_resource()
			if resource:
				new_projectile.setup_from_resource(resource, direction)
		
		# 应用伤害修改
		_apply_damage_reduction(new_projectile, 1.0 - damage_multiplier)
		
		# 如果不继承模组，清除分裂效果以避免无限分裂
		if not inherit_mods:
			new_projectile.remove_meta("split_effect")

## 应用伤害衰减[br]
## [param projectile] 投射物[br]
## [param reduction] 衰减比例
static func _apply_damage_reduction(projectile: Node2D, reduction: float) -> void:
	if projectile.has_method("get_projectile_resource"):
		var resource = projectile.get_projectile_resource()
		if resource and resource.has_method("get_projectile_config"):
			var config = resource.get_projectile_config()
			if config.has("base_damage"):
				config["base_damage"] = int(config["base_damage"] * (1.0 - reduction))
			if config.has("tick_damage"):
				config["tick_damage"] = int(config["tick_damage"] * (1.0 - reduction))

## 设置弹射碰撞监听器[br]
## [param projectile] 投射物
static func _setup_bounce_collision_monitor(projectile: Node2D) -> void:
	# 这里需要根据具体的投射物类型来实现
	# 暂时使用通用的area_entered信号
	if projectile.has_signal("area_entered"):
		if not projectile.area_entered.is_connected(_on_bounce_collision):
			projectile.area_entered.connect(_on_bounce_collision.bind(projectile))

## 设置分裂碰撞监听器[br]
## [param projectile] 投射物
static func _setup_split_collision_monitor(projectile: Node2D) -> void:
	if projectile.has_signal("area_entered"):
		if not projectile.area_entered.is_connected(_on_split_collision):
			projectile.area_entered.connect(_on_split_collision.bind(projectile))

## 弹射碰撞处理[br]
## [param projectile] 投射物[br]
## [param area] 碰撞区域
static func _on_bounce_collision(projectile: Node2D, area: Area2D) -> void:
	if area.is_in_group("enemies"):
		_on_projectile_bounce_hit(projectile, area)

## 分裂碰撞处理[br]
## [param projectile] 投射物[br]
## [param area] 碰撞区域
static func _on_split_collision(projectile: Node2D, area: Area2D) -> void:
	if area.is_in_group("enemies"):
		_on_projectile_split_hit(projectile, area)

## 添加追踪行为[br]
## [param projectile] 投射物
static func _add_homing_behavior(projectile: Node2D) -> void:
	# 这需要修改投射物的物理过程
	# 实际实现时需要在各个投射物类中集成此行为
	pass 