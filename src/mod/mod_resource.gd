extends Resource
class_name ModResource

## 模组资源 - 装备强化模组的配置资源[br]
## 定义模组的效果类型、兼容性和优先级系统

enum ModEffectType {
	ATTRIBUTE_MODIFIER, ## 属性修改（如攻击力+10%、攻击范围+20%）
	PROJECTILE_EFFECT, ## 投射物效果（如弹射、分裂、穿透）
	SPECIAL_EFFECT, ## 特殊效果（如无限弹药、生命偷取）
	HOOK_EFFECT ## Hook效果（响应游戏事件的回调效果）
}

## Hook类型枚举[br]
## 定义不同的游戏事件触发点
enum HookType {
	ON_EQUIP, ## 装备时
	ON_UNEQUIP, ## 卸载时
	ON_USE, ## 使用时
	ON_HIT, ## 命中时
	ON_DAMAGE_DEALT, ## 造成伤害时
	ON_KILL, ## 击杀敌人时
	ON_PROJECTILE_SPAWN, ## 投射物生成时
	ON_PROJECTILE_DESTROY, ## 投射物销毁时
	ON_COOLDOWN_START, ## 冷却开始时
	ON_COOLDOWN_END ## 冷却结束时
}

@export_group("基础信息")
@export var mod_name: String = "基础模组" ## 模组名称
@export var mod_id: String = "" ## 模组唯一标识
@export var description: String = "" ## 模组描述
@export var icon_texture: Texture2D ## 模组图标

@export var priority: int = 0 ## 优先级，数字越大优先级越高

@export_group("效果配置")
@export var effect_type: ModEffectType = ModEffectType.ATTRIBUTE_MODIFIER ## 效果类型
@export var effect_config: Dictionary = {} ## 效果配置参数


## 获取效果配置的安全访问方法[br]
## [param key] 配置键名[br]
## [param default_value] 默认值[br]
## [returns] 配置值
func get_effect_config(key: String, default_value = null):
	return effect_config.get(key, default_value)

## 验证模组资源的完整性[br]
## [returns] 是否有效
func is_valid() -> bool:
	if mod_name.is_empty():
		return false
	
	# 根据效果类型验证必要的配置
	match effect_type:
		ModEffectType.ATTRIBUTE_MODIFIER:
			if not effect_config.has("stat_name"):
				return false
			if not effect_config.has("modifier_type"):
				return false
			if not effect_config.has("value"):
				return false
		ModEffectType.PROJECTILE_EFFECT:
			if not effect_config.has("effect_name"):
				return false
		ModEffectType.SPECIAL_EFFECT:
			if not effect_config.has("effect_name"):
				return false
		ModEffectType.HOOK_EFFECT:
			if not effect_config.has("hook_type"):
				return false
	
	return true

## 获取模组信息字典[br]
## [returns] 模组信息
func get_mod_info() -> Dictionary:
	return {
		"name": mod_name,
		"id": mod_id,
		"description": description,
		"effect_type": effect_type,
		"priority": priority,
		"effect_config": effect_config
	}

## === 模组效果执行接口 ===

## 应用模组效果到投射物[br]
## [param projectile] 目标投射物[br]
## 子类可重写此方法来实现模组的初始化逻辑
func apply_to_projectile(projectile: Node) -> void:
	# 默认实现：将effect_config设置到projectile的meta中
	if effect_type == ModEffectType.PROJECTILE_EFFECT:
		var effect_name = effect_config.get("effect_name", "")
		if not effect_name.is_empty():
			projectile.set_meta(effect_name + "_mod", self)
			projectile.set_meta(effect_name + "_data", _get_initial_mod_data())

## 处理投射物命中事件[br]
## [param projectile] 投射物[br]
## [param target] 命中的目标[br]
## [returns] 是否应该继续处理后续逻辑
func on_projectile_hit(projectile: Node, target: Node) -> bool:
	# 子类重写此方法来实现命中时的效果
	return true

## 获取初始模组数据[br]
## [returns] 初始数据字典[br]
## 子类可重写此方法来提供自定义的初始数据
func _get_initial_mod_data() -> Dictionary:
	return effect_config.duplicate()

