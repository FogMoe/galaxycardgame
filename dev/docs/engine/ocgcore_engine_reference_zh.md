# ocgcore 引擎模块详解

本文档针对 `ocgcore/` 目录下的 C++ 源码，深入拆解游戏对战内核的组成、职责分层与常见交互流程，帮助内核与脚本开发者定位扩展点、理解各模块的真实实现。

## 1. 总体结构

`duel` 类是整个对战内核的根对象，它持有 Lua 解释器、`field` 场地实例、梅森旋转随机数引擎与所有对象集合，并暴露读取/写入消息缓冲区的基础设施。【F:ocgcore/duel.h†L31-L73】【F:ocgcore/duel.cpp†L18-L153】

核心对外接口集中在 `ocgapi.h`。宿主通过设置脚本/卡片/消息回调、调用 `create_duel_v2` 构造 `duel`，随后使用一系列 API 向内核灌入卡片、同步玩家资源并驱动 `process()` 主循环。【F:ocgcore/ocgapi.h†L39-L73】

Lua 解释器负责加载脚本与执行效果逻辑，而所有战斗状态则落地在 `field`、`card`、`effect` 等 C++ 对象中，保证既能脚本扩展又具有稳定的执行效率。

## 2. 对战实例（duel）

- **生命周期管理**：构造函数初始化 Lua 解释器、`field`、临时卡与消息缓冲；析构与 `clear()` 会逐个销毁卡牌、群组、效果及其 Lua 引用，确保重复开局不会残留状态或内存泄漏。【F:ocgcore/duel.cpp†L18-L57】
- **对象池与脚本注册**：`new_card/new_group/new_effect` 将实例插入 `std::unordered_set` 并调用解释器的 `register_*` 以供 Lua 获取引用；`delete_*` 则移除集合并解除 Lua 侧引用，必要时把对象从脚本临时集合 `sgroups` 与假定状态集合 `assumes` 中清除。【F:ocgcore/duel.h†L38-L65】【F:ocgcore/duel.cpp†L58-L127】
- **消息管道**：`write_buffer*`/`read_buffer` 向宿主发送事件或查询结果；`set_response*` 把玩家输入写回 `field::returns`。`buffer_size()` 把消息长度编码进 `process()` 返回值，提醒宿主读取。【F:ocgcore/duel.h†L52-L73】【F:ocgcore/duel.cpp†L107-L153】
- **随机性与注册表**：`get_next_integer` 抽象 RNG 版本，`registry` 提供键值存储，对应 `ocgapi` 的 registry API，可用于脚本共享状态或记录自定义战局数据。【F:ocgcore/duel.h†L32-L47】【F:ocgcore/duel.cpp†L149-L153】【F:ocgcore/ocgapi.h†L76-L83】

## 3. 场地状态模型（field）

`field` 拥有全部对战运行时数据：`player_info` 维护 LP、补给、卡组/墓地/额外区列表；`field_effect` 记录场地区域内生效的各种效果集合；`field_info` 跟踪回合数、阶段、全局唯一 ID 等元数据。【F:ocgcore/field.h†L81-L138】

核心成员 `processor core` 维护流程队列，`return_value` 作为与宿主交互的返回缓冲；`nil_event`、`rose_card` 等字段用于脚本扩展（如玫瑰决斗）或默认事件对象。【F:ocgcore/field.h†L181-L205】【F:ocgcore/field.h†L365-L379】

### 3.1 卡片入场与同步

`add_card/remove_card/move_card` 等函数负责把 `card` 放入对应列表，并设置 `fieldid`、`unique_fieldid`、`turnid`、Pendulum 计数与位置标记。每次操作都会刷新玩家信息并调用 `card::apply_field_effect` 让持续效果立即生效。【F:ocgcore/field.cpp†L65-L191】

`reload_field_info` 会把 LP、场区占用、连锁信息等打包到消息缓冲里，宿主可用于断线重连或状态刷新，一次性重建 UI。【F:ocgcore/field.cpp†L65-L104】

### 3.2 查询与判定接口

`get_useable_count*`、`get_spsummonable_count*` 等函数综合检查区域禁用、素材要求、唯一性等限制，是脚本判定召唤/移动是否合法的基础；`filter_field_effect`、`filter_player_effect` 从 `field_effect` 聚合中筛选满足条件的效果集合，为触发/适用流程提供候选。【F:ocgcore/field.h†L384-L456】【F:ocgcore/field.h†L428-L435】

大量 `is_player_can_*`、`check_*` 方法把复杂规则拆成可复用的判定，例如素材收集、XYZ/Synchro 条件计算、链接区判定等，Lua 侧可以直接调用这些接口避免重复编码。【F:ocgcore/field.h†L436-L520】

## 4. 流程调度（processor）

`field::add_process` 将待执行的 `processor_unit` 放入 `core.subunits`，随后 `process()` 把它们拼接到 `core.units` 并按 `type` 分发：

