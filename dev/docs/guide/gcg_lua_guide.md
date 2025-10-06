# GCG Lua 开发指南（中文）

> 本文整合并取代原有的 `galaxy_system_complete.md` 与 `lua_development_guide.md`，聚焦 Galaxy Card Game（GCG）在 YGOPro 引擎上的特殊规则及脚本习惯，帮助自动化工具与开发者快速产出合规的 Lua 脚本。

## 1. 快速入门

1. **脚本入口**：
   ```lua
   local s,id = Import()
   function s.initial(c)
       -- 在此编写卡片效应
   end
   ```
   - `Import()` 会自动把 `s.initial` 注册为卡片入口函数，并为单位卡注入 Galaxy 的全局规则。
   - 不再使用 YGO 时代的 `local s,id=GetID()` 或 `s.initial_effect`。

2. **参考原卡**：沿用 YGOPro 的成熟实现是最高优先级。拿到需求后先查 `dev/examples/script/c[原ID].lua`，再根据差异调整常量与调用。

3. **命名与常量**：优先使用 Galaxy 语义常量（`GALAXY_LOCATION_*`、`GALAXY_PHASE_*` 等），除极特殊情况外不要回退到 `LOCATION_MZONE`、`PHASE_DRAW` 等旧名。

## 2. GCG 与 YGO 的关键差异

| 范畴 | YGO 术语 | GCG 术语/行为 | 说明 |
| ---- | -------- | ------------- | ---- |
| 阶段 | Draw / Standby / Main1 / Battle / Main2 / End | 补给 / 战备 / 部署 / 交战 / 整备 / 休整 | 使用 `GALAXY_PHASE_*` 常量 |
| 卡区 | LOCATION_DECK / MZONE / SZONE / … | `GALAXY_LOCATION_BASIC_DECK` / `GALAXY_LOCATION_UNIT_ZONE` / … | 术语与 UI 一致 |
| 资源 | LP / 星级费用 | 补给（Supply），召唤成本=等级 | `Duel.CheckSupplyCost` / `Duel.PaySupplyCost` |
| 生命 | Attack / Defense | 攻击力 / 生命值（HP） | 守备值即当前 HP，使用 `Duel.AddHp` |
| 召唤 | 通常 + 特殊 | 仅特殊召唤，且必须表侧攻击 | 由 `Galaxy.UnitRule` 强制执行 |
| 战斗 | 破坏并扣 LP | 单位战斗只扣 HP；直击才扣 LP | `Galaxy.ReduceHP` 与 `EFFECT_AVOID_BATTLE_DAMAGE` |
| 陷阱 | 需盖放，发动受限制 | 均可手牌发动，仅能对方回合 | `Galaxy.TacticsRule` 全局处理 |
| 关键词 | 无 | Rush / Protect / Shield / Stealth / Lethal … | 自定义效果码，详见 §4 |

更多术语映射可查阅 `dev/docs/gcg_Glossary.md`。

## 3. Galaxy 核心系统

### 3.1 补给（Supply）系统
- **回合维护**：补给从 0/0 开始，每个补给阶段自动 +1 上限并回满，卡片可临时超上限，下回合自动钳制。
- **常用 API**：
  ```lua
  Duel.GetSupply(tp)           -- 当前补给
  Duel.GetMaxSupply(tp)        -- 补给上限
  Duel.SetSupply(tp, cur, max) -- 直接设置（慎用）
  Duel.AddSupply(tp, n)        -- 增加当前补给，可超过上限
  Duel.AddMaxSupply(tp, n)     -- 永久提升上限
  Duel.CheckSupplyCost(tp, n)  -- 是否支付得起
  Duel.PaySupplyCost(tp, n)    -- 扣除补给
  ```
- **费用写法模板**：
  ```lua
  function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
      if chk==0 then return Duel.CheckSupplyCost(tp,2) end
      Duel.PaySupplyCost(tp,2)
  end
  ```

### 3.2 单位与召唤规则
- `Galaxy.UnitRule(c)` 自动为所有单位卡注册：
  - 仅允许从手牌以表侧攻击形式特殊召唤。
  - 召唤时自动检查并扣除补给（默认成本=等级，可被 `EFFECT_FREE_DEPLOY` 置零）。
  - 攻击位锁定、战斗免破、护盾/隐身提示自动刷新。
- 不需要手动调用 `Galaxy.AddShieldDisplay` / `Galaxy.AddStealthDisplay`，系统会在单位入场时处理。

