extends Node
class_name Constants

## 游戏常量定义
## 包含所有游戏中使用的常量值，便于统一管理和调整

# 游戏平衡
const SPAWN_DISTANCE_FROM_SCREEN: float = 300.0 ## 增加生成距离，避免玩家看到敌人凭空出现
const DAMAGE_NUMBER_OFFSET_RANGE: float = 20.0

# 角色碰撞半径
const PLAYER_RADIUS: float = 20.0 ## 玩家角色的碰撞半径
const ENEMY_RADIUS: float = 15.0 ## 敌人角色的碰撞半径

# 敌人刷新相关
const ENEMY_MAX_DISTANCE_FROM_PLAYER: float = 2000.0 ## 敌人距离玩家的最大距离
const ENEMY_RESPAWN_DISTANCE_FROM_SCREEN: float = 200.0 ## 敌人重生时距离屏幕边缘的距离
const ENEMY_OFF_SCREEN_SPEED_MULTIPLIER: float = 2.0 ## 敌人在屏幕外时的速度倍数

# 性能监控
const SHOW_PERFORMANCE_MONITOR: bool = true ## 是否显示性能监控

# 性能优化
const USE_SIMPLE_MOVEMENT: bool = true ## 对简单敌人使用直接位置更新而非move_and_slide
const ENEMY_UPDATE_SKIP_FRAMES: int = 2 ## 敌人更新跳过的帧数（降低更新频率）
const MAX_ENEMIES_PER_FRAME: int = 50 ## 每帧最大处理的敌人数量
const DISTANCE_CHECK_OPTIMIZATION: bool = true ## 启用距离检查优化


# 敌人类型枚举
enum EnemyType {
	MELEE, ## 近战型敌人
	RANGED, ## 远程攻击敌人
	SPECIAL ## 特殊能力敌人
}

# 信用点系统
const CREDIT_MELEE_REWARD: int = 10 ## 近战敌人信用点奖励
const CREDIT_RANGED_REWARD: int = 15 ## 远程敌人信用点奖励
const CREDIT_SPECIAL_REWARD: int = 25 ## 特殊敌人信用点奖励

# 游戏状态枚举
enum GameState {
	MENU, ## 主菜单状态
	PLAYING, ## 游戏进行状态
	PAUSED, ## 游戏暂停状态
	GAME_OVER ## 游戏结束状态
}

# 物理层定义
const LAYER_PLAYER: int = 1
const LAYER_ENEMY: int = 2
const LAYER_PROJECTILE: int = 4
const LAYER_PICKUP: int = 8

# 组名定义
const GROUP_PLAYER: String = "player"
const GROUP_ENEMIES: String = "enemies"
const GROUP_PROJECTILES: String = "projectiles"
const GROUP_PICKUPS: String = "pickups"

# 伤害类型枚举
enum DamageType {
	枪械, ## 枪械伤害（手枪、步枪等）
	近战, ## 近战伤害（拳击、刀具等）
	能量, ## 能量伤害（电弧、激光等）
	爆炸, ## 爆炸伤害（炸弹、手榴弹等）
	火焰, ## 火焰伤害
	毒素, ## 毒素伤害
	冰冻, ## 冰冻伤害
	电击 ## 电击伤害
}

## 装备品质
## 装备品质影响装备的属性、效果
## 分为民用级企业级专业级军用级和传说级
enum EquipmentQuality {
	民用,
	专业,
	企业,
	军用,
	传说
}

enum EquipmentType {
	近战武器,
	枪械,
	能量武器,
	投掷物,
	装甲,
	护盾,
	植入物,
}

enum EquipmentProducer {
	无名作坊,
	公司1,
	公司2,
}

## 装备目标类型枚举
enum TargetType {
	最近敌人,      ## 攻击范围内最近的敌人
	最低生命值敌人, ## 攻击范围内生命值最低的敌人  
	随机敌人,      ## 攻击范围内的随机敌人
	随机位置       ## 攻击范围内的随机位置
}

# 获取伤害类型名称
static func get_damage_type_name(damage_type: DamageType) -> String:
	match damage_type:
		DamageType.枪械:
			return "枪械伤害"
		DamageType.近战:
			return "钝击伤害"
		DamageType.能量:
			return "能量伤害"
		DamageType.爆炸:
			return "炸药伤害"
		DamageType.火焰:
			return "火焰伤害"
		DamageType.毒素:
			return "毒素伤害"
		DamageType.冰冻:
			return "冰冻伤害"
		DamageType.电击:
			return "电击伤害"
		_:
			return "未知伤害"

# Buff类型枚举
enum BuffType {
	增益,   ## 正面效果
	减益,   ## 负面效果
	中性    ## 中性效果
}

# Buff效果类型枚举
enum BuffEffectType {
	属性修改,   ## 修改角色属性
	持续伤害,   ## 持续造成伤害
	控制效果,   ## 控制角色行为
	特殊效果,   ## 特殊机制效果
	复合效果    ## 组合多种效果
}

# 获取伤害类型颜色
static func get_damage_type_color(damage_type: DamageType) -> Color:
	match damage_type:
		DamageType.枪械:
			return Color.WHITE
		DamageType.近战:
			return Color.BROWN
		DamageType.能量:
			return Color.CYAN
		DamageType.爆炸:
			return Color.RED
		DamageType.火焰:
			return Color.ORANGE_RED
		DamageType.毒素:
			return Color.GREEN
		DamageType.冰冻:
			return Color.LIGHT_BLUE
		DamageType.电击:
			return Color.YELLOW
		_:
			return Color.WHITE