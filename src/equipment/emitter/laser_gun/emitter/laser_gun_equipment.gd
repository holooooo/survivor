extends EmitterEquipmentBase
class_name LaserGunEquipment

## 激光枪装备 - 向最低生命值敌人发射直线激光柱[br]
## 激光柱存在期间对范围内所有敌人持续造成能量伤害

func _ready() -> void:
	super._ready()
	# 设置伤害类型为能量

## 获取投射物生成位置 - 在玩家位置生成[br]
## [returns] 投射物生成的世界坐标
func _get_projectile_spawn_position() -> Vector2:
	if not owner_player:
		return Vector2.ZERO
	
	return owner_player.global_position

## 配置投射物特定属性 - 设置激光投射物的目标方向[br]
## [param projectile] 投射物实例
func _configure_projectile_specific(projectile: Node2D) -> void:
	# 获取目标方向
	var target_direction: Vector2 = _get_target_direction()
	
	# 设置激光投射物的方向和长度
	if projectile.has_method("setup_laser_beam"):
		var laser_range: float = emitter_config.get("attack_range", 300.0)
		projectile.setup_laser_beam(target_direction, laser_range) 