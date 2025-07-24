extends Node
class_name ModManager

## Mod管理器 - 负责管理玩家的Mod装备和事件监听[br]
## 集成EquipmentSlotManager，监听FightEventBus事件来触发Mod效果

@export var default_mods: Array[ModResource] = [] ## 默认Mod资源数组

@onready var equipment_slot_manager: EquipmentSlotManager = get_node("../EquipmentSlotManager")
@onready var player: Player = %Player

## 周期性检查计时器
var periodic_check_timer: Timer

## 当前已装备的Mod缓存
var active_mods: Array[ModResource] = []

## 事件计数器，用于统计触发器
var event_counters: Dictionary = {}

signal mod_triggered(mod_resource: ModResource, event_args: Dictionary)
signal mod_effect_executed(mod_resource: ModResource, effect_info: Dictionary)
signal mod_changed(slot_index: int, mod_resource: ModResource)
signal mod_slot_info_changed(slot_info: Dictionary)

func _ready() -> void:
	if not equipment_slot_manager:
		push_error("ModManager: 找不到EquipmentSlotManager")
		return
	
	if not player:
		push_error("ModManager: 找不到Player节点")
		return
	
	# 连接EquipmentSlotManager的信号
	equipment_slot_manager.mod_slot_changed.connect(_on_mod_slot_changed)
	
	# 连接FightEventBus的所有相关信号
	_connect_fight_event_signals()
	
	# 初始化周期性检查计时器
	_setup_periodic_timer()
	
	# 初始化已装备的Mod
	_refresh_active_mods()
	
	# 装备默认Mod
	_equip_default_mods()


## 连接FightEventBus的信号[br]
func _connect_fight_event_signals() -> void:
	# 玩家相关事件
	FightEventBus.on_player_damage.connect(_on_player_damage)
	
	# 装备相关事件
	FightEventBus.on_equip.connect(_on_equip)
	FightEventBus.on_equipment_used.connect(_on_equipment_used)
	FightEventBus.on_equipment_cooldown_start.connect(_on_equipment_cooldown_start)
	
	# 投射物相关事件
	FightEventBus.on_projectile_spawn.connect(_on_projectile_spawn)
	FightEventBus.on_projectile_hit.connect(_on_projectile_hit)
	FightEventBus.on_projectile_destroy.connect(_on_projectile_destroy)
	FightEventBus.on_projectile_kill.connect(_on_projectile_kill)
	
	# 命中效果相关事件
	FightEventBus.on_hit_effect_triggered.connect(_on_hit_effect_triggered)
	FightEventBus.on_knockback_applied.connect(_on_knockback_applied)
	FightEventBus.on_explosion_triggered.connect(_on_explosion_triggered)
	FightEventBus.on_projectile_split.connect(_on_projectile_split)
	FightEventBus.on_projectile_ricochet.connect(_on_projectile_ricochet)
	FightEventBus.on_vampire_heal.connect(_on_vampire_heal)
	FightEventBus.on_enemies_gathered.connect(_on_enemies_gathered)
	
	# 护甲相关事件
	FightEventBus.on_armor_damaged.connect(_on_armor_damaged)
	FightEventBus.on_armor_broken.connect(_on_armor_broken)
	FightEventBus.on_armor_regeneration_started.connect(_on_armor_regeneration_started)
	FightEventBus.on_armor_regeneration_finished.connect(_on_armor_regeneration_finished)
	FightEventBus.on_armor_fully_restored.connect(_on_armor_fully_restored)
	
	# Buff相关事件
	FightEventBus.buff_applied.connect(_on_buff_applied)
	FightEventBus.buff_removed.connect(_on_buff_removed)
	FightEventBus.buff_triggered.connect(_on_buff_triggered)
	FightEventBus.buff_expired.connect(_on_buff_expired)
	FightEventBus.buff_stacks_changed.connect(_on_buff_stacks_changed)


## 设置周期性检查计时器[br]
func _setup_periodic_timer() -> void:
	periodic_check_timer = Timer.new()
	periodic_check_timer.wait_time = 1.0  # 每秒检查一次
	periodic_check_timer.timeout.connect(_on_periodic_check)
	periodic_check_timer.autostart = true
	add_child(periodic_check_timer)


