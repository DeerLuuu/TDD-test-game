# 数字工厂 - 增量游戏策划案

## 一、游戏概述

**游戏名称**：数字工厂 (Number Factory)
**游戏类型**：增量放置游戏 (Incremental / Idle Game)
**核心玩法**：点击生成数字 → 加工数字 → 收集分数 → 自动化生产

---

## 二、核心系统设计

### 2.1 数字生成系统

**加分按钮 (ScoreButton)**
- 点击后在按钮上方生成一个数字对象
- 数字弹出动画效果
- 基础生成数字：1
- 可在点击模式下点击，拖动模式下拖动

**数字对象 (NumberObject)**
| 属性 | 类型 | 说明 |
|------|------|------|
| value | int | 数值（初始为1） |
| processed_level | int | 加工等级（0=原始，1=一次加工...） |
| _is_dragging | bool | 是否被拖动 |

**加工等级视觉效果**
| 等级 | 分数倍率 | 数字颜色 |
|------|----------|----------|
| 0 | ×1 | 白色 |
| 1 | ×2 | 绿色 |
| 2 | ×4 | 蓝色 |
| 3 | ×8 | 紫色 |
| 4 | ×16 | 金色 |
| 5+ | ×32+ | 粉红色 |

**最终分数公式**：`score = value × (2 ^ processed_level)`

---

### 2.2 传送带系统 (ConveyorBelt)

**功能特性**
- 自动检测范围内的数字并按方向移动
- 支持四个方向：↑ ↓ ← →
- 拖动时可使用鼠标滚轮实时切换方向
- 点击模式下支持点击，拖动模式下支持拖动

**配置参数**
| 参数 | 默认值 | 说明 |
|------|--------|------|
| speed | 100 px/s | 移动速度 |
| direction | RIGHT | 初始方向 |

**传送带等级规划**
| 等级 | 移动速度 | 检测范围 | 解锁费用 |
|------|----------|----------|----------|
| 1 | 100 px/s | 面板大小 | 100分 |
| 2 | 150 px/s | +20% | 300分 |
| 3 | 200 px/s | +40% | 800分 |

---

### 2.3 加工面板系统 (ProcessPanel)

**功能特性**
- 自动检测范围内的数字并接收
- 点击达到指定次数后完成加工
- 加工完成后数字等级+1，移动到面板上方
- 支持等待队列，加工中新数字自动排队
- 可拖动取出正在加工的数字

**配置参数**
| 参数 | 默认值 | 说明 |
|------|--------|------|
| clicks_required | 3 | 所需点击次数 |
| output_offset | (0, -80) | 输出位置偏移 |

**加工等级配置**
| 当前等级 | 所需点击 | 加工后等级 |
|----------|----------|------------|
| 0 | 3 | 1 |
| 1 | 5 | 2 |
| 2 | 8 | 3 |
| 3 | 12 | 4 |
| 4 | 18 | 5 |

---

### 2.4 收集面板系统 (CollectPanel)

**功能特性**
- 一次性面板，收集范围内所有数字
- 数字先集中到面板中心，再一起飞向加分面板
- 发送完成后自动删除

**配置参数**
| 参数 | 默认值 | 说明 |
|------|--------|------|
| is_one_time | true | 是否为一次性 |

**收集动画**
1. 数字集中到面板中心（0.3s）
2. 短暂暂停（0.1s）
3. 一起飞向加分面板（0.5s）
4. 加分并删除面板

---

### 2.5 删除系统 (DeleteCursor)

**功能特性**
- 按C键切换删除模式
- 红色半透明光标跟随鼠标
- 悬停在物品上时自动调整为物品大小
- 点击删除物品，爆出随机数字（1-10，总价值不超过物品价值60%）

**删除模式快捷键**
| 快捷键 | 功能 |
|--------|------|
| Z | 切换到点击模式 |
| X | 切换到拖动模式 |
| C | 切换到删除模式 |

---

### 2.6 商店系统 (Shop)

**当前商品**
| 名称 | 价格 | 说明 |
|------|------|------|
| 加分按钮 | 50分 | 点击生成数字 |
| 传送带 | 100分 | 自动移动数字 |
| 收集面板 | 80分 | 一次性收集数字 |
| 加工面板 | 150分 | 加工提升数字等级 |

**购买流程**
1. 从商店拖出物品预览
2. 放置到场景中（网格对齐）
3. 检测位置是否被占用
4. 扣除分数，生成物品

