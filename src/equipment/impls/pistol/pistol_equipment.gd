extends EmitterEquipmentBase
class_name PistolEquipment

## 手枪装备 - 远程射击装备[br]
## 每次射击发射3颗子弹，具备弹夹系统和装填机制

@export var orbit_radius: float = 50.0 ## 围绕玩家的轨道半径

@onready var pistol_sprite: Sprite2D = $PistolSprite

func _ready() -> void:
	super._ready()
	_setup_pistol_sprite()


## 自定义更新逻辑 - 手枪位置和旋转[br]
## [param delta] 时间增量
func _custom_update(delta: float) -> void:
	_update_pistol_position_and_rotation()

## 重写初始化方法，设置手枪初始位置[br]
## [param player] 装备拥有者
func initialize(player: Player) -> void:
	super.initialize(player)
	
	# 设置手枪初始位置
	if pistol_sprite and owner_player:
		pistol_sprite.global_position = owner_player.global_position + Vector2(orbit_radius, 0)





## 设置手枪精灵外观[br]
func _setup_pistol_sprite() -> void:
	if not pistol_sprite:
		return
	
	var default_texture: Texture2D = load("res://icon.svg")
	if default_texture:
		pistol_sprite.texture = default_texture
		pistol_sprite.modulate = Color.WHITE
		pistol_sprite.scale = Vector2(0.3, 0.3)

## 更新手枪位置和朝向[br]
func _update_pistol_position_and_rotation() -> void:
	if not pistol_sprite or not owner_player:
		return
	
	# 获取最近敌人的方向
	var target_direction: Vector2 = _get_target_direction()
	
	# 获取当前手枪相对玩家的方向
	var player_pos: Vector2 = owner_player.global_position
	var current_pos: Vector2 = pistol_sprite.global_position
	var current_direction: Vector2 = (current_pos - player_pos).normalized()
	
	# 如果当前方向无效，使用目标方向
	if current_direction == Vector2.ZERO:
		current_direction = target_direction
	
	# 计算目标方向与当前方向的角度差
	var current_angle: float = current_direction.angle()
	var target_angle: float = target_direction.angle()
	var angle_diff: float = target_angle - current_angle
	
	# 处理角度跳跃（-π到π之间）
	while angle_diff > PI:
		angle_diff -= 2 * PI
	while angle_diff < -PI:
		angle_diff += 2 * PI
	
	# 平滑旋转角度
	var rotation_speed: float = 5.0  # 旋转速度（弧度/秒）
	var max_rotation: float = rotation_speed * get_process_delta_time()
	
	var new_angle: float
	if abs(angle_diff) < max_rotation:
		new_angle = target_angle
	else:
		new_angle = current_angle + sign(angle_diff) * max_rotation
	
	# 计算新的方向向量
	var new_direction: Vector2 = Vector2.from_angle(new_angle)
	
	# 严格保持在orbit_radius距离上
	pistol_sprite.global_position = player_pos + new_direction * orbit_radius
	
	# 设置手枪朝向（指向目标方向）
	pistol_sprite.rotation = new_angle

## 获取目标方向 - 手枪朝向最近敌人[br]
## [returns] 目标方向向量
func _get_target_direction() -> Vector2:
	if not owner_player:
		return Vector2.RIGHT
	
	var nearest_enemy: Node2D = get_nearest_enemy_in_attack_range()
	if nearest_enemy:
		return (nearest_enemy.global_position - owner_player.global_position).normalized()
	else:
		return Vector2.RIGHT