# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Chinese xianxia-themed card roguelike (Slay the Spire-like) built with **Godot 4** and **GDScript**. The core loop is: Hub cultivation → Dungeon run (card battles) → Materials → Stronger cultivation.

**Engine**: Godot 4 (not compiled separately - use the Godot editor to run)
**Target**: PC/Steam (web prototype exists at `index.html`)

---

## Architecture

### Autoload Singletons (defined in project.godot)

| Autoload | File | Purpose |
|----------|------|---------|
| `GameState` | `scripts/core/game_state.gd` | Global state + localStorage save/load |
| `CardsDB` | `scripts/core/card_system.gd` | Card data loading and queries |
| `CombatEngine` | `scripts/core/combat.gd` | Battle state machine and resolution |

### Core Systems

**Combat Flow** (`combat.gd`):
- `start_fight()` → `start_turn()` → player plays cards → `end_player_turn()` → enemy acts → repeat
- BattleState enum: `IDLE → PLAYER_TURN → ENEMY_TURN → FIGHT_END`

**Five Elements (五行)** - Each card has an `el` field:
- **Mutual Generation (相生)**: fire→earth (blk+2), earth→metal (dmg+2), metal→water (draw+1), water→wood (heal+3), wood→fire (burn+2)
- Implemented via `sheng_ready` Dictionary in GameState - marks persist until consumed

**Card Effects** (`card_system.gd`):
- Cards have `effects: {dmg, blk, burn, poison, draw, heal, nextAtk}`
- Condition cards check `player_hp`, `hand.size()`, etc. at play time
- Charge buffs stored in `G.charge_buffs` array

**Shen Tong (神通)** - 8 special abilities triggered by conditions:
- Priority: survival (niepan/bumie) → elemental (fentian/kuhuan/houtu) → combo (lingsheng/lianhuan/poxian)
- Each tracked via counters in `GameState` (e.g., `consecutive_fire_count`, `consecutive_same_cost_count`)

### Key State Structures

**Meta (permanent)** - `GameState`:
- `linggen` (fire/wood/earth/water/metal)
- `realm` (1-15 cultivation stage)
- `xiuwei`, materials (lingcao/kuangshi/yaodan)
- `equipped_daotong`, `equipped_shentong` arrays
- `gongfa_collection` - names of unlocked cards

**Run (dungeon run)** - `GameState`:
- `in_run`, `current_layer`, `deck`, `hp/max_hp`, `lingshi`
- `draw_pile`, `discard_pile`, `hand` arrays

---

## Data Files

| File | Purpose |
|------|---------|
| `scripts/data/cards.json` | 60 card definitions with effects, rarity, element |
| `scripts/data/enemies.json` | Enemy intent pools, HP ranges, special abilities |
| `scripts/data/daotong.json` | 6 cultivation path definitions |
| `scripts/data/narrative.json` | 仙人日志 (immortal journals) |

---

## Key Files by Feature

- **Battle**: `combat.gd` (engine), `battle_hud.gd` (UI)
- **Cards**: `card_system.gd` (data), `card_view.gd` (UI)
- **Map**: `map_gen.gd` (generation), `map_view.gd` (UI)
- **Enemy AI**: `enemy_ai.gd` - intent-based system, weighted random selection
- **Save/Load**: `game_state.gd` - dual-layer (meta + run), localStorage on web

---

## Godot-Specific Notes

- Scenes use `.tscn` format (text-based, Godot 4 format)
- Project config in `project.godot` with `[autoload]` section
- Web build uses JavaScriptBridge for localStorage
- Desktop build uses `user://` filesystem path

---

## Design Principles (from docs)

1. **70/30 Rule**: 70% combat power from deck building, 30% from cultivation
2. **Five Elements**: Fire/Wood/Earth/Water/Metal with 相生 (generation) mechanics - card order matters
3. **No 相克 (conquest)**: Only generation, to keep it approachable
4. **Progressive unlock**: Daotong and difficulty modes unlock through clears