# Buff系统使用说明

## 📋 系统概述

Buff系统是一个完整的状态效果管理系统，支持各种增益、减益和控制效果。该系统采用组合式设计，具有高度的可扩展性和灵活性。

## 🏗️ 系统架构

### 核心组件关系

- **BuffResource**: 配置资源，定义buff的基本属性
- **BuffInstance**: 实例管理，处理单个buff的生命周期
- **BuffManager**: 管理器，统一管理角色身上的所有buff
- **BuffEffect**: 效果实现，具体的buff效果逻辑

### 支持的效果类型

1. **属性修改效果**: 伤害增强、速度减少、防御提升等
2. **持续伤害效果**: 毒素、火焰、电击等DOT效果
3. **控制效果**: 禁锢、沉默、无敌、击退等
4. **特殊效果**: 收割标记、收集标记等复杂机制

## 🔧 核心组件

### BuffResource - 配置资源
- 文件: `buff_resource.gd`
- 功能: 定义buff的基本属性和效果
- 属性: 名称、ID、描述、持续时间、层数、效果值等

### BuffInstance - 实例管理
- 文件: `buff_instance.gd`
- 功能: 管理单个buff的生命周期
- 职责: 定时器、层数管理、效果应用

### BuffManager - 管理器
- 文件: `buff_manager.gd`
- 功能: 管理角色身上的所有buff
- 职责: 添加、移除、更新、查询buff

### BuffEffect - 效果实现
- 文件: `effects/` 目录下的各种效果类
- 功能: 实现具体的buff效果
- 类型: 属性修改、持续伤害、控制、特殊效果

## 🚀 使用示例

### 1. 创建buff资源
```gdscript
# 创建伤害增强buff
var buff_resource = BuffResource.new()
buff_resource.buff_name = "伤害增强"
buff_resource.buff_id = "damage_boost"
buff_resource.duration = 10.0
buff_resource.effect_type = Constants.BuffEffectType.属性修改
buff_resource.set_effect_value("damage_multiplier", 0.25)
```

### 2. 应用buff到角色
```gdscript
# 获取角色的BuffManager
var buff_manager = player.get_buff_manager()

# 应用buff
buff_manager.add_buff(buff_resource, caster)
```

### 3. 检查buff状态
```gdscript
# 检查是否有无敌效果
if actor.is_invincible():
    print("角色当前无敌")

# 检查特定buff
if buff_manager.has_buff("damage_boost"):
    print("角色有伤害增强效果")
```

## 📁 文件结构

```
src/entities/buff/
├── buff_resource.gd         # 配置资源基类
├── buff_instance.gd         # 实例管理类
├── buff_manager.gd          # 管理器类
├── buff_test.gd             # 测试脚本
├── effects/                 # 效果实现
│   ├── attribute_modifier_buff_effect.gd
│   ├── control_buff_effect.gd
│   ├── dot_buff_effect.gd
│   └── special_buff_effect.gd
└── resources/               # 预设资源
    ├── damage_enhance_buff.tres
    ├── speed_reduce_buff.tres
    ├── poison_dot_buff.tres
    ├── invincible_buff.tres
    └── harvest_mark_buff.tres
```

## 🔄 事件系统

### FightEventBus信号
- `buff_applied(target, buff)`: buff应用事件
- `buff_removed(target, buff)`: buff移除事件
- `buff_triggered(target, buff, trigger_type)`: buff触发事件
- `buff_stacks_changed(target, buff, old_stacks, new_stacks)`: 层数变化事件

### 使用示例
```gdscript
# 监听buff应用事件
FightEventBus.buff_applied.connect(_on_buff_applied)

func _on_buff_applied(target: Actor, buff: BuffInstance):
    print("角色 %s 获得了buff: %s" % [target.name, buff.buff_resource.buff_name])
```

## 🎨 效果配置

### 属性修改配置
```gdscript
effect_values = {
    "damage_multiplier": 0.25,      # 伤害增加25%
    "speed_multiplier": -0.15,      # 速度减少15%
    "defense_multiplier": 0.1       # 防御增加10%
}
```

### 持续伤害配置
```gdscript
effect_values = {
    "damage_per_tick": 15,          # 每次伤害15点
    "damage_type": 5,               # 毒素伤害
    "tick_interval": 1.0            # 每秒触发一次
}
```

### 控制效果配置
```gdscript
effect_values = {
    "control_type": "invincible",   # 无敌效果
    "immunity_types": ["damage"]    # 免疫伤害
}
```

## 🔧 扩展开发

### 1. 添加新效果类型
继承BuffEffect基类，实现具体效果：
```gdscript
extends RefCounted
class_name CustomBuffEffect

func apply():
    # 应用效果逻辑
    pass

func remove():
    # 移除效果逻辑
    pass
```

### 2. 整合到装备系统
在装备中定义buff效果：
```gdscript
# 装备附带buff效果
equipment_resource.attached_buffs = [buff_resource]
```

### 3. 投射物施加buff
在投射物命中时应用buff：
```gdscript
func _on_hit(target: Actor):
    if attached_buff:
        target.get_buff_manager().add_buff(attached_buff, caster)
```

## 🐛 测试和调试

### 运行测试
```gdscript
# 添加测试脚本到场景
var test_script = preload("res://src/entities/buff/buff_test.gd")
var test_node = test_script.new()
get_tree().current_scene.add_child(test_node)
```

### 调试信息
系统会在控制台输出详细的调试信息，包括：
- buff应用和移除日志
- 效果触发记录
- 错误信息和警告

## 📊 性能优化

### 1. 对象池
频繁创建的buff实例使用对象池管理

### 2. 批量更新
将buff更新操作批量处理，减少逐个更新的开销

### 3. 事件优化
合理使用事件系统，避免过多的信号连接

## 🔄 后续计划

1. **装备系统整合**: 完成装备施加buff的机制
2. **投射物系统整合**: 实现投射物附带buff效果
3. **AI系统整合**: 敌人AI根据buff状态调整行为
4. **UI系统整合**: 显示buff图标和剩余时间
5. **保存系统**: 支持buff状态的保存和加载

## 📝 更新日志

### v1.0.0 (当前版本)
- ✅ 完成核心架构设计
- ✅ 实现基础buff管理功能
- ✅ 支持四种主要效果类型
- ✅ 集成事件系统
- ✅ 提供测试脚本
- ✅ 创建预设资源配置
- ✅ 整合Actor基类支持

系统已经可以投入使用，后续会根据需求继续完善和扩展功能。