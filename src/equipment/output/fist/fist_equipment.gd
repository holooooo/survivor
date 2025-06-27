extends EquipmentBase
class_name FistEquipment

## 拳击装备 - 默认的近战攻击装备[br]
## 每隔1秒发射一个拳击投射物，对范围内敌人造成伤害
@export var orbit_radius: float = 50.0 ## 围绕玩家的轨道半径

func _ready() -> void:
	# 投射物资源现在通过EquipmentResource配置
	pass

## 设置AOE配置（重写基类方法以应用到装备逻辑）[br]
## [param config] AOE配置字典
func set_aoe_config(config: Dictionary) -> void:
	super.set_aoe_config(config)
	
	# 应用AOE配置到装备行为
	if config.has("duration"):
		# 可以根据AOE配置调整装备行为
		pass

## 设置发射器配置（处理攻击距离检查）[br]
## [param config] 发射器配置字典
func set_emitter_config(config: Dictionary) -> void:
	super.set_emitter_config(config)

## 获取拳击投射物生成位置 - 在距离玩家100px半径圆中最接近敌人的位置[br]
## [returns] 投射物生成的世界坐标
func _get_projectile_spawn_position() -> Vector2:
	if not owner_player:
		return Vector2.ZERO
	
	var player_pos: Vector2 = owner_player.global_position
	var target_direction: Vector2 = _get_target_direction()
	
	# 在玩家周围operation_radius半径的圆上，找到最接近敌人的点
	var spawn_position: Vector2 = player_pos + target_direction * orbit_radius
	
	return spawn_position

## 检查是否可以使用装备[br]
## [returns] 是否可以使用
func can_use() -> bool:
	# 检查基类冷却
	if not super.can_use():
		return false
	
	# 检查攻击距离内是否有敌人
	if not has_enemies_in_attack_range():
		return false
	
	return true

## 执行拳击攻击效果 - 重写基类方法
func _execute_equipment_effect() -> void:
	if not owner_player:
		return
	
	# 获取投射物场景
	if not projectile_scene:
		return
	
	# 创建投射物
	var projectile: Node2D = projectile_scene.instantiate()
	
	# 获取主场景
	var main_scene: Node2D = owner_player.get_parent()
	if main_scene:
		main_scene.add_child(projectile)
		
		# 设置投射物初始位置
		projectile.global_position = _get_projectile_spawn_position()
		
		# 配置投射物
		if projectile.has_method("setup_from_resource") and projectile_resource:
			var target_direction: Vector2 = _get_target_direction()
			projectile.setup_from_resource(projectile_resource, target_direction)
		
		# 设置玩家引用和跟随半径
		if projectile.has_method("set_player_reference"):
			projectile.set_player_reference(owner_player, orbit_radius)

## 获取目标方向 - 优先选择攻击距离内最近的敌人[br]
## [returns] 目标方向向量
func _get_target_direction() -> Vector2:
	if not owner_player:
		return Vector2.RIGHT
	
	# 优先获取攻击距离内的最近敌人
	var nearest_enemy: Node2D = get_nearest_enemy_in_attack_range()
	
	if nearest_enemy:
		return (nearest_enemy.global_position - owner_player.global_position).normalized()
	else:
		return Vector2.RIGHT 
