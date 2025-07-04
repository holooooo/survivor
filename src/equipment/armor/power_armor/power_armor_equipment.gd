extends ArmorEquipmentBase
class_name PowerArmorEquipment

## 动力护甲装备 - 受到攻击时获得移动加速buff[br]
## 护甲值20，受攻击时获得不可叠加的移动加速20%buff，持续3秒，冷却10秒

@export var speed_buff_resource: BuffResource ## 移动加速buff资源
@export var activation_cooldown: float = 10.0 ## 激活冷却时间（秒）

# 内部状态
var last_activation_time: float = 0.0 ## 上次激活时间
var is_on_cooldown: bool = false

func _ready() -> void:
	super._ready()
	
	# 设置装备基础信息
	if not equipment_id:
		equipment_id = "power_armor"
	if not equipment_name:
		equipment_name = "动力护甲"
	
	# 加载移动加速buff资源
	if not speed_buff_resource:
		speed_buff_resource = load("res://src/entities/buff/resources/power_armor_speed_buff.tres")
	
	# 设置护甲值
	armor_value = 20

func _process(delta: float) -> void:
	super._process(delta)
	_update_cooldown(delta)

## 初始化装备[br]
## [param player] 装备拥有者
func initialize(player: Player) -> void:
	super.initialize(player)
	
	# 监听玩家受到伤害事件
	if not FightEventBus.on_player_damage.is_connected(_on_player_damaged):
		FightEventBus.on_player_damage.connect(_on_player_damaged)

## 玩家受到伤害时的回调[br]
## [param player] 受伤的玩家[br]
## [param damage] 伤害值
func _on_player_damaged(player: Player, damage: int) -> void:
	# 检查是否是装备拥有者
	if player != owner_player:
		return
	
	# 检查冷却状态
	if is_on_cooldown:
		print("动力护甲冷却中，无法激活")
		return
	
	# 激活移动加速buff
	_activate_speed_buff()

## 激活移动加速buff[br]
func _activate_speed_buff() -> void:
	if not owner_player or not speed_buff_resource:
		return
	
	# 检查是否已经有相同buff（不可叠加）
	if owner_player.has_buff("power_armor_speed"):
		print("动力护甲加速效果已存在，刷新持续时间")
		# 移除旧buff，添加新buff来刷新持续时间
		owner_player.remove_buff("power_armor_speed")
	
	# 添加移动加速buff
	var success = owner_player.add_buff(speed_buff_resource, owner_player)
	if success:
		print("动力护甲激活！获得移动加速效果")
		
		# 触发视觉和音效
		_trigger_activation_effects()
		
		# 开始冷却
		_start_cooldown()
	else:
		print("动力护甲激活失败")

## 触发激活效果[br]
func _trigger_activation_effects() -> void:
	# 发送动力护甲激活事件
	FightEventBus.buff_applied.emit(owner_player, null)
	
	# 这里可以添加视觉效果、音效等
	# 例如：粒子效果、护甲发光等
	print("动力护甲激活效果触发")

## 开始冷却[br]
func _start_cooldown() -> void:
	is_on_cooldown = true
	last_activation_time = Time.get_ticks_msec() / 1000.0

## 更新冷却状态[br]
## [param delta] 时间增量
func _update_cooldown(delta: float) -> void:
	if not is_on_cooldown:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var elapsed_time = current_time - last_activation_time
	
	if elapsed_time >= activation_cooldown:
		is_on_cooldown = false
		print("动力护甲冷却完成")

## 获取冷却剩余时间[br]
## [returns] 剩余冷却时间（秒）
func get_cooldown_remaining() -> float:
	if not is_on_cooldown:
		return 0.0
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var elapsed_time = current_time - last_activation_time
	return max(0.0, activation_cooldown - elapsed_time)

## 检查是否在冷却中[br]
## [returns] 是否在冷却中
func is_cooldown_active() -> bool:
	return is_on_cooldown

## 获取动力护甲状态信息[br]
## [returns] 状态信息字典
func get_power_armor_status() -> Dictionary:
	var base_status = get_armor_status()
	base_status["is_on_cooldown"] = is_on_cooldown
	base_status["cooldown_remaining"] = get_cooldown_remaining()
	base_status["activation_cooldown"] = activation_cooldown
	base_status["has_speed_buff"] = owner_player.has_buff("power_armor_speed") if owner_player else false
	return base_status

## 卸载装备时的清理
func _on_unequip() -> void:
	super._on_unequip()
	
	# 断开事件连接
	if FightEventBus.on_player_damage.is_connected(_on_player_damaged):
		FightEventBus.on_player_damage.disconnect(_on_player_damaged)
	
	# 移除加速buff
	if owner_player and owner_player.has_buff("power_armor_speed"):
		owner_player.remove_buff("power_armor_speed")

## 自定义护甲更新逻辑[br]
## [param delta] 时间增量
func _custom_armor_update(delta: float) -> void:
	# 动力护甲可以在这里添加特殊的视觉效果
	# 例如：冷却状态指示、激活时的动画等
	pass 