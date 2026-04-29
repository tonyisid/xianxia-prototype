# AI 美术规范 — 凡人修仙·卡牌肉鸽

> 版本：v1.0 | 日期：2026-04-30
> 风格定位：水墨国风 + 暗色游戏 UI

---

## 一、全局风格定义

### 1.1 核心风格词

```
Chinese ink wash painting, xianxia fantasy, dark moody atmosphere,
watercolor textures, traditional Chinese art style, muted colors,
gold accents, hand-painted feel, high detail, game card illustration
```

### 1.2 色彩规范

| 用途 | 色值 | 说明 |
|------|------|------|
| 背景 | `#0d0d1a` → `#1a1a2e` | 深紫黑渐变 |
| 主文字 | `#e0d5c1` | 暖米白 |
| 强调色 | `#d4a574` | 金铜色（按钮/标题/稀有度） |
| 火元素 | `#e74c3c` | 正红 |
| 木元素 | `#2ecc71` | 翠绿 |
| 土元素 | `#f39c12` | 琥珀 |
| 水元素 | `#3498db` | 冰蓝 |
| 金元素 | `#bdc3c7` | 银白 |
| 稀有度-白 | `#cccccc` | 灰白边框 |
| 稀有度-绿 | `#2ecc71` | 翠绿边框 |
| 稀有度-蓝 | `#3498db` | 冰蓝边框 |
| 稀有度-金(远景) | `#ffd700` | 金色边框 |

### 1.3 构图原则

- **卡牌**：竖版 280×400px，元素主体居中偏上，底部留白给文字
- **敌人**：正方形 256×256px，半身像/全身像，暗色背景
- **背景**：横版 1280×720px，大场景，低对比度，不抢前景
- **UI元素**：透明底 PNG，单色/渐变，矢量化优先

---

## 二、卡牌插画（120张）

### 2.1 Prompt 模板

```
[STYLE_PREFIX], a [CARD_SUBJECT], [ACTION/POSE], [ELEMENTAL_EFFECT],
ink wash texture background, Chinese fantasy card game illustration,
vertical composition, [COLOR_ACCENT] accent lighting,
detailed linework, muted tones, dark background
--ar 7:10 --s 750 --niji 6
```

### 2.2 变量表

| 变量 | 说明 | 示例 |
|------|------|------|
| STYLE_PREFIX | 固定风格前缀 | `Chinese ink wash painting, xianxia dark fantasy` |
| CARD_SUBJECT | 卡牌主题物 | `fire crow`, `flame serpent talisman`, `golden sword qi` |
| ACTION/POSE | 动作/姿态 | `diving attack`, `swirling around a hand`, `glowing in darkness` |
| ELEMENTAL_EFFECT | 元素特效 | `trailing flames`, `green poison mist`, `golden light rays` |
| COLOR_ACCENT | 主色调 | `red`, `green`, `amber`, `blue`, `silver` |

### 2.3 各元素 Prompt 示例

#### 🔥 火系

| 卡牌 | Prompt |
|------|--------|
| 火鸦 | `Chinese ink wash painting, a crow made of fire diving downward, trailing red flames, talisman paper texture, xianxia dark fantasy, vertical composition, red accent lighting, ink splatter background --ar 7:10` |
| 火蛇符 | `Chinese ink wash painting, a flaming serpent coiling around a yellow talisman, fire sparks, Chinese fantasy card game, red and gold accents, dark background --ar 7:10` |
| 火羽箭 | `Chinese ink wash painting, three burning feather arrows flying forward, flame trails, xianxia dark fantasy, vertical composition, warm red lighting --ar 7:10` |
| 三昧真火 | `Chinese ink wash painting, a massive three-colored fire lotus blooming, blue white and red flames intertwined, cosmic energy, xianxia dark fantasy, dramatic lighting --ar 7:10` |
| 炼狱火海 | `Chinese ink wash painting, apocalyptic sea of fire engulfing everything, molten ground, dark smoke clouds, xianxia dark fantasy, overwhelming red and orange --ar 7:10` |
| 火鸦变 | `Chinese ink wash painting, a person transforming into a giant fire crow, flames erupting from body, silhouette against full moon, xianxia dark fantasy --ar 7:10` |