---

### 2.7 相机系统 (GameCamera)

**功能特性**
- WASD移动相机
- +/- 缩放（0.5x ~ 3x）
- 平滑跟随和缩放

**配置参数**
| 参数 | 默认值 | 说明 |
|------|--------|------|
| move_speed | 600 px/s | 移动速度 |
| zoom_speed | 0.05 | 缩放速度 |
| min_zoom | 0.5 | 最小缩放 |
| max_zoom | 3.0 | 最大缩放 |

---

### 2.8 层级系统

**层级划分**
| 层级 | 用途 |
|------|------|
| Level1 | 背景层 |
| Level2 | 面板、按钮等静态物品 |
| Level3 | 数字等动态物品 |

---

## 三、自动化系统设计

### 3.1 自动传送带链

**概念**
多个传送带首尾相连，形成自动化传输线路。

**实现要点**
- 传送带自动将数字传递给下一个传送带
- 方向自动对齐
- 支持分支和合并

**设计配置**
```
传送带A → 传送带B → 加工面板 → 传送带C → 加分面板
```

---

### 3.2 自动点击面板 (AutoClicker) - 待实现

**功能设计**
- 放置在按钮上方区域
- 自动点击范围内的所有加分按钮
- 点击间隔可配置

**配置规划**
| 等级 | 点击间隔 | 范围大小 | 解锁费用 |
|------|----------|----------|----------|
| 1 | 2.0s | 1个按钮 | 200分 |
| 2 | 1.5s | 2个按钮 | 500分 |
| 3 | 1.0s | 3个按钮 | 1200分 |
| 4 | 0.5s | 5个按钮 | 3000分 |
| 5 | 0.2s | 全屏 | 8000分 |

---

### 3.3 智能加工流水线 - 待实现

**概念**
完整的自动化加工线路：
```
自动点击 → 数字生成 → 传送带 → 加工面板 → 传送带 → 加分面板
```

**组件连接规则**
1. 传送带出口对接加工面板入口
2. 加工面板出口对接传送带入口
3. 传送带出口对接加分面板

---

### 3.4 自动收集器 (AutoCollector) - 待实现

**功能设计**
- 持续收集范围内数字
- 可配置收集间隔
- 非一次性（与收集面板区别）

**配置规划**
| 等级 | 收集间隔 | 范围大小 | 解锁费用 |
|------|----------|----------|----------|
| 1 | 3.0s | 100px | 300分 |
| 2 | 2.0s | 150px | 800分 |
| 3 | 1.0s | 200px | 2000分 |

---

### 3.5 升级系统 - 待实现

**升级类型**
| 类型 | 效果 | 说明 |
|------|------|------|
| 速度升级 | 传送带/加工速度+20% | 提升自动化效率 |
| 范围升级 | 检测范围+20% | 扩大作用范围 |
| 倍率升级 | 分数倍率+10% | 提升收益 |
| 容量升级 | 队列容量+1 | 加工面板可排队更多 |

**升级价格公式**
```
price = base_price × (level ^ 1.5)
```

---

## 四、UI布局设计

```
┌──────────────────────────────────────────────────────────────┐
│  [商店面板]                                    分数: 0       │
│  模式: 点击 (Z/X/C切换)  方向: →                            │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐                       │
│  │加分  │ │传送带│ │收集  │ │加工  │                       │
│  │按钮  │ │      │ │面板  │ │面板  │                       │
│  │ 50分 │ │100分 │ │ 80分 │ │150分 │                       │
│  └──────┘ └──────┘ └──────┘ └──────┘                       │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│    ┌─────────┐      ┌─────────┐                            │
│    │ 传送带  │ ───► │ 加分面板│  (分数收集区)               │
│    │   →     │      │         │                            │
│    └─────────┘      └─────────┘                            │
│         ↑                                                   │
│    ┌─────────┐                                             │
│    │ 加工面板│  (加工后数字弹出)                           │
│    │  0/3    │                                             │
│    └─────────┘                                             │
│         ↑                                                   │
│    ┌─────────┐                                             │
│    │ 传送带  │ ───► ───►                                   │
│    │   →     │                                             │
│    └─────────┘                                             │
│         ↑                                                   │
│    ┌─────┐  ┌─────┐                                        │
│    │按钮 │  │按钮 │  (数字生成区)                          │
│    └─────┘  └─────┘                                        │
│        ↓        ↓                                           │
│     [数字]   [数字]                                         │
│                                                              │
│  [删除光标] - 红色预览框，点击删除物品                       │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│  WASD: 移动相机  +/-: 缩放  滚轮: 旋转传送带方向              │
└──────────────────────────────────────────────────────────────┘
```

