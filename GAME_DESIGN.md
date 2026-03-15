# 数字工厂 - 增量游戏策划案

## 一、游戏概述

**游戏名称**：数字工厂 (Number Factory)  
**游戏类型**：增量放置游戏 (Incremental / Idle Game)  
**核心玩法**：点击生成数字 → 加工数字 → 收集分数 → 自动化生产

---

## 二、核心系统设计

### 2.1 数字生成系统

**基础按钮**
- 点击后在按钮旁边生成一个数字对象
- 数字从按钮位置"弹出"，带有物理效果（重力下落、轻微弹跳）
- 基础生成数字：1

**数字对象属性**
| 属性 | 说明 |
|------|------|
| value | 数值（初始为1） |
| processed_level | 加工等级（0=原始，1=一次加工...） |
| can_drag | 是否可拖动 |
| position | 当前位置 |
| velocity | 物理速度（用于弹出效果） |

---

### 2.2 数字收集系统

**手动收集**
- 玩家可以拖动数字对象
- 将数字拖入分数面板区域时触发加分
- 加分公式：`score += value × (2 ^ processed_level)`

**传送带收集**
- 传送带面板自动吸附范围内的数字
- 使用Tween动画将数字平滑移动到分数面板
- 可配置传送速度和范围

**传送带配置**
```
传送带等级 | 吸附范围 | 移动速度 | 每秒处理量
    1     |  100px  |  0.5s   |    1个
    2     |  150px  |  0.3s   |    2个
    3     |  200px  |  0.2s   |    3个
```

---

### 2.3 数字加工厂系统

**加工厂按钮**（高级按钮）
- 需要放入数字才能激活
- 点击达到指定次数后完成加工
- 加工后数字的 `processed_level + 1`

**加工规则**
```
加工等级 | 所需点击次数 | 分数倍率 | 视觉效果
   0    |      3      |   ×1    | 白色数字
   1    |      5      |   ×2    | 绿色数字
   2    |      8      |   ×4    | 蓝色数字
   3    |     12      |   ×8    | 紫色数字
   4    |     18      |   ×16   | 金色数字
   5    |     25      |   ×32   | 彩虹数字
```

**加工厂类型**
| 类型 | 功能 | 解锁条件 |
|------|------|----------|
| 基础加工厂 | 数字+1加工等级 | 初始解锁 |
| 双倍加工厂 | 同时加工2个数字 | 累计100分 |
| 快速加工厂 | 点击次数需求-50% | 累计500分 |

---

### 2.4 自动点击系统

**自动点击面板**
- 放置在按钮上方区域
- 自动点击范围内的所有按钮
- 点击间隔可配置

**自动点击配置**
```
面板等级 | 点击间隔 | 范围大小 | 解锁费用
    1   |   2.0s   |  1个按钮 |   50分
    2   |   1.5s   |  2个按钮 |  200分
    3   |   1.0s   |  3个按钮 |  500分
    4   |   0.5s   |  5个按钮 | 1500分
    5   |   0.2s   |  全屏    | 5000分
```

---

## 三、UI布局设计

```
┌─────────────────────────────────────────────────────────┐
│  [分数面板]                                    分数: 0  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│    ┌─────────┐      ┌─────────┐      ┌─────────┐      │
│    │ 传送带  │ ───► │ 分数面板│      │ 自动点击│      │
│    │ 面板    │      │ (收集区)│      │ 面板    │      │
│    └─────────┘      └─────────┘      └─────────┘      │
│                                                         │
│         [数字弹出区域]                                  │
│              ↓                                          │
│    ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐                │
│    │按钮1│  │加工厂│  │加工厂│  │按钮2│                │
│    └─────┘  └─────┘  └─────┘  └─────┘                │
│              ↓          ↓                               │
│           [数字] [数字] [数字]                          │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  [升级商店]                                              │
│  □ 传送带 Lv.1 (50分)  □ 加工厂 Lv.1 (100分)            │
│  □ 自动点击 Lv.1 (50分) □ 新按钮 (200分)                │
└─────────────────────────────────────────────────────────┘
```

---

## 四、类结构设计

### 4.1 核心类

