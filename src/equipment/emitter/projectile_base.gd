extends Area2D
class_name ProjectileBase

## 投射物节点抽象基类 - 所有投射物节点的通用逻辑[br]
## 提供碰撞检测、生命周期管理、伤害处理、视觉效果等共同功能[br]
## 子类只需实现特定的移动模式和特殊效果

var equipment: EquipmentBase
var projectile_resource: EmitterProjectileResource
var equipment_stats: Dictionary = {} ## 装备修改后的属性
var mod_effects: Array[Dictionary] = [] ## 应用的模组效果

# 生命周期管理
var lifetime_timer: float = 0.0 ## 存活时间计时器
var is_destroyed: bool = false ## 是否已被销毁

# 射程追踪系统
var start_position: Vector2 ## 投射物起始位置
var traveled_distance: float = 0.0 ## 已飞行距离
var max_range: float = 0.0 ## 最大射程
var range_check_enabled: bool = true ## 是否启用射程检查

# 穿透系统
var pierce_remaining: int = 0 ## 剩余穿透次数
var has_hit_target: bool = false ## 是否已命中目标

# 伤害系统
var base_damage: int = 10 ## 基础伤害
var current_damage: int = 10 ## 当前伤害（可能被模组修改）
var damage_type: Constants.DamageType = Constants.DamageType.枪械 ## 伤害类型
var is_critical_hit_flag: bool = false ## 是否为暴击

# 投射物标记系统
var flags: Dictionary = {} ## 投射物标记，用于控制各种效果行为

# Buff系统
var attached_buffs: Array[BuffResource] = [] ## 投射物附带的buff效果

# 碰撞系统
var colliding_targets: Array[Node] = [] ## 当前碰撞中的目标

# 视觉组件（可选）
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_setup_collision_system()
	_setup_lifecycle()
	add_to_group(Constants.GROUP_PROJECTILES)


func _physics_process(delta: float) -> void:
	pass

func _process(delta: float) -> void:
	if is_destroyed:
		return
	lifetime_timer += delta
	
	# 更新飞行距离追踪
	_update_traveled_distance()
	# 检查生命周期
	if _should_destroy():
		_destroy_projectile()
		return
	
	# 执行特定移动逻辑
	_update_movement(delta)
	
	# 执行特定更新逻辑
	_update_custom(delta)

## 从资源配置投射物[br]
## [param resource] 投射物资源[br]
## [param direction] 初始方向[br]
## [param stats] 装备修改后的属性
func setup_from_resource(_equipment: EquipmentBase, resource: EmitterProjectileResource, direction: Vector2, stats: Dictionary = {}) -> void:
	self.equipment = _equipment
	projectile_resource = resource
	equipment_stats = stats
	
	if not projectile_resource:
		push_error("Projectile resource not set.")
		queue_free()
		return
	
	# 记录起始位置
	start_position = global_position
	
	# 设置射程系统
	var equipment_attack_range: float = equipment_stats.get("attack_range", 300.0)
	max_range = projectile_resource.get_effective_max_range(equipment_attack_range)
	range_check_enabled = projectile_resource.range_check_enabled
	
	# 设置穿透系统
	pierce_remaining = equipment_stats.get("pierce_count", projectile_resource.pierce_count)
	
	# 设置基础属性
	base_damage = equipment_stats.get("base_damage", projectile_resource.base_damage)
	current_damage = base_damage
	
	# 设置伤害类型 - 优先使用装备的伤害类型，其次使用投射物资源的伤害类型
	damage_type = equipment_stats.get("damage_type", Constants.DamageType.枪械)
	if damage_type == Constants.DamageType.枪械 and projectile_resource.has_method("get_damage_type"):
		damage_type = projectile_resource.get_damage_type()
	
	# 应用玩家属性加成
	_apply_player_stats_bonuses()
	
	# 设置视觉效果
	_setup_visuals()
	
	# 执行特定初始化
	_initialize_specific(direction)

	FightEventBus.on_projectile_spawn.emit(equipment.owner_player, equipment, self)
	# 初始化完成后启用碰撞检测
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

## 设置碰撞系统
func _setup_collision_system() -> void:
	collision_layer = 4 # 武器层
	collision_mask = 2 # 敌人层
	
	# 连接碰撞信号
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

## 设置生命周期系统
func _setup_lifecycle() -> void:
	# 生命周期将由资源配置或子类处理，这里不需要默认定时器
	pass