- **操作等待**：如 `PROCESSOR_SELECT_CARD`、`PROCESSOR_SELECT_CHAIN` 等在等待玩家输入时返回 `PROCESSOR_WAITING | buffer_size()`，提示宿主读取消息后写回响应。
- **步骤推进**：`adjust_step`、`process_turn`、`refresh_location_info` 等函数按 `step` 拆分多阶段执行，完成后弹出对应 `processor_unit`。

这种链表+状态机的结构支持嵌套流程（通过 `core.subunits`）并明确阻塞点，是引擎与 UI 协作的核心。【F:ocgcore/processor.cpp†L17-L200】

## 5. 卡片对象模型（card）

`card_state` 捕捉卡片当前与历史属性、位置、控制者、原因等信息；配套的 `query_cache` 避免重复计算查询结果，`material_info` 记录同调/超量/链接素材限制，供脚本查询。【F:ocgcore/card.h†L37-L111】

`card` 本体维护先前/当前/临时状态、召唤信息、唯一性 ID、计数器映射、关联关系、装备/叠放目标等，并携带 `metadata` 以便脚本附加标签。`sendto_param`、`sum_param` 等字段用于在流程间传递临时参数（如送去何处、召唤使用的素材）。【F:ocgcore/card.h†L113-L200】

## 6. 效果系统（effect 与 effectset）

`effect` 记录描述文本、代码、作用范围、重置标志、计数限制与触发条件函数指针，同时缓存激活时的持有者、位置、连锁信息。`is_activateable`、`check_count_limit`、`is_chainable` 等方法综合事件上下文判断能否发动，`reset`/`recharge` 在阶段结束或效果失效时清理状态。【F:ocgcore/effect.h†L29-L130】

`required_handorset_effects`、`flag` 标志数组与 `hint_timing` 支撑可选连锁、必发效果与提示时机；当效果授予其他卡时，`is_granted` 与场地中的 `grant_effect_container` 一起维护授予链路，确保效果可追踪并在移除时正确撤销。【F:ocgcore/effect.h†L45-L130】【F:ocgcore/field.h†L103-L127】

## 7. Lua 解释器桥接（interpreter）

解释器维护 Lua 主状态、协程表、参数队列与内存跟踪器，向脚本开放 `load_script`、`call_function`、`call_card_function`、`call_coroutine` 等接口。`add_param`/`push_param` 将 C++ 对象或整数压入 Lua 栈，`card2value`/`group2value`/`effect2value` 保证跨语言引用一致，并支持复制函数引用用于异步操作。【F:ocgcore/interpreter.h†L27-L88】

`is_effect_check`、`check_filter` 等辅助函数为 Lua 回调提供快速条件判断；`clone_function_ref`、`get_ref_object` 则支撑效果克隆、延迟执行等高级脚本需求。

## 8. 宿主交互与 API 流程

1. **初始化**：宿主注册 `script_reader`、`card_reader`、`message_handler` 后，通过 `create_duel_v2` 构建 `duel`，再调用 `set_player_info`、`set_player_supply`、`new_card` 等 API 完成初始牌组与资源设定。【F:ocgcore/ocgapi.h†L39-L70】
2. **主循环**：重复调用 `process()` 直到返回 `PROCESSOR_END`。当返回值含 `PROCESSOR_WAITING` 时，应读取 `get_message`/`read_buffer` 中的消息，展示给玩家，并在收到输入后调用 `set_response*` 推进流程。【F:ocgcore/ocgapi.h†L63-L73】【F:ocgcore/duel.cpp†L107-L153】【F:ocgcore/processor.cpp†L35-L200】
3. **查询与同步**：宿主可随时使用 `query_card`、`query_field_info`、`get_registry_*` 等 API 获取最新状态或自定义存档，支撑断线重连、录像与调试工具。【F:ocgcore/ocgapi.h†L67-L83】
4. **收尾**：对战结束后调用 `end_duel` 释放场地与脚本资源，必要时执行 `duel::clear()` 或直接销毁实例，防止宿主残留旧数据。【F:ocgcore/ocgapi.h†L54-L55】【F:ocgcore/duel.cpp†L29-L57】

## 9. 扩展建议

- 新增事件或阶段时，需要在 `processor::process()` 的 `switch` 中添加 `PROCESSOR_*` 分支，并实现对应的处理函数/消息封装，确保等待玩家输入时返回 `PROCESSOR_WAITING`。【F:ocgcore/processor.cpp†L35-L200】
- 扩展卡片属性需同步更新 `card_state`、`query_cache` 与 Lua 查询接口，同时在 `reload_field_info` 中补充字段，保持脚本与宿主看到的一致数据。【F:ocgcore/card.h†L37-L111】【F:ocgcore/field.cpp†L65-L104】
- 面向宿主的新 API 应同步声明于 `ocgapi.h` 并在实现中写入消息缓冲或修改场地，必要时在 `interpreter` 层提供脚本封装，使 C++/Lua/宿主三方保持一致语义。【F:ocgcore/ocgapi.h†L39-L83】【F:ocgcore/interpreter.h†L27-L88】
