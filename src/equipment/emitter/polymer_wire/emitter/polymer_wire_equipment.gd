extends EmitterEquipmentBase
class_name PolymerWireEquipment

## 高分子线装备 - 标记敌人并在条件满足时造成高额伤害[br]
## 标记攻击范围内的随机敌人，当标记数量>5或无其他敌人时移除标记并造成伤害

@export var mark_damage: int = 75 ## 标记爆炸伤害
@export var max_marks: int = 5 ## 最大标记数量

var marked_enemies: Array[Node] = [] ## 已标记的敌人列表

func _ready() -> void:
	super._ready()
	# 设置伤害类型
	damage_type = Constants.DamageType.能量

## 重写执行装备效果
func _execute_equipment_effect() -> void:
	if not owner_player:
		return
	
	# 获取攻击范围内的敌人
	var enemies_in_range = _get_enemies_in_range()
	
	# 过滤掉已标记的敌人
	var unmarked_enemies = enemies_in_range.filter(func(enemy): return enemy not in marked_enemies)
	
	# 如果没有未标记的敌人，触发标记爆炸
	if unmarked_enemies.is_empty():
		_trigger_mark_explosion()
		return
	
	# 随机选择一个未标记的敌人进行标记
	var target_enemy = unmarked_enemies[randi() % unmarked_enemies.size()]
	_mark_enemy(target_enemy)
	
	# 检查是否达到最大标记数量
	if marked_enemies.size() > max_marks:
		_trigger_mark_explosion()

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

## 标记敌人[br]
## [param enemy] 要标记的敌人
func _mark_enemy(enemy: Node) -> void:
	if not enemy or not is_instance_valid(enemy) or enemy in marked_enemies:
		return
	
	marked_enemies.append(enemy)
	
	# 添加视觉标记效果
	_add_mark_visual(enemy)
	
	# 连接敌人死亡信号，自动移除标记
	if enemy.has_signal("died"):
		# 使用one_shot连接，避免重复连接
		if not enemy.died.is_connected(_on_marked_enemy_died):
			enemy.died.connect(_on_marked_enemy_died.bind(enemy), CONNECT_ONE_SHOT)
	
	print("标记敌人: ", enemy.name, " 当前标记数量: ", marked_enemies.size())

## 添加标记视觉效果[br]
## [param enemy] 被标记的敌人
func _add_mark_visual(enemy: Node) -> void:
	# 检查是否已经有标记
	if enemy.get_node_or_null("PolymerWireMark"):
		return
	
	# 创建标记图标
	var mark_icon = Sprite2D.new()
	mark_icon.name = "PolymerWireMark"
	mark_icon.texture = load("res://icon.svg") # 使用默认图标作为标记
	mark_icon.scale = Vector2(0.2, 0.2)
	mark_icon.modulate = Color.MAGENTA
	mark_icon.position = Vector2(0, -30) # 显示在敌人头上
	
	enemy.add_child(mark_icon)
	
	# 添加闪烁效果 - 使用有限循环避免无限循环问题
	var tween = mark_icon.create_tween()
	tween.set_loops(-1) # -1 表示无限循环，但绑定到mark_icon上，会随着节点销毁而停止
	tween.tween_property(mark_icon, "modulate:a", 0.5, 0.5)
	tween.tween_property(mark_icon, "modulate:a", 1.0, 0.5)

## 移除敌人标记[br]
## [param enemy] 要移除标记的敌人
func _remove_mark_visual(enemy: Node) -> void:
	if not enemy or not is_instance_valid(enemy):
		return
	
	var mark_icon = enemy.get_node_or_null("PolymerWireMark")
	if mark_icon:
		# 立即删除标记图标，Tween会自动随着节点销毁而停止
		mark_icon.queue_free()

## 触发标记爆炸
func _trigger_mark_explosion() -> void:
	if marked_enemies.is_empty():
		return
	
	print("触发标记爆炸！标记数量: ", marked_enemies.size())
	
	# 对所有标记的敌人造成伤害
	for enemy in marked_enemies:
		if enemy and is_instance_valid(enemy) and not enemy.is_dead:
			_deal_explosion_damage(enemy)
			_remove_mark_visual(enemy)
	
	# 清空标记列表
	marked_enemies.clear()

## 对敌人造成爆炸伤害[br]
## [param enemy] 目标敌人
func _deal_explosion_damage(enemy: Node) -> void:
	if not enemy.has_method("take_damage"):
		return
	
	# 应用玩家属性加成
	var final_damage = mark_damage
	if owner_player and owner_player.stats_manager:
		var damage_multiplier = owner_player.stats_manager.get_damage_multiplier(damage_type)
		final_damage = int(final_damage * damage_multiplier)
	
	# 造成伤害
	enemy.take_damage(final_damage)
	
	# 显示伤害数字
	var damage_color = Constants.get_damage_type_color(damage_type)
	EventBus.show_damage_number(final_damage, enemy.global_position, damage_color)
	
	# 发送伤害事件
	FightEventBus.on_projectile_hit.emit(owner_player, self, null, enemy, final_damage, damage_type)

## 标记的敌人死亡回调[br]
## [param enemy] 死亡的敌人
func _on_marked_enemy_died(enemy: Node) -> void:
	if enemy and enemy in marked_enemies:
		marked_enemies.erase(enemy)
		_remove_mark_visual(enemy)
		print("标记的敌人死亡，移除标记。剩余标记: ", marked_enemies.size())
		
		# 由于使用了CONNECT_ONE_SHOT，信号会自动断开，无需手动断开

## 重写检查是否可以使用装备
func can_use() -> bool:
	# 检查基类条件
	if not super.can_use():
		return false
	
	# 检查是否有可标记的目标
	var enemies_in_range = _get_enemies_in_range()
	var unmarked_enemies = enemies_in_range.filter(func(enemy): return enemy not in marked_enemies)
	
	# 如果没有未标记的敌人但有标记，可以触发爆炸
	if unmarked_enemies.is_empty() and not marked_enemies.is_empty():
		return true
	
	# 如果有未标记的敌人，可以标记
	return not unmarked_enemies.is_empty()

## 重写投射物生成 - 高分子线不需要投射物
func _fire_single_projectile() -> void:
	# 高分子线不发射投射物，直接执行标记逻辑
	pass

## 清理所有标记[br]
## 在装备卸载时调用
func _cleanup_all_marks() -> void:
	for enemy in marked_enemies:
		if enemy and is_instance_valid(enemy):
			_remove_mark_visual(enemy)
			# 由于使用了CONNECT_ONE_SHOT，死亡时信号会自动断开
			# 但为了安全起见，手动断开仍然存在的连接
			if enemy.has_signal("died") and enemy.died.is_connected(_on_marked_enemy_died):
				enemy.died.disconnect(_on_marked_enemy_died)
	
	marked_enemies.clear()
	print("高分子线装备：清理所有标记")

## 重写节点退出场景树时的清理
func _exit_tree() -> void:
	_cleanup_all_marks() 