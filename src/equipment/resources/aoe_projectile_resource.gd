extends ProjectileBase
class_name AOEProjectileResource

## AOE投射物资源 - 区域攻击投射物的专门配置[br]
## 用于持续范围伤害效果[br]
## 注意：duration和lifetime是同一概念，表示投射物的存在时间

@export_group("AOE持续伤害")
@export var continuous_damage: bool = true ## 是否持续伤害
@export var tick_damage: int = 3 ## 每次tick伤害
@export var damage_tick_interval: float = 0.1 ## 伤害tick间隔
@export var total_damage_ticks: int = 5 ## 总伤害tick次数

@export_group("AOE范围检测")
@export var detection_method: DetectionMethod = DetectionMethod.RADIUS ## 检测方式
@export var detection_radius: float = 50.0 ## 检测半径
@export var affected_groups: Array[String] = ["enemies"] ## 影响的群组

@export_group("AOE视觉表现")
@export var show_range_indicator: bool = true ## 显示范围指示器
@export var range_indicator_color: Color = Color.YELLOW ## 范围指示器颜色
@export var damage_number_offset: Vector2 = Vector2(0, -20) ## 伤害数字偏移

enum DetectionMethod {
	RADIUS, ## 圆形半径检测
	BOX, ## 矩形区域检测
	CONE ## 扇形检测
}

## 设置AOE参数（由装备资源调用）[br]
## [param duration] 持续时间[br]
## [param interval] 伤害间隔[br]
## [param max_ticks] 最大伤害次数[br]
## [param radius] 检测半径[br]
## [param damage] 基础伤害
func set_aoe_parameters(duration: float, interval: float, max_ticks: int, radius: float, damage: int) -> void:
	# 统一lifetime和duration为同一概念
	lifetime = duration
	damage_tick_interval = interval
	total_damage_ticks = max_ticks
	detection_radius = radius
	tick_damage = damage
	
	# 更新基础投射物参数，确保一致性
	damage_per_tick = tick_damage
	damage_interval = damage_tick_interval
	damage_ticks = total_damage_ticks
	detection_range = detection_radius

## 获取AOE配置信息[br]
## [returns] AOE配置字典
func get_aoe_config() -> Dictionary:
	return {
		"continuous_damage": continuous_damage,
		"tick_damage": tick_damage,
		"damage_tick_interval": damage_tick_interval,
		"total_damage_ticks": total_damage_ticks,
		"detection_method": detection_method,
		"detection_radius": detection_radius,
		"affected_groups": affected_groups,
		"show_range_indicator": show_range_indicator,
		"range_indicator_color": range_indicator_color
	}

## 验证AOE投射物资源的有效性[br]
## [returns] 是否有效
func is_valid_aoe_config() -> bool:
	if tick_damage <= 0:
		return false
	if damage_tick_interval <= 0:
		return false
	if total_damage_ticks <= 0:
		return false
	if detection_radius <= 0:
		return false
	if affected_groups.is_empty():
		return false
	return true 