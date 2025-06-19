extends Node

## 游戏常量定义
## 包含所有游戏中使用的常量值，便于统一管理和调整

# 武器属性
const BULLET_DEFAULT_SPEED: float = 400.0
const BULLET_DEFAULT_DAMAGE: int = 15
const BULLET_LIFETIME: float = 5.0

# 游戏平衡
const SPAWN_DISTANCE_FROM_SCREEN: float = 300.0  ## 增加生成距离，避免玩家看到敌人凭空出现
const DAMAGE_NUMBER_OFFSET_RANGE: float = 20.0

# 角色碰撞半径
const PLAYER_RADIUS: float = 20.0  ## 玩家角色的碰撞半径
const ENEMY_RADIUS: float = 15.0   ## 敌人角色的碰撞半径

# 敌人刷新相关
const ENEMY_MAX_DISTANCE_FROM_PLAYER: float = 2000.0  ## 敌人距离玩家的最大距离
const ENEMY_RESPAWN_DISTANCE_FROM_SCREEN: float = 200.0  ## 敌人重生时距离屏幕边缘的距离
const ENEMY_OFF_SCREEN_SPEED_MULTIPLIER: float = 2.0  ## 敌人在屏幕外时的速度倍数

# 性能监控
const SHOW_PERFORMANCE_MONITOR: bool = true  ## 是否显示性能监控

# 性能优化
const USE_SIMPLE_MOVEMENT: bool = true  ## 对简单敌人使用直接位置更新而非move_and_slide
const ENEMY_UPDATE_SKIP_FRAMES: int = 2  ## 敌人更新跳过的帧数（降低更新频率）
const MAX_ENEMIES_PER_FRAME: int = 50  ## 每帧最大处理的敌人数量
const DISTANCE_CHECK_OPTIMIZATION: bool = true  ## 启用距离检查优化

# 物理性能优化
const MAX_BULLETS_ON_SCREEN: int = 100  ## 屏幕上同时存在的最大子弹数
const BULLET_POOL_SIZE: int = 50  ## 子弹对象池大小
const USE_BULLET_POOLING: bool = true  ## 启用子弹对象池
const PHYSICS_CULLING_DISTANCE: float = 1500.0  ## 物理剔除距离
const AREA2D_OPTIMIZATION: bool = true  ## 启用Area2D优化

# 敌人类型枚举
enum EnemyType {
	MELEE,    ## 近战型敌人
	RANGED,   ## 远程攻击敌人  
	SPECIAL   ## 特殊能力敌人
}

# 游戏状态枚举
enum GameState {
	MENU,     ## 主菜单状态
	PLAYING,  ## 游戏进行状态
	PAUSED,   ## 游戏暂停状态
	GAME_OVER ## 游戏结束状态
} 