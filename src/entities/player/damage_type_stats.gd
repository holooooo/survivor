extends Resource
class_name DamageTypeStats

## 单个伤害类型的完整属性组[br]
## 包含该伤害类型的所有相关属性

@export var damage_multiplier: float = 1.0      ## 伤害倍率
@export var critical_chance: float = 0.05       ## 暴击率
@export var critical_multiplier: float = 2.0    ## 暴击倍率
@export var cooldown_reduction: float = 0.0     ## 冷却时间缩减百分比
@export var attack_range_bonus: float = 0.0     ## 攻击范围加成百分比
@export var reload_speed_multiplier: float = 1.0 ## 装弹速度倍率

## 创建副本[br]
## [returns] 新的DamageTypeStats实例
func duplicate_stats() -> DamageTypeStats:
	var new_stats = DamageTypeStats.new()
	new_stats.damage_multiplier = damage_multiplier
	new_stats.critical_chance = critical_chance
	new_stats.critical_multiplier = critical_multiplier
	new_stats.cooldown_reduction = cooldown_reduction
	new_stats.attack_range_bonus = attack_range_bonus
	new_stats.reload_speed_multiplier = reload_speed_multiplier
	return new_stats

## 应用属性修改[br]
## [param stat_name] 属性名称[br]
## [param value] 新值
func set_stat(stat_name: String, value: float) -> void:
	match stat_name:
		"damage_multiplier":
			damage_multiplier = value
		"critical_chance":
			critical_chance = clamp(value, 0.0, 1.0)
		"critical_multiplier":
			critical_multiplier = max(value, 1.0)
		"cooldown_reduction":
			cooldown_reduction = clamp(value, 0.0, 1.0)
		"attack_range_bonus":
			attack_range_bonus = value
		"reload_speed_multiplier":
			reload_speed_multiplier = max(value, 0.1)

## 获取属性值[br]
## [param stat_name] 属性名称[br]
## [returns] 属性值
func get_stat(stat_name: String) -> float:
	match stat_name:
		"damage_multiplier":
			return damage_multiplier
		"critical_chance":
			return critical_chance
		"critical_multiplier":
			return critical_multiplier
		"cooldown_reduction":
			return cooldown_reduction
		"attack_range_bonus":
			return attack_range_bonus
		"reload_speed_multiplier":
			return reload_speed_multiplier
		_:
			return 0.0 