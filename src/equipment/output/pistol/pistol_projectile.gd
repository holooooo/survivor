extends Area2D
class_name PistolProjectile


## 手枪子弹投射物 - 直线飞行的子弹[br]
## 以直线方式飞向目标，具备穿透和伤害衰减能力

const TRAIL_LENGTH: int = 20 ## 拖尾长度
const TRAIL_INTERVAL: float = 0.02 ## 拖尾更新间隔

var projectile_resource: EmitterProjectileResource
var direction: Vector2 = Vector2.RIGHT ## 飞行方向
var current_speed: float = 800.0 ## 当前飞行速度
var lifetime_timer: float = 0.0 ## 存活时间计时器
var pierce_left: int = 1 ## 剩余穿透次数
var trail_timer: float = 0.0 ## 拖尾更新计时器

# 模组效果支持
var mod_effects: Array[Dictionary] = [] ## 应用的模组效果
var equipment_stats: Dictionary = {} ## 装备修改后的属性
signal projectile_hit(hit_target: Node2D) ## 投射物命中信号

@onready var sprite: Sprite2D = $Sprite2D
@onready var trail: Line2D = $Trail

func _ready() -> void:
	# 设置碰撞检测
	collision_layer = 4 # 武器层
	collision_mask = 2 # 敌人层
	
	# 添加到投射物组
	add_to_group("projectiles")
	
	# 连接碰撞信号 - 敌人是Area2D，需要使用area_entered
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if not projectile_resource:
		return
	
	lifetime_timer += delta
	
	# 生存时间或飞行距离到期时销毁
	if lifetime_timer >= projectile_resource.lifetime:
		_destroy_projectile()
		return
	
	# 直线移动
	global_position += direction * current_speed * delta
	
	_update_trail(delta)

## 从资源配置投射物[br]
## [param resource] 投射物资源[br]
## [param fly_direction] 飞行方向[br]
## [param equipment_stats] 装备修改后的属性（可选）
func setup_from_resource(resource: EmitterProjectileResource, fly_direction: Vector2, equipment_stats: Dictionary = {}) -> void:
	self.projectile_resource = resource
	self.equipment_stats = equipment_stats
	direction = fly_direction.normalized()
	
	if not self.projectile_resource:
		push_error("Projectile resource not set for PistolProjectile.")
		queue_free()
		return
	
	# 初始化参数，优先使用装备修改后的属性
	pierce_left = equipment_stats.get("pierce_count", self.projectile_resource.pierce_count)
	current_speed = equipment_stats.get("projectile_speed", self.projectile_resource.projectile_speed)
	
	# 设置外观
	_setup_visuals()
	
	# 设置子弹朝向
	if direction != Vector2.ZERO:
		rotation = direction.angle()

## 处理区域碰撞（敌人Area2D）[br]
## [param area] 碰撞的区域
func _on_area_entered(area: Area2D) -> void:
	# 检查是否是可命中的敌人
	if area.is_in_group("enemies"):
		_hit_enemy(area)

## 命中敌人处理[br]
## [param enemy] 被命中的敌人节点
func _hit_enemy(enemy: Node) -> void:
	if not projectile_resource:
		return

	var current_pierce = projectile_resource.pierce_count - pierce_left

	# 优先使用装备修改后的base_damage，如果没有则使用投射物资源的
	var base_damage = equipment_stats.get("base_damage", projectile_resource.base_damage)
	var damage = _calculate_pierce_damage(base_damage, current_pierce)

	# 对敌人造成伤害
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
	
	# 发射命中信号，触发模组效果
	projectile_hit.emit(enemy)
	
	# 减少穿透次数
	pierce_left -= 1
	
	if pierce_left < 0:
		_destroy_projectile()
	else:
		# 更新穿透后的速度
		current_speed = projectile_resource.get_pierce_speed(current_pierce + 1)


## 销毁投射物[br]
func _destroy_projectile() -> void:
	if is_queued_for_deletion():
		return
	queue_free()

## 设置视觉效果[br]
func _setup_visuals() -> void:
	# 设置精灵
	if sprite:
		if projectile_resource.projectile_texture:
			sprite.texture = projectile_resource.projectile_texture
		sprite.modulate = projectile_resource.projectile_color
		sprite.scale = projectile_resource.projectile_scale
	
	# 设置拖尾
	if trail:
		trail.width_curve = _create_trail_curve()
		trail.default_color = projectile_resource.trail_color

## 更新拖尾[br]
## [param delta] 每一帧的时间
func _update_trail(delta: float) -> void:
	if not trail:
		return
	
	trail_timer += delta
	if trail_timer < TRAIL_INTERVAL:
		return
	trail_timer = 0.0
	
	trail.global_position = Vector2.ZERO
	trail.global_rotation = 0.0
	
	# 添加新点
	trail.add_point(global_position)
	
	# 移除旧点
	while trail.get_point_count() > TRAIL_LENGTH:
		trail.remove_point(0)

## 创建拖尾曲线[br]
## [returns] 拖尾的宽度曲线
func _create_trail_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.2, 1.0))
	curve.add_point(Vector2(1.0, 1.0))
	return curve

## 添加模组效果到投射物[br]
## [param effects] 模组效果数组
func add_mod_effects(effects: Array[Dictionary]) -> void:
	mod_effects = effects
	ProjectileModifier.apply_mod_effects_to_projectile(self, mod_effects)

## 计算当前穿透后的伤害（复制自投射物资源的逻辑）[br]
## [param base_damage] 基础伤害[br]
## [param current_pierce] 当前穿透次数[br]
## [returns] 计算后的伤害值
func _calculate_pierce_damage(base_damage: int, current_pierce: int) -> int:
	if current_pierce <= 0:
		return base_damage
	
	var pierce_damage_reduction = equipment_stats.get("pierce_damage_reduction", projectile_resource.pierce_damage_reduction)
	var damage_multiplier: float = 1.0 - (pierce_damage_reduction * current_pierce)
	damage_multiplier = max(damage_multiplier, 0.1) # 最少保留10%伤害
	
	return int(base_damage * damage_multiplier)

## 获取投射物资源[br]
## [returns] 投射物资源
func get_projectile_resource() -> EmitterProjectileResource:
	return projectile_resource