extends CharacterBody2D
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

# Buff系统
var buff_manager: BuffManager

# 碰撞检测区域 - 用于伤害检测和触发器
var collision_area: Area2D

signal health_changed(new_health: int, max_health: int)
signal armor_changed(new_armor: int, max_armor: int)
signal died(actor: Actor)

func _ready() -> void:
	current_health = max_health
	current_armor = max_armor
	_initialize_buff_manager()
	_setup_collision_area()
	
	# 启用碰撞监听
	set_collision_monitoring(true, true)
	
	# 监听生命值变化，用于检查收割标记触发条件
	health_changed.connect(_on_health_changed)
	armor_changed.connect(_on_armor_changed)
	died.connect(_on_died)

## 设置碰撞检测区域[br]
## 创建Area2D子节点用于伤害检测和触发器
func _setup_collision_area() -> void:
	# 先尝试获取场景中已存在的CollisionArea
	collision_area = get_node_or_null("CollisionArea")
	if not collision_area:
		# 如果场景中没有CollisionArea，动态创建一个
		collision_area = Area2D.new()
		collision_area.name = "CollisionArea"
		add_child(collision_area)
		
		# 为动态创建的Area2D添加碰撞形状
		var collision_shape = CollisionShape2D.new()
		collision_shape.name = "AreaCollision"
		var shape = RectangleShape2D.new()
		shape.size = Vector2(120, 120)
		collision_shape.shape = shape
		collision_area.add_child(collision_shape)
	
	# 确保CollisionArea属于正确的组
	if not collision_area.is_in_group("actors"):
		collision_area.add_to_group("actors")

## 获取碰撞检测区域[br]
## [return] Area2D碰撞检测区域
func get_collision_area() -> Area2D:
	return collision_area

## 设置碰撞区域的监听状态[br]
## [param enable_monitoring] 是否启用监听[br]
## [param enable_monitorable] 是否可被监听
func set_collision_monitoring(enable_monitoring: bool = true, enable_monitorable: bool = true) -> void:
	if collision_area:
		collision_area.set_deferred("monitoring", enable_monitoring)
		collision_area.set_deferred("monitorable", enable_monitorable)

## 移动到指定位置[br]
## [param target_position] 目标位置[br]
## [param delta] 帧时间间隔
func move_towards(target_position: Vector2, delta: float) -> void:
	if is_dead or is_immobilized():
		velocity = Vector2.ZERO
		return
		
	var direction = (target_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

## 按方向移动[br]
## [param direction] 移动方向向量[br]
## [param delta] 帧时间间隔
func move_by_direction(direction: Vector2, delta: float) -> void:
	if is_dead or is_immobilized():
		velocity = Vector2.ZERO
		return
		
	velocity = direction.normalized() * speed
	move_and_slide()

## 设置移动速度[br]
## [param new_velocity] 新的移动速度向量
func set_velocity_direct(new_velocity: Vector2) -> void:
	if is_dead or is_immobilized():
		velocity = Vector2.ZERO
		return
	velocity = new_velocity

## 停止移动[br]
func stop_movement() -> void:
	velocity = Vector2.ZERO
	
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
## [param damage] 伤害值[br]
## [param damage_type] 伤害类型
func take_damage(damage: int, damage_type: int = 0) -> void:
	# 检查无敌状态
	if is_invincible():
		print("无敌状态，免疫伤害")
		return
	
	# 应用伤害修正
	var modified_damage = apply_damage_modifiers(damage, damage_type)
	var remaining_damage = modified_damage
	
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

## 检查是否有无敌状态[br]
## [return] 是否无敌
func is_invincible() -> bool:
	if buff_manager and buff_manager.has_method("has_control_effect"):
		return buff_manager.has_control_effect("invincible")
	return false

## 检查是否被禁锢[br]
## [return] 是否被禁锢
func is_immobilized() -> bool:
	if buff_manager and buff_manager.has_method("has_control_effect"):
		return buff_manager.has_control_effect("immobilize")
	return false

## 检查是否被沉默[br]
## [return] 是否被沉默
func is_silenced() -> bool:
	if buff_manager and buff_manager.has_method("has_control_effect"):
		return buff_manager.has_control_effect("silence")
	return false

## 应用伤害修正[br]
## [param damage] 原始伤害[br]
## [param damage_type] 伤害类型[br]
## [return] 修正后的伤害
func apply_damage_modifiers(damage: int, damage_type: int = 0) -> int:
	if buff_manager and buff_manager.has_method("apply_damage_modifiers"):
		return buff_manager.apply_damage_modifiers(damage, damage_type)
	return damage

## 初始化buff管理器[br]
func _initialize_buff_manager() -> void:
	# 尝试获取场景中的BuffManager节点
	buff_manager = get_node_or_null("%BuffManager")
	if not buff_manager:
		# 如果场景中没有BuffManager，动态创建一个
		buff_manager = BuffManager.new()
		buff_manager.name = "BuffManager"
		add_child(buff_manager)

## 获取BuffManager实例[br]
## [returns] BuffManager实例
func get_buff_manager() -> Node:
	return buff_manager

## 添加buff[br]
## [param buff_resource] buff资源[br]
## [param caster] 施法者[br]
## [returns] 是否成功添加
func add_buff(buff_resource, caster: Actor = null) -> bool:
	if buff_manager:
		return buff_manager.add_buff(buff_resource, caster)
	return false

## 移除buff[br]
## [param buff_id] buff ID[br]
## [returns] 是否成功移除
func remove_buff(buff_id: String) -> bool:
	if buff_manager and buff_manager.has_method("remove_buff"):
		return buff_manager.remove_buff(buff_id)
	return false

## 检查是否有指定buff[br]
## [param buff_id] buff ID[br]
## [returns] 是否存在
func has_buff(buff_id: String) -> bool:
	if buff_manager and buff_manager.has_method("has_buff"):
		return buff_manager.has_buff(buff_id)
	return false

## 生命值变化回调[br]
## [param new_health] 新的生命值[br]
## [param max_health] 最大生命值
func _on_health_changed(new_health: int, max_health: int) -> void:
	# 检查收割标记的触发条件
	if buff_manager and buff_manager.has_method("_check_special_buff_triggers"):
		var harvest_buff = null
		for buff in buff_manager.active_buffs:
			if buff.buff_resource.buff_id == "harvest_mark":
				harvest_buff = buff
				break
		
		if harvest_buff:
			buff_manager._check_special_buff_triggers(harvest_buff)

func _on_armor_changed(new_armor: int, max_armor: int) -> void:
	pass

func _on_died(actor: Actor) -> void:
	pass