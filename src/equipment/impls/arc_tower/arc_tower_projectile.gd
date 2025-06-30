extends ProjectileBase
class_name ArcTowerProjectile

## 电弧塔投射物 - 电弧攻击的视觉和伤害实现[br]
## 从起点到终点创建电弧效果，对目标造成即时伤害[br]
## 具备电弧特效和命中反馈

var start_position: Vector2
var end_position: Vector2
var has_hit_target: bool = false

@onready var line_renderer: Node2D = null
@onready var hit_effect: Node2D = $HitEffect
@onready var audio_player: AudioStreamPlayer2D = $AudioPlayer

## 设置电弧攻击参数[br]
## [param start_pos] 起始位置[br]
## [param end_pos] 目标位置[br]
## [param resource] 投射物资源
func setup_arc_attack(start_pos: Vector2, end_pos: Vector2, resource: EmitterProjectileResource) -> void:
	start_position = start_pos
	end_position = end_pos
	
	# 设置位置和方向
	global_position = start_position
	_setup_collision_detection()
	_create_arc_effect()

## 实现抽象方法：初始化特定逻辑[br]
## [param direction] 初始方向（电弧攻击忽略方向）
func _initialize_specific(direction: Vector2) -> void:
	# 电弧攻击在setup_arc_attack中处理位置，这里不需要额外操作
	# 禁用传统的碰撞检测，使用自己的目标检测逻辑
	if collision_shape:
		collision_shape.disabled = true

## 实现抽象方法：更新移动逻辑[br]
## [param delta] 时间增量
func _update_movement(delta: float) -> void:
	# 电弧攻击是即时的，不需要移动
	pass

## 实现抽象方法：获取投射物类型[br]
## [returns] 类型标识
func _get_projectile_type() -> String:
	return "arc"

## 重写自定义更新逻辑[br]
## [param delta] 时间增量
func _update_custom(delta: float) -> void:
	# 更新电弧视觉效果
	_update_arc_visual()

## 设置碰撞检测
func _setup_collision_detection() -> void:
	# 电弧是即时攻击，不需要物理碰撞检测
	# 直接检查目标位置的敌人
	call_deferred("_check_target_at_end_position")

## 创建电弧视觉效果
func _create_arc_effect() -> void:
	# 先使用简单的Line2D确保可见性
	var arc_line = Line2D.new()
	add_child(arc_line)
	
	# 设置线条属性
	arc_line.width = 5.0
	arc_line.default_color = Color.CYAN
	arc_line.add_point(to_local(start_position))
	arc_line.add_point(to_local(end_position))
	
	# 添加电弧闪烁效果
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(arc_line, "modulate:a", 0.5, 0.1)
	tween.tween_property(arc_line, "modulate:a", 1.0, 0.1)
	
	# 存储引用
	line_renderer = arc_line
	
## 更新电弧视觉效果
func _update_arc_visual() -> void:
	# 着色器会自动处理电弧动画效果，这里不需要额外更新
	pass

## 重写目标进入处理 - 电弧攻击的即时命中[br]
## [param target] 进入的目标
func _on_target_entered(target: Node) -> void:
	if has_hit_target:
		return
	
	has_hit_target = true
	
	# 造成伤害
	_deal_damage_to_target(target, current_damage)
	
	# 创建命中特效
	_create_hit_effect(target.global_position)
	
	# 播放音效
	_play_hit_sound()
	
	# 电弧命中后快速消失
	_fade_out_quickly()

## 检查终点位置的目标
func _check_target_at_end_position() -> void:
	if has_hit_target:
		return
	
	# 获取场景树中的所有敌人
	var enemies = get_tree().get_nodes_in_group("enemies")
	var target_found: Node2D = null
	var min_distance: float = 30.0 # 30像素内算命中
	
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			var distance = enemy.global_position.distance_to(end_position)
			if distance < min_distance:
				target_found = enemy
				min_distance = distance
	
	if target_found:
		_on_target_entered(target_found)

## 创建命中特效[br]
## [param hit_pos] 命中位置
func _create_hit_effect(hit_pos: Vector2) -> void:
	if not hit_effect:
		hit_effect = Node2D.new()
		add_child(hit_effect)
	
	# 简单的闪光效果
	var flash = ColorRect.new()
	flash.size = Vector2(20, 20)
	flash.color = Color.YELLOW
	flash.position = to_local(hit_pos) - flash.size / 2
	hit_effect.add_child(flash)
	
	# 闪光渐隐
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.2)
	tween.tween_callback(flash.queue_free)

## 播放命中音效
func _play_hit_sound() -> void:
	if audio_player:
		# 这里可以设置电弧命中的音效
		# audio_player.stream = preload("res://audio/arc_hit.ogg")
		# audio_player.play()
		pass

## 快速淡出
func _fade_out_quickly() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(_destroy_projectile)