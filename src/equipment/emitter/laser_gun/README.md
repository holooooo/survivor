# 激光枪装备

## 概述

激光枪是基于fist装备实现的能量武器，向周围生命值最低的敌人发射直线激光柱。

## 特性

- **目标选择**: 自动瞄准攻击范围内生命值最低的敌人
- **攻击方式**: 直线长方形激光柱，同时攻击范围内所有敌人
- **持续伤害**: 激光柱存在0.5秒，每0.08秒造成5点能量伤害
- **视觉效果**: 青色激光束，带有外发光效果和闪烁动画
- **冷却时间**: 3秒

## 技术实现

### 文件结构
```
laser_gun/
├── emitter/
│   ├── laser_gun_equipment.gd        # 装备逻辑
│   └── laser_gun_equipment.tscn      # 装备场景
├── projectile/
│   ├── laser_gun_projectile.gd       # 投射物逻辑
│   └── laser_gun_projectile.tscn     # 投射物场景
├── laser_gun_equipment_resource.tres  # 装备资源配置
└── laser_gun_projectile_resource.tres # 投射物资源配置
```

### 核心特性

1. **激光束生成**: 使用ColorRect创建视觉效果，RectangleShape2D创建碰撞区域
2. **方向计算**: 基于最低生命值敌人位置计算激光方向
3. **持续伤害**: 通过定时器实现持续伤害机制
4. **视觉效果**: 主体激光+外发光+闪烁动画

### 配置参数

- **攻击范围**: 300像素
- **激光宽度**: 60像素  
- **基础伤害**: 5点/次
- **伤害间隔**: 0.08秒
- **生存时间**: 0.5秒
- **伤害类型**: 能量伤害

## 使用方法

激光枪可以通过装备管理器自动装备，或添加到战斗场景的默认装备列表中：

```gdscript
# 在装备管理器中添加激光枪
var laser_gun_resource = load("res://src/equipment/emitter/laser_gun/laser_gun_equipment_resource.tres")
equipment_manager.equip_item(laser_gun_resource)
```

## 扩展性

- 可通过修改投射物资源调整伤害、射程、持续时间等参数
- 支持通过mod系统进一步增强
- 可作为其他激光类武器的基础模板 