extends Area2D
class_name Actor

## 基础actor类，所有游戏实体的基类[br]
## 提供通用的生命值、移动等基础功能[br]
## [codeblock]
## # 使用示例：
## extends Actor
## func _ready():
##     super()
##     max_health = 100
## [/codeblock]

@export var max_health: int = 100
@export var speed: float = 200.0

var current_health: int
var is_dead: bool = false

signal health_changed(new_health: int, max_health: int)
signal died(actor: Actor)

func _ready() -> void:
	current_health = max_health

## 移动到指定位置[br]
## [param target_position] 目标位置[br]
## [param delta] 帧时间间隔
func move_towards(target_position: Vector2, delta: float) -> void:
	if is_dead:
		return
		
	var direction = (target_position - global_position).normalized()
	global_position += direction * speed * delta

## 按方向移动[br]
## [param direction] 移动方向向量[br]
## [param delta] 帧时间间隔
func move_by_direction(direction: Vector2, delta: float) -> void:
	if is_dead:
		return
		
	global_position += direction.normalized() * speed * delta
	
## 设置生命值[br]
## [param health] 新的生命值
func set_health(health: int) -> void:
	var old_health = current_health
	current_health = clamp(health, 0, max_health)
	
	if current_health != old_health:
		health_changed.emit(current_health, max_health)
		
	if current_health <= 0 and not is_dead:
		die()

## 受到伤害[br]
## [param damage] 伤害值
func take_damage(damage: int) -> void:
	set_health(current_health - damage)

## 恢复生命值[br]
## [param amount] 恢复的生命值
func heal(amount: int) -> void:
	set_health(current_health + amount)

## 死亡处理
func die() -> void:
	if is_dead:
		return
		
	is_dead = true
	died.emit(self)
	_on_death()

## 子类可重写的死亡回调
func _on_death() -> void:
	pass

## 获取当前生命值比例[br]
## [return] 生命值比例 (0.0 - 1.0)
func get_health_ratio() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health) 