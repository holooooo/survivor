extends Area2D
class_name Spike
## 用于标记点位，并支持生成敌人或者触发事件
signal actived
@export var active_delay: float = 0.5 ## 激活延迟（秒）
@export var on_ready: bool = true ## 是否在节点准备就绪时激活

@export var on_player_entered: bool = false: ## 是否在玩家进入时激活
	set(value):
		print("on_player_entered: ", name, value)
		if value:
			if not body_entered.is_connected(player_entered):
				body_entered.connect(player_entered)
		elif body_entered.is_connected(player_entered):
			body_entered.disconnect(player_entered)

@export var on_player_exited: bool = false: ## 是否在玩家离开时激活
	set(value):
		if value:
			if not body_exited.is_connected(player_entered):
				body_exited.connect(player_entered)
		elif body_exited.is_connected(player_entered):
			body_exited.disconnect(player_entered)

@export var on_enemy_entered: bool = false: ## 是否在敌人进入时激活
	set(value):
		if value:
			if not body_entered.is_connected(enemy_entered):
				body_entered.connect(enemy_entered)
		elif body_entered.is_connected(enemy_entered):
			body_entered.disconnect(enemy_entered)

@export var on_enemy_exited: bool = false: ## 是否在敌人离开时激活
	set(value):
		if value:
			if not body_exited.is_connected(enemy_exited):
				body_exited.connect(enemy_exited)
		elif body_exited.is_connected(enemy_exited):
			body_exited.disconnect(enemy_exited)

@export var max_active_count: int = 1 ## 最大激活次数，0表示无限制

var active_count: int = 0 ## 当前激活次数


func _ready() -> void:
	if on_ready:
		effect(self) # 如果需要在准备就绪时激活，则直接调用 effect
	# 连接信号
	on_player_entered = on_player_entered
	on_player_exited = on_player_exited
	on_enemy_entered = on_enemy_entered
	on_enemy_exited = on_enemy_exited


func player_entered(body: Node) -> void:
	print("Player entered: ", body.name, " at ", global_position)
	if body.is_in_group(Constants.GROUP_PLAYER):
		effect(body)


func player_exited(body: Node) -> void:
	if body.is_in_group(Constants.GROUP_PLAYER):
		effect(body)


func enemy_entered(body: Node) -> void:
	if body.is_in_group(Constants.GROUP_ENEMIES):
		effect(body)


func enemy_exited(body: Node) -> void:
	if body.is_in_group(Constants.GROUP_ENEMIES):
		effect(body)


func effect(n: Node2D) -> void:
	if max_active_count > 0 and active_count >= max_active_count:
		return # 达到最大激活次数，忽略
	active_count += 1
	emit_signal("actived")

	# 延迟激活
	await get_tree().create_timer(active_delay).timeout

	# 触发事件
	activate(n)


## virtual 方法，子类可以重写以实现具体的激活逻辑
func activate(_n: Node2D) -> void:
	pass