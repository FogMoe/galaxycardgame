# C++ 模块全景文档（经代码验证）

## 1. 项目结构与依赖
本项目的 C++ 代码主要分布在 `ocgcore` 与 `gframe` 两大目录：

- **`ocgcore`**：封装对外 C 接口、决斗容器、规则执行状态机、卡牌/效果数据模型，以及 Lua 脚本绑定，是服务器与客户端共享的对局引擎。【F:ocgcore/ocgapi.h†L39-L83】【F:ocgcore/duel.h†L29-L76】【F:ocgcore/field.h†L36-L200】【F:ocgcore/interpreter.h†L27-L88】
- **`gframe`**：构建客户端运行时，涵盖窗口/渲染初始化、对局数据结构、网络通信、音频及资源加载模块，是玩家与核心交互的宿主环境。【F:gframe/game.cpp†L34-L138】【F:gframe/client_field.h†L26-L164】【F:gframe/network.h†L4-L195】【F:gframe/sound_manager.h†L15-L105】

运行时依赖包括 Irrlicht 图形引擎（渲染/UI）、libevent（网络）、SQLite（卡片数据库）以及可选的 miniaudio/irrKlang 音频后端，这些库均在各自模块的头文件与初始化逻辑中显式引用。【F:gframe/game.h†L4-L126】【F:gframe/network.h†L4-L195】【F:gframe/data_manager.h†L4-L139】【F:gframe/sound_manager.h†L6-L56】

## 2. 决斗核心（`ocgcore`）
### 2.1 模块总览
核心文件之间的协作关系如下：

- `duel.h/cpp` 管理整局对决的生命周期、消息缓冲与对象池。【F:ocgcore/duel.h†L29-L76】
- `field.h/cpp`、`processor.cpp`、`operations.cpp` 与 `playerop.cpp` 共同组成状态机：`field::process` 轮询 `processor_unit` 队列，根据类型执行流程或等待响应，具体操作（召唤、破坏、移动等）由 `operations.cpp` 推入队列，而玩家交互流程在 `playerop.cpp` 中编码。【F:ocgcore/field.h†L144-L200】【F:ocgcore/processor.cpp†L17-L185】【F:ocgcore/operations.cpp†L151-L247】【F:ocgcore/playerop.cpp†L15-L112】
- `card.h`、`group.h`、`effect.h` 定义了运行时对象及其关系；`metadata.*`、`buffer.h` 等提供辅助结构。【F:ocgcore/card.h†L37-L200】【F:ocgcore/group.h†L20-L44】【F:ocgcore/effect.h†L29-L130】
- `interpreter.h/cpp` 与 `scriptlib.*` 管理 Lua 虚拟机及脚本 API，使得卡片效果可由脚本扩展。【F:ocgcore/interpreter.h†L27-L88】【F:ocgcore/scriptlib.h†L18-L200】【F:ocgcore/libduel.cpp†L20-L187】

### 2.2 C 接口与宿主集成
`ocgapi.h` 暴露的 `extern "C"` 函数允许任何宿主加载规则引擎：

- **资源回调**：`set_script_reader`、`set_card_reader`、`set_message_handler` 注册宿主回调；辅助函数 `read_script`/`read_card`/`handle_message` 统一访问路径。【F:ocgcore/ocgapi.h†L39-L49】
- **决斗生命周期**：`create_duel`/`create_duel_v2` 创建实例，`start_duel`/`end_duel` 管控启动与清理，`set_player_info` 与一组补给函数初始化对局资源值。【F:ocgcore/ocgapi.h†L51-L61】
- **消息驱动**：宿主循环调用 `process` 推进状态，通过 `get_message`/`get_log_message` 读取输出，并用 `set_responsei`/`set_responseb` 注入玩家响应；`preload_script` 支持脚本预热。【F:ocgcore/ocgapi.h†L62-L74】
- **状态查询与扩展**：`new_card`、`query_card`、`query_field_*` 等读写场地；Koishi 特有的注册表 API 提供跨决斗共享数据的键值对。【F:ocgcore/ocgapi.h†L65-L83】

典型宿主流程会先注册资源回调，再创建对局并在主循环中交替调用 `process` 与 `get_message` 直至 `PROCESSOR_END` 标志出现，同时根据玩家输入调用响应接口继续推进。

### 2.3 决斗容器（`duel`）
`duel` 对象统筹所有运行时资源：

