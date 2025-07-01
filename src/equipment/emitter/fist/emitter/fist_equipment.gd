extends EmitterEquipmentBase
class_name FistEquipment

## 拳击装备 - 默认的近战攻击装备[br]
## 每隔1秒发射一个拳击投射物，对范围内敌人造成伤害
@export var orbit_radius: float = 50.0 ## 围绕玩家的轨道半径

## 获取投射物生成位置 - 在距离玩家orbit_radius半径圆中最接近敌人的位置[br]
## [returns] 投射物生成的世界坐标
func _get_projectile_spawn_position() -> Vector2:
	if not owner_player:
		return Vector2.ZERO
	
	var player_pos: Vector2 = owner_player.global_position
	var target_direction: Vector2 = _get_target_direction()
	
	# 在玩家周围orbit_radius半径的圆上，找到最接近敌人的点
	var spawn_position: Vector2 = player_pos + target_direction * orbit_radius
	
	return spawn_position

## 配置投射物特定属性 - 设置拳击投射物的玩家引用[br]
## [param projectile] 投射物实例
func _configure_projectile_specific(projectile: Node2D) -> void:
	# 设置玩家引用和跟随半径
	if projectile.has_method("set_player_reference"):
		projectile.set_player_reference(owner_player, orbit_radius)
