# gframe 客户端框架详解

本文档聚焦 `gframe/` 目录下的 C++ 模块，进一步拆解 UI 客户端在初始化流程、资源管理、网络通信、场面渲染与多模式支持中的职责，便于 UI/前端与工具开发者深入理解引擎联动细节。

## 1. 应用入口与生命周期

`Game::Initialize()` 是客户端启动入口：创建 Irrlicht 设备、解析配置与皮肤、载入限制表/卡片数据库/字符串/服务器列表，并初始化图像、字体、音频、GUI 环境等依赖，为后续场景构建打好基础。【F:gframe/game.cpp†L33-L239】

界面控件（主菜单、联机房间、建房面板、图像与提示窗口等）也在初始化阶段构建并根据配置调整尺寸与皮肤，随后把事件接收器绑定到 `menuHandler`。【F:gframe/game.cpp†L240-L1147】

`Game::MainLoop()` 则负责主渲染循环：设置摄像机与投影视图，检测窗口尺寸变化，绘制战场/菜单/牌组编辑界面，调度 `SoundManager` 播放对应场景 BGM，并在每帧处理 Steam 状态、关闭信号与 FPS 统计等杂务。【F:gframe/game.cpp†L1157-L1279】

## 2. 数据与资源管理

`DataManager` 抽象卡片数据、字符串、服务器列表与脚本加载，提供卡片查询、文本格式化、系列检索、脚本回调等接口，外部依赖通过它获取卡片信息并在需要时加载额外脚本文件。【F:gframe/data_manager.h†L18-L139】

`DeckManager` 维护当前牌组、限制表集合与 `.ydk` 读写逻辑，提供从文件/流读取、保存、分类管理、合法性校验与卡片统计等功能，是牌组编辑器与房间校验的底层支撑。【F:gframe/deck_manager.h†L42-L155】

图像资源通过 `ImageManager` 与 `Game::Initialize()` 中的 `imageManager.Initial()` 注入设备并加载，音频资源则由 `SoundManager` 初始化后统一管理，分别负责贴图与音效/BGM 的生命周期。【F:gframe/game.cpp†L125-L239】【F:gframe/sound_manager.h†L15-L106】

## 3. 界面与输入分发

初始化阶段创建的 GUI 控件在 `menuHandler` 与 `ClientField` 的事件系统下运作：

- `ClientField::OnEvent` 根据按钮/列表/鼠标事件分发到对战操作（如猜拳、先后手、投降、连锁设置、录像控制等），并通过 `DuelClient` 或 `ReplayMode` 发送网络/本地指令。【F:gframe/event_handler.cpp†L16-L198】
- `ClientField` 自身持有大量列表（手牌、怪区、陷区等）与交互状态，用于在 UI 侧维护客户端牌面、选择面板与链信息，并暴露方法刷新动画、选择状态与响应封装。【F:gframe/client_field.h†L26-L164】【F:gframe/client_field.cpp†L12-L144】

窗口级事件在 `Game` 中转换：初始化阶段设置 `device->setEventReceiver(&menuHandler)`，在进入对战后切换到 `ClientField` 处理实时操作，实现菜单与对战 UI 的分离。【F:gframe/game.cpp†L1126-L1156】

## 4. 网络通信栈

`network.h` 定义了客户端与服务器之间的结构体、缓冲区限制与常量，包括主机信息、玩家/房间封包、聊天长度等，保证所有网络消息具有确定的内存布局，可直接写入 libevent 缓冲区。【F:gframe/network.h†L16-L195】

`DuelClient` 封装所有客户端网络行为：

- `StartClient` 创建 libevent `bufferevent`、建立连接、开启线程，并根据是否建房附加超时处理，同时重置随机数与缓存状态。【F:gframe/duelclient.cpp†L435-L465】
- `ClientRead` 从缓冲区分段读取消息，调用 `HandleSTOCPacketLan` 分析服务器指令；`ClientEvent` 处理连接成功或异常，更新 UI 按钮状态并分发提示。【F:gframe/duelclient.cpp†L497-L520】【F:gframe/duelclient.cpp†L515-L707】
- `HandleSTOCPacketLan` 根据协议类型分派：对战消息转交 `ClientAnalyze`、错误提示根据错误码弹窗/复用 UI 控件、房间列表刷新、录像交互等都在此集中处理。【F:gframe/duelclient.cpp†L666-L855】

