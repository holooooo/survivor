extends HitEffectResource
class_name ExplosionHitEffect

## 爆炸命中效果 - 命中敌人时在原地生成快速引爆的爆炸投射物[br]
## 参考bomb投射物系统，支持可配置的爆炸参数

@export_group("爆炸配置")
@export var explosion_radius: float = 100.0 ## 爆炸半径
@export var use_damage_ratio: bool = true ## 是否使用伤害比例模式
@export var damage_ratio: float = 0.8 ## 爆炸伤害比例（相对于原伤害）
@export var fixed_damage: int = 50 ## 固定爆炸伤害（非比例模式）
@export var inherit_damage_type: bool = true ## 是否继承原投射物伤害类型
@export var detonation_delay: float = 0.1 ## 引爆延迟时间
@export var explosion_spread_speed: float = 500.0 ## 爆炸扩散速度

func _init():
	effect_name = "爆炸效果"
	effect_id = "explosion"

## 重写执行效果方法[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [param projectile] 投射物实例[br]
## [param target] 目标节点[br]
## [param hit_info] 命中信息字典
func execute_effect(player: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, hit_info: Dictionary) -> void:
	if not hit_info.has("hit_position"):
		return
	
	var explosion_position: Vector2 = hit_info.hit_position
	var original_damage: int = hit_info.get("damage", projectile.current_damage)
	var original_damage_type: Constants.DamageType = hit_info.get("damage_type", projectile.damage_type)
	
	# 计算爆炸伤害
	var explosion_damage: int
	if use_damage_ratio:
		explosion_damage = int(original_damage * damage_ratio)
	else:
		explosion_damage = fixed_damage
	
	# 确定爆炸伤害类型
	var explosion_damage_type: Constants.DamageType
	if inherit_damage_type:
		explosion_damage_type = original_damage_type
	else:
		explosion_damage_type = Constants.DamageType.爆炸
	
	# 延迟创建爆炸，避免在物理查询期间修改状态
	call_deferred("_create_explosion_deferred", explosion_position, explosion_damage, explosion_damage_type, player, equipment)

## 延迟创建爆炸效果[br]
## [param position] 爆炸位置[br]
## [param damage] 爆炸伤害[br]
## [param damage_type] 爆炸伤害类型[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例
func _create_explosion_deferred(position: Vector2, damage: int, damage_type: Constants.DamageType, player: Player, equipment: EquipmentBase) -> void:
	# 创建爆炸节点
	var explosion: Area2D = _create_explosion_area(position, damage, damage_type, player, equipment)
	
	if explosion:
		# 添加到场景树中
		if equipment.get_parent():
			equipment.get_parent().add_child(explosion)
		else:
			# 备用方案：添加到玩家的父节点
			if player.get_parent():
				player.get_parent().add_child(explosion)
			else:
				explosion.queue_free()
				return
		
		# 设置爆炸位置
		explosion.global_position = position
		
		# 发送爆炸信号
		FightEventBus.on_explosion_triggered.emit(position, explosion_radius, damage)

## 创建爆炸区域[br]
## [param position] 爆炸位置[br]
## [param damage] 爆炸伤害[br]
## [param damage_type] 爆炸伤害类型[br]
## [param player] 玩家实例[br]
## [param equipment] 装备实例[br]
## [returns] 爆炸Area2D节点
func _create_explosion_area(position: Vector2, damage: int, damage_type: Constants.DamageType, player: Player, equipment: EquipmentBase) -> Area2D:
	var explosion = Area2D.new()
	explosion.name = "ExplosionEffect"
	
	# 设置碰撞层级
	explosion.collision_layer = 0
	explosion.collision_mask = 2  # 敌人层
	
	# 创建碰撞形状
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 0.0  # 初始半径为0，通过动画扩大
	collision_shape.shape = circle_shape
	explosion.add_child(collision_shape)
	
	# 创建视觉效果（简单的圆形）
	var visual = ColorRect.new()
	visual.size = Vector2.ZERO
	visual.color = Color.ORANGE
	visual.position = Vector2.ZERO
	explosion.add_child(visual)
	
	# 存储爆炸参数
	explosion.set_meta("explosion_damage", damage)
	explosion.set_meta("damage_type", damage_type)
	explosion.set_meta("player", player)
	explosion.set_meta("equipment", equipment)
	explosion.set_meta("affected_targets", [])
	
	# 连接碰撞信号
	explosion.area_entered.connect(_on_explosion_area_entered.bind(explosion))
	
	# 启动爆炸动画
	_start_explosion_animation(explosion, circle_shape, visual)
	
	return explosion

