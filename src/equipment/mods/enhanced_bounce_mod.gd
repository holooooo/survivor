extends ModResource
class_name EnhancedBounceMod

## 增强弹跳模组 - 增加弹跳子弹的弹跳次数[br]
## 演示mod之间相互影响的功能

## 重写应用到投射物的方法[br]
## [param projectile] 目标投射物
func apply_to_projectile(projectile: Node) -> void:
	super.apply_to_projectile(projectile)
	
	# 查找弹跳mod并增强它
	var additional_bounces = effect_config.get("additional_bounces", 2)
	
	# 等待一帧，确保其他mod已经应用完毕
	await projectile.get_tree().process_frame
	
	# 修改弹跳mod的数据
	modify_other_mod(projectile, "bounce_projectile", {
		"remaining_bounces": additional_bounces  # 这会覆盖原值
	})
	
	# 或者可以累加弹跳次数
	if projectile.has_meta("bounce_projectile_data"):
		var bounce_data = projectile.get_meta("bounce_projectile_data", {})
		var current_bounces = bounce_data.get("remaining_bounces", 0)
		bounce_data["remaining_bounces"] = current_bounces + additional_bounces
		projectile.set_meta("bounce_projectile_data", bounce_data)
		print("增强弹跳效果已应用：弹跳次数+", additional_bounces)

## 重写命中处理方法[br]
## [param projectile] 投射物[br]
## [param target] 命中的目标[br]
## [returns] 是否继续处理后续逻辑
func on_projectile_hit(projectile: Node, target: Node) -> bool:
	# 这个mod只在初始化时生效，命中时不做额外处理
	return true

## 重写获取初始模组数据[br]
## [returns] 增强弹跳模组的初始数据
func _get_initial_mod_data() -> Dictionary:
	return {
		"additional_bounces": effect_config.get("additional_bounces", 2),
		"effect_applied": false
	} 