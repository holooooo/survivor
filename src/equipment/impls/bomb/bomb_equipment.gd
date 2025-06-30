extends EmitterEquipmentBase
class_name BombEquipment

## 炸弹装备 - 随机投掷爆炸装备[br]
## 在玩家周围随机位置投掷炸弹，每颗炸弹延时爆炸造成范围伤害

# 投掷配置
var min_throw_distance: float = 100.0 ## 最小投掷距离
var max_throw_distance: float = 400.0 ## 最大投掷距离

# 爆炸配置（传递给投射物）
var detonation_time: float = 2.0 ## 引爆时间
var explosion_radius: float = 100.0 ## 爆炸半径
var explosion_spread_speed: float = 500.0 ## 爆炸扩散速度

func _ready() -> void:
	super._ready()
	_setup_bomb_config()

## 设置炸弹配置[br]
func _setup_bomb_config() -> void:
	# 从装备配置获取炸弹特有参数
	if emitter_config.has("min_throw_distance"):
		min_throw_distance = emitter_config.min_throw_distance
	if emitter_config.has("max_throw_distance"):
		max_throw_distance = emitter_config.max_throw_distance
	if emitter_config.has("detonation_time"):
		detonation_time = emitter_config.detonation_time
	if emitter_config.has("explosion_radius"):
		explosion_radius = emitter_config.explosion_radius
	if emitter_config.has("explosion_spread_speed"):
		explosion_spread_speed = emitter_config.explosion_spread_speed

## 重写获取投射物生成位置 - 炸弹随机投掷[br]
## [returns] 随机投掷位置的世界坐标
func _get_projectile_spawn_position() -> Vector2:
	if not owner_player:
		return Vector2.ZERO
	
	# 在玩家周围的环形区域内随机选择一个点
	var random_angle: float = randf_range(0, 2 * PI)
	var random_distance: float = randf_range(min_throw_distance, max_throw_distance)
	
	var offset: Vector2 = Vector2.from_angle(random_angle) * random_distance
	return owner_player.global_position + offset

## 重写特定投射物配置 - 传递炸弹特有参数[br]
## [param projectile] 投射物实例
func _configure_projectile_specific(projectile: Node2D) -> void:
	# 炸弹不需要特殊配置，爆炸参数通过装备统计传递
	pass

## 重写获取当前装备统计 - 包含炸弹特有参数[br]
## [returns] 包含爆炸参数的装备统计字典
func _get_current_stats() -> Dictionary:
	var stats: Dictionary = super._get_current_stats()
	
	# 添加炸弹特有参数
	stats["detonation_time"] = detonation_time
	stats["explosion_radius"] = explosion_radius
	stats["explosion_spread_speed"] = explosion_spread_speed
	
	return stats

## 重写特定使用条件检查[br]
## [returns] 是否可以使用
func _can_use_specific() -> bool:
	# 炸弹可以检查攻击范围内是否有敌人（可选）
	var range_check: bool = emitter_config.get("range_check_enabled", true)
	if not range_check:
		return true
	
	# 如果启用了范围检查，只有范围内有敌人时才投掷炸弹
	var nearest_enemy: Node2D = get_nearest_enemy_in_attack_range()
	return nearest_enemy != null 