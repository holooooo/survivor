extends Resource
class_name ProjectileBase

## 投射物基类 - 投射物的配置资源[br]
## 定义投射物的基本属性和行为参数

@export var projectile_name: String = "基础投射物"
@export var damage_per_tick: int = 3 ## 每次伤害数值
@export var damage_interval: float = 0.1 ## 伤害间隔（秒）
@export var lifetime: float = 0.5 ## 生存时间（秒）
@export var detection_range: float = 50.0 ## 检测范围
@export var damage_ticks: int = 5 ## 造成伤害的次数
@export var projectile_texture: Texture2D ## 投射物贴图
@export var projectile_color: Color = Color.YELLOW ## 投射物颜色
@export var projectile_scale: Vector2 = Vector2(0.8, 0.8) ## 投射物缩放 