## 修改其他模组的数据[br]
## [param projectile] 投射物[br]
## [param other_mod_id] 其他模组的ID[br]
## [param modifications] 要应用的修改[br]
## 用于实现模组间的相互影响
func modify_other_mod(projectile: Node, other_mod_id: String, modifications: Dictionary) -> void:
	var other_mod_data_key = other_mod_id + "_data"
	if projectile.has_meta(other_mod_data_key):
		var other_data = projectile.get_meta(other_mod_data_key, {})
		for key in modifications:
			other_data[key] = modifications[key]
		projectile.set_meta(other_mod_data_key, other_data)

## === Hook系统方法 ===

## 执行Hook效果[br]
## [param hook_type] Hook类型[br]
## [param context] 上下文数据（包含装备、目标、伤害等信息）[br]
## 子类可重写此方法实现自定义的Hook处理逻辑
func execute_hook(hook_type: HookType, context: Dictionary) -> void:
	print("执行Hook效果: ", mod_name, " Hook类型: ", hook_type, " 上下文: ", context.keys())
	
	# 默认Hook处理逻辑
	match hook_type:
		HookType.ON_EQUIP:
			_on_equip_hook(context)
		HookType.ON_UNEQUIP:
			_on_unequip_hook(context)
		HookType.ON_USE:
			_on_use_hook(context)
		HookType.ON_HIT:
			_on_hit_hook(context)
		HookType.ON_DAMAGE_DEALT:
			_on_damage_dealt_hook(context)
		HookType.ON_KILL:
			_on_kill_hook(context)
		HookType.ON_PROJECTILE_SPAWN:
			_on_projectile_spawn_hook(context)
		HookType.ON_PROJECTILE_DESTROY:
			_on_projectile_destroy_hook(context)
		HookType.ON_COOLDOWN_START:
			_on_cooldown_start_hook(context)
		HookType.ON_COOLDOWN_END:
			_on_cooldown_end_hook(context)

## === 默认Hook处理方法 - 子类可重写 ===

## 装备时Hook[br]
## [param context] 上下文数据
func _on_equip_hook(context: Dictionary) -> void:
	var equipment = context.get("equipment", null)
	if equipment:
		print("mod ", mod_name, " 在装备 ", equipment.equipment_name, " 上生效")

## 卸载时Hook[br]
## [param context] 上下文数据
func _on_unequip_hook(context: Dictionary) -> void:
	var equipment = context.get("equipment", null)
	if equipment:
		print("mod ", mod_name, " 从装备 ", equipment.equipment_name, " 上移除")

## 使用时Hook[br]
## [param context] 上下文数据
func _on_use_hook(context: Dictionary) -> void:
	# 可以根据effect_config配置不同的使用效果
	pass

## 命中时Hook[br]
## [param context] 上下文数据
func _on_hit_hook(context: Dictionary) -> void:
	var target = context.get("target", null)
	var damage = context.get("damage", 0)
	var damage_type = context.get("damage_type", Constants.DamageType.枪械)
	
	# 可以根据effect_config实现不同的命中效果
	# 例如：生命偷取、附加伤害、状态效果等

## 造成伤害时Hook[br]
## [param context] 上下文数据
func _on_damage_dealt_hook(context: Dictionary) -> void:
	# 可以根据effect_config实现伤害相关的效果
	pass

## 击杀敌人时Hook[br]
## [param context] 上下文数据
func _on_kill_hook(context: Dictionary) -> void:
	var equipment = context.get("equipment", null)
	var target = context.get("target", null)
	
	# 可以实现击杀奖励、冷却减少等效果
	var cooldown_reduction = effect_config.get("cooldown_reduction_on_kill", 0.0)
	if cooldown_reduction > 0.0 and equipment:
		print("击杀敌人，减少冷却时间: ", cooldown_reduction, "秒")

## 投射物生成时Hook[br]
## [param context] 上下文数据
func _on_projectile_spawn_hook(context: Dictionary) -> void:
	var projectile = context.get("projectile", null)
	if projectile:
		# 可以修改投射物属性
		pass

## 投射物销毁时Hook[br]
## [param context] 上下文数据
func _on_projectile_destroy_hook(context: Dictionary) -> void:
	# 可以实现投射物销毁时的特殊效果
	pass

## 冷却开始时Hook[br]
## [param context] 上下文数据
func _on_cooldown_start_hook(context: Dictionary) -> void:
	# 可以修改冷却时间
	pass

## 冷却结束时Hook[br]
## [param context] 上下文数据
func _on_cooldown_end_hook(context: Dictionary) -> void:
	# 可以实现冷却结束时的效果
	pass