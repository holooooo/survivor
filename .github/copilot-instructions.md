# Copilot Instructions for Geometry Survivor

## 项目架构概览
- **五层结构**：
	1. `globals/`：核心服务（如 EventBus, GameManager, Constants）
	2. `entities/`：游戏实体（玩家、敌人、Buff）
	3. `equipment/`：武器、防具、Mod、特效
	4. `ui/`：用户界面组件
	5. `scenes/`：场景组织与预制体

## 关键系统与模式
- **事件系统**：FightEventBus 实现模块间解耦通信（如 `on_projectile_kill`, `on_equipment_used` 等）
- **装备系统**：模块化武器/防具，基类如 `equipment_base.gd`，发射器/防具/Mod 细分目录
- **Buff系统**：`buff_manager.gd` 统一管理，支持属性修饰、持续伤害、控制等效果
- **Safe House**：元进程据点，6个房间由 `safe_house_manager.gd` 管理

## 开发与调试流程
- **运行游戏**：
	- `godot --path /Users/xiechuyu/code/godot/geometry-survivor/`
- **运行特定场景**：
	- `godot --path /Users/xiechuyu/code/godot/geometry-survivor/ src/fight/fight.tscn`
- **导出构建**：
	- `godot --path /Users/xiechuyu/code/godot/geometry-survivor/ --export-release "Windows Desktop" build/`
- **调试参数**：
	- `--verbose`（详细日志）、`--debug-collisions`（显示碰撞体）

## 代码风格与约定
- **统一使用 Tab 缩进**
- **GDScript 强类型，优先组合优于继承**
- **节点命名 PascalCase，方法 snake_case**
- **节点引用优先用 `$NodePath`**
- **新函数需添加文档注释，注释以代码块总结为主，避免逐行注释**
- **功能开发前先分析现有代码，理清需求再动手**
- **避免单文件多模块，保持最小职责原则**

## tres 资源文件规范
- `type` 永远为 Resource，`script_class` 为实际子类
- `uid` 可省略，`path` 必须正确
- 参考 `emitter_projectile_resource.gd` 相关 tres 文件格式

## 重要文件/目录参考
- `src/globals/`：事件、全局管理器
- `src/entities/`：玩家、敌人、Buff
- `src/equipment/`：装备、发射器、Mod
- `src/ui/`：UI 组件
- `src/safe_house/`：Safe House 相关

> 如遇不明确需求，优先与用户确认，保持代码可扩展与简洁喵~