## Mod槽位变化处理[br]
## [param slot_index] 槽位索引[br]
## [param mod_resource] Mod资源（null表示卸载）
func _on_mod_slot_changed(slot_index: int, mod_resource: ModResource) -> void:
	print("ModManager: Mod槽位 %d 变化: %s" % [slot_index, mod_resource.mod_name if mod_resource else "卸载"])
	_refresh_active_mods()
	
	# 发出Mod变化信号
	mod_changed.emit(slot_index, mod_resource)
	mod_slot_info_changed.emit(get_mod_slot_info())


## 刷新已装备的Mod列表[br]
func _refresh_active_mods() -> void:
	active_mods = equipment_slot_manager.get_all_equipped_mods()
	print("ModManager: 已装备Mod数量: %d" % active_mods.size())
	
	# 重置所有Mod的状态
	for mod in active_mods:
		mod.reset_mod_state()


## 处理事件触发[br]
## [param event_type] 事件类型[br]
## [param event_args] 事件参数
func _handle_event(event_type: String, event_args: Dictionary) -> void:
	# 添加事件类型到参数中
	event_args["event_type"] = event_type
	event_args["player"] = player
	
	# 更新事件计数器
	_update_event_counter(event_type, event_args)
	
	# 检查所有已装备的Mod
	for mod in active_mods:
		if mod.can_trigger(event_args):
			mod.execute_effect(player, event_args)
			mod_triggered.emit(mod, event_args)
			mod_effect_executed.emit(mod, mod.get_mod_info())


## 更新事件计数器[br]
## [param event_type] 事件类型[br]
## [param event_args] 事件参数
func _update_event_counter(event_type: String, event_args: Dictionary) -> void:
	# 基础事件计数
	if not event_counters.has(event_type):
		event_counters[event_type] = 0
	event_counters[event_type] += 1
	
	# 特定装备的事件计数
	if event_args.has("equipment"):
		var equipment = event_args["equipment"]
		if equipment:
			var equipment_key = "%s_%s" % [event_type, equipment.get_script().get_global_name()]
			if not event_counters.has(equipment_key):
				event_counters[equipment_key] = 0
			event_counters[equipment_key] += 1


## 获取事件计数[br]
## [param event_type] 事件类型[br]
## [param equipment_class] 装备类名（可选）[br]
## [returns] 事件计数
func get_event_count(event_type: String, equipment_class: String = "") -> int:
	var key = event_type
	if not equipment_class.is_empty():
		key = "%s_%s" % [event_type, equipment_class]
	
	return event_counters.get(key, 0)


## 周期性检查[br]
## 用于处理需要周期性检查的触发器
func _on_periodic_check() -> void:
	var event_args = {
		"event_type": "periodic_check",
		"player": player,
		"current_time": Time.get_time_dict_from_system()
	}
	
	# 检查所有已装备的Mod
	for mod in active_mods:
		if mod.can_trigger(event_args):
			mod.execute_effect(player, event_args)
			mod_triggered.emit(mod, event_args)


## 以下是FightEventBus事件处理函数
func _on_player_damage(player_node: Player, damage: int) -> void:
	_handle_event("player_damage", {"damage": damage})

func _on_equip(player_node: Player, equipment: EquipmentBase) -> void:
	_handle_event("equip", {"equipment": equipment})

func _on_equipment_used(player_node: Player, equipment: EquipmentBase) -> void:
	_handle_event("equipment_used", {"equipment": equipment})

func _on_equipment_cooldown_start(player_node: Player, equipment: EquipmentBase, last_use_time: float, cooldown_time: float) -> void:
	_handle_event("equipment_cooldown_start", {"equipment": equipment, "last_use_time": last_use_time, "cooldown_time": cooldown_time})

func _on_projectile_spawn(player_node: Player, equipment: EquipmentBase, projectile: ProjectileBase) -> void:
	_handle_event("projectile_spawn", {"equipment": equipment, "projectile": projectile})

