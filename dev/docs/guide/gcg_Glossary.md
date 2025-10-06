# GCG 术语速查表

> 费用=能源=补给。本文帮助脚本和文档统一使用 Galaxy Card Game（GCG）的专用术语。

## 1. 常用术语映射

### 1.1 阶段
- 抽卡阶段 (Draw Phase, DP) → **补给阶段** (`GALAXY_PHASE_SUPPLY`)
- 准备阶段 (Standby Phase, SP) → **战备阶段** (`GALAXY_PHASE_PREPARATION`)
- 主要阶段 1 (Main Phase 1, M1) → **部署阶段** (`GALAXY_PHASE_DEPLOY`)
- 战斗阶段 (Battle Phase, BP) → **交战阶段** (`GALAXY_PHASE_COMBAT`)
- 主要阶段 2 (Main Phase 2, M2) → **整备阶段** (`GALAXY_PHASE_ORGANIZE`)
- 结束阶段 (End Phase, EP) → **休整阶段** (`GALAXY_PHASE_REST`)

### 1.2 卡片类型与区域
- 主卡组 → **基本卡组** (`GALAXY_LOCATION_BASIC_DECK`)
- 额外卡组 → **特殊卡组** (`GALAXY_LOCATION_SPECIAL_DECK`)
- 怪兽卡 → **单位** (`GALAXY_TYPE_UNIT`)
- 魔法卡 → **支援** (`GALAXY_TYPE_SUPPORT`)
- 陷阱卡 → **战术** (`GALAXY_TYPE_TACTICS`)
- 通常怪兽 → **一般单位**（仍使用 `TYPE_NORMAL`）
- 效果怪兽 → **部队** (`GALAXY_TYPE_FORCES`)
- 融合怪兽 → **大型单位** (`GALAXY_TYPE_LARGE`)
- 永续卡 → **设施** (`GALAXY_TYPE_FACILITY`)
- 场地卡 → **区域卡** (`GALAXY_TYPE_AREA`)
- 装备卡 → **强化** (`GALAXY_TYPE_ENHANCEMENT`)
- 速攻魔法 → **快速支援** (`GALAXY_TYPE_QUICK`)
- 反击陷阱 → **反制战术** (`GALAXY_TYPE_COUNTER`)
- 手牌区 → `GALAXY_LOCATION_HAND_CARDS`
- 单位区（原怪兽区）→ `GALAXY_LOCATION_UNIT_ZONE`
- 支援区（原魔陷区）→ `GALAXY_LOCATION_SUPPORT_ZONE`
- 弃牌区（原墓地）→ `GALAXY_LOCATION_DISCARD`
- 游戏外（原除外）→ `GALAXY_LOCATION_EXILED`

### 1.3 其他常见名词
- 特殊召唤 → **部署**
- 发动 → **使用**
- 指示物 → **标记**
- 衍生物 → **临时单位**
- LP → **影响力**（系统仍存在，但战斗伤害规则已调整）

## 2. Galaxy 常量一览
> 完整定义可在 `script/constant.lua` 中查阅。

### 2.1 特性（属性）
- `GALAXY_PROPERTY_LEGION` (ATTRIBUTE_EARTH) → **军团**
- `GALAXY_PROPERTY_FLEET` (ATTRIBUTE_WATER) → **舰队**
- `GALAXY_PROPERTY_STATION` (ATTRIBUTE_FIRE) → **空间站**
- `GALAXY_PROPERTY_STARPORT` (ATTRIBUTE_WIND) → **星港**
- `GALAXY_PROPERTY_COMMANDER` (ATTRIBUTE_LIGHT) → **指挥官**

> 暂未为 DARK / DIVINE 提供 Galaxy 别名，如需使用请保留原属性名称。

### 2.2 类别（种族）
- `GALAXY_CATEGORY_HUMAN` (RACE_WARRIOR) → **人类**
- `GALAXY_CATEGORY_MAMMAL` (RACE_BEAST) → **哺乳类**
- `GALAXY_CATEGORY_REPTILE` (RACE_DINOSAUR) → **爬行类**
- `GALAXY_CATEGORY_AVIAN` (RACE_WINDBEAST) → **鸟类**
- `GALAXY_CATEGORY_ARTHROPOD` (RACE_INSECT) → **节肢类**
- `GALAXY_CATEGORY_MOLLUSK` (RACE_SEASERPENT) → **软体类**
- `GALAXY_CATEGORY_FUNGAL` (RACE_REPTILE) → **真菌类**
- `GALAXY_CATEGORY_UNDEAD` (RACE_ZOMBIE) → **死灵**
- `GALAXY_CATEGORY_AURORA` (RACE_THUNDER) → **极光**

> 其他 `RACE_*` 目前无 Galaxy 别名（例如机械、龙族、魔法师等），可继续使用原称。

### 2.3 自定义效果码
- `EFFECT_RUSH (500)`：部署回合即可攻击
- `EFFECT_PROTECT (501)`：保护/嘲讽
- `EFFECT_SHIELD (502)`：护盾，抵挡一次伤害
- `EFFECT_SHIELD_HINT (503)`：护盾 UI 提示（由系统自动注册）
- `EFFECT_FREE_DEPLOY (504)`：免补给部署
- `EFFECT_UPDATE_HP (505)`：持续 HP 增减
- `EFFECT_LETHAL (506)`：致命
- `EFFECT_STEALTH (507)`：隐身
- `EFFECT_STEALTH_HINT (508)`：隐身 UI 提示（由系统自动注册）

### 2.4 HP 事件常量
- `GALAXY_EVENT_HP_DAMAGE`：单位受到立即伤害事件
- `GALAXY_EVENT_HP_RECOVER`：单位立即恢复事件
- `GALAXY_EVENT_HP_EFFECT_CHANGE`：持续效果改变 HP 时触发

## 3. 数据库字段要点
- `cards.cdb` 的 `datas` 表字段：
  - `type` → 判断单位/支援/战术等（位标志）
  - `level` → 默认补给成本
  - `attack` → 攻击力
  - `defense` → 基础 HP
  - `attribute` → 特性对应 `GALAXY_PROPERTY_*`
  - `race` → 类别对应 `GALAXY_CATEGORY_*`
- `texts` 表包含卡名与描述，维持 YGO 格式。

## 4. 术语使用建议
- 脚本与文档中统一使用 Galaxy 术语，避免 YGO 与 Galaxy 名称混用。
- UI 或提示文本若需要中文，请参照本表翻译。
- 发现新的常量或命名规范时，记得更新本文件，保持与代码一致。