## 设置视觉效果
func _setup_visuals() -> void:
	if sprite and projectile_resource:
		if projectile_resource.projectile_texture:
			sprite.texture = projectile_resource.projectile_texture
		sprite.modulate = projectile_resource.projectile_color
		sprite.scale = projectile_resource.projectile_scale
	
	# 设置碰撞形状
	if collision_shape and projectile_resource:
		_setup_collision_shape()

## 设置碰撞形状
func _setup_collision_shape() -> void:
	if not collision_shape or not collision_shape.shape:
		return
	
	if collision_shape.shape is CircleShape2D:
		var shape: CircleShape2D = collision_shape.shape as CircleShape2D
		shape.radius = projectile_resource.detection_radius
	elif collision_shape.shape is RectangleShape2D:
		var shape: RectangleShape2D = collision_shape.shape as RectangleShape2D
		var size = projectile_resource.detection_radius * 2
		shape.size = Vector2(size, size)

## 处理Area2D碰撞进入[br]
## [param area] 碰撞的区域
func _on_area_entered(area: Area2D) -> void:
	if _is_valid_target(area) and area not in colliding_targets:
		colliding_targets.append(area)
		_on_target_entered(area)

## 处理Area2D碰撞离开[br]
## [param area] 离开的区域
func _on_area_exited(area: Area2D) -> void:
	if area in colliding_targets:
		colliding_targets.erase(area)
		_on_target_exited(area)

## 处理RigidBody2D碰撞进入[br]
## [param body] 碰撞的刚体
func _on_body_entered(body: Node2D) -> void:
	if _is_valid_target(body) and body not in colliding_targets:
		colliding_targets.append(body)
		_on_target_entered(body)

## 处理RigidBody2D碰撞离开[br]
## [param body] 离开的刚体
func _on_body_exited(body: Node2D) -> void:
	if body in colliding_targets:
		colliding_targets.erase(body)
		_on_target_exited(body)

## 检查是否为有效目标[br]
## [param target] 目标节点[br]
## [returns] 是否为有效目标
func _is_valid_target(target: Node) -> bool:
	if not is_instance_valid(target):
		return false
	
	# 检查是否在影响组内
	if projectile_resource and not projectile_resource.affected_groups.is_empty():
		for group in projectile_resource.affected_groups:
			if target.is_in_group(group):
				return true
		return false
	
	# 默认检查敌人组
	return target.is_in_group("enemies")

## 对目标造成伤害[br]
## [param target] 目标节点[br]
## [param damage_amount] 伤害数值
func _deal_damage_to_target(target: Node, damage_amount: int) -> void:
	# 获取实际的Actor目标（如果目标是CollisionArea，获取其父节点）
	var actual_target = _get_actual_target(target)
	if not actual_target:
		return
	
	actual_target.take_damage(damage_amount)

	# 根据伤害类型显示不同颜色的伤害数字
	var damage_color: Color = get_damage_type_color()
	EventBus.show_damage_number(damage_amount, actual_target.global_position, damage_color)
	FightEventBus.on_projectile_hit.emit(equipment.owner_player, equipment, self, actual_target, damage_amount, damage_type)
	
	# 施加附带的buff
	_apply_attached_buffs_to_target(actual_target)

## 获取实际的Actor目标[br]
## [param target] 检测到的目标节点[br]
## [returns] 实际的Actor节点
func _get_actual_target(target: Node) -> Node:
	# 如果目标是Actor的CollisionArea，返回其父节点（Actor）
	if target.name == "CollisionArea" and target.get_parent() is Actor:
		return target.get_parent()
	
	# 如果目标本身是Actor，直接返回
	if target is Actor:
		return target
	
	# 其他情况返回null
	return null

## 检查是否应该销毁[br]
## [returns] 是否应该销毁
func _should_destroy() -> bool:
	# 基础生命周期检查
	if _should_destroy_by_lifetime():
		return true
	
	# 枪械类型的特殊检查
	if equipment.resource.equipment_type == Constants.EquipmentType.枪械:
		if _should_destroy_by_range():
			return true
		if _should_destroy_by_pierce():
			return true
	
	return false

## 检查是否因生命周期到期而销毁[br]
## [returns] 是否应该销毁
func _should_destroy_by_lifetime() -> bool:
	if not projectile_resource:
		return lifetime_timer >= 5.0 # 默认5秒，资源未初始化时的回退
	
	return lifetime_timer >= projectile_resource.lifetime