func _on_projectile_hit(player_node: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, damage: int, damage_type: Constants.DamageType) -> void:
	_handle_event("projectile_hit", {"equipment": equipment, "projectile": projectile, "target": target, "damage": damage, "damage_type": damage_type})

func _on_projectile_destroy(player_node: Player, equipment: EquipmentBase, projectile: ProjectileBase) -> void:
	_handle_event("projectile_destroy", {"equipment": equipment, "projectile": projectile})

func _on_projectile_kill(player_node: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, damage: int, damage_type: Constants.DamageType) -> void:
	_handle_event("projectile_kill", {"equipment": equipment, "projectile": projectile, "target": target, "damage": damage, "damage_type": damage_type})

func _on_hit_effect_triggered(player_node: Player, equipment: EquipmentBase, projectile: ProjectileBase, target: Node, effect_name: String) -> void:
	_handle_event("hit_effect_triggered", {"equipment": equipment, "projectile": projectile, "target": target, "effect_name": effect_name})

func _on_knockback_applied(target: Node, direction: Vector2, strength: float) -> void:
	_handle_event("knockback_applied", {"target": target, "direction": direction, "strength": strength})

func _on_explosion_triggered(position: Vector2, radius: float, damage: int) -> void:
	_handle_event("explosion_triggered", {"position": position, "radius": radius, "damage": damage})

func _on_projectile_split(original_projectile: ProjectileBase, split_projectiles: Array) -> void:
	_handle_event("projectile_split", {"original_projectile": original_projectile, "split_projectiles": split_projectiles})

func _on_projectile_ricochet(projectile: ProjectileBase, old_target: Node, new_target: Node) -> void:
	_handle_event("projectile_ricochet", {"projectile": projectile, "old_target": old_target, "new_target": new_target})

func _on_vampire_heal(player_node: Player, heal_amount: int) -> void:
	_handle_event("vampire_heal", {"heal_amount": heal_amount})

func _on_enemies_gathered(center: Vector2, enemies: Array, radius: float) -> void:
	_handle_event("enemies_gathered", {"center": center, "enemies": enemies, "radius": radius})

func _on_armor_damaged(player_node: Player, armor_equipment: Node, current_armor: int, max_armor: int, damage: int) -> void:
	_handle_event("armor_damaged", {"armor_equipment": armor_equipment, "current_armor": current_armor, "max_armor": max_armor, "damage": damage})

func _on_armor_broken(player_node: Player, armor_equipment: Node, max_armor: int) -> void:
	_handle_event("armor_broken", {"armor_equipment": armor_equipment, "max_armor": max_armor})

func _on_armor_regeneration_started(player_node: Player, armor_equipment: Node) -> void:
	_handle_event("armor_regeneration_started", {"armor_equipment": armor_equipment})

func _on_armor_regeneration_finished(player_node: Player, armor_equipment: Node, regenerated_amount: int) -> void:
	_handle_event("armor_regeneration_finished", {"armor_equipment": armor_equipment, "regenerated_amount": regenerated_amount})

func _on_armor_fully_restored(player_node: Player, armor_equipment: Node, restored_amount: int) -> void:
	_handle_event("armor_fully_restored", {"armor_equipment": armor_equipment, "restored_amount": restored_amount})

func _on_buff_applied(target: Actor, buff_instance: BuffInstance) -> void:
	_handle_event("buff_applied", {"target": target, "buff_instance": buff_instance})

func _on_buff_removed(target: Actor, buff_instance: BuffInstance) -> void:
	_handle_event("buff_removed", {"target": target, "buff_instance": buff_instance})

func _on_buff_triggered(target: Actor, buff_instance: BuffInstance, trigger_type: String) -> void:
	_handle_event("buff_triggered", {"target": target, "buff_instance": buff_instance, "trigger_type": trigger_type})

func _on_buff_expired(target: Actor, buff_instance: BuffInstance) -> void:
	_handle_event("buff_expired", {"target": target, "buff_instance": buff_instance})

