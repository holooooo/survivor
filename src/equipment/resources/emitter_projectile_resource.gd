extends ProjectileBase
class_name EmitterProjectileResource

## 发射器投射物资源 - 统一发射类投射物的配置[br]
## 支持子弹、AOE、光束等多种投射物类型[br]
## 使用枚举类型管理不同的投射物模式

@export_group("投射物类型")
@export var projectile_type: ProjectileType = ProjectileType.BULLET ## 投射物类型

@export_group("飞行配置")
@export var projectile_speed: float = 800.0 ## 飞行速度
@export var max_travel_distance: float = 500.0 ## 最大飞行距离
@export var gravity_affected: bool = false ## 是否受重力影响
@export var trajectory_curve: float = 0.0 ## 轨迹弯曲度

@export_group("伤害配置")
@export var hit_damage: int = 10 ## 命中伤害
@export var tick_damage: int = 3 ## 持续伤害（AOE类型）
@export var hit_knockback: float = 0.0 ## 击退力度

@export_group("持续效果")
@export var continuous_damage: bool = false ## 是否持续伤害
@export var damage_tick_interval: float = 0.1 ## 伤害tick间隔
@export var total_damage_ticks: int = 5 ## 总伤害tick次数

@export_group("穿透系统")
@export var pierce_count: int = 0 ## 穿透数量
@export var pierce_damage_reduction: float = 0.2 ## 穿透伤害衰减
@export var pierce_speed_reduction: float = 0.1 ## 穿透速度衰减

@export_group("范围检测")
@export var detection_method: DetectionMethod = DetectionMethod.POINT ## 检测方式
@export var detection_radius: float = 5.0 ## 检测半径
@export var affected_groups: Array[String] = ["enemies"] ## 影响的群组

@export_group("视觉效果")
@export var trail_length: float = 20.0 ## 拖尾长度
@export var trail_color: Color = Color.WHITE ## 拖尾颜色
@export var show_range_indicator: bool = false ## 显示范围指示器
@export var range_indicator_color: Color = Color.YELLOW ## 范围指示器颜色
@export var impact_effect: bool = true ## 命中特效
@export var fade_out: bool = false ## 渐隐效果

## 投射物类型枚举
enum ProjectileType {
	BULLET, ## 子弹类型
	AOE, ## AOE类型
	BEAM, ## 光束类型
	EXPLOSIVE ## 爆炸类型
}

## 检测方式枚举
enum DetectionMethod {
	POINT, ## 点碰撞检测
	RADIUS, ## 圆形半径检测
	BOX, ## 矩形区域检测
	CONE ## 扇形检测
}



## 获取投射物配置信息[br]
## [returns] 投射物配置字典
func get_projectile_config() -> Dictionary:
	return {
		"projectile_type": projectile_type,
		"projectile_speed": projectile_speed,
		"max_travel_distance": max_travel_distance,
		"gravity_affected": gravity_affected,
		"trajectory_curve": trajectory_curve,
		"hit_damage": hit_damage,
		"tick_damage": tick_damage,
		"hit_knockback": hit_knockback,
		"continuous_damage": continuous_damage,
		"damage_tick_interval": damage_tick_interval,
		"total_damage_ticks": total_damage_ticks,
		"pierce_count": pierce_count,
		"pierce_damage_reduction": pierce_damage_reduction,
		"pierce_speed_reduction": pierce_speed_reduction,
		"detection_method": detection_method,
		"detection_radius": detection_radius,
		"affected_groups": affected_groups,
		"trail_length": trail_length,
		"trail_color": trail_color,
		"show_range_indicator": show_range_indicator,
		"range_indicator_color": range_indicator_color,
		"impact_effect": impact_effect,
		"fade_out": fade_out
	}



## 计算当前穿透后的伤害[br]
## [param current_pierce] 当前穿透次数[br]
## [returns] 计算后的伤害值
func get_pierce_damage(current_pierce: int) -> int:
	if current_pierce <= 0:
		return hit_damage
	
	var damage_multiplier: float = 1.0 - (pierce_damage_reduction * current_pierce)
	damage_multiplier = max(damage_multiplier, 0.1) # 最少保留10%伤害
	
	return int(hit_damage * damage_multiplier)

## 计算当前穿透后的速度[br]
## [param current_pierce] 当前穿透次数[br]
## [returns] 计算后的速度值
func get_pierce_speed(current_pierce: int) -> float:
	if current_pierce <= 0:
		return projectile_speed
	
	var speed_multiplier: float = 1.0 - (pierce_speed_reduction * current_pierce)
	speed_multiplier = max(speed_multiplier, 0.3) # 最少保留30%速度
	
	return projectile_speed * speed_multiplier

## 验证投射物资源的有效性[br]
## [returns] 是否有效
func is_valid_projectile_config() -> bool:
	# 通用验证
	if affected_groups.is_empty():
		return false
	
	# 类型特定验证
	match projectile_type:
		ProjectileType.BULLET:
			if projectile_speed <= 0:
				return false
			if max_travel_distance <= 0:
				return false
			if hit_damage <= 0:
				return false
			if pierce_count < 0:
				return false
			if pierce_damage_reduction < 0 or pierce_damage_reduction > 1:
				return false
			if pierce_speed_reduction < 0 or pierce_speed_reduction > 1:
				return false
		ProjectileType.AOE:
			if tick_damage <= 0:
				return false
			if damage_tick_interval <= 0:
				return false
			if total_damage_ticks <= 0:
				return false
			if detection_radius <= 0:
				return false
	
	return true

 