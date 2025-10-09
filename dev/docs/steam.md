# Steam SDK 集成规范

本文档记录本项目在使用 Steamworks SDK 时的统一约定，确保所有开发者按照同一流程配置与维护相关功能。

## 目录结构与资源

- 将官方 Steamworks SDK 解压至仓库根目录 `steamsdk/`。
- 运行 `premake5 --steamsdk vs2022`（或其他目标 action）生成 VS 工程，Premake 会自动：
  - 加入 `steamsdk/public` 为头文件包含路径；
  - 为不同平台配置链接目录（Windows `redistributable_bin/`, Linux `redistributable_bin/linux64`, macOS `redistributable_bin/osx`）；
  - 定义编译宏 `YGOPRO_USE_STEAM_SDK`。
- Windows 调试时需把 `steamsdk/redistributable_bin/win64/steam_api64.dll`（或 Win32 平台的 `steam_api.dll`）复制到可执行文件输出目录。
- 在 `steam_appid.txt` 填写正式 AppID（如 `4039420`），放在可执行文件同目录，且将该文件加入 `.gitignore`。

## 运行时指引

- 游戏初始化时会调用 `SteamAPI_Init()`：
  - 成功：`steam_sdk_available = true`，并确保后续可以调用 `SteamFriends()` 等接口。
  - 失败：记录日志 `SteamAPI_Init failed; Steam rich presence disabled.`，同时保持 `steam_sdk_available = false`，所有 Steam 功能自动跳过，不会影响游戏流程。
- 主循环每帧：
  - 若 `steam_sdk_available == true`，调用 `SteamAPI_RunCallbacks()`。
  - 根据状态自动更新 Rich Presence：
    - `In Battle`（牌局中，`dInfo.isStarted == true`）；
    - `In Room`（房间/准备界面，`wHostPrepare` 可见）；
    - `Deck Builder`（组卡界面，`is_building == true` 且未开局）；
    - `Main Menu`（其余情况）。
- 状态字符串会被转换为 `#Status_*` token，例如 `Main Menu` → `#Status_MAIN_MENU`、`In Room` → `#Status_IN_ROOM`。请在 Steamworks 后台对应配置 Enhanced Rich Presence 显示文案。
- 游戏退出时调用 `SteamAPI_Shutdown()`，并清空本地状态缓存。

### 成就系统

- 成就逻辑集中在 `Game::TryUnlockPendingSteamAchievements()` 中维护，所有触发入口只需设置布尔状态并调用该函数即可。
- 当前内置成就：
  - `ACH_FIRST_LAUNCH`：首次从 Steam 启动游戏，在 `SteamAPI_Init()` 成功后标记。
  - `ACH_FIRST_DECK_BUILD`：首次从卡组编辑器返回主菜单，在 `Game::OnDeckBuilderClosed()` 中标记。
  - `ACH_FIRST_VICTORY`：首次线上对局获胜，在 `Game::OnLocalPlayerWin()` 中标记，仅对参战玩家生效（旁观及录像不会触发）。
- 每个触发入口都会先检查 `steam_sdk_available`，并在 Steam 服务不可用时静默跳过，确保无 SDK / 未登录情况下仍能正常游玩。
- `TryUnlockPendingSteamAchievements()` 会重复查询 SteamUserStats，直到 Steam 客户端同步完成为止；调用是幂等的，可以安全地放在主循环。
- 新增成就时，保持上述模式：添加状态位、在事件入口设置、在统一函数中追加 `try_unlock("<ACH_ID>", flag)`，并在后台配置成就属性。

## 编译配置

- Premake 默认会为 VS 工程禁用 Steam SDK 头文件带来的 `C4828` 警告。
- 在 WSL 环境下调用 `./premake5.exe` 可能出现 `UtilBindVsockAnyPort` 等 WSL 限制，可直接在 Windows 端运行同命令生成工程。
- 如需更换动作（如 `vs2019`、`gmake2` 等），`--steamsdk` 开关同样适用。

## 开发注意事项

- 所有与 Steam 相关的代码都应放在 `#ifdef YGOPRO_USE_STEAM_SDK ... #endif` 块内。
- 仅在 `steam_sdk_available == true` 时调用 `SteamFriends()`、`SteamUser()` 等接口；其余情况必须提前判断，避免空指针或崩溃。
- 调用 Rich Presence 时，优先设置 `status` 字段，必要时设置 `steam_display`（本项目已在 `UpdateSteamRichPresence` 中统一处理）。
- 后续若新增状态，务必：
  1. 在 `UpdateSteamRichPresence` 中维护对应的状态字符串；
  2. 在 Steamworks 后台配置新的 `#Status_*` token。

### 调试建议

- 保持 Steam 客户端运行，使用拥有 App 访问权限的账号登陆。
- 使用 `steam_appid.txt` 行为仅限本地调试；上线前需通过 Steam 客户端启动游戏。
- 若需要验证富状态，可在好友列表中查看或开启 Steamworks Rich Presence 调试工具。

## 版本更新流程

1. 更新 `steamsdk/` 目录（替换为最新 SDK）后，重新执行 `premake5 --steamsdk <action>`。
2. 如 SDK 更换导致接口变化，确保 `YGOPRO_USE_STEAM_SDK` 块内代码适配新的 API。
3. 测试流程：
   - 启动游戏，确认未安装 Steam/未运行 Steam 时能正常启动。
   - 在 Steam 客户端运行游戏，验证 Rich Presence 状态切换：主菜单 / 组卡 / 对战。
   - 使用自动化流程（或手动）复制 DLL 到所有发布包中。

保持本文档更新，确保团队成员在处理 Steam 集成时遵循统一规范。 