#### 🌿 木系

| 卡牌 | Prompt |
|------|--------|
| 灵草护体 | `Chinese ink wash painting, glowing green vines wrapping around a person protectively, medicinal herbs floating, xianxia dark fantasy, green accent --ar 7:10` |
| 毒雾符 | `Chinese ink wash painting, a yellow talisman dissolving into toxic green mist, skull shapes in smoke, xianxia dark fantasy, sickly green glow --ar 7:10` |
| 回春术 | `Chinese ink wash painting, a glowing medicinal herb releasing green healing energy into a wounded hand, xianxia dark fantasy, soft green light --ar 7:10` |
| 以毒攻毒 | `Chinese ink wash painting, purple poison being converted into green healing light, yin yang transformation, xianxia dark fantasy, dual tone --ar 7:10` |
| 百草护元 | `Chinese ink wash painting, a hundred medicinal herbs forming a green shield dome, ancient Chinese pharmacy, xianxia dark fantasy, emerald glow --ar 7:10` |

#### ⛰️ 土系

| 卡牌 | Prompt |
|------|--------|
| 土刺符 | `Chinese ink wash painting, stone spikes erupting from ground, dust clouds, Chinese talisman floating above, xianxia dark fantasy, amber accent --ar 7:10` |
| 灵盾符 | `Chinese ink wash painting, a glowing amber stone shield with ancient runes, rocky texture, xianxia dark fantasy, warm golden light --ar 7:10` |
| 山崩诀 | `Chinese ink wash painting, a mountain splitting apart and crashing down, boulders flying, dust and amber energy, xianxia dark fantasy, dramatic scale --ar 7:10` |
| 大地守护 | `Chinese ink wash painting, earth golem forming a protective wall, amber crystal energy shield, xianxia dark fantasy, warm golden glow --ar 7:10` |

#### 💧 水系

| 卡牌 | Prompt |
|------|--------|
| 水波术 | `Chinese ink wash painting, a water blade cutting through air, ice crystals forming, blue ripples, xianxia dark fantasy, cool blue accent --ar 7:10` |
| 寒冰符 | `Chinese ink wash painting, a talisman encased in ice, frost spreading outward, frozen flowers, xianxia dark fantasy, icy blue glow --ar 7:10` |
| 玄冰诀 | `Chinese ink wash painting, ancient ice technique releasing frozen dragon breath, crystalline destruction, xianxia dark fantasy, deep blue --ar 7:10` |
| 水镜盾 | `Chinese ink wash painting, a mirror made of flowing water reflecting attacks, lotus patterns, xianxia dark fantasy, reflective blue --ar 7:10` |

#### ⚔️ 金系

| 卡牌 | Prompt |
|------|--------|
| 金光咒 | `Chinese ink wash painting, golden light explosion from clasped hands, metallic energy beams, xianxia dark fantasy, silver and gold accent --ar 7:10` |
| 穿甲符 | `Chinese ink wash painting, a glowing golden arrow piercing through stone armor, shattering effect, xianxia dark fantasy, sharp metallic light --ar 7:10` |
| 万剑归宗 | `Chinese ink wash painting, ten thousand flying swords converging in a massive formation, golden sword rain, xianxia dark fantasy, overwhelming silver light --ar 7:10` |

#### 无属性

| 卡牌 | Prompt |
|------|--------|
| 灵气运转 | `Chinese ink wash painting, spiritual energy flowing in circular patterns, yin yang balance, xianxia dark fantasy, purple mystical glow --ar 7:10` |
| 淬火术 | `Chinese ink wash painting, a weapon being tempered in mystical purple fire, sparks flying, xianxia dark fantasy, dual purple and orange --ar 7:10` |

### 2.4 升级版卡牌

升级版在同一 prompt 基础上追加：
```
, enhanced glowing aura, brighter [COLOR_ACCENT] effects, evolved form,
more detailed, power surge effect
```

### 2.5 蓄力型/条件型卡牌

蓄力型卡牌添加：
```
, charging energy effect, concentric rings of power,
building force visualization
```

