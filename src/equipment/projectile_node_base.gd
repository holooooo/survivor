extends Area2D
class_name ProjectileNodeBase

## 投射物节点抽象基类 - 所有投射物节点的通用逻辑[br]
## 提供碰撞检测、生命周期管理、伤害处理、视觉效果等共同功能[br]
## 子类只需实现特定的移动模式和特殊效果

var projectile_resource: EmitterProjectileResource
var equipment_stats: Dictionary = {} ## 装备修改后的属性
var mod_effects: Array[Dictionary] = [] ## 应用的模组效果

# 生命周期管理
var lifetime_timer: float = 0.0 ## 存活时间计时器
var is_destroyed: bool = false ## 是否已被销毁

# 伤害系统
var base_damage: int = 10 ## 基础伤害
var current_damage: int = 10 ## 当前伤害（可能被模组修改）

# 碰撞系统
var colliding_targets: Array[Node] = [] ## 当前碰撞中的目标

# 视觉组件（可选）
var sprite: Sprite2D
var collision_shape: CollisionShape2D

signal projectile_hit(target: Node2D) ## 投射物命中信号
signal projectile_destroyed() ## 投射物销毁信号

func _ready() -> void:
	_find_optional_nodes()
	_setup_collision_system()
	_setup_lifecycle()
	add_to_group("projectiles")

## 查找可选节点[br]
func _find_optional_nodes() -> void:
	# 安全查找Sprite2D节点
	sprite = get_node_or_null("Sprite2D")
	if not sprite:
		sprite = get_node_or_null("Sprite")
	
	# 安全查找CollisionShape2D节点
	collision_shape = get_node_or_null("CollisionShape2D")
	if not collision_shape:
		collision_shape = get_node_or_null("CollisionShape")

func _physics_process(delta: float) -> void:
	if is_destroyed:
		return
	
	lifetime_timer += delta
	
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
func setup_from_resource(resource: EmitterProjectileResource, direction: Vector2, stats: Dictionary = {}) -> void:
	projectile_resource = resource
	equipment_stats = stats
	
	if not projectile_resource:
		push_error("Projectile resource not set.")
		queue_free()
		return
	
	# 设置基础属性
	base_damage = equipment_stats.get("base_damage", projectile_resource.base_damage)
	current_damage = base_damage
	
	# 设置视觉效果
	_setup_visuals()
	
	# 执行特定初始化
	_initialize_specific(direction)

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
	if target.has_method("take_damage"):
		target.take_damage(damage_amount)
	
	# 发射命中信号
	projectile_hit.emit(target)

## 检查是否应该销毁[br]
## [returns] 是否应该销毁
func _should_destroy() -> bool:
	if not projectile_resource:
		return lifetime_timer >= 5.0 # 默认5秒
	
	return lifetime_timer >= projectile_resource.lifetime

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
	projectile_destroyed.emit()
	
	# 从组中移除
	if is_in_group("projectiles"):
		remove_from_group("projectiles")
	
	# 销毁节点
	queue_free()

## 添加模组效果[br]
## [param effects] 模组效果数组
func add_mod_effects(effects: Array[Dictionary]) -> void:
	mod_effects = effects
	ProjectileModifier.apply_mod_effects_to_projectile(self, mod_effects)

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
	# 默认立即造成伤害
	_deal_damage_to_target(target, current_damage)

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