## 检查是否因射程超限而销毁[br]
## [returns] 是否应该销毁
func _should_destroy_by_range() -> bool:
	if not range_check_enabled or max_range <= 0.0:
		return false
	
	return traveled_distance >= max_range

## 检查是否因穿透次数耗尽而销毁[br]
## [returns] 是否应该销毁
func _should_destroy_by_pierce() -> bool:
	# 只有在已命中目标且穿透次数耗尽时才销毁
	return has_hit_target and pierce_remaining <= 0

## 销毁投射物[br]
func _destroy_projectile() -> void:
	if is_destroyed:
		return
	
	is_destroyed = true
	
	# 执行销毁前逻辑
	_before_destroy()
	
	# 清理碰撞目标
	colliding_targets.clear()
	
	# 发射销毁信号
	FightEventBus.on_projectile_destroy.emit(equipment.owner_player, equipment, self)
	
	# 从组中移除
	if is_in_group("projectiles"):
		remove_from_group("projectiles")
	
	# 销毁节点
	queue_free()

## 添加模组效果[br]
## [param effects] 模组效果数组
func add_mod_effects(effects: Array[Dictionary]) -> void:
	mod_effects = effects
	
	for effect_data in mod_effects:
		var mod_resource = effect_data.get("mod_resource", null)
		if mod_resource and mod_resource is ModResource:
			mod_resource.apply_to_projectile(self)

## 获取投射物信息[br]
## [returns] 投射物信息字典
func get_projectile_info() -> Dictionary:
	return {
		"type": _get_projectile_type(),
		"damage": current_damage,
		"lifetime_remaining": _get_remaining_lifetime(),
		"position": global_position,
		"targets_count": colliding_targets.size(),
		"is_destroyed": is_destroyed
	}

## 获取剩余生命周期[br]
## [returns] 剩余时间
func _get_remaining_lifetime() -> float:
	if not projectile_resource:
		return 0.0
	return max(0.0, projectile_resource.lifetime - lifetime_timer)

## === 抽象方法 - 子类必须实现 ===

## 执行特定移动逻辑[br]
## [param delta] 时间增量
func _update_movement(delta: float) -> void:
	# 子类实现特定的移动逻辑（直线移动、跟随、轨道等）
	pass

## 初始化特定逻辑[br]
## [param direction] 初始方向
func _initialize_specific(direction: Vector2) -> void:
	# 子类实现特定的初始化逻辑
	pass

## 获取投射物类型标识[br]
## [returns] 类型字符串
func _get_projectile_type() -> String:
	return "base"

## === 可重写方法 ===

## 目标进入处理[br]
## [param target] 进入的目标
func _on_target_entered(target: Node) -> void:
	# 标记已命中目标
	has_hit_target = true
	
	# 默认立即造成伤害
	_deal_damage_to_target(target, current_damage)
	
	# 处理穿透逻辑（枪械类型）
	if damage_type == Constants.DamageType.枪械:
		_handle_pierce_logic(target)

## 目标离开处理[br]
## [param target] 离开的目标
func _on_target_exited(target: Node) -> void:
	# 子类可重写此方法来处理目标离开逻辑
	pass

## 自定义更新逻辑[br]
## [param delta] 时间增量
func _update_custom(delta: float) -> void:
	# 子类可重写此方法来实现额外的更新逻辑
	pass

## 销毁前处理[br]
func _before_destroy() -> void:
	# 子类可重写此方法来处理销毁前的清理逻辑
	pass


## 获取投射物伤害类型[br]
## [returns] 伤害类型
func get_damage_type() -> Constants.DamageType:
	return damage_type

## 设置投射物伤害类型[br]
## [param new_damage_type] 新的伤害类型
func set_damage_type(new_damage_type: Constants.DamageType) -> void:
	damage_type = new_damage_type

## 获取伤害类型名称[br]
## [returns] 伤害类型中文名称
func get_damage_type_name() -> String:
	return Constants.get_damage_type_name(damage_type)

## 获取伤害类型颜色[br]
## [returns] 伤害类型对应的颜色
func get_damage_type_color() -> Color:
	return Constants.get_damage_type_color(damage_type)

# 旧的硬编码mod处理方法已移除，现在使用ModResource系统

