@tool
extends Node
class_name PlayerStatsManager

## 玩家属性管理器[br]
## 使用Dictionary[DamageType, DamageTypeStats]管理各伤害类型属性

signal stats_changed(damage_type: Constants.DamageType, stat_name: String, old_value: float, new_value: float)
signal base_stats_changed(stat_name: String, old_value, new_value)

@export_tool_button("初始化属性", "reset_all_stats") var init_base_stats_action = reset_all_stats
# 基础属性
@export var base_stats: Dictionary[String, float] = {
		"max_health_bonus": 0.0,
		"health_regen_rate": 0.0,
		"armor": 0,
		"move_speed_multiplier": 1.0,
		"magazine_capacity_bonus": 0,
		"projectile_speed_multiplier": 1.0,
		"multishot_count": 0,
		"pierce_count": 0,
		"bounce_count": 0
	}

# 伤害类型属性字典 - Dictionary[Constants.DamageType, DamageTypeStats]
@export var damage_type_stats: Dictionary[Constants.DamageType, DamageTypeStats] = {
		Constants.DamageType.枪械:DamageTypeStats.new(),
		Constants.DamageType.近战:DamageTypeStats.new(),
		Constants.DamageType.爆炸:DamageTypeStats.new(),
		Constants.DamageType.能量:DamageTypeStats.new(),
		Constants.DamageType.火焰:DamageTypeStats.new(),
		Constants.DamageType.冰冻:DamageTypeStats.new(),
		Constants.DamageType.毒素:DamageTypeStats.new(),
		Constants.DamageType.电击:DamageTypeStats.new()
	}

var owner_player: Player

## 初始化玩家引用[br]
## [param player] 玩家实例
func initialize(player: Player) -> void:
	owner_player = player

## 获取指定伤害类型的属性组[br]
## [param damage_type] 伤害类型[br]
## [returns] 伤害类型属性组，如果不存在则返回null
func get_damage_type_stats(damage_type: Constants.DamageType) -> DamageTypeStats:
	return damage_type_stats.get(damage_type, null)

## 获取伤害倍率[br]
## [param damage_type] 伤害类型[br]
## [returns] 伤害倍率
func get_damage_multiplier(damage_type: Constants.DamageType) -> float:
	var stats = get_damage_type_stats(damage_type)
	return stats.damage_multiplier if stats else 1.0

## 获取暴击率[br]
## [param damage_type] 伤害类型[br]
## [returns] 暴击率
func get_critical_chance(damage_type: Constants.DamageType) -> float:
	var stats = get_damage_type_stats(damage_type)
	return stats.critical_chance if stats else 0.05

## 获取暴击倍率[br]
## [param damage_type] 伤害类型[br]
## [returns] 暴击倍率
func get_critical_multiplier(damage_type: Constants.DamageType) -> float:
	var stats = get_damage_type_stats(damage_type)
	return stats.critical_multiplier if stats else 2.0

## 获取冷却缩减[br]
## [param damage_type] 伤害类型[br]
## [returns] 冷却缩减百分比
func get_cooldown_reduction(damage_type: Constants.DamageType) -> float:
	var stats = get_damage_type_stats(damage_type)
	return stats.cooldown_reduction if stats else 0.0

## 获取攻击范围加成[br]
## [param damage_type] 伤害类型[br]
## [returns] 攻击范围加成百分比
func get_attack_range_bonus(damage_type: Constants.DamageType) -> float:
	var stats = get_damage_type_stats(damage_type)
	return stats.attack_range_bonus if stats else 0.0

## 获取装弹速度倍率[br]
## [param damage_type] 伤害类型[br]
## [returns] 装弹速度倍率
func get_reload_speed_multiplier(damage_type: Constants.DamageType) -> float:
	var stats = get_damage_type_stats(damage_type)
	return stats.reload_speed_multiplier if stats else 1.0

## 进行暴击判定[br]
## [param damage_type] 伤害类型[br]
## [returns] 是否暴击
func roll_critical(damage_type: Constants.DamageType) -> bool:
	var chance = get_critical_chance(damage_type)
	return randf() < chance

