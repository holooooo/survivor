extends ModResource
class_name EnhancedBounceMod

## 增强弹跳模组 - 增加弹跳子弹的弹跳次数[br]
## 使用ON_HIT Hook系统实现增强弹跳效果

## 重写Hook执行方法[br]
## [param hook_type] Hook类型[br]
## [param context] 上下文数据
func execute_hook(hook_type: ModResource.HookType, context: Dictionary) -> void:
	if hook_type != ModResource.HookType.ON_HIT:
		return
	
	var projectile = context.get("projectile", null)
	var target = context.get("target", null)
	
	if not projectile or not target:
		print("增强弹跳mod: 缺少投射物或目标")
		return
	
	print("增强弹跳mod触发，投射物: ", projectile.name, " 目标: ", target.name)
	
	# 检查是否有弹跳mod的数据
	var bounce_data_key = "bounce_projectile_data"
	if projectile.has_meta(bounce_data_key):
		var bounce_data = projectile.get_meta(bounce_data_key, {})
		var additional_bounces = effect_config.get("additional_bounces", 2)
		
		# 增加弹跳次数
		var current_bounces = bounce_data.get("remaining_bounces", 0)
		bounce_data["remaining_bounces"] = current_bounces + additional_bounces
		projectile.set_meta(bounce_data_key, bounce_data)
		
		print("增强弹跳效果已应用：弹跳次数+", additional_bounces, " 总次数: ", bounce_data["remaining_bounces"])
	else:
		print("增强弹跳mod: 投射物没有弹跳数据，无法增强")
