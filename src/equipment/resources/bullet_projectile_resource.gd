extends ProjectileBase
class_name BulletProjectileResource

## 子弹投射物资源 - 射击类投射物的专门配置[br]
## 用于各种射击武器的子弹

@export_group("子弹飞行")
@export var bullet_speed: float = 800.0 ## 子弹飞行速度
@export var max_travel_distance: float = 500.0 ## 最大飞行距离
@export var gravity_affected: bool = false ## 是否受重力影响
@export var trajectory_curve: float = 0.0 ## 轨迹弯曲度（弧线射击）

@export_group("穿透系统")
@export var pierce_count: int = 1 ## 穿透数量
@export var pierce_damage_reduction: float = 0.2 ## 穿透伤害衰减
@export var pierce_speed_reduction: float = 0.1 ## 穿透速度衰减

@export_group("命中效果")
@export var hit_damage: int = 10 ## 命中伤害
@export var hit_knockback: float = 0.0 ## 击退力度
@export var hit_groups: Array[String] = ["enemies"] ## 可命中的群组

@export_group("子弹视觉")
@export var bullet_trail_length: float = 20.0 ## 拖尾长度
@export var trail_color: Color = Color.WHITE ## 拖尾颜色
@export var impact_effect: bool = true ## 命中特效
@export var muzzle_flash_scale: float = 1.0 ## 枪口闪光缩放

## 设置子弹参数（由装备资源调用）[br]
## [param damage] 子弹伤害[br]
## [param range] 最大射程[br]
## [param speed] 子弹速度[br]
## [param pierce] 穿透次数[br]
## [param pierce_reduction] 穿透伤害衰减
func set_bullet_parameters(damage: int, range: float, speed: float, pierce: int, pierce_reduction: float) -> void:
	hit_damage = damage
	max_travel_distance = range
	bullet_speed = speed
	pierce_count = pierce
	pierce_damage_reduction = pierce_reduction
	
	# 更新基础参数
	damage_per_tick = hit_damage
	lifetime = max_travel_distance / bullet_speed # 根据射程和速度计算生存时间
	detection_range = 5.0 # 子弹使用较小的碰撞检测范围

## 获取子弹配置信息[br]
## [returns] 子弹配置字典
func get_bullet_config() -> Dictionary:
	return {
		"bullet_speed": bullet_speed,
		"max_travel_distance": max_travel_distance,
		"gravity_affected": gravity_affected,
		"trajectory_curve": trajectory_curve,
		"pierce_count": pierce_count,
		"pierce_damage_reduction": pierce_damage_reduction,
		"pierce_speed_reduction": pierce_speed_reduction,
		"hit_damage": hit_damage,
		"hit_knockback": hit_knockback,
		"hit_groups": hit_groups,
		"bullet_trail_length": bullet_trail_length,
		"trail_color": trail_color,
		"impact_effect": impact_effect,
		"muzzle_flash_scale": muzzle_flash_scale
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
		return bullet_speed
	
	var speed_multiplier: float = 1.0 - (pierce_speed_reduction * current_pierce)
	speed_multiplier = max(speed_multiplier, 0.3) # 最少保留30%速度
	
	return bullet_speed * speed_multiplier

## 验证子弹投射物资源的有效性[br]
## [returns] 是否有效
func is_valid_bullet_config() -> bool:
	if bullet_speed <= 0:
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
	if hit_groups.is_empty():
		return false
	return true 