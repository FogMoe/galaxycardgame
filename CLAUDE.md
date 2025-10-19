# CLAUDE.md

为协助智能体在本仓库中高效、安全地开发，这份指南总结了 Galaxy Card Game（GCG）的核心信息、工作流程与注意事项。请务必先阅读再开展工作。

## 1. 项目速览
- 本仓库改造自 YGOPro，引擎使用 C++/Irrlicht，卡片效果通过 Lua 实现。
- 游戏规则已全面换装为 Galaxy 机制（补给=费用、HP=守备力等）。
- 主要关注点：`script/` 目录下的卡片脚本与 `dev/docs/` 中的开发文档。
- C++ 引擎分为 `ocgcore`（对局核心）和 `gframe`（客户端界面）两大模块。

## 2. 工作准则（务必遵守）
1. **不要尝试自行编译或启动客户端**：构建流程复杂，统一由用户负责。
2. **优先查阅官方示例**：修改脚本前参考 `dev/examples/script/` 和已存在的 `script/c[ID].lua`。
3. **引用最新文档**：所有 Galaxy 规则资料整合在 `dev/docs/guide/gcg_lua_guide.md`。
4. **保持命名一致**：代码和描述统一使用 Galaxy 术语与常量（`GALAXY_LOCATION_*`、`GALAXY_EVENT_*` 等）。
5. **操作谨慎**：避免改动与需求无关的资源；发现仓库已有脏改动时先与用户确认处理方式。

## 3. 常见任务：编写 / 修改 Lua 卡片脚本
按照下列步骤执行，可大幅降低出错率：

1. **理解需求**：收集卡片类型、补给成本、关键词效果、触发时点、目标等要素。
2. **寻找模板**：
   - 入口写法固定为 `local s,id = Import()` + `function s.initial(c)`。
   - 使用最新指南中的示例片段（章节 5.1～5.4）。
3. **实现效果**：
   - **补给成本**：使用 `Duel.CheckSupplyCost` / `Duel.PaySupplyCost`（推荐用于 cost 函数）。
   - **HP 变化**：
     - `Duel.AddHp(card, value, reason)` - 增减 HP，触发事件，处理护盾/隐身（用于战斗/效果伤害）
     - `Duel.SetHp(card, value)` - 直接设置 HP，不触发事件（用于复活/初始化）
   - **最大 HP 增益**：使用 `EFFECT_UPDATE_HP`（持续效果）。
   - Trap/战术卡的发动限制由系统全局处理，无需重复实现。
4. **条件与校验**：激活前先 `Duel.IsExistingMatchingCard` 或 `Duel.IsExistingTarget` 检查目标；缺少目标时拒绝发动。
5. **事件监听**：需要响应生命变化时使用 `GALAXY_EVENT_HP_DAMAGE` / `GALAXY_EVENT_HP_RECOVER` / `GALAXY_EVENT_HP_EFFECT_CHANGE`，注意 `eg`、`ev` 的含义。
6. **数据库查询**：
   - 仅允许单条 `SELECT` 语句，禁止包含 `;`、`INSERT`、`UPDATE` 等关键字。
   - 返回值需检查 `results` 是否为 `nil` 或存在 `results.error`。
7. **自测方法**：在回答中描述如何在游戏内验证（如召唤 / 触发路径、补给扣除、护盾交互等），用户据此执行实测。

## 4. Galaxy 关键机制速查

### 4.1 补给（Supply）系统
- **回合维护**：补给从 0/0 开始，每个补给阶段自动 +1 上限并回满。
- **召唤成本**：费用 = 卡等级，可通过 `EFFECT_FREE_DEPLOY` 免除。
- **API 选择**：
  - **`Duel.PaySupplyCost(tp, cost)`**（推荐）：
    - 规范的"支付成本"，用于卡片激活的 cost 函数
    - 拒绝 0 或负数（`cost <= 0` 时不执行）
    - 项目中所有 cost 函数均使用此 API
  - **`Duel.SpendSupply(tp, amount)`**：
    - 通用的"花费补给"，适用于效果操作中的灵活补给扣除
    - 允许任意值（包括 0 或负数），可接受浮点数
    - 使用场景：非 cost 的补给消耗（如"消耗全部补给"的效果）
