extends Area2D
class_name Bullet

## 子弹类 - 处理子弹的移动和碰撞逻辑[br]
## 使用距离检测代替计时器来优化性能

@export var speed: float = GameConstants.BULLET_DEFAULT_SPEED
@export var damage: int = GameConstants.BULLET_DEFAULT_DAMAGE
var direction: Vector2
var distance_traveled: float = 0.0  ## 已移动距离
var max_distance: float = 800.0  ## 最大移动距离

func _ready() -> void:
	# 设置子弹的碰撞层
	collision_layer = GameConstants.COLLISION_LAYER_ENEMY_PROJECTILE
	collision_mask = GameConstants.COLLISION_LAYER_PLAYER
	
	# 连接碰撞信号
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# 注册到物理优化器

func _physics_process(delta: float) -> void:
	var movement = direction * speed * delta
	position += movement
	distance_traveled += movement.length()
	
	# 超过最大距离时销毁
	if distance_traveled >= max_distance:
		queue_free()

## 设置子弹移动方向[br]
## [param dir] 移动方向向量
func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()

## 设置子弹参数[br]
## [param dir] 移动方向[br]
## [param bullet_speed] 子弹速度[br]
## [param bullet_damage] 子弹伤害
func setup(dir: Vector2, bullet_speed: float, bullet_damage: int) -> void:
	direction = dir.normalized()
	speed = bullet_speed
	damage = bullet_damage
	distance_traveled = 0.0  # 重置移动距离

## 处理碰撞事件[br]
## [param body] 碰撞的物体
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.take_damage(damage)
		queue_free() 