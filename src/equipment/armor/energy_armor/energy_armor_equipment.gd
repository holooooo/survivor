extends ArmorEquipmentBase
class_name EnergyArmorEquipment

## 电能护甲装备 - 基于ArmorEquipmentBase的电能护甲实现[br]
## 提供标准的护甲值和自动回复机制

func _ready() -> void:
	super._ready()
	# 设置装备类型
	if not equipment_id:
		equipment_id = "energy_armor"
	if not equipment_name:
		equipment_name = "电能护甲"

## 自定义护甲更新逻辑 - 电能护甲的特殊效果[br]
## [param delta] 时间增量
func _custom_armor_update(delta: float) -> void:
	# 电能护甲可以在这里添加特殊的视觉效果或音效
	# 例如：护甲回复时的电流效果
	pass 