条件型卡牌添加：
```
, conditional trigger effect, split composition showing
before and after activation
```

---

## 三、敌人立绘（8种）

### 3.1 Prompt 模板

```
Chinese ink wash painting, [ENEMY_NAME], [APPEARANCE],
[POSE/ACTION], dark xianxia atmosphere,
square composition, muted colors, game enemy portrait
--ar 1:1 --s 750 --niji 6
```

### 3.2 各敌人 Prompt

| 敌人 | Prompt |
|------|--------|
| 🐺 野狼妖 | `Chinese ink wash painting, a demonic wolf with glowing red eyes, dark fur, snarling pose, ghostly mist around paws, xianxia dark fantasy, square composition, ink splatter background` |
| 🐍 青蛇妖 | `Chinese ink wash painting, a giant green snake demon, shedding skin effect, coiled aggressive pose, fangs bared, toxic green mist, xianxia dark fantasy, square composition` |
| 🌿 藤妖 | `Chinese ink wash painting, a tree demon made of twisted vines, human-like face in bark, extending thorny tendrils, xianxia dark fantasy, green and brown tones, square composition` |
| 🦇 蝠群 | `Chinese ink wash painting, a swarm of bats forming a menacing cloud, red eyes glowing in darkness, moonlit sky, xianxia dark fantasy, square composition` |
| 🐸 毒蟾 | `Chinese ink wash painting, a massive poisonous toad demon, warty skin with toxic green glow, sitting in swamp, purple poison dripping, xianxia dark fantasy, square composition` |
| 🐗 嗜血野猪妖 | `Chinese ink wash painting, a berserk demonic boar, blood-stained tusks, rage red aura, charging pose, xianxia dark fantasy, square composition, dramatic red lighting` |
| 🕸️ 幽冥蛛后 | `Chinese ink wash painting, a ghostly spider queen, half human half spider, pale white face, dark web throne, ghostly blue eyes, xianxia dark fantasy, square composition, eerie` |
| 🦇 巨蝠妖(Boss) | `Chinese ink wash painting, a colossal bat demon lord, faceless head with shifting features, enormous wings spread wide, dark nether valley background, boss presence, xianxia dark fantasy, square composition, dramatic scale` |

### 3.3 小蛛（召唤物）

`Chinese ink wash painting, a small ghost spider, translucent body, pale blue glow, simple cute menacing, xianxia dark fantasy, square composition`

---

## 四、背景（4张）

| 场景 | 尺寸 | Prompt |
|------|------|--------|
| 洞府 | 1280×720 | `Chinese ink wash painting, a hermit cave dwelling, meditation mat, incense burner, glowing crystals on walls, peaceful misty mountain view through cave entrance, xianxia dark fantasy, horizontal, soft warm lighting` |
| 战斗背景 | 1280×720 | `Chinese ink wash painting, dark misty valley with twisted trees, ghostly light filtering through fog, ancient ruins in distance, xianxia dark fantasy, horizontal, moody atmosphere` |
| Boss背景 | 1280×720 | `Chinese ink wash painting, a dark underground cavern with giant stalactites, blood-red moon visible through crack, ancient seals glowing on walls, xianxia dark fantasy, horizontal, ominous` |
| 休整点 | 1280×720 | `Chinese ink wash painting, a small campfire in a rocky alcove, warm glow in darkness, meditation cushions, herbs drying on a line, xianxia dark fantasy, horizontal, cozy and warm` |

---

## 五、UI 框架元素

### 5.1 按钮样式

```
圆角矩形, 深色背景(#2a2a3e), 金铜色边框(#d4a574),
hover 时边框发光 box-shadow: 0 0 15px rgba(212,165,116,0.4)
```

### 5.2 HP/灵力条