## 启动爆炸动画[br]
## [param explosion] 爆炸节点[br]
## [param shape] 碰撞形状[br]
## [param visual] 视觉节点
func _start_explosion_animation(explosion: Area2D, shape: CircleShape2D, visual: ColorRect) -> void:
	# 等待引爆延迟
	await explosion.get_tree().create_timer(detonation_delay).timeout
	
	if not is_instance_valid(explosion):
		return
	
	# 启用碰撞检测
	explosion.monitoring = true
	explosion.monitorable = true
	
	# 计算动画持续时间
	var duration: float = explosion_radius / explosion_spread_speed if explosion_spread_speed > 0 else 0.2
	
	# 创建扩散动画
	var tween: Tween = explosion.create_tween()
	tween.set_parallel(true)
	
	# 动画1: 扩大碰撞区域
	tween.tween_property(shape, "radius", explosion_radius, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 动画2: 扩大视觉效果
	var final_size = Vector2.ONE * explosion_radius * 2
	var final_position = -final_size / 2
	tween.tween_property(visual, "size", final_size, duration)
	tween.tween_property(visual, "position", final_position, duration)
	
	# 动画3: 渐隐效果
	tween.set_parallel(false)
	tween.tween_property(visual, "modulate:a", 0.0, 0.2)
	tween.tween_callback(explosion.queue_free)

## 爆炸区域碰撞处理[br]
## [param explosion] 爆炸节点[br]
## [param area] 进入的区域
func _on_explosion_area_entered(explosion: Area2D, area: Area2D) -> void:
	if not is_instance_valid(explosion) or not is_instance_valid(area):
		return
	
	var target = area.get_parent()
	if not target or not target.is_in_group("enemies"):
		return
	
	# 检查是否已经影响过这个目标
	var affected_targets: Array = explosion.get_meta("affected_targets", [])
	if target in affected_targets:
		return
	
	# 添加到已影响列表
	affected_targets.append(target)
	explosion.set_meta("affected_targets", affected_targets)
	
	# 造成爆炸伤害
	var explosion_damage: int = explosion.get_meta("explosion_damage", 0)
	var damage_type: Constants.DamageType = explosion.get_meta("damage_type", Constants.DamageType.爆炸)
	var player: Player = explosion.get_meta("player")
	var equipment: EquipmentBase = explosion.get_meta("equipment")
	
	if target.has_method("take_damage"):
		target.take_damage(explosion_damage)
		
		# 显示伤害数字
		var damage_color: Color = Constants.get_damage_type_color(damage_type)
		EventBus.show_damage_number(explosion_damage, target.global_position, damage_color)
		
		# 发送命中事件
		if player and equipment:
			FightEventBus.on_projectile_hit.emit(player, equipment, null, target, explosion_damage, damage_type)

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
	
	# 检查爆炸半径是否有效
	if explosion_radius <= 0:
		return false
	
	return true

## 获取效果描述[br]
## [returns] 效果描述文本
func get_description() -> String:
	var desc: String
	if use_damage_ratio:
		desc = "在命中点引爆，造成 %.0f%% 伤害，半径 %.0f" % [damage_ratio * 100, explosion_radius]
	else:
		desc = "在命中点引爆，造成 %d 固定伤害，半径 %.0f" % [fixed_damage, explosion_radius]
	
	if detonation_delay > 0:
		desc += "（延迟 %.1f秒）" % detonation_delay
	
	if trigger_probability < 1.0:
		desc += "（%.0f%% 概率）" % (trigger_probability * 100)
	if cooldown_time > 0:
		desc += "（冷却 %.1f秒）" % cooldown_time
	return desc 