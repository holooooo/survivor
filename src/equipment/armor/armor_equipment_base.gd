extends EquipmentBase
class_name ArmorEquipmentBase

## 护甲装备抽象基类 - 所有护甲类装备的通用逻辑[br]
## 提供护甲值计算、回复机制、事件管理等共同功能[br]
## 子类只需实现特定的护甲逻辑和特殊效果

@export_group("护甲配置")
@export var armor_value: int = 50 ## 提供的护甲值

# 护甲回复系统
var armor_regeneration_rate: float = 5.0 ## 护甲回复速度（每秒回复的护甲值）
var no_damage_delay: float = 5.0 ## 无伤害延迟（秒）
var regeneration_interval: float = 1.0 ## 回复间隔（秒）

# 内部状态
var is_regenerating: bool = false
var regeneration_timer: float = 0.0
var no_damage_timer: float = 0.0 ## 无伤害计时器
var last_damage_time: float = 0.0 ## 最后受伤时间

# 护甲配置缓存
var armor_config: Dictionary = {}

signal armor_regeneration_started()
signal armor_regeneration_finished()
signal armor_fully_restored(restored_amount: int)

func _ready() -> void:
	super._ready()
	_setup_armor_system()

func _process(delta: float) -> void:
	_update_armor_regeneration(delta)
	_custom_armor_update(delta)

## 设置护甲系统
func _setup_armor_system() -> void:
	# 从配置应用护甲参数
	if armor_config.has("armor_value"):
		armor_value = armor_config.armor_value
	if armor_config.has("armor_regeneration_rate"):
		armor_regeneration_rate = armor_config.armor_regeneration_rate
	if armor_config.has("no_damage_delay"):
		no_damage_delay = armor_config.no_damage_delay
	if armor_config.has("regeneration_interval"):
		regeneration_interval = armor_config.regeneration_interval

## 初始化装备[br]
## [param player] 装备拥有者
func initialize(player: Player) -> void:
	super.initialize(player)
	
	FightEventBus.on_player_damage.connect(on_player_damage)
	
	# 通知装备管理器重新计算护甲值
	_notify_armor_change()

## 设置护甲配置[br]
## [param config] 护甲配置字典
func set_armor_config(config: Dictionary) -> void:
	armor_config = config
	_setup_armor_system()

## 获取护甲值[br]
## [returns] 护甲值
func get_armor_value() -> int:
	return armor_value

## 获取护甲状态信息[br]
## [returns] 状态信息字典
func get_armor_status() -> Dictionary:
	return {
		"armor_value": armor_value,
		"is_regenerating": is_regenerating,
		"no_damage_progress": no_damage_timer / no_damage_delay,
		"no_damage_delay": no_damage_delay,
		"armor_regeneration_rate": armor_regeneration_rate,
		"regeneration_interval": regeneration_interval,
		"last_damage_time": last_damage_time,
		"time_since_damage": Time.get_time_dict_from_system()["unix"] - last_damage_time
	}

## 玩家护甲变化回调[br]
## [param new_armor] 新护甲值[br]
## [param max_armor] 最大护甲值
func on_player_damage(player: Player, damage: int) -> void:
	# 记录受伤时间，重置无伤害计时器
	last_damage_time = Time.get_ticks_msec()
	no_damage_timer = 0.0

	# 如果正在回复，停止回复
	if is_regenerating:
		_stop_regeneration()


## 停止护甲回复
func _stop_regeneration() -> void:
	if is_regenerating:
		is_regenerating = false
		regeneration_timer = 0.0
		armor_regeneration_finished.emit()
		FightEventBus.on_armor_regeneration_finished.emit(owner_player, self, 0)

## 更新护甲回复系统[br]
## [param delta] 时间增量
func _update_armor_regeneration(delta: float) -> void:
	if not _should_regenerate():
		return
	
	no_damage_timer += delta
	
	if _should_start_regeneration():
		_start_regeneration()
	
	if is_regenerating:
		_process_regeneration(delta)