func _on_buff_stacks_changed(target: Actor, buff_instance: BuffInstance, old_stacks: int, new_stacks: int) -> void:
	_handle_event("buff_stacks_changed", {"target": target, "buff_instance": buff_instance, "old_stacks": old_stacks, "new_stacks": new_stacks})


## 装备默认Mod[br]
func _equip_default_mods() -> void:
	if default_mods.size() > 0:
		print("ModManager: 装备默认Mod，数量: %d" % default_mods.size())
		for mod_resource in default_mods:
			if mod_resource and mod_resource.is_valid_mod():
				var slot_index = equipment_slot_manager.try_equip_mod(mod_resource)
				if slot_index != -1:
					print("ModManager: 成功装备默认Mod '%s' 到槽位 %d" % [mod_resource.mod_name, slot_index])
				else:
					print("ModManager: 装备默认Mod失败: %s" % mod_resource.mod_name)
			else:
				print("ModManager: 无效的默认Mod资源")
	else:
		print("ModManager: 没有配置默认Mod")


## 装备Mod[br]
## [param mod_resource] 要装备的Mod资源[br]
## [param slot_index] 指定槽位索引，-1表示自动寻找空槽位[br]
## [returns] 装备成功的槽位索引，失败返回-1
func equip_mod(mod_resource: ModResource, slot_index: int = -1) -> int:
	if not mod_resource:
		print("ModManager: 装备Mod失败：Mod资源为空")
		return -1
	
	if not mod_resource.is_valid_mod():
		print("ModManager: 装备Mod失败：Mod资源无效")
		return -1
	
	# 尝试装备到Mod槽位
	var result_slot = equipment_slot_manager.try_equip_mod(mod_resource, slot_index)
	if result_slot == -1:
		print("ModManager: 没有可用的Mod槽位")
		return -1
	
	print("ModManager: 成功装备Mod '%s' 到槽位 %d" % [mod_resource.mod_name, result_slot])
	
	# 发出Mod变化信号
	mod_changed.emit(result_slot, mod_resource)
	mod_slot_info_changed.emit(get_mod_slot_info())
	
	return result_slot


## 卸载指定槽位的Mod[br]
## [param slot_index] 槽位索引[br]
## [returns] 是否成功卸载
func unequip_mod(slot_index: int) -> bool:
	var mod_resource = equipment_slot_manager.get_mod_at_slot(slot_index)
	if not mod_resource:
		return false
	
	var success = equipment_slot_manager.unequip_mod_slot(slot_index)
	if success:
		print("ModManager: 成功卸载Mod '%s' 从槽位 %d" % [mod_resource.mod_name, slot_index])
		
		# 发出Mod变化信号
		mod_changed.emit(slot_index, null)
		mod_slot_info_changed.emit(get_mod_slot_info())
	
	return success


## 获取指定槽位的Mod[br]
## [param slot_index] 槽位索引[br]
## [returns] Mod资源
func get_mod_at_slot(slot_index: int) -> ModResource:
	return equipment_slot_manager.get_mod_at_slot(slot_index)


## 获取所有已装备的Mod[br]
## [returns] Mod资源数组
func get_all_equipped_mods() -> Array[ModResource]:
	return equipment_slot_manager.get_all_equipped_mods()


## 检查是否可以装备更多Mod[br]
## [returns] 是否可以装备
func can_equip_more_mods() -> bool:
	var slot_info = equipment_slot_manager.get_mod_slot_info()
	return slot_info.get("available_slots", 0) > 0


## 获取Mod槽位信息[br]
## [returns] Mod槽位信息字典
func get_mod_slot_info() -> Dictionary:
	return equipment_slot_manager.get_mod_slot_info()


## 获取管理器状态信息[br]
## [returns] 状态信息字典
func get_manager_info() -> Dictionary:
	return {
		"active_mods_count": active_mods.size(),
		"event_counters": event_counters,
		"periodic_timer_active": periodic_check_timer.is_stopped() == false if periodic_check_timer else false,
		"default_mods_count": default_mods.size(),
		"mod_slot_info": get_mod_slot_info()
	}