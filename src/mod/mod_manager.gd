extends Node
class_name ModManager

## 模组管理器 - 管理装备的模组系统[br]
## 处理模组的安装卸载、兼容性检查和效果计算

@export var default_mods: Array[ModResource] = [] ## 默认mod资源数组

@onready var player: Player = get_parent() as Player
@onready var slot_manager: EquipmentSlotManager = %EquipmentSlotManager
const MAX_MOD_SLOTS: int = 10 ## 最大模组槽位数量

var mod_slots: Array[ModResource] = [] ## 模组槽位数组
var base_stats: Dictionary = {} ## 基础属性缓存
var modified_stats: Dictionary = {} ## 修改后的属性

signal mod_changed(slot_index: int, mod_resource: ModResource)
signal mod_slot_info_changed(slot_info: Dictionary)

func _ready() -> void:
	mod_slots.resize(MAX_MOD_SLOTS)
	for i in range(MAX_MOD_SLOTS):
		mod_slots[i] = null
	slot_manager.mod_slot_changed.connect(_on_mod_slot_changed)
	_equip_default_mods()

## mod槽位变化回调
func _on_mod_slot_changed(slot_index: int, mod_resource: ModResource) -> void:
	mod_changed.emit(slot_index, mod_resource)
	mod_slot_info_changed.emit(slot_manager.get_mod_slot_info())


## 装备默认mod
func _equip_default_mods() -> void:
	if default_mods.size() > 0:
		print("装备默认mod，数量: ", default_mods.size())
		for mod_resource in default_mods:
			if mod_resource and mod_resource.is_valid():
				var slot_index = equip_mod(mod_resource)
				if slot_index != -1:
					print("成功装备默认mod: ", mod_resource.mod_name, " 到槽位: ", slot_index)
				else:
					print("装备默认mod失败: ", mod_resource.mod_name)
			else:
				print("无效的默认mod资源")
	else:
		print("没有配置默认mod")

## 装备mod[br]
## [param mod_resource] 要装备的mod资源[br]
## [param slot_index] 指定槽位索引，-1表示自动寻找空槽位[br]
## [returns] 装备成功的槽位索引，失败返回-1
func equip_mod(mod_resource: ModResource, slot_index: int = -1) -> int:
	if not mod_resource:
		print("装备mod失败：mod资源为空")
		return -1
	
	# 尝试装备到mod槽位
	var result_slot = slot_manager.try_equip_mod(mod_resource, slot_index)
	if result_slot == -1:
		push_warning("没有可用的mod槽位")
		return -1
	mod_changed.emit(result_slot, mod_resource)
	return result_slot