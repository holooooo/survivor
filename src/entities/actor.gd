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

# 护甲系统
var max_armor: int = 0 ## 最大护甲值
var current_armor: int = 0 ## 当前护甲值

signal health_changed(new_health: int, max_health: int)
signal armor_changed(new_armor: int, max_armor: int)
signal died(actor: Actor)

func _ready() -> void:
	current_health = max_health
	current_armor = max_armor

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
	var remaining_damage = damage
	
	# 先消耗护甲
	if current_armor > 0:
		var armor_damage = min(current_armor, remaining_damage)
		current_armor -= armor_damage
		remaining_damage -= armor_damage
		armor_changed.emit(current_armor, max_armor)
	
	# 剩余伤害作用于生命值
	if remaining_damage > 0:
		set_health(current_health - remaining_damage)

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

## 设置护甲值[br]
## [param armor] 新的护甲值
func set_armor(armor: int) -> void:
	var old_armor = current_armor
	current_armor = clamp(armor, 0, max_armor)
	
	if current_armor != old_armor:
		armor_changed.emit(current_armor, max_armor)

## 设置最大护甲值[br]
## [param armor] 新的最大护甲值
func set_max_armor(armor: int) -> void:
	max_armor = max(0, armor)
	current_armor = min(current_armor, max_armor)
	armor_changed.emit(current_armor, max_armor)

## 恢复护甲[br]
## [param amount] 恢复的护甲值
func restore_armor(amount: int) -> void:
	set_armor(current_armor + amount)

## 获取当前护甲比例[br]
## [return] 护甲比例 (0.0 - 1.0)
func get_armor_ratio() -> float:
	if max_armor <= 0:
		return 0.0
	return float(current_armor) / float(max_armor) 