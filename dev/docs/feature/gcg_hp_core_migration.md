# Galaxy HP 核心化方案（设计草案）

> 目的：将当前由 Lua 层模拟的 HP 机制迁移至 C++ 内核，实现与 ATK 同步的即时更新，并简化脚本逻辑。

## 背景问题

- 现状通过 `Galaxy.CalculateHp` 在 `EVENT_ADJUST` 中处理 HP，所有 `Duel.AddHp` 调用先写入 Flag，等到下一次 Adjust 才真正更新守备值。
- 由于 HP 更新晚于 ATK，Lua 脚本在同一时点读取 `GetHp()` 会得到旧值，需要额外监听或冗余判断，容易出错。
- 护盾、隐身、致命等效果的处理散落在 Lua 中，维护成本高。

## 核心改动概览

1. **卡片字段**
   - 在 `Card` 结构新增 `current_hp` / `max_hp`（或重用 DEF 但内部统一管理）。
   - 初始化时同步 `current_hp = max_hp = base_hp`。

2. **Duel API**
   - 在 C++ 实现 `Duel::AddHp(Card*, int32 value, int32 reason, int32 effect_player)`：
     - 支持护盾拦截、隐身移除。
     - HP 改变后立刻更新 `current_hp`，并在 HP ≤ 0 时调用 `Destroy`.
     - 调用统一事件分发函数（见下文）。
   - `Duel::SetHp(Card*, int32 value)`：直接设置当前 HP，钳制范围 0~max，不触发伤害事件。
   - Lua 层 `Duel.AddHp/SetHp` 仅做调用转发。

3. **HP 事件分发**
   - 在 C++ 侧新增 `Duel::RaiseHpEvent(Card*, int32 diff, bool is_effect_change, int32 reason, int32 responsible_player)`。
   - `AddHp/SetHp` 中在 HP 实际变化时调用：
     - `diff > 0` -> `GALAXY_EVENT_HP_RECOVER`
     - `diff < 0` -> `GALAXY_EVENT_HP_DAMAGE`
     - 持续效果调整 -> `GALAXY_EVENT_HP_EFFECT_CHANGE`
   - `ev` 为 `abs(diff)`；通过 `raise_event` 与 `raise_single_event` 同步抛给 Lua。
   - 事件后立即触发 `AdjustInstantly`，保持场面同步。

4. **护盾与隐身**
   - 在 HP 处理中检查 `EFFECT_SHIELD`，首次伤害改为移除护盾并终止伤害。
   - 受伤时移除 `EFFECT_STEALTH`。
   - UI 提示依旧由 Lua 的展示函数维护，但不再额外触发事件。

5. **持续效果（EFFECT_UPDATE_HP）**
   - 核心维护 `max_hp = base_hp + Σ效果`，当效果变化时即时调整 max、current。
   - 若当前 HP 超出新上限则下调，并触发 `GALAXY_EVENT_HP_EFFECT_CHANGE`。
   - Lua 中原有的 `Galaxy.CalculateHp` 仅保留用于注册持续效果或辅助 UI 的细节，删除 Flag 累积逻辑。

6. **兼容性处理**
   - 所有 Lua 文件保持 `Card:GetHp()`、`GetMaxHp()` 接口不变。
   - 需要验证录像 / 存档是否需要新增字段序列化。
   - 文档（如 `gcg_lua_guide.md`）更新说明 HP 现为内核即时数值。

## 测试清单

- 单体受伤、治疗、护盾挡伤、隐身被破除。
- `EFFECT_UPDATE_HP` 叠加与移除，确认事件与数值同步。
- 多个单位同时结算的群体伤害（例如 `c80000004`）是否均能即时触发衍生物。
- 与 `c80000002` 等依赖 `GALAXY_EVENT_HP_DAMAGE` 的脚本兼容性。
- 回放 / 重连场景确保 HP 同步。

## 推进建议

1. 在独立分支实现上述 C++ 结构与 API，保持 Lua 接口签名不变。
2. 移除 Lua 中 `FLAG_ADD_HP_IMMEDIATELY_*`、`Galaxy.CalculateAddHpImmediately` 等过时代码，替换为直接调用核心。
3. 更新开发文档，并通知脚本编写者：HP 现为即时数值，无需再做延迟处理。
4. 完成核心合并前，继续保留此文档作为开发任务占位。完成后同步标记为已实现。

---

> 状态：设计稿，等待核心层实现。完成后请在此文档补充最终实现细节与版本信息。
