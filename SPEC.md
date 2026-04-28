# 仙侠卡牌肉鸽 · 技术方案 v0.1

> 基于 `xianxia-prototype/index.html` 原型逆向分析生成
> 文档版本：v0.1 | 日期：2026-04-29

---

## 一、项目概述

**项目名称**：凡人修仙 · 卡牌肉鸽（代号 xianxia-card-roguelike）
**类型**：单机卡牌肉鸽（Slay the Spire-like）网页游戏
**技术选型**：单文件 HTML（原型）→ 架构升级后可拆分
**目标平台**：PC 浏览器 / 微信小程序（未来）

---

## 二、技术架构

### 2.1 当前架构（原型）

```
index.html (单文件)
├── <style> 样式区块 (~100行 CSS)
├── <body> DOM 结构（各 Screen 的 div）
└── <script> 游戏逻辑 (~500行 Vanilla JS)
```

**特点**：
- 零依赖，无 npm/webpack
- 全局变量 `G` 承载所有状态
- DOM 直接操作，无渲染抽象层
- 事件绑定使用行内 onclick

### 2.2 架构升级方向（推荐）

```
src/
├── core/
│   ├── GameState.ts          # 状态机定义（TS）
│   ├── CombatSystem.ts       # 战斗计算逻辑
│   ├── CardSystem.ts         # 卡牌效果解析
│   ├── EnemyAI.ts            # 敌人意图系统
│   └── DungeonMap.ts         # 地图生成
├── data/
│   ├── cards.ts              # 卡牌静态配置
│   ├── enemies.ts            # 敌人配置
│   ├── dungeons.ts           # 地图节点配置
│   └── drugs.ts              # 丹药配置
├── ui/
│   ├── UIRenderer.ts         # DOM 渲染抽象
│   ├── CardView.ts           # 卡牌视图组件
│   └── BattleView.ts         # 战斗视图
├── Game.ts                   # 主循环/状态机入口
└── main.ts                   # 入口
```

---

## 三、核心系统详解

### 3.1 卡牌系统

#### 卡牌数据结构

```typescript
interface Card {
  id: number;           // 全局唯一 ID
  name: string;         // 名称
  type: 'atk' | 'def' | 'skill';  // 攻击/防御/功法
  cost: number;        // 灵力消耗
  // 效果字段
  dmg: number;         // 伤害
  blk: number;         // 格挡
  burn: number;        // 灼烧
  poison: number;      // 中毒
  draw: number;        // 抽牌数
  heal: number;        // 治疗
  el: Element;         // 元素属性
  desc: string;        // 显示描述
  // 特殊效果
  spFire: number;      // 火牌灵力加成
  blkPerFire: number;  // 每火牌格挡
  nextAtk: number;     // 下次攻击加成
  upgraded: boolean;   // 是否已升级
  origName?: string;   // 升级前名称
}
```

#### 元素系统

| 元素 | CSS Class | 属性色 | 说明 |
|------|-----------|--------|------|
| 火 (fire) | card-fire | #e74c3c | 主动进攻，关联灼烧 |
| 木 (wood) | card-wood | #27ae60 | 治疗/格挡 |
| 土 (earth) | card-earth | #f39c12 | 防御为主 |
| 水 (water) | card-water | #3498db | 控制/抽牌 |
| 无 (none) | card-none | #9b59b6 | 中立功法 |

#### 卡池结构

| 稀有度 | 来源 | 示例 |
|--------|------|------|
| 初始牌组 | 固定构筑 | 火鸦×4, 灵草护体×3, 丹火引燃×2, 药炉感悟×1 |
| 白色奖励 | 普通战斗后 | 火蛇符, 土刺符, 木藤符, 灵盾符, 淬火术, 灵气运转 |
| 绿色奖励 | 普通战斗后 | 三昧真火, 丹火淬体, 炼丹手记, 火鸦变, 毒雾符, 以毒攻毒 |
| 蓝色奖励 | 精英战斗后 | 炼狱火海, 丹意凝形, 噬魂毒, 百草护元 |
| 移除奖励 | 精英/精炼 | 可选择从牌组/弃牌堆移除卡牌 |

---

### 3.2 战斗系统

#### 战斗流程

```
startFight() / startBoss()
  → initEnemy()           初始化敌人
  → shuffleIntoDeck()     洗牌
  → startTurn()           开始回合
      → drawCard()×5      抽5张
      → showIntent()      显示敌人意图
      → updateUI()        渲染手牌
  → [玩家出牌] → _playCard() → 结算效果
  → endPlayerTurn()       结束回合
      → 灼烧/中毒 tick    状态伤害结算
      → 敌人行动          意图结算
      → 毒虫 tick
      → G.intIdx++        意图轮换
  → [死亡检查] → 击败 → showCardSelect() / 胜利
```