---

## 五、类结构设计

### 5.1 已实现类

```
Global (单例)
├── OperationMode: enum { CLICK, DRAG, DELETE }
├── current_mode: OperationMode
├── drag_direction: Vector2
├── GRID_SIZE: int = 25
└── methods:
	├── snap_position_to_grid(pos)     # 网格对齐
	├── get_scaled_global_mouse_position(viewport)  # 考虑缩放的鼠标位置
	├── check_position_occupied(pos, size, exclude)  # 位置占用检测
	└── calculate_drop_values(total)   # 计算删除掉落数值

NumberObject (数字对象)
├── value: int
├── processed_level: int
├── _is_dragging: bool
└── methods:
	├── get_final_value()              # value × 2^processed_level
	├── process()                      # 加工等级+1
	├── _check_drop_zone()             # 检测放入区域
	└── _check_and_remove_from_process_panel()  # 从加工面板取出

ScoreButton (加分按钮)
├── number_scene: PackedScene
├── level_node_arr: Array[Node2D]
└── methods:
	├── _spawn_number()                # 生成数字
	├── _start_drag() / _end_drag()    # 拖动功能
	└── _apply_pop_animation(number)   # 弹出动画

ConveyorBelt (传送带)
├── speed: float = 100.0
├── direction: Vector2
├── numbers: Array[NumberObject]
└── methods:
	├── rotate_direction()             # 顺时针旋转
	├── rotate_direction_ccw()         # 逆时针旋转
	├── _detect_numbers()              # 检测范围内数字
	└── _move_numbers(delta)           # 移动数字

ProcessPanel (加工面板)
├── clicks_required: int = 3
├── output_offset: Vector2
├── current_number: NumberObject
├── current_clicks: int
├── processing: bool
├── waiting_queue: Array
└── methods:
	├── accept_number(number)          # 接收数字
	├── remove_number(number)          # 取出数字
	├── on_click()                     # 点击加工
	├── _auto_detect_numbers()         # 自动检测数字
	├── _complete_processing()         # 完成加工
	└── _process_next_in_queue()       # 处理队列下一个

CollectPanel (收集面板)
├── is_one_time: bool = true
├── collected_numbers: Array[NumberObject]
└── methods:
	├── collect_and_send()             # 收集并发送
	├── collect_numbers()              # 收集范围内数字
	├── play_collect_animation()       # 集中动画
	└── send_to_drop_zone()            # 发送到加分面板

DeleteCursor (删除光标)
├── _hovered_item: Control
└── methods:
	├── _update_position()             # 更新位置
	├── _update_size()                 # 更新大小
	├── _update_hovered_item()         # 更新悬停检测
	└── _delete_item(item)             # 删除物品

Shop (商店)
├── _items: Array
├── level_node_arr: Array[Node2D]
└── methods:
	├── add_item(item_data)            # 添加商品
	├── try_purchase(index)            # 尝试购买
	├── _spawn_purchased_item()        # 生成购买物品
	└── toggle_mode()                  # 切换模式

ShopItem (商店物品)
├── item_name: String
├── cost: int
├── scene_path: String
└── methods:
	├── can_afford(score)              # 检查是否买得起
	├── purchase(score)                # 执行购买
	└── _check_drag_out()              # 检测拖出商店

GameCamera (相机)
├── move_speed: float = 600.0
├── zoom_speed: float = 0.05
├── min_zoom: float = 0.5
├── max_zoom: float = 3.0
└── methods:
	├── zoom_in() / zoom_out()         # 缩放
	├── _handle_movement(delta)        # WASD移动
	└── _handle_zoom()                 # +/-缩放

ScoreDropZone (加分面板)
└── methods:
	└── on_number_dropped(number)      # 数字放入时加分
```

### 5.2 待实现类

