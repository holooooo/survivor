extends RefCounted
class_name EquipmentTags

## 装备标签枚举 - 用于模组兼容性检查[br]
## 提供类型安全的装备分类标签系统

enum Tag {
	## 武器类型
	枪械, ## 火器
	近战, ## 近战
	爆炸物, ## 爆炸物
	能量武器, ## 能量武器
	
	## 攻击模式
	投射物, ## 投射物
	范围攻击, ## 范围攻击
	光束, ## 光束
	自动瞄准, ## 自动瞄准

	## 具体武器
	手枪, ## 手枪
	拳击, ## 拳击
	炸弹, ## 炸弹
	电弧塔,
	
	## 冷却方式
	自动充能,
	手动充能,
	
	## 通配符
	通用 ## 通用（兼容所有装备）
}

## 检查两个标签数组是否有交集[br]
## [param tags1] 标签数组1[br]
## [param tags2] 标签数组2[br]
## [returns] 是否有交集
static func has_compatible_tags(tags1: Array[int], tags2: Array[int]) -> bool:
	# 检查通配符
	if Tag.通用 in tags1 or Tag.通用 in tags2:
		return true
	
	# 检查交集
	for tag in tags1:
		if tag in tags2:
			return true
	
	return false