## 应用玩家属性加成[br]
func _apply_player_stats_bonuses() -> void:
	if equipment and equipment.owner_player and equipment.owner_player.stats_manager:
		var player_stats = equipment.owner_player.stats_manager
		var projectile_damage_type = get_damage_type()
		
		# 应用伤害倍率
		var damage_multiplier = player_stats.get_damage_multiplier(projectile_damage_type)
		current_damage = int(base_damage * damage_multiplier)
		
		# 进行暴击判定
		if player_stats.roll_critical(projectile_damage_type):
			var crit_multiplier = player_stats.get_critical_multiplier(projectile_damage_type)
			current_damage = int(current_damage * crit_multiplier)
			# 可以在这里添加暴击视觉效果标记
			_mark_as_critical_hit()

## 标记为暴击（子类可重写）[br]
func _mark_as_critical_hit() -> void:
	is_critical_hit_flag = true
	# 子类可以重写此方法来添加暴击视觉效果
	# 例如：改变颜色、添加特效等
	pass

## 检查是否为暴击[br]
## [returns] 是否为暴击
func is_critical_hit() -> bool:
	return is_critical_hit_flag

## 获取基础伤害[br]
## [returns] 基础伤害值
func get_base_damage() -> int:
	return base_damage

## 获取装备统计[br]
## [returns] 装备统计字典
func get_equipment_stats() -> Dictionary:
	return equipment_stats

## 获取剩余穿透次数[br]
## [returns] 剩余穿透次数
func get_pierce_remaining() -> int:
	return pierce_remaining

## 设置投射物标记[br]
## [param flag_name] 标记名称[br]
## [param value] 标记值
func set_flag(flag_name: String, value) -> void:
	flags[flag_name] = value

## 获取投射物标记[br]
## [param flag_name] 标记名称[br]
## [param default_value] 默认值[br]
## [returns] 标记值
func get_flag(flag_name: String, default_value = null):
	return flags.get(flag_name, default_value)

## 检查是否有指定标记[br]
## [param flag_name] 标记名称[br]
## [returns] 是否存在该标记
func has_flag(flag_name: String) -> bool:
	return flags.has(flag_name)

## 移除投射物标记[br]
## [param flag_name] 标记名称
func remove_flag(flag_name: String) -> void:
	flags.erase(flag_name)

## 获取所有标记[br]
## [returns] 标记字典
func get_all_flags() -> Dictionary:
	return flags.duplicate()

## 处理穿透逻辑[br]
## [param target] 命中的目标
func _handle_pierce_logic(target: Node) -> void:
	# 减少穿透次数
	pierce_remaining -= 1
	
	# 如果有穿透资源配置，应用穿透伤害和速度衰减
	if projectile_resource and pierce_remaining >= 0:
		var current_pierce = projectile_resource.pierce_count - pierce_remaining
		
		# 更新伤害（基于穿透次数的衰减）
		if current_pierce > 0:
			var pierce_damage = projectile_resource.get_pierce_damage(current_pierce)
			# 重新应用玩家属性加成
			current_damage = pierce_damage
			_apply_player_stats_bonuses()

## 更新飞行距离追踪
func _update_traveled_distance() -> void:
	traveled_distance = (global_position - start_position).length()

## 施加附带的buff到目标[br]
## [param target] 目标节点
func _apply_attached_buffs_to_target(target: Node) -> void:
	if not target or attached_buffs.is_empty():
		return
	
	# 检查目标是否支持buff
	if not target.has_method("add_buff"):
		return
	
	# 获取施法者（投射物的发射者）
	var caster = equipment.owner_player if equipment else null
	
	for buff_resource in attached_buffs:
		if buff_resource:
			var success = target.add_buff(buff_resource, caster)
			if success:
				print("投射物 %s 对目标施加buff: %s" % [_get_projectile_type(), buff_resource.buff_name])

## 添加附带的buff[br]
## [param buff_resource] buff资源
func add_attached_buff(buff_resource: BuffResource) -> void:
	if buff_resource and buff_resource not in attached_buffs:
		attached_buffs.append(buff_resource)

## 设置附带的buff列表[br]
## [param buffs] buff资源数组
func set_attached_buffs(buffs: Array[BuffResource]) -> void:
	attached_buffs = buffs

## 获取附带的buff列表[br]
## [returns] buff资源数组
func get_attached_buffs() -> Array[BuffResource]:
	return attached_buffs