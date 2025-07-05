extends HitEffectResource
class_name GatherHitEffect

## 集聚命中效果 - 命中敌人时使一定范围内的敌人向投射物靠拢[br]
## 类似击退效果的反向操作，属于控制效果会禁用敌人移动

@export_group("集聚配置")
@export var gather_radius: float = 200.0 ## 集聚影响范围
@export var gather_duration: float = 0.5 ## 拉拽持续时间
@export var gather_strength: float = 0.8 ## 拉拽强度（0-1，表示拉拽到目标位置的比例）
@export var disable_ai_during_gather: bool = true ## 集聚期间是否禁用敌人AI

func _init():
	effect_name = "集聚效果"
	effect_id = "gather"

## 重写执行效果方法[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例[br]
## [param target] 目标节点[br]
## [param hit_info] 命中信息字典
func execute_effect(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, hit_info: Dictionary) -> void:
	if not hit_info.has("hit_position"):
		return
	
	var gather_center: Vector2 = hit_info.hit_position
	
	# 延迟执行集聚效果，避免在物理查询期间修改状态
	call_deferred("_apply_gather_deferred", gather_center, player, equipment)

## 延迟应用集聚效果[br]
## [param center] 集聚中心位置[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例
func _apply_gather_deferred(center: Vector2, player: Player, equipment: EquipmentBase) -> void:
	# 查找范围内的敌人
	var enemies_in_range: Array[Node] = _find_enemies_in_range(center)
	
	if enemies_in_range.is_empty():
		return
	
	# 对每个敌人应用集聚效果
	var gathered_enemies: Array[Node] = []
	for enemy in enemies_in_range:
		if _apply_gather_to_enemy(enemy, center):
			gathered_enemies.append(enemy)
	
	# 发送集聚信号
	if not gathered_enemies.is_empty():
		FightEventBus.on_enemies_gathered.emit(center, gathered_enemies, gather_radius)

## 查找范围内的敌人[br]
## [param center] 中心位置[br]
## [returns] 范围内的敌人数组
func _find_enemies_in_range(center: Vector2) -> Array[Node]:
	var enemies_in_range: Array[Node] = []
	
	# 获取场景树中的所有敌人
	var scene_tree = Engine.get_main_loop() as SceneTree
	if not scene_tree:
		return enemies_in_range
	
	var all_enemies = scene_tree.get_nodes_in_group("enemies")
	
	for enemy in all_enemies:
		if not enemy or not is_instance_valid(enemy):
			continue
		
		# 检查敌人是否在集聚范围内
		var distance = enemy.global_position.distance_to(center)
		if distance <= gather_radius:
			enemies_in_range.append(enemy)
	
	return enemies_in_range

## 对单个敌人应用集聚效果[br]
## [param enemy] 敌人节点[br]
## [param center] 集聚中心[br]
## [returns] 是否成功应用效果
func _apply_gather_to_enemy(enemy: Node, center: Vector2) -> bool:
	if not enemy or not is_instance_valid(enemy):
		return false
	
	# 检查敌人是否支持集聚（有位置属性）
	if not enemy.has_method("get_global_position") and not enemy.get("global_position"):
		return false
	
	# 禁用敌人移动（如果启用）
	if disable_ai_during_gather:
		_disable_enemy_movement(enemy)
	
	# 计算目标位置
	var start_position: Vector2 = enemy.global_position
	var direction_to_center: Vector2 = (center - start_position).normalized()
	var distance_to_center: float = start_position.distance_to(center)
	var pull_distance: float = distance_to_center * gather_strength
	var target_position: Vector2 = start_position + direction_to_center * pull_distance
	
	# 使用Tween实现拉拽动画
	var tween = enemy.create_tween()
	if not tween:
		# 如果无法创建Tween，恢复移动能力
		if disable_ai_during_gather:
			_enable_enemy_movement(enemy)
		return false
	
	# 拉拽动画
	tween.tween_property(enemy, "global_position", target_position, gather_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 集聚结束后恢复敌人移动能力
	if disable_ai_during_gather:
		tween.tween_callback(func(): _enable_enemy_movement(enemy))
	
	return true

## 禁用敌人移动[br]
## [param enemy] 敌人节点
func _disable_enemy_movement(enemy: Node) -> void:
	# 检查敌人是否有禁用移动的方法
	if enemy.has_method("set_movement_disabled"):
		enemy.set_movement_disabled(true)
	elif enemy.has_method("disable_movement"):
		enemy.disable_movement()
	elif enemy.has_property("can_move"):
		enemy.can_move = false
	elif enemy.has_property("movement_disabled"):
		enemy.movement_disabled = true
	# 如果敌人有速度属性，可以临时保存并设为0
	elif enemy.has_property("speed"):
		if not enemy.has_meta("original_speed"):
			enemy.set_meta("original_speed", enemy.speed)
		enemy.speed = 0

## 恢复敌人移动[br]
## [param enemy] 敌人节点
func _enable_enemy_movement(enemy: Node) -> void:
	# 检查敌人是否有恢复移动的方法
	if enemy.has_method("set_movement_disabled"):
		enemy.set_movement_disabled(false)
	elif enemy.has_method("enable_movement"):
		enemy.enable_movement()
	elif enemy.has_property("can_move"):
		enemy.can_move = true
	elif enemy.has_property("movement_disabled"):
		enemy.movement_disabled = false
	# 恢复原始速度
	elif enemy.has_property("speed") and enemy.has_meta("original_speed"):
		enemy.speed = enemy.get_meta("original_speed")
		enemy.remove_meta("original_speed")

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
	
	# 检查集聚范围是否有效
	if gather_radius <= 0:
		return false
	
	# 检查集聚强度是否有效
	if gather_strength <= 0 or gather_strength > 1.0:
		return false
	
	return true

## 获取效果描述[br]
## [returns] 效果描述文本
func get_description() -> String:
	var desc = "集聚 %.0f 范围内敌人，拉拽强度 %.0f%%，持续 %.1f秒" % [gather_radius, gather_strength * 100, gather_duration]
	if trigger_probability < 1.0:
		desc += "（%.0f%% 概率）" % (trigger_probability * 100)
	if cooldown_time > 0:
		desc += "（冷却 %.1f秒）" % cooldown_time
	return desc 