- **成员组成**：持有 Lua 解释器、`field` 场地、梅森旋转随机数、全局元数据及用于垃圾回收的 `std::unordered_set` 容器。【F:ocgcore/duel.h†L29-L44】
- **消息缓冲**：`write_buffer*`/`read_buffer`/`buffer_size` 负责序列化协议字节流，宿主通过 `get_message` 即读取该缓冲的内容。【F:ocgcore/duel.h†L52-L69】
- **对象工厂与生命周期**：`new_card`/`new_group`/`new_effect` 及对应删除函数集中管理运行对象，确保 C++ 与 Lua 引用同步；`registry` 则承载可持久化的引擎配置。【F:ocgcore/duel.h†L55-L76】

### 2.4 场地、事件与流程调度
`field` 类及其内嵌结构描述对局状态，并通过 `processor` 管理流程：

- **事件建模**：`tevent`、`chain`、`optarget` 记录触发源、目标集合、连锁顺序与附加参数，为效果解析提供上下文。【F:ocgcore/field.h†L36-L79】
- **玩家与场地信息**：`player_info` 保存各区域卡组列表、补给值、禁用区域等；`field_effect` 维护永续/触发效果容器与授予关系；`field_info` 跟踪回合、阶段与唯一标识。【F:ocgcore/field.h†L81-L138】
- **处理队列**：`processor` 内含 `processor_unit` 链表与多种候选卡集合（可召唤/可攻击等），驱动规则解析和玩家选择。【F:ocgcore/field.h†L144-L200】
- **执行循环**：`field::process` 按 `processor_unit::type` 分发到调整、回合推进、玩家选择、位置选择等分支，若需要玩家输入则返回 `PROCESSOR_WAITING` 并保留状态。【F:ocgcore/processor.cpp†L35-L185】
- **动作排队**：诸如 `special_summon`、`destroy`、`release` 等高层操作在 `operations.cpp` 中设置卡片状态、填充原因信息，并调用 `add_process` 将 `PROCESSOR_*` 单元压入队列，确保动画与脚本按统一机制推进。【F:ocgcore/operations.cpp†L151-L247】
- **玩家输入协议**：`playerop.cpp` 的 `select_battle_command`、`select_idle_command` 等函数把候选选项编码进消息缓冲，并验证宿主返回值合法性，保证客户端不会提交越界索引。【F:ocgcore/playerop.cpp†L15-L112】

### 2.5 运行对象模型
- **卡牌（`card`）**：`card_state` 保存当前/历史属性，`query_cache` 避免重复计算，`material_info` 记录召唤素材限制。类本体包含所有运行时标记（控制者、唯一 ID、装备关系、计数器等）以及效果容器，支撑复杂的召唤与效果判定。【F:ocgcore/card.h†L37-L200】
- **卡组集合（`group`）**：封装一组卡牌指针并携带引用计数、元数据和读写标记，常用于传递查询结果或脚本层的选择集合。【F:ocgcore/group.h†L20-L44】
- **效果（`effect`）**：记录触发范围、计数限制、重置规则、提示信息等元数据，并提供 `is_activateable`、`check_count_limit`、`get_value` 等实用方法，用于判断脚本条件和读取返回值。【F:ocgcore/effect.h†L29-L130】

### 2.6 Lua 脚本环境
- **解释器**：`interpreter` 负责 Lua 状态创建、协程管理、参数入栈及函数调用，支持注册/注销 card、group、effect 实例并在 Lua 侧维护弱引用，防止悬挂指针。【F:ocgcore/interpreter.h†L27-L88】
- **脚本库**：`scriptlib` 暴露大量以 `card_*`、`effect_*`、`duel_*` 开头的 API，涵盖属性查询、效果注册、数据库读取、随机数和注册表访问，为脚本提供与引擎交互的唯一入口。【F:ocgcore/scriptlib.h†L18-L200】
- **宿主辅助实现**：`libduel.cpp` 中的函数（如 `duel_query_database`、`duel_read_card`）实现了脚本 API，包含输入校验与只读 SQLite 查询，确保脚本访问安全可控。【F:ocgcore/libduel.cpp†L20-L187】

## 3. 客户端运行框架（`gframe`）
### 3.1 Game 入口与配置
`Game` 类是客户端的主循环入口：

- `Config` 结构罗列渲染、字体、网络、音频等设置，`DuelInfo` 记录 LP、补给、阶段、倒计时与 UI 文本缓冲，`BotInfo`/`FadingUnit` 等则服务于 AI 对战与界面动画。【F:gframe/game.h†L57-L193】
- `Game::Initialize` 负责创建 Irrlicht 设备、加载皮肤、初始化 `DeckManager`、`ImageManager`、`DataManager` 与字符串/服务器配置，同时尝试加载额外卡片数据库并建立 GUI 环境。【F:gframe/game.cpp†L34-L137】

