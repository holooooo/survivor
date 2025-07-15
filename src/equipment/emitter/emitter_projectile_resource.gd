extends Resource
class_name EmitterProjectileResource

## 发射器投射物资源 - 统一发射类投射物的配置[br]

@export_group("基础配置")
@export var projectile_name: String = "基础投射物"
@export var projectile_texture: Texture2D ## 投射物贴图
@export var projectile_color: Color = Color.YELLOW ## 投射物颜色
@export var projectile_scale: Vector2 = Vector2(0.8, 0.8) ## 投射物缩放


@export_group("飞行配置")
@export var max_range: float = 0.0 ## 最大射程（0=使用装备射程）
@export var range_check_enabled: bool = true ## 是否启用射程检查
@export var projectile_speed: float = 800.0 ## 飞行速度
@export var lifetime: float = 0.5 ## 生存时间（秒）

@export_group("伤害配置")
@export var base_damage: int = 10 ## 命中伤害
@export var damage_ticks: int = 5 ## 造成伤害的次数
@export var damage_interval: float = 0.1 ## 伤害间隔（秒）
@export var damage_type: Constants.DamageType = Constants.DamageType.枪械 ## 投射物伤害类型

@export_group("穿透系统")
@export var pierce_count: int = 0 ## 穿透数量
@export var pierce_damage_reduction: float = 0.2 ## 穿透伤害衰减
@export var pierce_speed_reduction: float = 0.1 ## 穿透速度衰减

@export_group("碰撞检测")
@export var detection_radius: float = 5.0 ## 检测半径
@export var affected_groups: Array[String] = ["enemies"] ## 影响的群组

@export_group("视觉效果")
@export var trail_length: float = 20.0 ## 拖尾长度
@export var trail_color: Color = Color.WHITE ## 拖尾颜色
@export var fade_out: bool = false ## 渐隐效果


## 获取投射物配置信息[br]
## [returns] 投射物配置字典
func get_projectile_config() -> Dictionary:
	return {
		# EmitterProjectileResource 特有的属性
		"projectile_speed": projectile_speed,
		"base_damage": base_damage,
		"pierce_count": pierce_count,
		"pierce_damage_reduction": pierce_damage_reduction,
		"pierce_speed_reduction": pierce_speed_reduction,
		"detection_radius": detection_radius,
		"affected_groups": affected_groups,
		"trail_length": trail_length,
		"trail_color": trail_color,
		"fade_out": fade_out,
		"projectile_name": projectile_name,
		"damage_interval": damage_interval,
		"lifetime": lifetime,
		"damage_ticks": damage_ticks,
		"projectile_texture": projectile_texture,
		"projectile_color": projectile_color,
		"projectile_scale": projectile_scale,
		"max_range": max_range,
		"range_check_enabled": range_check_enabled
	}


## 获取投射物伤害类型[br]
## [returns] 伤害类型
func get_damage_type() -> Constants.DamageType:
	return damage_type

## 设置投射物伤害类型[br]
## [param new_damage_type] 新的伤害类型
func set_damage_type(new_damage_type: Constants.DamageType) -> void:
	damage_type = new_damage_type


## 计算当前穿透后的伤害[br]
## [param current_pierce] 当前穿透次数[br]
## [returns] 计算后的伤害值
func get_pierce_damage(current_pierce: int) -> int:
	if current_pierce <= 0:
		return base_damage
	
	var damage_multiplier: float = 1.0 - (pierce_damage_reduction * current_pierce)
	damage_multiplier = max(damage_multiplier, 0.1) # 最少保留10%伤害
	
	return int(base_damage * damage_multiplier)


## 验证投射物资源的有效性[br]
## [returns] 是否有效
func is_valid_projectile_config() -> bool:
	# 基础验证
	if projectile_speed <= 0:
		return false
	if base_damage <= 0:
		return false
	if pierce_count < 0:
		return false
	if pierce_damage_reduction < 0 or pierce_damage_reduction > 1:
		return false
	if pierce_speed_reduction < 0 or pierce_speed_reduction > 1:
		return false
	if detection_radius <= 0:
		return false
	if affected_groups.is_empty():
		return false
	
	return true

## 获取有效的最大射程[br]
## [param equipment_attack_range] 装备的攻击范围[br]
## [returns] 有效的最大射程
func get_effective_max_range(equipment_attack_range: float) -> float:
	if max_range > 0.0:
		return max_range
	return equipment_attack_range
