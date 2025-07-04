extends EmitterEquipmentBase
class_name PolymerWireEquipment

## 高分子线装备 - 使用buff系统标记敌人[br]
## 施加收割标记buff，由buff系统处理收割逻辑

@export var harvest_mark_buff_resource: BuffResource ## 收割标记buff资源

func _ready() -> void:
	super._ready()
	# 设置伤害类型
	damage_type = Constants.DamageType.能量
	
	# 加载收割标记buff资源
	if not harvest_mark_buff_resource:
		harvest_mark_buff_resource = load("res://src/entities/buff/resources/harvest_mark_buff.tres")

## 重写执行装备效果
func _execute_equipment_effect() -> void:
	if not owner_player or not harvest_mark_buff_resource:
		return
	
	# 获取攻击范围内的敌人
	var enemies_in_range = _get_enemies_in_range()
	
	if enemies_in_range.is_empty():
		return
	
	# 随机选择一个敌人进行标记
	var target_enemy = enemies_in_range[randi() % enemies_in_range.size()]
	_mark_enemy_with_buff(target_enemy)

## 获取攻击范围内的敌人[br]
## [returns] 敌人节点数组
func _get_enemies_in_range() -> Array[Node]:
	var enemies_in_range: Array[Node] = []
	var attack_range: float = emitter_config.get("attack_range", 300.0)
	
	if not owner_player:
		return enemies_in_range
	
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in all_enemies:
		if enemy and is_instance_valid(enemy) and not enemy.is_dead:
			var distance = owner_player.global_position.distance_to(enemy.global_position)
			if distance <= attack_range:
				enemies_in_range.append(enemy)
	
	return enemies_in_range

## 使用buff系统标记敌人[br]
## [param enemy] 要标记的敌人
func _mark_enemy_with_buff(enemy: Node) -> void:
	if not enemy or not is_instance_valid(enemy):
		return
	
	# 使用buff系统施加收割标记
	# 视觉标记由buff系统的SpecialBuffEffect自动管理
	var success = enemy.add_buff(harvest_mark_buff_resource, owner_player)
	if success:
		print("高分子线标记敌人: %s" % enemy.name)
	else:
		print("高分子线标记失败: %s" % enemy.name)

# 视觉标记管理已移至SpecialBuffEffect，此处不再需要

## 重写检查是否可以使用装备
func can_use() -> bool:
	# 检查基类条件
	if not super.can_use():
		return false
	
	# 检查是否有可标记的目标
	var enemies_in_range = _get_enemies_in_range()
	return not enemies_in_range.is_empty()

## 重写投射物生成 - 高分子线不需要投射物
func _fire_single_projectile() -> void:
	# 高分子线不发射投射物，直接执行标记逻辑
	pass 