### 3.3 战斗与生命系统
- **HP=守备力**；单位的当前生命值通过守备力系统实现。
- **常用 API**：
  ```lua
  Duel.AddHp(card, value, reason)  -- 增减当前HP（会触发事件）
  Duel.SetHp(card, value)          -- 直接设置当前HP（不触发事件）
  Card.GetHp()                     -- 获取当前HP
  Card.GetMaxHp()                  -- 获取最大HP（含EFFECT_UPDATE_HP效果）
  ```
- **`Duel.AddHp(card, value, reason)`** 用于战斗/效果伤害或治疗：
  - `value`：HP变化量（负数为伤害，正数为治疗）。
  - `reason`：必须为 `REASON_BATTLE` 或 `REASON_EFFECT`。
  - 会自动处理护盾（首次伤害改为移除护盾）。
  - 对隐身单位造成伤害时移除隐身。
  - **触发 HP 事件**（见下）。
- **`Duel.SetHp(card, value)`** 用于直接设置HP（如复活、初始化）：
  - `value`：要设置的HP值（必须 ≥ 0）。
  - **不触发 HP 事件**，不处理护盾/隐身。
  - 自动钳制到最大HP范围。
  - 适用场景：复活效果、变身效果、初始化状态。
- **HP 事件常量**（位于 `script/constant.lua`）：
  - `GALAXY_EVENT_HP_DAMAGE`：立即伤害事件（ev 为绝对值）。
  - `GALAXY_EVENT_HP_RECOVER`：立即治疗事件。
  - `GALAXY_EVENT_HP_EFFECT_CHANGE`：EFFECT_UPDATE_HP 造成的数值改变。
- 自毁机制仍依赖 `EFFECT_SELF_DESTROY` 条件函数；避免直接 `Duel.Destroy` 处理战斗结算。

### 3.4 战斗与战术规则
- `Galaxy.PlayerRule` 与 `Galaxy.BattleRule` 会全局限制：
  - 召唤当回合不能攻击（除非拥有 `EFFECT_RUSH`）。
  - 怪兽对怪兽战斗不产生 LP 伤害。
  - 攻击目标优先选择拥有 `EFFECT_PROTECT` 但没有隐身的单位。
- `Galaxy.TacticsRule` 把所有战术（陷阱）改为对手回合从手牌发动，无需逐卡实现。

## 4. 自定义效果码与语义别名

| 效果码 | 功能 | 备注 |
| ------ | ---- | ---- |
| `EFFECT_RUSH (500)` | 部署回合即可攻击 | 解除全局攻击限制 |
| `EFFECT_PROTECT (501)` | 嘲讽：必须优先被攻击 | 与隐身互斥 |
| `EFFECT_SHIELD (502)` | 护盾：抵挡一次伤害 | 显示提示由系统控制 |
| `EFFECT_SHIELD_HINT (503)` | 护盾 UI 标记 | **勿**手动注册 |
| `EFFECT_FREE_DEPLOY (504)` | 召唤免补给 | 在召唤费用流程识别 |
| `EFFECT_UPDATE_HP (505)` | 持续增减 HP | 产生 `HP_EFFECT_CHANGE` 事件 |
| `EFFECT_LETHAL (506)` | 致命：战斗后无护盾即击杀 | 与护盾互动 |
| `EFFECT_STEALTH (507)` | 隐身：不可被选作目标 | 攻击/发动后移除 |
| `EFFECT_STEALTH_HINT (508)` | 隐身 UI 标记 | **勿**手动注册 |

语义化别名（在 `Card` 对象上）：
- HP 相关：`GetHp()`、`GetMaxHp()`、`GetBaseHp()`。
- 补给成本：`GetSupplyCost()`、`IsSupplyCostAbove(n)`。
- 特性与类别：`IsGalaxyProperty(prop)`、`IsGalaxyCategory(cat)`。

## 5. 常用脚本模式

### 5.1 单位技能示例
```lua
-- 单位：支付2补给破坏1张敌方支援/战术
local s,id = Import()
function s.initial(c)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(GALAXY_LOCATION_UNIT_ZONE)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
    e1:SetCost(s.cost)
    e1:SetTarget(s.tg)
    e1:SetOperation(s.op)
    c:RegisterEffect(e1)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckSupplyCost(tp,2) end
    Duel.PaySupplyCost(tp,2)
end

function s.tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsOnField() and chkc:IsType(GALAXY_TYPE_SUPPORT+GALAXY_TYPE_TACTICS) end
    if chk==0 then
        return Duel.IsExistingTarget(Card.IsType,tp,0,LOCATION_ONFIELD,1,nil,GALAXY_TYPE_SUPPORT+GALAXY_TYPE_TACTICS)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectTarget(tp,Card.IsType,tp,0,LOCATION_ONFIELD,1,1,nil,GALAXY_TYPE_SUPPORT+GALAXY_TYPE_TACTICS)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.op(e,tp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.Destroy(tc,REASON_EFFECT)
    end
end
```

