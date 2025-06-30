extends ModResource
class_name SplitProjectileMod

## 分裂投射物模组 - 使投射物在命中敌人后分裂为多个子弹[br]
## 实现投射物的分裂逻辑，包括角度计算、新投射物创建等

## 重写应用到投射物的方法[br]
## [param projectile] 目标投射物
func apply_to_projectile(projectile: Node) -> void:
	super.apply_to_projectile(projectile)

## 重写命中处理方法[br]
## [param projectile] 投射物[br]
## [param target] 命中的目标[br]
## [returns] 是否继续处理后续逻辑
func on_projectile_hit(projectile: Node, target: Node) -> bool:
	var data_key = "split_projectile_data"
	if not projectile.has_meta(data_key):
		return true
	
	var split_data = projectile.get_meta(data_key, {})
	if split_data.get("has_split", false):
		return true
	
	split_data["has_split"] = true
	projectile.set_meta(data_key, split_data)
	
	# 延迟创建分裂投射物以避免物理查询冲突
	_create_split_projectiles.call_deferred(projectile, target, split_data)
	return true

## 重写获取初始模组数据[br]
## [returns] 分裂模组的初始数据
func _get_initial_mod_data() -> Dictionary:
	return {
		"split_count": effect_config.get("split_count", 2),
		"split_angle_spread": effect_config.get("split_angle_spread", 30.0),
		"damage_multiplier": effect_config.get("damage_multiplier", 0.8),
		"inherit_mods": effect_config.get("inherit_mods", false),
		"has_split": false
	}

## 创建分裂投射物[br]
## [param projectile] 原投射物[br]
## [param hit_target] 命中的目标[br]
## [param split_data] 分裂数据
func _create_split_projectiles(projectile: Node, hit_target: Node, split_data: Dictionary) -> void:
	var split_count = split_data.get("split_count", 2)
	var base_angle_spread = split_data.get("split_angle_spread", 30.0)
	var damage_multiplier = split_data.get("damage_multiplier", 0.8)
	var inherit_mods = split_data.get("inherit_mods", false)
	
	var main_scene = projectile.get_parent()
	if not main_scene:
		return
	
	# 获取当前飞行方向
	var original_direction = Vector2.RIGHT
	if projectile.has_method("_get_direction"):
		original_direction = projectile.call("_get_direction")
	
	print("创建 ", split_count, " 个分裂子弹")
	
	for i in range(split_count):
		# 直接复制当前投射物
		var new_projectile: Node2D = projectile.duplicate()
		
		if not new_projectile:
			continue
		
		main_scene.add_child(new_projectile)
		
		# 设置位置
		new_projectile.global_position = projectile.global_position
		
		# 计算分裂方向
		var angle_offset: float
		if i == 0:
			# 第一个子弹：右边角度
			angle_offset = base_angle_spread
		elif i == 1:
			# 第二个子弹：左边角度
			angle_offset = -base_angle_spread
		else:
			# 第三个及以后：继续累加角度
			angle_offset = -(base_angle_spread * (i))
		
		var split_direction = original_direction.rotated(deg_to_rad(angle_offset))
		
		# 设置投射物方向
		if new_projectile.has_method("_set_direction"):
			new_projectile.call("_set_direction", split_direction)
		
		# 重置生命周期
		if "lifetime_timer" in new_projectile:
			new_projectile.lifetime_timer = 0.0
		
		# 应用伤害修改
		if "current_damage" in new_projectile:
			new_projectile.current_damage = int(new_projectile.current_damage * damage_multiplier)
		
		# 如果不继承模组，清除分裂效果以避免无限分裂
		if not inherit_mods:
			new_projectile.remove_meta("split_projectile_mod")
			new_projectile.remove_meta("split_projectile_data") 