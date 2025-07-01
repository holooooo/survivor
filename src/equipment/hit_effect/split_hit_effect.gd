extends HitEffectResource
class_name SplitHitEffect

## 分裂命中效果 - 命中敌人时复制多个投射物向不同方向飞行[br]
## 分裂的投射物继承原投射物的属性但重置生命周期

@export_group("分裂配置")
@export var split_count: int = 3 ## 分裂投射物数量
@export var spread_angle_degrees: float = 60.0 ## 扩散角度范围（左右各30度=总60度）
@export var damage_multiplier: float = 0.8 ## 分裂投射物伤害倍率
@export var inherit_pierce: bool = true ## 是否继承穿透属性
@export var inherit_speed: bool = true ## 是否继承飞行速度
@export var reset_lifetime: bool = true ## 是否重置生命周期

func _init():
	effect_name = "分裂效果"
	effect_id = "split"

## 重写执行效果方法[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例[br]
## [param target] 目标节点[br]
## [param hit_info] 命中信息字典
func execute_effect(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, hit_info: Dictionary) -> void:
	if not projectile or not hit_info.has("projectile_direction"):
		return
	
	# 标记原投射物已分裂
	projectile.set_flag("is_splited", true)
	
	var original_direction = hit_info.projectile_direction
	var spawn_position = hit_info.get("hit_position", projectile.global_position)
	
	_create_split_projectiles_deferred(equipment, projectile, spawn_position, original_direction)

## 延迟创建分裂投射物[br]
## [param equipment] 装备实例[br]
## [param original_projectile] 原投射物[br]
## [param spawn_position] 生成位置[br]
## [param original_direction] 原始方向
func _create_split_projectiles_deferred(equipment: EquipmentBase, original_projectile: ProjectileBase, spawn_position: Vector2, original_direction: Vector2) -> void:
	var split_projectiles: Array = []
	
	# 创建分裂投射物
	for i in range(split_count):
		var angle_offset = _calculate_split_angle(i)
		var new_direction = original_direction.rotated(deg_to_rad(angle_offset))
		
		var split_projectile = _create_split_projectile(equipment, original_projectile, spawn_position, new_direction)
		if split_projectile:
			# 标记分裂投射物
			split_projectile.set_flag("created_by", "split")
			split_projectiles.append(split_projectile)
	
	# 发送分裂信号
	if not split_projectiles.is_empty():
		FightEventBus.on_projectile_split.emit(original_projectile, split_projectiles)

## 计算分裂角度[br]
## [param index] 分裂投射物索引[br]
## [returns] 相对于原方向的角度偏移（度）
func _calculate_split_angle(index: int) -> float:
	if split_count == 1:
		return 0.0
	
	var half_spread = spread_angle_degrees / 2.0
	var angle_step = spread_angle_degrees / (split_count - 1) if split_count > 1 else 0
	
	# 奇数位靠左，偶数位靠右的分布
	if index % 2 == 0: # 偶数索引：右侧
		var right_index = index / 2
		return right_index * angle_step
	else: # 奇数索引：左侧
		var left_index = (index + 1) / 2
		return -left_index * angle_step

## 创建分裂投射物[br]
## [param equipment] 装备实例[br]
## [param original_projectile] 原投射物[br]
## [param spawn_position] 生成位置[br]
## [param direction] 飞行方向[br]
## [returns] 创建的分裂投射物
func _create_split_projectile(equipment: EquipmentBase, original_projectile: ProjectileBase, spawn_position: Vector2, direction: Vector2) -> ProjectileBase:
	if not equipment.projectile_scene:
		return null
	
	# 创建新投射物实例
	var split_projectile = equipment.projectile_scene.instantiate()
	if not split_projectile:
		return null
	
	# 添加到场景树中
	if equipment.projectile_pool:
		equipment.projectile_pool.call_deferred("add_child", split_projectile)

	# 设置位置
	split_projectile.global_position = spawn_position
	
	# 复制原投射物的配置
	var split_config = _create_split_config(original_projectile)
	
	# 初始化分裂投射物
	if split_projectile.has_method("setup_from_resource") and equipment.projectile_resource:
		split_projectile.setup_from_resource(equipment, equipment.projectile_resource, direction, split_config)
	
	return split_projectile

## 创建分裂投射物的配置[br]
## [param original_projectile] 原投射物[br]
## [returns] 分裂投射物的配置字典
func _create_split_config(original_projectile: ProjectileBase) -> Dictionary:
	var config = {}
	
	# 继承原投射物的装备统计
	if original_projectile.has_method("get_equipment_stats"):
		config = original_projectile.get_equipment_stats().duplicate()
	elif original_projectile.equipment_stats:
		config = original_projectile.equipment_stats.duplicate()
	
	# 应用伤害倍率
	if config.has("base_damage"):
		config.base_damage = int(config.base_damage * damage_multiplier)
	
	# 穿透属性处理
	if inherit_pierce and config.has("pierce_count"):
		# 继承当前剩余的穿透次数
		if original_projectile.has_method("get_pierce_remaining"):
			config.pierce_count = original_projectile.get_pierce_remaining()
		elif original_projectile.has_property("pierce_remaining"):
			config.pierce_count = original_projectile.pierce_remaining
	else:
		# 不继承穿透
		config.pierce_count = 0
	
	# 速度处理
	if not inherit_speed:
		# 使用原始速度而非当前速度
		if original_projectile.projectile_resource:
			config.projectile_speed = original_projectile.projectile_resource.projectile_speed
	
	return config

## 重写触发条件检查[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例[br]
## [param target] 目标节点[br]
## [param damage] 造成的伤害[br]
## [param damage_type] 伤害类型[br]
## [param is_critical] 是否暴击[br]
## [param is_kill] 是否击杀[br]
## [returns] 是否可以触发
func can_trigger(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, damage: int, damage_type: Constants.DamageType, is_critical: bool = false, is_kill: bool = false) -> bool:
	# 先检查基类条件
	if not super.can_trigger(player, equipment, projectile, target, damage, damage_type, is_critical, is_kill):
		return false

	# 检查投射物是否已经分裂过
	if projectile.has_flag("is_splited"):
		return false

	# 检查投射物是否由分裂创建
	if projectile.get_flag("created_by") == "split":
		return false

	# 检查是否有投射物场景用于分裂
	if not equipment or not equipment.projectile_scene:
		return false

	# 检查分裂数量是否有效
	if split_count <= 0:
		return false

	return true

## 获取效果描述[br]
## [returns] 效果描述文本
func get_description() -> String:
	var desc = "分裂成 %d 个投射物，伤害 %.0f%%" % [split_count, damage_multiplier * 100]
	if trigger_probability < 1.0:
		desc += "（%.0f%% 概率）" % (trigger_probability * 100)
	if cooldown_time > 0:
		desc += "（冷却 %.1f秒）" % cooldown_time
	return desc