```
AutoClicker (自动点击面板)
├── interval: float
├── range: Rect2
├── target_buttons: Array
└── methods:
	├── scan_buttons()                 # 扫描范围内按钮
	└── auto_click()                   # 执行自动点击

AutoCollector (自动收集器)
├── interval: float
├── range: float
└── methods:
	├── scan_numbers()                 # 扫描范围内数字
	└── collect_and_send()             # 收集并发送

UpgradeShop (升级商店)
├── upgrades: Dictionary
└── methods:
	├── purchase(upgrade_id)           # 购买升级
	└── apply_upgrade()                # 应用升级效果

SaveManager (存档管理)
└── methods:
	├── save_game()                    # 保存游戏
	├── load_game()                    # 加载游戏
	└── calculate_offline_profit()     # 计算离线收益
```

---

## 六、开发进度

### 已完成
- [x] NumberObject 类（可拖动、加工等级、分数计算、颜色变化）
- [x] ScoreButton 类（点击生成数字、拖动放置）
- [x] ScoreDropZone 类（分数收集）
- [x] ConveyorBelt 类（四方向、旋转、自动移动数字）
- [x] ProcessPanel 类（自动检测、点击加工、等待队列）
- [x] CollectPanel 类（一次性收集、动画效果）
- [x] DeleteCursor 类（删除模式、爆出数字）
- [x] Shop 类（购买物品、位置检测）
- [x] GameCamera 类（WASD移动、+/-缩放）
- [x] Global 单例（操作模式、网格对齐、坐标转换）
- [x] 层级系统（Level1/2/3）

### 待开发
- [ ] AutoClicker 类（自动点击按钮）
- [ ] AutoCollector 类（持续收集数字）
- [ ] 升级系统
- [ ] 传送带自动连接
- [ ] 存档系统
- [ ] 音效与特效
- [ ] 成就系统
- [ ] 离线收益

---

## 七、数值平衡

### 收益曲线
| 阶段 | 目标分数 | 预计时间 | 主要玩法 |
|------|----------|----------|----------|
| 初期 | 0 - 500 | 5分钟 | 手动点击、手动加分 |
| 早期 | 500 - 2000 | 10分钟 | 传送带、收集面板 |
| 中期 | 2000 - 1万 | 20分钟 | 加工面板、多条传送带 |
| 后期 | 1万 - 10万 | 60分钟 | 自动点击、流水线 |
| 终期 | 10万+ | 持续 | 全自动化、升级优化 |

### 物品价值
| 物品 | 基础价值 | 删除掉落 |
|------|----------|----------|
| 加分按钮 | 100 | 30-60分 |
| 传送带 | 100 | 30-60分 |
| 收集面板 | 80 | 24-48分 |
| 加工面板 | 150 | 45-90分 |

---

## 八、技术要点

### 8.1 网格对齐
```gdscript
static func snap_position_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		roundi(pos.x / GRID_SIZE) * GRID_SIZE,
		roundi(pos.y / GRID_SIZE) * GRID_SIZE
	)
```

### 8.2 相机缩放坐标转换
```gdscript
static func get_scaled_global_mouse_position(viewport: Viewport) -> Vector2:
	var mouse_pos = viewport.get_mouse_position()
	var canvas_transform = viewport.get_canvas_transform()
	return canvas_transform.affine_inverse() * mouse_pos
```

### 8.3 Tween动画
```gdscript
func _move_number_to_center(number: NumberObject) -> void:
	var target_pos = global_position + size / 2 - number.size / 2
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(number, "global_position", target_pos, 0.3)
```

### 8.4 范围检测
```gdscript
func _auto_detect_numbers() -> void:
	var panel_rect = Rect2(global_position, size)
	for number in get_tree().get_nodes_in_group("number_objects"):
		var number_center = number.global_position + number.size / 2
		if panel_rect.has_point(number_center):
			accept_number(number)
			return
```

### 8.5 预览禁用模式
```gdscript
func _ready() -> void:
	if has_meta("is_preview") and get_meta("is_preview"):
		return  # 预览状态不执行逻辑
```

---

## 九、后续扩展

### 9.1 短期目标
- 实现自动点击面板
- 实现升级系统
- 完善传送带自动连接

### 9.2 中期目标
- 存档系统
- 成就系统
- 离线收益

### 9.3 长期目标
- 排行榜
- 皮肤系统
- 特殊事件
- 多语言支持

---

## 十、快捷键一览

| 快捷键 | 功能 |
|--------|------|
| Z | 切换到点击模式 |
| X | 切换到拖动模式 |
| C | 切换到删除模式 |
| W/A/S/D | 移动相机 |
| + / = | 放大相机 |
| - / _ | 缩小相机 |
| 鼠标滚轮 | 旋转传送带方向（拖动时） |
