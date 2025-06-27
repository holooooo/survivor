extends Area2D
class_name ArcTowerProjectile

## 电弧塔投射物 - 电弧攻击的视觉和伤害实现[br]
## 从起点到终点创建电弧效果，对目标造成即时伤害[br]
## 具备电弧特效和命中反馈

var projectile_resource: EmitterProjectileResource
var start_position: Vector2
var end_position: Vector2
var arc_damage: int = 15
var has_hit_target: bool = false
var lifetime: float = 0.3 ## 电弧持续时间

@onready var line_renderer: Node2D = null
@onready var hit_effect: Node2D = $HitEffect
@onready var audio_player: AudioStreamPlayer2D = $AudioPlayer

signal target_hit(target: Node2D, damage: int)

func _ready() -> void:
	# 设置碰撞检测
	collision_layer = 4 # 武器层
	collision_mask = 2 # 敌人层
	
	# 连接信号
	area_entered.connect(_on_area_entered)
	
	# 添加到投射物组
	add_to_group("projectiles")
	
	# 设置自动销毁
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func _process(delta: float) -> void:
	# 更新电弧视觉效果
	_update_arc_visual()

## 设置电弧攻击参数[br]
## [param start_pos] 起始位置[br]
## [param end_pos] 目标位置[br]
## [param resource] 投射物资源
func setup_arc_attack(start_pos: Vector2, end_pos: Vector2, resource: EmitterProjectileResource) -> void:
	start_position = start_pos
	end_position = end_pos
	projectile_resource = resource
	
	if resource:
		# 直接访问属性，如果不存在则使用默认值
		arc_damage = resource.hit_damage if resource.hit_damage else 15
		lifetime = resource.lifetime if resource.lifetime else 0.3
	
	# 设置位置和方向
	global_position = start_position
	_setup_collision_detection()
	_create_arc_effect()

## 从资源配置投射物（兼容方法）[br]
## [param resource] 投射物资源[br]
## [param direction] 方向（被忽略，使用目标位置）
func setup_from_resource(resource: Resource, direction: Vector2) -> void:
	projectile_resource = resource
	if resource:
		# 直接访问属性，如果不存在则使用默认值
		arc_damage = resource.hit_damage if resource.hit_damage else 15
		lifetime = resource.lifetime if resource.lifetime else 0.3

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

## 碰撞检测回调
func _on_area_entered(area: Area2D) -> void:
	var target = area.get_parent()
	
	# 检查是否为敌人且未被命中
	if not has_hit_target and target and target.is_in_group("enemies"):
		_hit_target(target)

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
		_hit_target(target_found)
	else:
		pass

## 命中目标处理[br]
## [param target] 被命中的目标
func _hit_target(target: Node2D) -> void:
	if has_hit_target:
		return
	
	has_hit_target = true
	
	# 造成伤害
	if target.has_method("take_damage"):
		target.take_damage(arc_damage)
	else:
		pass
	
	# 创建命中特效
	_create_hit_effect(target.global_position)
	
	# 播放音效
	_play_hit_sound()
	
	# 发射信号
	target_hit.emit(target, arc_damage)
	
	# 电弧命中后快速消失
	_fade_out_quickly()

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
	tween.tween_callback(queue_free)

## 获取投射物状态信息[br]
## [returns] 状态信息字典
func get_projectile_info() -> Dictionary:
	return {
		"type": "arc",
		"damage": arc_damage,
		"start_pos": start_position,
		"end_pos": end_position,
		"has_hit": has_hit_target,
		"lifetime_remaining": lifetime
	}