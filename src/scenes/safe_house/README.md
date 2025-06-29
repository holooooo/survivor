# 安全屋系统

安全屋系统是游戏的局外培养核心功能，提供房间切换、游戏状态管理和各种培养功能的入口。

## 🏗️ 系统架构

```
安全屋系统
├── SafeHouse (主场景)
├── SafeHouseManager (房间管理器)
├── NavigationBar (导航栏组件)
└── 房间系统
    ├── MainRoom (主界面)
    ├── BattleRoom (作战室)
    ├── RecruitRoom (招募室)
    ├── UpgradeRoom (改造室)
    ├── ResearchRoom (研究室)
    └── BrandRoom (品牌室)
```

## 📁 文件结构

```
src/scenes/safe_house/
├── safe_house.tscn              # 主安全屋场景
├── safe_house.gd                # 主场景脚本
├── safe_house_manager.gd        # 房间管理器
├── components/
│   ├── navigation_bar.tscn      # 导航栏场景
│   └── navigation_bar.gd        # 导航栏脚本
├── rooms/                       # 各个房间
│   ├── main_room.tscn/gd        # 主房间
│   ├── battle_room.tscn/gd      # 作战室
│   ├── recruit_room.tscn/gd     # 招募室
│   ├── upgrade_room.tscn/gd     # 改造室
│   ├── research_room.tscn/gd    # 研究室
│   └── brand_room.tscn/gd       # 品牌室
└── test_safe_house.gd           # 测试脚本
```

## 🎮 功能特性

### 核心功能
- ✅ 房间切换系统
- ✅ 游戏周期管理（每次战斗算一周）
- ✅ 导航栏快速切换
- ✅ 主房间状态显示
- ✅ 房间预览功能

### 房间功能
- **主界面**: 显示游戏时间、周期和房间预览
- **作战室**: 选择角色和目的地，进入战斗（待实现）
- **招募室**: 招募、查看、开除角色（待实现）
- **改造室**: 改造角色能力（待实现）
- **研究室**: 研究新技术（待实现）
- **品牌室**: 品牌合作和通行证（待实现）

## 🚀 使用方法

### 1. 基本集成

在其他场景中切换到安全屋：

```gdscript
# 通过EventBus切换（推荐）
EventBus.change_scene_safely("res://src/scenes/safe_house/safe_house.tscn")

# 或直接切换
get_tree().change_scene_to_file("res://src/scenes/safe_house/safe_house.tscn")
```

### 2. 战斗完成后切换

在战斗场景中，战斗结束时：

```gdscript
# 发送战斗完成信号（会自动增加游戏周期）
EventBus.battle_completed.emit()

# 然后切换到安全屋
EventBus.change_scene_safely("res://src/scenes/safe_house/safe_house.tscn")
```

### 3. 测试系统

使用测试脚本验证功能：

```gdscript
# 创建测试节点
var tester = preload("res://src/scenes/safe_house/test_safe_house.gd").new()
add_child(tester)

# 或手动切换到安全屋
tester.switch_to_safe_house()
```

## 🔧 扩展开发

### 添加新房间

1. 创建房间脚本（继承Control）
2. 实现 `on_room_activated()` 方法
3. 在 `SafeHouseManager.RoomType` 枚举中添加新类型
4. 更新场景文件和导航栏

### 房间通信

各房间通过SafeHouseManager进行通信：

```gdscript
# 获取管理器引用
var manager = get_parent().get_node("SafeHouseManager")

# 切换到其他房间
manager.switch_to_room(SafeHouseManager.RoomType.BATTLE)

# 获取游戏周期
var week = manager.get_game_week()
```

## 📋 待实现功能

1. **作战室完整功能**
   - 角色选择界面
   - 目的地选择
   - 装备配置
   - 战斗参数设置

2. **招募室功能**
   - 角色列表显示
   - 招募系统
   - 角色管理

3. **改造室功能**
   - 角色属性升级
   - 装备强化
   - 技能学习

4. **研究室功能**
   - 科技树
   - 研究进度
   - 解锁新功能

5. **品牌室功能**
   - 品牌列表
   - 合作协议
   - 通行证系统

## 🐛 故障排除

### 常见问题

1. **房间切换失败**
   - 检查场景文件路径是否正确
   - 确认SafeHouseManager正确初始化

2. **导航栏按钮无响应**
   - 确认信号连接正确
   - 检查节点路径引用

3. **游戏周期不更新**
   - 确认EventBus.battle_completed信号正确发送
   - 检查SafeHouseManager是否连接信号

### 调试方法

启用详细日志查看系统状态：

```gdscript
# 在安全屋场景的_ready()中添加
print("当前房间: ", safe_house_manager.get_current_room())
print("游戏周期: ", safe_house_manager.get_game_week())
```

## 📝 更新日志

### v1.0.0 (当前版本)
- ✅ 完成基础房间切换系统
- ✅ 实现导航栏组件
- ✅ 添加游戏周期管理
- ✅ 创建所有房间基础结构
- ✅ 集成EventBus通信 