内置 `NetServer` 可启动房主模式或局域网广播，封装监听、accept、读写与广播逻辑，并提供向玩家发送数据、重发缓存、断线清理等工具，方便客户端在本地直接承载服务器功能。【F:gframe/netserver.h†L10-L69】

## 5. 客户端场面模型

`ClientField` 维持前端需要渲染的全部卡片实体（牌组、手牌、场区、墓地、除外、额外区等）与交互列表（可召唤、可发动、可攻击等），并提供获取/添加/移动卡片、刷新计数、构建选择面板等方法，确保 UI 与 ocgcore 消息保持同步。【F:gframe/client_field.h†L26-L164】

实现层在 `client_field.cpp` 中完成资源回收、初始分布、序列重排、卡片动画与选项弹窗等具体逻辑，在接收到 `DuelClient` 转来的网络消息后更新界面状态，驱动 3D 卡牌与 GUI 控件的联动。【F:gframe/client_field.cpp†L12-L198】

## 6. 单机、录像与辅助模式

`SingleMode` 为单人脚本模式封装独立的 `pduel`、消息分析、响应设置与区域刷新流程，提供专门的线程入口与消息处理函数，使单机剧情无需外部服务器即可运行。【F:gframe/single_mode.h†L10-L37】

`Replay` 负责 `.yrp`/`.yrpX` 录像的头部扩展、数据写入与读取，支持压缩标志、种子序列、牌组列表、响应流等结构化信息，并提供保存、重命名、删除等工具函数，配合 UI 实现录像回放与存档管理。【F:gframe/replay.h†L12-L121】

录像/单机相关按钮事件在 `ClientField::OnEvent` 中集中处理，通过 `ReplayMode` 或 `SingleMode` 的接口触发暂停、单步、重放、退出等行为，实现多模式共享 UI。【F:gframe/event_handler.cpp†L52-L140】

## 7. 音频与反馈系统

`SoundManager` 支持多种后端（miniaudio / irrKlang），内部维护 BGM 场景列表、当前播放状态、音量控制接口以及大量常用音效枚举。客户端场景切换或 UI 交互时调用 `PlayBGM`、`PlaySoundEffect` 等函数即可统一管理音乐与提示音。【F:gframe/sound_manager.h†L15-L106】

在主循环中，`SoundManager` 会根据对战状态自动切换战斗/胜利/失败/优势劣势 BGM，菜单与牌组界面也使用专用曲目，保证玩家反馈一致性。【F:gframe/game.cpp†L1157-L1232】

## 8. 扩展建议

- 新增界面或按钮时，需在 `Game::Initialize()` 中创建控件、在对应事件处理器（`menuHandler` 或 `ClientField::OnEvent`）中注册逻辑，并考虑是否需要在 `SoundManager` 添加音效常量，以维持统一交互体验。【F:gframe/game.cpp†L240-L1147】【F:gframe/event_handler.cpp†L16-L198】【F:gframe/sound_manager.h†L45-L106】
- 拓展网络协议需同步更新 `network.h` 的结构体定义，并在 `DuelClient::HandleSTOCPacketLan` / `SendPacketToServer` 侧实现序列化与 UI 反馈，确保不同模式都能正确解析新消息。【F:gframe/network.h†L16-L195】【F:gframe/duelclient.cpp†L666-L855】
- 若添加新的单机/录像特性，可在 `SingleMode` 或 `Replay` 扩展处理逻辑，同时在 `ClientField` 的事件/渲染流程中补充对应 UI 控件与状态更新，保证多模式间状态同步。【F:gframe/single_mode.h†L10-L37】【F:gframe/replay.h†L12-L121】【F:gframe/client_field.h†L26-L164】