### 3.2 数据载入与卡组管理
- **DataManager**：读取 SQLite 卡片库、字符串、服务器列表，并提供编号/文本检索、格式化工具以及静态的 `CardReader`/`ScriptReaderEx` 以供 OCGCore 回调直接使用。【F:gframe/data_manager.h†L22-L139】
- **DeckManager**：在 `current_deck` 内维护主、额外、备牌列表，支持 LF 禁限表加载、卡组导入导出及生成网络协议所需的数组形式，是 UI、网络与核心之间的数据桥梁。【F:gframe/deck_manager.h†L42-L155】

### 3.3 客户端场景与交互
`ClientField` 将对局现场映射为客户端对象：追踪各区域卡牌向量、可操作列表、当前连锁、提示与选项，并实现事件响应（鼠标命中、菜单、选中集合），供 UI 层渲染与交互逻辑调用。【F:gframe/client_field.h†L26-L164】

### 3.4 网络通信
- `network.h` 定义客户端/服务器协议的数据结构，并使用 `static_assert` 确保与网络字节布局兼容；同时提供缓冲区大小常量供序列化使用。【F:gframe/network.h†L16-L195】
- `DuelClient` 基于 libevent 管理网络会话：维护连接状态、发送缓冲、远程房间刷新线程，并提供 `SendPacketToServer`、`SetResponseI/B` 等静态方法与核心消息交互。【F:gframe/duelclient.h†L53-L157】
- `NetServer` 在服务器模式下监听连接、转发消息，并复用协议结构体封装发送逻辑（含重发缓冲），用于本地或远程对战服务器。【F:gframe/netserver.h†L10-L69】

### 3.5 音频系统
`SoundManager` 统一 BGM/音效播放，内部根据编译选项选择 miniaudio 或 irrKlang，并暴露 `PlayBGM`、`PlaySoundEffect`、`SetSoundVolume` 等接口供 UI 触发场景音频。【F:gframe/sound_manager.h†L15-L105】

### 3.6 与核心引擎的交互路径
客户端在多处将资源读取与消息处理对接至 OCGCore：

- 回放与单人模式启动时，调用 `set_script_reader(DataManager::ScriptReaderEx)`、`set_card_reader(DataManager::CardReader)` 和 `set_message_handler`，随后创建 `pduel`，设置玩家信息并预加载脚本，从而驱动核心引擎运行。【F:gframe/replay_mode.cpp†L23-L195】
- 游戏运行期通过 `process`/`get_message` 循环驱动 UI，并用 `set_responseb` 回填回放指令，逻辑与实时对战保持一致。【F:gframe/replay_mode.cpp†L80-L118】

## 4. 集成实践建议
1. **初始化资源**：客户端应在启动时加载卡片数据库与字符串，并注册 `DataManager` 的脚本/卡片读取回调，确保核心引擎访问到统一的资源缓存。【F:gframe/game.cpp†L88-L120】【F:gframe/data_manager.h†L116-L125】
2. **创建决斗**：根据对战参数调用 `create_duel`/`create_duel_v2`，设置玩家 LP、起始手牌、补给等，再执行 `start_duel` 并进入 `process` 循环。【F:gframe/replay_mode.cpp†L157-L195】【F:ocgcore/ocgapi.h†L51-L63】
3. **消息循环**：每帧读取 `process` 返回的缓冲长度，使用 `get_message` 解包后驱动 UI/音频，并在玩家操作后调用 `set_response*` 或网络发送函数同步状态。【F:gframe/replay_mode.cpp†L80-L118】【F:ocgcore/ocgapi.h†L62-L74】
4. **扩展脚本**：新增效果时在 Lua 中调用 `scriptlib` 提供的 `card_*`/`duel_*` API，可结合 `preload_script` 与 `DataManager::LoadExtraScripts` 实现热加载及补丁管理。【F:ocgcore/scriptlib.h†L18-L200】【F:ocgcore/libduel.cpp†L92-L195】【F:gframe/replay_mode.cpp†L190-L195】
5. **网络/服务端部署**：使用 `DuelClient`/`NetServer` 的封装确保与协议结构体一致，通过 libevent 事件循环读写消息；服务器侧可重发上次写入的缓冲保证可靠性。【F:gframe/duelclient.h†L65-L157】【F:gframe/netserver.h†L21-L69】

以上内容基于源码逐项验证，旨在帮助开发者快速定位需要扩展或集成的组件，并掌握核心引擎与宿主框架之间的调用约定。
