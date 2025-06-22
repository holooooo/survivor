extends Area2D
class_name PistolProjectile

## 手枪子弹投射物 - 直线飞行的子弹[br]
## 以直线方式飞向目标，命中敌人后立即消失

var projectile_resource: ProjectileBase
var direction: Vector2 = Vector2.RIGHT ## 飞行方向
var speed: float = 800.0 ## 飞行速度
var lifetime_timer: float = 0.0 ## 存活时间计时器
var has_hit_target: bool = false ## 是否已命中目标

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# 设置碰撞检测
	collision_layer = 4 # 武器层
	collision_mask = 2  # 敌人层
	
	# 添加到投射物组
	add_to_group("projectiles")
	
	# 连接碰撞信号
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not projectile_resource or has_hit_target:
		return
	
	lifetime_timer += delta
	
	# 生存时间到期时销毁
	if lifetime_timer >= projectile_resource.lifetime:
		_destroy_projectile()
		return
	
	# 直线移动
	global_position += direction * speed * delta

## 从资源配置投射物[br]
## [param resource] 投射物资源[br]
## [param fly_direction] 飞行方向
func setup_from_resource(resource: Resource, fly_direction: Vector2) -> void:
	projectile_resource = resource
	direction = fly_direction.normalized()
	
	if not projectile_resource:
		return
	
	# 设置外观
	if sprite and projectile_resource.projectile_texture:
		sprite.texture = projectile_resource.projectile_texture
		sprite.modulate = projectile_resource.projectile_color
		sprite.scale = projectile_resource.projectile_scale
	elif sprite:
		# 使用默认外观
		var default_texture: Texture2D = load("res://icon.svg")
		if default_texture:
			sprite.texture = default_texture
			sprite.modulate = projectile_resource.projectile_color if projectile_resource else Color.WHITE
			sprite.scale = projectile_resource.projectile_scale if projectile_resource else Vector2(0.3, 0.3)
	
	# 设置子弹朝向
	if direction != Vector2.ZERO:
		rotation = direction.angle()

## 处理区域碰撞（敌人Area2D）[br]
## [param area] 碰撞的区域
func _on_area_entered(area: Area2D) -> void:
	if has_hit_target:
		return
	
	# 检查是否是敌人
	if area.is_in_group("enemies"):
		_hit_enemy(area)

## 处理刚体碰撞（敌人RigidBody2D或CharacterBody2D）[br]
## [param body] 碰撞的刚体
func _on_body_entered(body: Node2D) -> void:
	if has_hit_target:
		return
	
	# 检查是否是敌人
	if body.is_in_group("enemies"):
		_hit_enemy(body)

## 命中敌人处理[br]
## [param enemy] 被命中的敌人节点
func _hit_enemy(enemy: Node) -> void:
	if has_hit_target or not projectile_resource:
		return
	
	has_hit_target = true
	
	# 对敌人造成伤害
	if enemy.has_method("take_damage"):
		enemy.take_damage(projectile_resource.damage_per_tick)
	
	# 立即销毁子弹
	_destroy_projectile()

## 销毁投射物[br]
func _destroy_projectile() -> void:
	queue_free()

## 设置投射物参数（兼容旧接口）[br]
## [param fly_direction] 飞行方向[br]
## [param damage] 伤害数值[br]
## [param bullet_speed] 飞行速度[br]
## [param proj_lifetime] 投射物存在时间
func setup(fly_direction: Vector2, damage: int, bullet_speed: float = 800.0, proj_lifetime: float = 3.0) -> void:
	# 创建临时资源用于兼容
	var temp_resource = preload("res://src/equipment/projectile_base.gd").new()
	temp_resource.damage_per_tick = damage
	temp_resource.lifetime = proj_lifetime
	temp_resource.projectile_color = Color.WHITE
	temp_resource.projectile_scale = Vector2(0.3, 0.3)
	
	speed = bullet_speed
	setup_from_resource(temp_resource, fly_direction) 