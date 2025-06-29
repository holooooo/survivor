extends Node
class_name SafeHouseManager

## 安全屋管理器 - 负责房间切换逻辑和游戏时间管理[br]
## 管理各个房间的显示和隐藏，处理导航功能

# 房间类型枚举
enum RoomType {
	MAIN,        ## 主界面
	BATTLE,      ## 作战室
	RECRUIT,     ## 招募室
	UPGRADE,     ## 改造室
	RESEARCH,    ## 研究室
	BRAND        ## 品牌室
}

# 当前激活的房间
var current_room: RoomType = RoomType.MAIN
# 游戏周期计数（每出发一次战斗算一周）
var game_week: int = 1
# 房间节点引用
var room_container: Control
var rooms: Dictionary = {}

# 信号
signal room_changed(new_room: RoomType)
signal game_week_changed(week: int)

func _ready() -> void:
	_initialize_manager()

## 初始化管理器
func _initialize_manager() -> void:
	# 连接事件总线信号
	if EventBus:
		EventBus.battle_completed.connect(_on_battle_completed)

## 设置房间容器[br]
## [param container] 房间容器节点
func set_room_container(container: Control) -> void:
	room_container = container
	_register_rooms()

## 注册所有房间节点
func _register_rooms() -> void:
	if not room_container:
		return
	
	# 查找并注册各个房间
	var main_room = room_container.get_node_or_null("MainRoom")
	var battle_room = room_container.get_node_or_null("BattleRoom")
	var recruit_room = room_container.get_node_or_null("RecruitRoom")
	var upgrade_room = room_container.get_node_or_null("UpgradeRoom")
	var research_room = room_container.get_node_or_null("ResearchRoom")
	var brand_room = room_container.get_node_or_null("BrandRoom")
	
	if main_room:
		rooms[RoomType.MAIN] = main_room
	if battle_room:
		rooms[RoomType.BATTLE] = battle_room
	if recruit_room:
		rooms[RoomType.RECRUIT] = recruit_room
	if upgrade_room:
		rooms[RoomType.UPGRADE] = upgrade_room
	if research_room:
		rooms[RoomType.RESEARCH] = research_room
	if brand_room:
		rooms[RoomType.BRAND] = brand_room
	
	# 初始显示主房间
	switch_to_room(RoomType.MAIN)

## 切换到指定房间[br]
## [param room_type] 目标房间类型
func switch_to_room(room_type: RoomType) -> void:
	if current_room == room_type:
		return
	
	# 隐藏当前房间
	if rooms.has(current_room):
		rooms[current_room].visible = false
	
	# 显示目标房间
	if rooms.has(room_type):
		rooms[room_type].visible = true
		current_room = room_type
		room_changed.emit(room_type)
		
		# 如果房间有激活方法，调用它
		var room = rooms[room_type]
		if room.has_method("on_room_activated"):
			room.on_room_activated()
	else:
		push_warning("房间未找到: " + str(room_type))

## 获取当前房间类型[br]
## [returns] 当前房间类型
func get_current_room() -> RoomType:
	return current_room

## 获取当前游戏周期[br]
## [returns] 当前游戏周期
func get_game_week() -> int:
	return game_week

## 增加游戏周期
func advance_week() -> void:
	game_week += 1
	game_week_changed.emit(game_week)

## 战斗完成回调
func _on_battle_completed() -> void:
	advance_week()

## 获取房间名称[br]
## [param room_type] 房间类型[br]
## [returns] 房间显示名称
func get_room_name(room_type: RoomType) -> String:
	match room_type:
		RoomType.MAIN:
			return "主界面"
		RoomType.BATTLE:
			return "作战室"
		RoomType.RECRUIT:
			return "招募室"
		RoomType.UPGRADE:
			return "改造室"
		RoomType.RESEARCH:
			return "研究室"
		RoomType.BRAND:
			return "品牌室"
		_:
			return "未知房间" 