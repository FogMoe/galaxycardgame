# 效果/融合怪 0 星 & 魔陷等级化 兼容性评估

> **状态**: 技术可行性调研  
> **范围**: `ocgcore` C++ 引擎 + Lua 脚本生态

---

## 背景

- 有新增卡片需求：让效果怪兽、融合怪兽可以是 **0 星**。
- 同时，希望为 **魔法/陷阱卡补充等级** 信息，便于脚本或 UI 使用。
- 需要确认：是否只改数据库即可，还是必须动到底层 C++ 代码。

---

## 现状梳理

### 怪兽等级下限

- `card::get_level()` (`ocgcore/card.cpp:994-1023`) 取得最终等级后，会把所有 `< 1` 的值强制提升回 **1**。
- 多数依赖等级的逻辑都调用 `get_level()`；例如上级召唤可用 `operations.cpp:1693-1700`、仪式素材筛选 `field.cpp:1867-1897`、Lua API `Card.GetLevel` (`libcard.cpp:3710`)。
- Lua 的 `Card.AddMonsterAttribute` (`libcard.cpp:3460-3468`) 只有在传入 `level` 非 0 时才写入 `EFFECT_CHANGE_LEVEL`，为 0 时直接跳过。

### 魔陷等级读取

- `card::get_level()` 对非怪兽（且没有 `EFFECT_PRE_MONSTER`）的卡直接返回 **0**。
- `Card.GetOriginalLevel` (`libcard.cpp:525-532`) 会把 `data.level` 原样返回，只要没有被标记 `STATUS_NO_LEVEL`。
- 当前 UI/脚本中涉及等级的默认假设均针对怪兽，魔陷等级在数据库中即使填上也不会被 `get_level()` 暴露。

---

## 需求分析与兼容性

### 1. 效果/融合怪 0 星

| 问题点 | 现状表现 | 调整建议 |
| --- | --- | --- |
| 等级下限 | `get_level()` 把 `<1` 拉回 1 | 将 `<1` 修正为 `level = std::max(level, 0)` |
| 等级选择 | `Duel.AnnounceLevel` 默认 [1,12] | 需要允许脚本传入 0；最好放宽默认范围或在调用处显式提供 |
| 添加怪兽属性 | `Card.AddMonsterAttribute` 忽略 level=0 | 放宽条件，允许写入 0 星 |
| 仪式素材检查 | 要求 `get_level() > 0` | 若 0 星需要参与仪式素材，需放宽判断 |
| 其他依赖 | 上级召唤 / Xyz 等比较逻辑 | 逻辑基于 `<5/<7` 判断，兼容 0 星，无需额外修改 |

**结论**: 单靠数据库无法生效，必须调整 C++ 等级计算与若干脚本 API 才能稳定支持 0 星；兼容风险主要来自仪式素材与脚本默认值，需要补充测试。

### 2. 魔法/陷阱的等级

| 场景 | 现状 | 方案 |
| --- | --- | --- |
| 脚本读取 | `Card.GetLevel` 恒为 0 | 改用 `Card.GetOriginalLevel` 或新增专用 API |
| 底层逻辑 | 大量流程把“有等级”视为“是怪兽” | 直接让 `get_level()` 对魔陷返回非 0 会破坏既有假设 |
| 数据存储 | `card_data.level` 可记录任意值 | 在数据库填入等级即可被 `GetOriginalLevel` 或自定义 metadata 读取 |

**结论**: 若仅需元数据（如 UI 展示、脚本条件），无需改底层；改脚本去读取 `GetOriginalLevel` 即可。若想让魔陷参与基于等级的怪兽流程（上级、仪式等），需系统性审查所有“等级=怪兽”判定，改动范围大，风险高。

---

## 推荐方案

1. **0 星怪兽**  
   - 修改 `card::get_level()` 的下限逻辑，允许 0。  
   - 更新 `Card.AddMonsterAttribute` 以支持写入 0。  
   - 检查 `Duel.AnnounceLevel` 默认参数，确保脚本可以选 0。  
   - 视策划需求决定是否放宽仪式素材（`field::get_ritual_material`）中对 `>0` 的限制。  
   - 覆盖性测试：上级召唤、Xyz/Synchro/Ritual、脚本查询。

2. **魔陷等级**  
   - 数据层面：在 `cards.cdb` 中写入 `level` 即可。  
   - 使用侧：推荐脚本/UI 通过 `Card.GetOriginalLevel` 或 metadata 读取，避免触碰底层逻辑。  
   - 若未来需要“带等级的魔陷”参与怪兽流程，应另开专项设计文档和回归测试。

---

## 后续步骤

1. 与策划确认：  
   - 0 星怪兽是否能参与仪式等流程。  
   - 魔陷等级的使用场景（纯展示 vs. 参与规则）。
2. 落实 C++ 代码修改与 Lua API 调整，并补充单元/脚本测试。
3. 更新相关脚本和数据库，确保新数值被正确消费。
4. 提供 QA 用例，覆盖 0 星怪兽的常见召唤/调度场景以及魔陷等级读取。

---

## 参考源码

- `ocgcore/card.cpp:994-1023` (`card::get_level`)  
- `ocgcore/libcard.cpp:3459-3468` (`Card.AddMonsterAttribute`)  
- `ocgcore/libduel.cpp:4696-4739` (`Duel.AnnounceLevel`)  
- `ocgcore/field.cpp:1867-1897` (`field::get_ritual_material`)  
- `ocgcore/libcard.cpp:525-532` (`Card.GetOriginalLevel`)