## 设置伤害类型属性[br]
## [param damage_type] 伤害类型[br]
## [param stat_name] 属性名称[br]
## [param value] 新值
func set_damage_type_stat(damage_type: Constants.DamageType, stat_name: String, value: float) -> void:
	var stats = get_damage_type_stats(damage_type)
	if stats:
		var old_value = stats.get_stat(stat_name)
		stats.set_stat(stat_name, value)
		stats_changed.emit(damage_type, stat_name, old_value, value)

## 修改伤害类型属性（增加值）[br]
## [param damage_type] 伤害类型[br]
## [param stat_name] 属性名称[br]
## [param modifier] 修改值
func modify_damage_type_stat(damage_type: Constants.DamageType, stat_name: String, modifier: float) -> void:
	var stats = get_damage_type_stats(damage_type)
	if stats:
		var current_value = stats.get_stat(stat_name)
		var new_value = current_value + modifier
		set_damage_type_stat(damage_type, stat_name, new_value)

## 获取基础属性值[br]
## [param stat_name] 属性名称[br]
## [returns] 基础属性值
func get_base_stat(stat_name: String):
	return base_stats.get(stat_name, 0)

## 设置基础属性值[br]
## [param stat_name] 属性名称[br]
## [param value] 新值
func set_base_stat(stat_name: String, value) -> void:
	if base_stats.has(stat_name):
		var old_value = base_stats[stat_name]
		base_stats[stat_name] = value
		base_stats_changed.emit(stat_name, old_value, value)

## 修改基础属性值（增加值）[br]
## [param stat_name] 属性名称[br]
## [param modifier] 修改值
func modify_base_stat(stat_name: String, modifier) -> void:
	if base_stats.has(stat_name):
		var current_value = base_stats[stat_name]
		var new_value = current_value + modifier
		set_base_stat(stat_name, new_value)

## 获取所有伤害类型的属性概览[br]
## [returns] 属性概览字典
func get_all_damage_stats_overview() -> Dictionary:
	var overview = {}
	for damage_type in damage_type_stats:
		var stats = damage_type_stats[damage_type]
		overview[damage_type] = {
			"damage_multiplier": stats.damage_multiplier,
			"critical_chance": stats.critical_chance,
			"critical_multiplier": stats.critical_multiplier,
			"cooldown_reduction": stats.cooldown_reduction,
			"attack_range_bonus": stats.attack_range_bonus,
			"reload_speed_multiplier": stats.reload_speed_multiplier
		}
	return overview

## 重置所有属性到默认值[br]
func reset_all_stats() -> void:
	_initialize_base_stats()
	_initialize_damage_type_stats()

func _initialize_base_stats() -> void:
	base_stats = {
		"max_health_bonus": 0.0,
		"health_regen_rate": 0.0,
		"armor": 0,
		"move_speed_multiplier": 1.0,
		"magazine_capacity_bonus": 0,
		"projectile_speed_multiplier": 1.0,
		"multishot_count": 0,
		"pierce_count": 0,
		"bounce_count": 0
	}

func _initialize_damage_type_stats() -> void:
	damage_type_stats = {
		Constants.DamageType.枪械:DamageTypeStats.new(),
		Constants.DamageType.近战:DamageTypeStats.new(),
		Constants.DamageType.爆炸:DamageTypeStats.new(),
		Constants.DamageType.能量:DamageTypeStats.new(),
		Constants.DamageType.火焰:DamageTypeStats.new(),
		Constants.DamageType.冰冻:DamageTypeStats.new(),
		Constants.DamageType.毒素:DamageTypeStats.new(),
		Constants.DamageType.电击:DamageTypeStats.new()
	}


## 应用属性包（用于装备、mod等）[br]
## [param stat_package] 属性包字典
func apply_stat_package(stat_package: Dictionary) -> void:
	# 应用基础属性修改
	if stat_package.has("base_stats"):
		var base_modifications = stat_package.base_stats
		for stat_name in base_modifications:
			modify_base_stat(stat_name, base_modifications[stat_name])
	
	# 应用伤害类型属性修改
	if stat_package.has("damage_type_stats"):
		var damage_modifications = stat_package.damage_type_stats
		for damage_type in damage_modifications:
			var type_stats = damage_modifications[damage_type]
			for stat_name in type_stats:
				modify_damage_type_stat(damage_type, stat_name, type_stats[stat_name])