## 检查是否应该进行护甲回复[br]
func _should_regenerate() -> bool:
	return owner_player and owner_player.max_armor > 0 and owner_player.current_armor < owner_player.max_armor

## 检查是否应该开始回复[br]
func _should_start_regeneration() -> bool:
	return no_damage_timer >= no_damage_delay and not is_regenerating

## 开始护甲回复[br]
func _start_regeneration() -> void:
	is_regenerating = true
	regeneration_timer = 0.0
	armor_regeneration_started.emit()
	FightEventBus.on_armor_regeneration_started.emit(owner_player, self)

## 处理护甲回复逻辑[br]
func _process_regeneration(delta: float) -> void:
	regeneration_timer += delta
	
	if regeneration_timer >= regeneration_interval:
		var restore_amount = _calculate_restore_amount()
		
		if restore_amount > 0:
			_perform_armor_restore(restore_amount)
		else:
			_stop_regeneration()

## 计算回复量[br]
func _calculate_restore_amount() -> int:
	var base_regen_rate = _get_total_armor_regeneration_rate()
	var player_multiplier = _get_player_armor_regeneration_multiplier()
	var restore_amount = int(base_regen_rate * player_multiplier)
	
	if restore_amount <= 0:
		return 0
	
	return min(restore_amount, owner_player.max_armor - owner_player.current_armor)

## 执行护甲回复[br]
func _perform_armor_restore(restore_amount: int) -> void:
	owner_player.restore_armor(restore_amount)
	regeneration_timer = 0.0
	
	if owner_player.current_armor >= owner_player.max_armor:
		_handle_full_restore(restore_amount)

## 处理护甲完全恢复[br]
func _handle_full_restore(restore_amount: int) -> void:
	armor_fully_restored.emit(restore_amount)
	FightEventBus.on_armor_fully_restored.emit(owner_player, self, restore_amount)
	_stop_regeneration()

## 获取总护甲回复速度[br]
## [returns] 所有装备提供的护甲回复速度之和
func _get_total_armor_regeneration_rate() -> float:
	var total_rate = 0.0
	
	if owner_player and owner_player.equipment_manager:
		var all_equipment = owner_player.equipment_manager.get_all_equipment_instances()
		for equipment in all_equipment:
			if equipment.has_method("get_armor_regeneration_rate"):
				total_rate += equipment.get_armor_regeneration_rate()
	
	return total_rate

## 获取玩家护甲回复倍率[br]
## [returns] 玩家的护甲回复倍率
func _get_player_armor_regeneration_multiplier() -> float:
	if owner_player and owner_player.stats_manager:
		# 从玩家属性管理器获取护甲回复倍率
		var multiplier = owner_player.stats_manager.get_base_stat("armor_regeneration_multiplier")
		return multiplier if multiplier > 0.0 else 1.0
	return 1.0

## 获取护甲回复速度[br]
## [returns] 此装备提供的护甲回复速度
func get_armor_regeneration_rate() -> float:
	return armor_regeneration_rate

## 通知装备管理器护甲值变化
func _notify_armor_change() -> void:
	if owner_player and owner_player.equipment_manager:
		owner_player.equipment_manager.recalculate_total_armor()

## 卸载装备时的清理
func _on_unequip() -> void:
	if FightEventBus.on_player_damage.is_connected(on_player_damage):
		FightEventBus.on_player_damage.disconnect(on_player_damage)

	# 通知装备管理器重新计算护甲值
	_notify_armor_change()

## 重写使用装备方法 - 护甲装备是被动的
func use_equipment() -> bool:
	# 护甲装备是被动装备，不需要主动使用
	return false

## 重写检查是否可以使用
func can_use() -> bool:
	# 护甲装备是被动装备，始终返回false
	return false

## === 可重写方法 ===

## 自定义护甲更新逻辑[br]
## [param delta] 时间增量
func _custom_armor_update(delta: float) -> void:
	# 子类可重写此方法来实现特定的更新逻辑（如特殊效果、动画等）
	pass 