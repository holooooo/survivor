extends RefCounted
class_name AttributeModifierBuffEffect

var buff_instance
var target: Actor
var is_applied: bool = false
var applied_modifiers: Dictionary = {}

func initialize(instance) -> void:
	buff_instance = instance
	target = instance.target

func apply() -> void:
	if is_applied:
		return
	
	is_applied = true
	_apply_damage_modifiers()
	_apply_speed_modifiers()

func remove() -> void:
	if not is_applied:
		return
	
	is_applied = false
	_remove_damage_modifiers()
	_remove_speed_modifiers()

func on_tick() -> void:
	pass

func _apply_damage_modifiers() -> void:
	var damage_multiplier = get_effect_value("damage_multiplier", 0.0)
	if damage_multiplier != 0.0:
		_apply_player_stat_modifier("damage_multiplier", damage_multiplier)

func _apply_speed_modifiers() -> void:
	var speed_multiplier = get_effect_value("speed_multiplier", 0.0)
	if speed_multiplier != 0.0:
		_apply_player_stat_modifier("move_speed_multiplier", speed_multiplier)

func _remove_damage_modifiers() -> void:
	_remove_player_stat_modifier("damage_multiplier")

func _remove_speed_modifiers() -> void:
	_remove_player_stat_modifier("move_speed_multiplier")

func _apply_player_stat_modifier(stat_name: String, value: float) -> void:
	if target is not Player:
		return
	
	var stats_manager = target.stats_manager
	if not stats_manager:
		return
	
	var final_value = value * buff_instance.current_stacks
	
	if stats_manager.has_method("modify_base_stat"):
		stats_manager.modify_base_stat(stat_name, final_value)
	
	applied_modifiers[stat_name] = final_value

func _remove_player_stat_modifier(stat_name: String) -> void:
	if not applied_modifiers.has(stat_name):
		return
	
	if target is not Player:
		return
	
	var stats_manager = target.stats_manager
	if not stats_manager:
		return
	
	var applied_value = applied_modifiers[stat_name]
	
	if stats_manager.has_method("modify_base_stat"):
		stats_manager.modify_base_stat(stat_name, -applied_value)
	
	applied_modifiers.erase(stat_name)

func get_effect_value(key: String, default_value = 0.0):
	if buff_instance and buff_instance.buff_resource:
		return buff_instance.buff_resource.get_effect_value(key, default_value)
	return default_value