#### 伤害计算顺序

```
总伤害 = 基础伤害 + fireCrowBonus + nextAtk + danYiStacks
     ↓
格挡减免：actualDmg = 总伤害 - min(格挡, 总伤害)
     ↓
应用到目标 HP
```

#### 状态效果

| 状态 | 触发时机 | 效果 |
|------|----------|------|
| 灼烧 (burn) | 回合**结束**（玩家出牌后） | 减少对应层数 HP，层数-1 |
| 中毒 (poison) | 回合**结束**（敌人行动后） | 减少对应层数 HP，层数-1 |
| 格挡 (block) | 回合**开始**清零 | 抵挡伤害，由 blkPerFire 等赋予 |
| 下次攻击加成 (nextAtk) | 攻击时清零 | 叠加在伤害上 |
| 火牌计数 (firePlayed) | 回合**开始**清零 | 用于 blkPerFire 等计算 |

#### 连击系统 (Combo)

触发条件：同一张牌在同一个**玩家回合**内打出**≥2次**
- 第2次打出：显示 `🔥2连击!` 弹出动画
- 第3次打出：额外 +2 灼烧（火鸦）
- 第N次打出：N越大特效越强

---

### 3.3 敌人 AI 系统

#### 意图机制（Intent-Based AI）

每个敌人持有一个**意图循环数组** `intents[]`，按顺序轮换。

示例意图对象：
```typescript
{
  n: '撕咬',           // 名称
  ic: '⚔️',            // 图标
  d: 6,                // 伤害值（0表示无伤害）
  blk: 0,              // 获得的格挡
  lsteal: 0,           // 生命偷取比例
}
```

#### 精英/首领机制

- **狂暴触发**：当 HP 低于 `enrageBelow` 时，`intents` 切换为 `rageIntents`，伤害 +`enrageBonus`
- **狂暴线**：首领 HP 降至 30% 时触发
- **多目标**：蝠群类敌人有第二个 HP 条，共享 intent

#### 敌人分类

| 类型 | HP 范围 | 意图池大小 | 特殊机制 |
|------|---------|-----------|----------|
| 普通 | 22~30 (按进度缩放) | 3~4 | 无 |
| 精英 | 45~60 (按进度缩放) | 4 | 狂暴 / 产卵 |
| Boss | 65~75 | 4+4(狂暴) | 狂暴转换 |

---

### 3.4 地牢地图系统

#### 地图结构

```
节点序列 (12 nodes):
[F] → [F] → [R] → [F] → [F] → [E] → [F] → [R] → [F] → [E] → [F] → [B]

标识含义：
F = 普通战斗  (Fight)
E = 精英战斗  (Elite)
R = 休整事件  (Rest)
B = Boss 首领
```

#### 节点内容

| 节点类型 | 后置奖励 |
|----------|----------|
| 普通战斗 | 3 选 1 卡牌（可跳过） |
| 精英战斗 | 4 选 1 卡牌 + 可移除 1 张 |
| 休整事件 | 休息/修炼/精炼三选一 |
| Boss | 通关结算 |

---

### 3.5 丹药系统

**总携带上限**：5 瓶

| 丹药 | 效果 | 上限 |
|------|------|------|
| 回春丹 | 回复 15 HP | 3 |
| 凝元丹 | 下次攻击 +3 | 2 |
| 护脉丹 | 获得 10 格挡 | 2 |

每场战斗**仅可使用一次**丹药。

---

### 3.6 升级/精炼系统

#### 升级 (Rest - 修炼)

强化效果（叠加）：
- 伤害 ×1.5
- 格挡 ×1.5
- 灼烧层 +1
- 中毒层 +2
- 抽牌数 +1
- 费用 -1（最低 0）

#### 精炼 (Rest - 精炼)

从**牌组+弃牌堆**中选择一张卡牌永久移除。

---

## 四、数据配置

### 4.1 卡牌池（POOL）

完整卡池共 22 张，详见 §3.1。

### 4.2 敌人配置

**普通敌人**（5 种）：
- 野狼妖 🐺 / 青蛇妖 🐍 / 藤妖 🌿 / 蝠群 🦇🦇 / 毒蟾 🐸

**精英敌人**（2 种）：
- 嗜血野猪妖 🐗（狂暴）
- 幽冥蛛后 🕸️（产卵召唤小蛛）

**Boss**：
- 巨蝠妖 🦇（30% 狂暴线）

### 4.3 地图配置