- **其他 API**：`Duel.GetSupply`、`Duel.GetMaxSupply`、`Duel.AddSupply`、`Duel.AddMaxSupply` 等。

### 4.2 生命（HP）系统
- **HP = 守备力**：单位的当前生命值通过守备力系统实现。
- **战斗规则**：单位战斗只扣 HP，护盾抵挡首次伤害，隐身被打后移除。
- **API 选择**：
  - **`Duel.AddHp(card, value, reason)`**（推荐用于伤害/治疗）：
    - `value`：HP 变化量（负数为伤害，正数为治疗）
    - `reason`：必须为 `REASON_BATTLE` 或 `REASON_EFFECT`
    - **触发 HP 事件**（`GALAXY_EVENT_HP_DAMAGE` / `HP_RECOVER` / `HP_EFFECT_CHANGE`）
    - 自动处理护盾（首次伤害改为移除护盾）
    - 对隐身单位造成伤害时移除隐身
  - **`Duel.SetHp(card, value)`**（用于复活/初始化）：
    - `value`：要设置的 HP 值（必须 ≥ 0）
    - **不触发 HP 事件**，不处理护盾/隐身
    - 自动钳制到最大 HP 范围
    - 适用场景：复活效果、变身效果、初始化状态
- **其他 API**：`Card.GetHp()`、`Card.GetMaxHp()`、`EFFECT_UPDATE_HP`（持续增减最大 HP）。

### 4.3 关键词与全局规则
- **关键词效果码**：`EFFECT_RUSH`（速攻）、`EFFECT_PROTECT`（嘲讽）、`EFFECT_SHIELD`（护盾）、`EFFECT_STEALTH`（隐身）、`EFFECT_LETHAL`（致命）等，具体列表见 `script/constant.lua`。
- **全局规则**：
  - 所有单位自动注册召唤限制、护盾/隐身提示、战斗伤害改写等；无需重复编码。
  - 战术卡强制对方回合、可手牌发动；单位召唤回合默认不能攻击。

## 5. 参考资料

### 5.1 Lua 脚本开发
- **Galaxy Lua 指南**：`dev/docs/guide/gcg_lua_guide.md`（唯一权威文档，已涵盖流程、示例、常量说明）。
- **术语表**：`dev/docs/guide/gcg_Glossary.md`（术语映射与常量一览）。
- **API 速查**：`dev/luatips/tips.json`；常用片段在 `dev/luatips/snippets.json`。
- **完整常量定义**：`script/constant.lua`（所有 Galaxy 常量的定义）。
- **实战样例**：`script/` 与 `dev/examples/script/`（真实卡片脚本示例）。

### 5.2 C++ 引擎文档（供高级开发参考）
- **C++ 模块全景**：`dev/docs/engine/cpp_modules_overview_zh.md`（项目结构与依赖关系）。
- **ocgcore 引擎参考**：`dev/docs/engine/ocgcore_engine_reference_zh.md`（对局核心引擎详解）。
- **gframe 引擎参考**：`dev/docs/engine/gframe_engine_reference_zh.md`（客户端界面引擎详解）。
- **注意**：通常情况下无需修改 C++ 代码，仅在深入了解引擎机制时参考。

## 6. 构建与平台（仅供参考）
- 主构建系统为 Premake5，备用 CMake；具体参数见 `premake5.lua`。
- Windows 默认编译所有依赖；Linux/macOS 更依赖系统包。
- 如需为用户提供构建建议，仅提醒其使用 `premake5` 或 `cmake`，不要在自动化流程中尝试执行。

---

## 使用建议

1. **开发优先级**：Lua 脚本开发 > 了解引擎机制 > 修改 C++ 代码（极少需要）。
2. **问题排查**：
   - 规则或接口有疑问时，优先查阅 `dev/docs/guide/gcg_lua_guide.md`。
   - 需要了解底层实现时，参考 `dev/docs/engine/` 中的引擎文档。
   - 若仍不确定，请在回复中提出并等待用户确认，再做后续修改。
3. **代码风格**：遵循现有代码的命名和结构约定，保持一致性。
