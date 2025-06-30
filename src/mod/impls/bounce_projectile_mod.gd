extends ModResource
class_name BounceProjectileMod

## 弹跳投射物模组 - 使投射物在命中敌人后弹跳到其他敌人[br]
## 使用ON_HIT Hook系统实现投射物弹跳逻辑

## 重写Hook执行方法[br]
## [param hook_type] Hook类型[br]
## [param context] 上下文数据
func execute_hook(hook_type: ModResource.HookType, context: Dictionary) -> void:
	if hook_type != ModResource.HookType.ON_HIT:
		return
	
	var projectile = context.get("projectile", null)
	var target = context.get("target", null)
	
	if not projectile or not target:
		print("弹跳mod: 缺少投射物或目标")
		return
	
	print("弹跳mod触发，投射物: ", projectile.name, " 目标: ", target.name)
	
	var data_key = "bounce_projectile_data"
	if not projectile.has_meta(data_key):
		# 初始化弹跳数据
		projectile.set_meta(data_key, _get_initial_mod_data())
		print("初始化弹跳数据")
	
	var bounce_data = projectile.get_meta(data_key, {})
	var remaining_bounces = bounce_data.get("remaining_bounces", 0)
	
	print("剩余弹跳次数: ", remaining_bounces)
	
	if remaining_bounces <= 0:
		print("弹跳次数用完，销毁投射物")
		if projectile.has_method("_destroy_projectile"):
			projectile.call("_destroy_projectile")
		return
	
	var bounced_enemies = bounce_data.get("bounced_enemies", [])
	if target in bounced_enemies:
		print("目标已被弹跳过，跳过")
		return
	
	# 记录已弹跳的敌人
	bounced_enemies.append(target)
	bounce_data["bounced_enemies"] = bounced_enemies
	bounce_data["remaining_bounces"] = remaining_bounces - 1
	projectile.set_meta(data_key, bounce_data)
	
	print("寻找下一个弹跳目标...")
	
	# 寻找下一个弹跳目标
	var next_target = _find_bounce_target(projectile, target, bounce_data)
	if next_target:
		print("找到弹跳目标: ", next_target.name)
		# 重新定向到新目标
		var direction = (next_target.global_position - projectile.global_position).normalized()
		if projectile.has_method("_set_direction"):
			projectile.call("_set_direction", direction)
		
		# 重置生命周期计时器
		if "lifetime_timer" in projectile:
			projectile.lifetime_timer = 0.0
	else:
		print("未找到弹跳目标，销毁投射物")
		if projectile.has_method("_destroy_projectile"):
			projectile.call("_destroy_projectile")

## 重写获取初始模组数据[br]
## [returns] 弹跳模组的初始数据
func _get_initial_mod_data() -> Dictionary:
	return {
		"remaining_bounces": effect_config.get("bounce_count", 3),
		"bounce_range": effect_config.get("bounce_range", 600.0),
		"damage_reduction": effect_config.get("damage_reduction_per_bounce", 0.1),
		"bounced_enemies": []
	}

## 寻找弹跳目标[br]
## [param projectile] 投射物[br]
## [param current_target] 当前目标[br]
## [param bounce_data] 弹跳数据[br]
## [returns] 下一个弹跳目标
func _find_bounce_target(projectile: Node, current_target: Node, bounce_data: Dictionary) -> Node2D:
	var bounce_range = bounce_data.get("bounce_range", 600.0)
	var bounced_enemies = bounce_data.get("bounced_enemies", [])
	
	var scene_tree = projectile.get_tree()
	if not scene_tree:
		return null
	
	var enemies = scene_tree.get_nodes_in_group("enemies")
	var valid_targets: Array[Node2D] = []
	
	for enemy in enemies:
		if enemy == current_target or enemy in bounced_enemies:
			continue
		
		if enemy is Node2D and is_instance_valid(enemy):
			var distance = current_target.global_position.distance_to(enemy.global_position)
			if distance <= bounce_range:
				valid_targets.append(enemy)
	
	print("找到 ", valid_targets.size(), " 个有效弹跳目标")
	
	# 随机选择一个有效目标
	if valid_targets.size() > 0:
		return valid_targets[randi() % valid_targets.size()]
	
	return null