```javascript
const MAP = ['F','F','R','F','F','E','F','R','F','E','F','B'];
// 共12节点，双休息，双精英，Boss收尾
```

---

## 五、UI/渲染架构

### 5.1 屏幕（Screen）体系

| Screen ID | 用途 | 显示条件 |
|-----------|------|----------|
| title-screen | 标题/开始界面 | 游戏启动 |
| drug-screen | 丹药选择 | 开始后，进秘境前 |
| battle-screen | 战斗主界面 | 战斗中 |
| card-select-screen | 卡牌选择界面 | 战斗胜利后 |
| rest-screen | 休整界面 | 休整节点 |
| end-screen | 结算界面 | 玩家死亡/通关 |

### 5.2 DOM 结构

```
body
├── #title-screen
├── #drug-screen
├── #battle-screen
│   ├── #progress-bar       顶部路线图
│   ├── #enemy-area        敌人区域
│   │   ├── .enemy-name
│   │   ├── .enemy-sprite
│   │   ├── .enemy-hp-bar + fill
│   │   ├── .enemy-hp-text
│   │   ├── .enemy-intent
│   │   └── .enemy-status
│   ├── #log-area          战斗日志
│   ├── #player-area
│   │   ├── #player-info   (HP条, 灵力, 格挡, 状态, 结束回合)
│   │   └── #hand-area     手牌区
│   └── #drug-bar          丹药快捷栏
├── #card-select-screen
├── #rest-screen
└── #end-screen
```

### 5.3 渲染策略

当前：全量 `innerHTML` 重建 → 性能一般
优化方向：
- 使用 `display:none` 切换 screen，不操作 innerHTML
- 手牌区使用差异更新（diffing）
- 引入 Web Component 或 Vue/React 组件化

---

## 六、特殊机制汇总

| 机制 | 触发条件 | 效果 |
|------|----------|------|
| 火鸦连击 | 同回合第2+次打出火鸦 | 额外灼烧层数 |
| 火鸦变 | 打出火鸦变 | 所有火鸦本局 +3 伤害（永久） |
| 丹意凝形 | 打出丹意凝形 | 每层 +1 攻击（永久叠加） |
| 百草护元 | 打出百草护元 | 每回合开始 +3 格挡（永久） |
| 药炉感悟 | 每火牌打出手牌 | 获得 2×火牌数 格挡 |
| 丹火引燃 | 打出时手牌有火牌 | +1 灵力 |
| 灵气运转 | 打出 | 抽2弃1 |
| 淬火术 | 打出 | 下次攻击 +4 |
| 以毒攻毒 | 打出 | 造成中毒层数伤害（上限15） |
| 炼狱火海 | AOE | 同时打击两个目标 |

---

## 七、待解决问题 / 技术债务

### 高优先级

1. **状态机重构**：`G` 全局变量 + 屏幕 show/hide 的隐式状态机难以扩展，建议迁移到 TS 状态机（XState 或自研）
2. **卡牌效果可扩展性**：当前特殊效果 hardcoded 在 `_playCard`，建议改为「效果标签 + 效果函数表」模式
3. **内存泄漏**：Combo 弹窗动画后 `setTimeout` 未做清理，大批量出牌可能堆积 timer

### 中优先级

4. **数值平衡**：敌人 HP 缩放系数 `1 + nodeIdx * 0.04` 偏线性，Boss 前期过于简单
5. **音效/震动**：当前无任何音效，可引入 Web Audio API
6. **移动端适配**：手牌布局在窄屏下会溢出
7. **存档系统**：刷新页面游戏进度丢失，需引入 localStorage

### 低优先级

8. **多人/联机**：当前纯单机，无网络需求
9. **微信小程序移植**：需重构 DOM 为 canvas 或使用 WeChat WebView
10. **AI 敌人**：可加入自动出牌 AI（玩家不想操作时）

---

## 八、附录

### 文件结构（目标）

```
xianxia-prototype/
├── index.html              # 单文件原型（当前）
├── SPEC.md                 # 本文档
├── src/                    # 重构后源码
│   ├── core/
│   ├── data/
│   ├── ui/
│   └── utils/
└── docs/                   # 其他文档
```

### 关键全局变量

| 变量 | 类型 | 用途 |
|------|------|------|
| `G` | object | 游戏全局状态 |
| `EL_C` | object | 元素→CSS类名映射 |
| `EL_N` | object | 元素→中文名映射 |
| `POOL` | array | 奖励卡牌工厂函数池 |
| `MAP` | array | 地牢节点序列 |
| `uid` | number | 卡牌 ID 自增器 |

---

*文档生成工具：OpenClaw | 源码分析：基于 index.html 静态分析*
