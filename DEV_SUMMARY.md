# Temporal Echo - 开发总结

## 项目概述

**游戏名称**: Temporal Echo  
**类型**: 竞技场射击 + 时间回声机制  
**开发周期**: TriJam #358 (3天游戏jam)  
**引擎**: Godot 4.6  
**分辨率**: 800x600

## 核心机制

### 1. 时间回声系统 (Temporal Echo)
- 玩家发射子弹后，3秒后生成"回声"
- 回声会复制玩家3秒前的动作和射击
- 创造协同攻击的可能性

### 2. 子弹物理
- 速度: 400px/s，每次反弹+20%
- 最大3次反弹
- 颜色变化: 白→黄→橙→红

### 3. Boss AI
- 追击玩家 (80px/s)
- 接触伤害
- 10 HP

## 开发流程时间线

### Day 1 - 核心机制
- [x] 玩家移动和瞄准
- [x] 子弹发射和反弹
- [x] 基础墙壁碰撞
- [x] 子弹颜色变化

### Day 2 - 回声系统
- [x] 玩家历史记录系统
- [x] 回声生成逻辑
- [x] 回声子弹同步
- [x] 视觉效果

### Day 3 - 完整游戏循环
- [x] Boss AI 追击
- [x] 伤害系统
- [x] UI/HUD
- [x] 音效和BGM
- [x] 胜负条件
- [x] 标题画面

## 技术亮点

### 1. 历史记录系统
```gdscript
# 记录玩家每帧状态
func _record_history_with_shoot(did_shoot: bool):
    history[history_index] = {
        "pos": player.global_position,
        "rot": player.rotation,
        "shoot": did_shoot
    }
```

### 2. 回声生成
- 使用 `call_deferred` 避免循环引用
- 3秒延迟准确复现

### 3. AI 测试系统
- 使用 `Input.action_press()` 模拟玩家
- 状态机: IDLE → MOVE → AIM → SHOOT
- 添加随机噪声避免机械化

## 设计决策

### 为什么用 1-bit 风格？
- 时间紧迫，减少美术工作量
- 聚焦游戏机制本身
- 黑白对比强化"时间"主题

### 为什么选择回声机制？
- 契合 "Temporal" (时间) 主题
- 创造独特的策略维度
- 让玩家与"过去的自己"合作

## 遇到的挑战

### 1. 回声子弹不同步
**问题**: 回声生成时子弹位置偏移  
**解决**: 使用相对坐标而非绝对坐标

### 2. AI 射击检测不到
**问题**: `is_action_just_pressed` 一帧检测  
**解决**: AI 保持 aim 按下多一帧

### 3. 子弹反弹角度错误
**问题**: 镜面反射计算错误  
**解决**: `velocity = velocity.bounce(collision.get_normal())`

## 学到的经验

### 1. 快速原型
- 先用方块代替美术资源
- 核心机制优先， polish 最后

### 2. 调试工具
- 添加可视化调试 (轨迹预览)
- 日志系统帮助定位问题

### 3. AI 开发
- 使用 Input 模拟而非直接调用方法
- 添加随机噪声让 AI 更自然

## 游戏平衡

### 参数调整
| 参数 | 初值 | 最终值 | 原因 |
|------|------|--------|------|
| Boss速度 | 100px/s | 80px/s | 太快玩家无法逃脱 |
| 射击冷却 | 1.0s | 0.5s | 增加射击频率 |
| 安全距离 | 250px | 400px | AI需要更多空间 |
| 子弹反弹 | 2次 | 3次 | 增加策略性 |

## 代码结构

```
src/
├── player.gd          # 玩家控制器 + 历史记录
├── bullet.gd          # 子弹物理
├── echo.gd            # 回声逻辑
├── boss.gd            # Boss AI
├── ai_echo_test.gd    # AI测试系统
├── game_manager.gd    # 游戏状态
├── audio_manager.gd   # 音效管理
└── title_screen.gd    # 标题画面

scenes/
├── game.tscn          # 主游戏场景
├── player.tscn        # 玩家预制体
├── boss.tscn          # Boss预制体
├── bullet.tscn        # 子弹预制体
└── title_screen.tscn  # 标题画面
```

## 使用的工具

- **引擎**: Godot 4.6
- **音效**: MaouDamashii (免费素材)
- **代码**: VS Code + Godot Tools
- **版本控制**: Git + GitHub

## 最终评价

### 成功之处
✅ 核心机制实现完整  
✅ 回声系统独特有趣  
✅ AI 测试系统方便调试  
✅ 代码结构清晰

### 改进空间
🔧 美术可以更精致  
🔧 Boss AI 可以更多样化  
🔧 可以增加关卡设计  
🔧 难度曲线需要调整

## 给未来自己的建议

1. **Jam 开发要专注**: 3天内完成比完美更重要
2. **机制要验证**: 先做出可玩的原型
3. **保留调试工具**: AI 测试系统帮了大忙
4. **文档要即时**: 开发时记录比事后回忆更准确

## 相关链接

- GitHub: https://github.com/sdotyxz/temporal-echo
- GameJam: TriJam #358

---
*Developed by Banksia Studio (S + 灰)*
*2026-02-09*