```
NumberObject (数字对象)
├── value: int                    # 数值
├── processed_level: int          # 加工等级
├── is_dragging: bool             # 是否被拖动
└── methods:
    ├── get_final_value()         # 获取最终分数值
    ├── process()                 # 执行加工
    └── tween_to(target)          # 移动动画

BaseButton (基础按钮)
├── number_prefab: PackedScene    # 数字预制体
├── spawn_position: Vector2       # 生成位置
└── methods:
    ├── on_click()                # 点击生成数字
    └── spawn_number()            # 实例化数字

ProcessingFactory (加工厂按钮)
├── numbers_inside: Array         # 内部数字列表
├── clicks_needed: int            # 所需点击次数
├── current_clicks: int           # 当前点击次数
└── methods:
    ├── insert_number(num)        # 放入数字
    ├── on_click()                # 点击加工
    └── complete_process()        # 完成加工弹出

ConveyorBelt (传送带面板)
├── range: float                  # 吸附范围
├── speed: float                  # 移动速度
├── target_panel: ScorePanel      # 目标分数面板
└── methods:
    ├── scan_numbers()            # 扫描范围内数字
    ├── absorb_number(num)        # 吸附数字
    └── transport_number(num)     # 传送数字

AutoClicker (自动点击面板)
├── interval: float               # 点击间隔
├── range: Rect2                  # 范围区域
├── target_buttons: Array         # 范围内按钮
└── methods:
    ├── scan_buttons()            # 扫描范围内按钮
    └── auto_click()              # 执行自动点击

ScorePanel (分数面板)
├── score: int                    # 当前分数
└── methods:
    ├── add_score(value)          # 加分
    └── check_unlockables()       # 检查解锁项

UpgradeShop (升级商店)
├── upgrades: Dictionary          # 升级项列表
└── methods:
    ├── purchase(upgrade_id)      # 购买升级
    └── apply_upgrade()           # 应用升级效果
```

---

## 五、开发计划（TDD方式）

### Phase 1: 核心数字系统
- [ ] NumberObject 类（可拖动、加工等级、分数计算）
- [ ] BaseButton 类（点击生成数字）
- [ ] ScorePanel 类（分数收集）

### Phase 2: 传送带系统
- [ ] ConveyorBelt 类（范围检测、吸附、Tween移动）
- [ ] 与 ScorePanel 集成

### Phase 3: 加工厂系统
- [ ] ProcessingFactory 类（放入数字、点击加工、分数倍率）
- [ ] 加工等级视觉效果

### Phase 4: 自动化系统
- [ ] AutoClicker 类（范围扫描、自动点击）
- [ ] 升级系统

### Phase 5: 完善
- [ ] UpgradeShop 升级商店
- [ ] 存档系统
- [ ] 音效与特效

---

## 六、数值平衡

### 收益曲线
```
阶段  | 目标分数    | 预计时间 | 主要玩法
------|------------|---------|----------
初期  | 0 - 500    | 5分钟   | 手动点击
早期  | 500 - 2000 | 10分钟  | 传送带 + 加工厂
中期  | 2000 - 1万 | 20分钟  | 自动点击
后期  | 1万+       | 持续    | 全自动化
```

### 升级价格公式
```
price = base_price × (level ^ 1.5)
```

---

## 七、技术要点

### 7.1 拖动实现
```gdscript
func _gui_input(event):
    if event is InputEventMouseButton and event.pressed:
        _dragging = true
    elif event is InputEventMouseButton and not event.pressed:
        _dragging = false
        _check_drop_zone()
    elif event is InputEventMouseMotion and _dragging:
        global_position = get_global_mouse_position()
```

### 7.2 Tween动画
```gdscript
func tween_to(target_pos: Vector2, duration: float):
    var tween = create_tween()
    tween.tween_property(self, "global_position", target_pos, duration)
    tween.tween_callback(func(): _on_tween_complete())
```

### 7.3 范围检测
```gdscript
func scan_numbers() -> Array:
    var numbers = []
    for num in get_tree().get_nodes_in_group("numbers"):
        if global_position.distance_to(num.global_position) <= range:
            numbers.append(num)
    return numbers
```

---

## 八、后续扩展

- **成就系统**：累计分数、加工次数等里程碑
- **离线收益**：根据自动点击器计算离线产出
- **排行榜**：全球分数排名
- **皮肤系统**：数字和按钮外观
- **特殊事件**：限时双倍分数等
