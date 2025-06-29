extends Node

## 安全屋系统测试脚本 - 用于验证系统功能[br]
## 可用于测试房间切换、信号连接等功能

func _ready() -> void:
	print("=== 安全屋系统测试开始 ===")
	_test_scene_loading()

## 测试场景加载
func _test_scene_loading() -> void:
	print("正在测试安全屋场景加载...")
	
	# 尝试加载安全屋场景
	var safe_house_scene = preload("res://src/scenes/safe_house/safe_house.tscn")
	if safe_house_scene:
		print("✓ 安全屋主场景加载成功")
		
		# 实例化场景进行基础测试
		var safe_house_instance = safe_house_scene.instantiate()
		if safe_house_instance:
			print("✓ 安全屋场景实例化成功")
			safe_house_instance.queue_free()
		else:
			print("✗ 安全屋场景实例化失败")
	else:
		print("✗ 安全屋主场景加载失败")
	
	# 测试各个房间场景
	_test_room_scenes()

## 测试各个房间场景
func _test_room_scenes() -> void:
	print("正在测试各个房间场景...")
	
	var room_scenes = {
		"主房间": "res://src/scenes/safe_house/rooms/main_room.tscn",
		"作战室": "res://src/scenes/safe_house/rooms/battle_room.tscn",
		"招募室": "res://src/scenes/safe_house/rooms/recruit_room.tscn",
		"改造室": "res://src/scenes/safe_house/rooms/upgrade_room.tscn",
		"研究室": "res://src/scenes/safe_house/rooms/research_room.tscn",
		"品牌室": "res://src/scenes/safe_house/rooms/brand_room.tscn"
	}
	
	for room_name in room_scenes:
		var scene_path = room_scenes[room_name]
		var loaded_scene = load(scene_path)
		if loaded_scene:
			print("✓ ", room_name, " 场景加载成功")
		else:
			print("✗ ", room_name, " 场景加载失败: ", scene_path)
	
	print("=== 安全屋系统测试完成 ===")

## 手动切换到安全屋场景 - 供外部调用
func switch_to_safe_house() -> void:
	print("正在切换到安全屋场景...")
	if EventBus:
		EventBus.change_scene_safely("res://src/scenes/safe_house/safe_house.tscn")
	else:
		get_tree().change_scene_to_file("res://src/scenes/safe_house/safe_house.tscn") 