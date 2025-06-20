extends Node2D


# 伤害数字场景预加载
const MAX_DAMAGE_NUMBERS: int = 100
var damage_number_scene: PackedScene = preload("res://src/scenes/common/prefabs/damage_number.tscn")
var _damage_number_pool: Array[Label] = []
var _damage_number_pool_index: int = 0

func _ready() -> void:
	register_pool()

func register_pool() -> void:
	# 将信号连接到处理函数
	EventBus.damage_number_requested.connect(create_damage_number)

	# 预加载伤害数字实例到对象池
	for i in range(MAX_DAMAGE_NUMBERS):
		var damage_number: Label = damage_number_scene.instantiate()
		_damage_number_pool.append(damage_number)
		add_child(damage_number)


## 从对象池获取并显示伤害数字[br]
## [param damage] 伤害数值[br]
## [param world_position] 世界坐标位置[br]
## [param color] 伤害数字颜色
func create_damage_number(damage: int, world_position: Vector2, color: Color) -> void:
	var damage_number: Label = _damage_number_pool[_damage_number_pool_index]
	
	# 更新下一个可用实例的索引，实现循环使用
	_damage_number_pool_index = (_damage_number_pool_index + 1) % MAX_DAMAGE_NUMBERS
	
	# 添加随机偏移避免重叠
	var random_offset: Vector2 = MathUtils.get_random_offset_position(Vector2.ZERO, GameConstants.DAMAGE_NUMBER_OFFSET_RANGE)
	var display_position: Vector2 = world_position + Vector2(0, -30) + random_offset
	
	# 显示伤害数字
	damage_number.show_at_position(damage, color, display_position)