- HP 条：红色→暗红渐变, 圆角 6px
- 灵力条：紫色→暗紫渐变 (#9b59b6→#8e44ad)
- 敌人 HP 条：暗红, 带骷髅图标

### 5.3 卡牌边框

| 稀有度 | 边框 | 发光 |
|--------|------|------|
| 白 | 1px #cccccc | 无 |
| 绿 | 2px #2ecc71 | 微光 |
| 蓝 | 2px #3498db + 内发光 | 蓝光 |
| 金(远景) | 3px #ffd700 + 外发光 | 金光 |

### 5.4 状态图标

| 状态 | 颜色 | 动画 |
|------|------|------|
| 灼烧 | 🔥 #e74c3c | 火焰粒子飘起 |
| 中毒 | ☠️ #2ecc71 | 绿色气泡 |
| 格挡 | 🛡️ #3498db | 蓝色光圈 |
| 蓄力 | 💫 #ffd700 | 金色旋转 |
| 暴击 | ⚡ #ffd700 | 金色闪光 |

---

## 六、特效（粒子/动画）

| 特效 | 实现方式 | 说明 |
|------|---------|------|
| 灼烧 | GPUParticles2D, 火焰贴图 | 橙红粒子上升, 大小随机 |
| 中毒 | GPUParticles2D, 气泡贴图 | 绿色气泡上浮 |
| 格挡 | Shader, 蓝色光罩 | 半透明蓝色半球 |
| 暴击 | Shader + GPUParticles2D | 金色闪光 + 屏幕震动 |
| 五行相生 | Line2D + 粒子 | 元素符号连线 + 光点流动 |
| 突破 | Shader + 全屏光柱 | 从下至上金色光柱 |
| 出牌动画 | Tween | 卡牌飞向目标(敌人/自身) |
| 受伤 | Shader + 屏幕震动 | 红色闪烁 + 震动 |

---

## 七、字体

| 用途 | 字体 | 备选 |
|------|------|------|
| 标题/按钮 | SimSun / STSong | Noto Serif CJK SC |
| 正文/描述 | SimSun / STSong | Noto Sans CJK SC |
| 数字(DMG) | 无衬线体 | Source Han Sans |

---

## 八、批量生产流程

### 8.1 Midjourney 批量命令

```bash
# 批量生成火系卡牌（10张）
for card in "fire crow" "flame serpent talisman" "fire feather arrow" \
  "ignition technique" "flame shield" "samadhi true fire" \
  "fire body forging" "flame explosion" "inferno sea" "fire intent";
do
  echo "Chinese ink wash painting, a ${card}, xianxia dark fantasy card illustration, red accent, vertical composition, ink texture background --ar 7:10 --s 750 --niji 6"
done
```

### 8.2 后处理流程

1. **筛选**：每张生成 4 选 1，标准：风格统一 + 元素清晰 + 文字空间充足
2. **裁切**：统一 280×400px（卡牌）/ 256×256（敌人）
3. **调色**：批量应用 LUT，统一色调到规范色板
4. **去瑕疵**：手动修掉 AI 生成的文字/多余元素
5. **命名**：`card_fire_01.png` / `card_fire_01_upg.png` / `enemy_wolf.png`

### 8.3 预估工时

| 资源 | 数量 | 生成 | 筛选+后处理 | 合计 |
|------|------|------|------------|------|
| 卡牌插画 | 120张 | 4h | 8h | 12h |
| 敌人立绘 | 9张 | 1h | 2h | 3h |
| 背景 | 4张 | 1h | 1h | 2h |
| UI素材 | 20+ | 2h | 2h | 4h |
| 特效素材 | 6种 | 2h | 3h | 5h |
| **合计** | | **10h** | **16h** | **~26h (3-4天)** |

---

## 九、质量标准

### 9.1 必须满足

- [ ] 风格统一（所有素材看起来属于同一个游戏）
- [ ] 元素符号可辨识（火鸦看起来像火鸦，不是普通鸟）
- [ ] 暗色背景下清晰可辨
- [ ] 卡牌底部 1/3 留白给文字描述
- [ ] 无 AI 生成文字/水印

### 9.2 加分项

- [ ] 元素特效有层次感（内焰/外焰）
- [ ] 敌人有独特轮廓（远处也能辨认）
- [ ] 背景有纵深感（前景/中景/远景）
- [ ] 特效帧率 ≥ 30fps

---

*AI 美术规范 v1.0 | 基于 DESIGN-MVP §13 | 配合 Midjourney Niji 6 / Stable Diffusion 生成*