### 5.2 HP 操作示例
```lua
-- 示例1: 使用 Duel.AddHp 造成伤害（会触发HP事件）
function s.damage_op(e,tp,eg,ep,ev,re,r,rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.AddHp(tc, -3, REASON_EFFECT)  -- 造成3点伤害，触发事件
    end
end

-- 示例2: 使用 Duel.SetHp 复活（不触发HP事件）
function s.revive_op(e,tp,eg,ep,ev,re,r,rp)
    local c = e:GetHandler()
    if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP_ATTACK)>0 then
        Duel.SetHp(c, 1)  -- 直接设置HP为1，不触发伤害事件
    end
end
```

### 5.3 HP 事件监听
```lua
-- 当对手单位扣血时，我方加1补给
local e=Effect.CreateEffect(c)
e:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
e:SetCode(GALAXY_EVENT_HP_DAMAGE)
e:SetRange(GALAXY_LOCATION_UNIT_ZONE)
e:SetCondition(function(e,tp,eg)
    return eg:IsExists(Card.IsControler,1,nil,1-tp)
end)
e:SetOperation(function(e,tp)
    Duel.AddSupply(tp,1)
end)
c:RegisterEffect(e)
```

### 5.4 支援/战术卡建议
- 激活前先判断目标是否存在。例如：
  ```lua
  function s.condition(e,tp)
      return Duel.IsExistingMatchingCard(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,nil,tp)
  end
  ```
- 激活后若需要给满血单位加最大生命值，请使用 `EFFECT_UPDATE_HP` 并设置合适的 reset（常见 `RESET_EVENT+RESETS_STANDARD`）。

### 5.5 禁止使用的旧模式
- `Duel.CheckLPCost` / `Duel.PayLPCost`：请改用补给接口。
- 手动 `Galaxy.CheckCost` / `Galaxy.PayCost`：相关函数已在代码中注释掉。
- 直接调用 `Galaxy.AddShieldDisplay(c)`/`Galaxy.RemoveShieldDisplay(c)`：真实签名为事件回调，且系统会自动处理 UI，手动调用会引发脚本错误。

## 6. 数据库查询（Duel.QueryDatabase）

GCG 允许脚本以只读方式查询 `cards.cdb`，用于随机检索或筛选卡片。使用规范：

```lua
local sql = [[
    SELECT id FROM datas
    WHERE type & %d ~= 0
    AND attribute = %d
    ORDER BY RANDOM()
    LIMIT 1
]]
local query = string.format(sql, GALAXY_TYPE_UNIT, GALAXY_PROPERTY_LEGION)
local rows = Duel.QueryDatabase(query)
if rows and not rows.error and #rows > 0 then
    local card_id = rows[1].id
    -- 执行后续逻辑
end
```

**安全限制**（由 `ocgcore/libduel.cpp` 强制）：
- 仅允许单条 `SELECT` 语句；含 `;`、`INSERT`、`UPDATE`、`DELETE`、`DROP`、`CREATE`、`ALTER`、`PRAGMA`、`ATTACH`、`--`、`/*` 等关键字会被拒绝。
- 失败时返回 `{ error = "..." }`，或直接 `nil`。
- 查询在 C++ 层以只读方式打开数据库，无需担心锁。

## 7. 调试与质量保证

1. **渐进式验证**：每实现一个效果就进游戏测试，观察补给与 HP 是否按预期结算。
2. **重点测试场景**：
   - 补给不足或超上限时效果是否阻止或钳制。
   - 护盾、隐身、致命效果的相互作用。
   - 潜在的手牌发动陷阱是否被限制在对手回合。
3. **保持语义一致**：所有提示文本与 UI 应使用 Galaxy 术语（单位/支援/战术、补给/生命等）。
4. **文档更新**：若发现新的常量或系统函数，请同步维护本指南，避免 AI 引用过时 API。

## 8. 相关资料
- 术语映射：`dev/docs/gcg_Glossary.md`
- 关键常量定义：`script/constant.lua`
- Galaxy 框架实现：`script/utility.lua`
- 示例卡脚本：`script/c10000000.lua` ~ `c10000102.lua`


