# 时间回声 (Temporal Echo)

**TriJam #358 参赛作品** - 一款具有时间回声机制的3小时GameJam游戏。

## 一句话介绍

> "发射你的时间回声——3秒后，过去的你从墙边反弹回来与你并肩作战。"

## 核心机制

玩家发射"时间回声"，这些回声不会立即与敌人互动。3秒后，玩家的幽灵出现在发射位置并发射同样的子弹，创造与当前玩家交叉火力的机会。

## 游戏循环

1. **瞄准射击** → 向墙壁射击设置反弹角度
2. **移动** → 为交叉火力时刻定位
3. **时间回声激活** → 3秒前的自己在过去位置开火
4. **协同打击** → 现在的你和过去的你同时射击敌人

## 技术栈

- **引擎**: Godot 4.6
- **语言**: GDScript
- **分辨率**: 800x600
- **目标帧率**: 60

## 项目结构

```
TemporalEcho/
├── openspec/              # OpenSpec 文档
│   └── changes/
│       └── core-gameplay/
│           ├── proposal.md       # 游戏概念
│           ├── specs/            # 需求规格
│           ├── design.md         # 技术架构
│           └── tasks.md          # 77个实施任务
├── src/                   # 源代码（待实现）
├── scenes/                # Godot 场景（待实现）
├── assets/                # 游戏资源（待实现）
└── project.godot          # Godot 项目文件
```

## 设计文档

- **[提案](openspec/changes/core-gameplay/proposal.md)** - 游戏概念与概述
- **[需求](openspec/changes/core-gameplay/specs/requirements.md)** - 详细规格说明
- **[设计](openspec/changes/core-gameplay/design.md)** - 技术架构
- **[任务](openspec/changes/core-gameplay/tasks.md)** - 77个实施任务与时间表

## 当前状态

⏳ **设计阶段** - 审查 OpenSpec 文档，准备实施

## 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE) 文件
