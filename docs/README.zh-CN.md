# 组队、匹配与支援 UI：从找到队友到共同游戏

把组队、邀请支援和战斗中的队员信息，连接为跨越菜单与游戏内 HUD 的连续体验。

**Evan（Yaxin）Ge · Lua / C++ / UMG · ProjectZ**

[English](../README.md) · [功能截图](#功能截图) · [我的工作](#我的工作) · [深入阅读](#深入阅读)

## 功能截图

三张图分别展示完整面板、队员 HUD 与支援列表。[全部四张图、英文标签和素材署名](../media/SCREENSHOTS.md)。

### 组队主面板与邀请

![组队成员槽位与右侧邀请列表](../media/screenshots/Team_MainUI.png)

**功能：**查看活动与队员，通过推荐、好友、最近或世界寻找玩家。皇冠标记队长，当前操作为“等待开始”；功能支持收起面板而不离队。

**相关工作：**不同匹配协议的共同状态、按角色变化的操作、邀请详情，以及主面板和缩小通知之间的状态连接。

[面板与 HUD 流程](CASE_STUDY.md#flow-a-create-a-team-minimise-restore) · [统一 Model 决策](DECISIONS.md#1-one-ui-facing-model-over-different-matching-systems) · [面板操作实现](CODE_TOUR.md#2-full-panel--player-intent)

### 战斗队员 HUD

![战斗画面右侧的队员等级、名字、血量与距离](../media/screenshots/HUD_TeamPanel.png)

**功能：**关注画面右侧队员列表，战斗中无需打开主面板也能查看等级、名字、血量与距离。[查看原图](../media/screenshots/HUD_TeamPanel.png)。

**相关工作：**我完成了该 HUD 的实现和数据维护，区分成员结构、实时战斗信息与较完整玩家资料的刷新职责，减少重复列表工作并保留必要的数据刷新。

[性能与数据时效性案例](HUD_PERFORMANCE.md) · [刷新链路代码导读](CODE_TOUR.md#7-hud-performance-read-the-cost-chain-then-run-the-model)

### 支援列表与可用状态

![带邀请助战、忙碌状态、收藏、筛选与搜索的玩家列表](../media/screenshots/SupportUI.png)

**功能：**通过收藏、筛选、刷新和搜索寻找支援玩家；可用条目显示“邀请助战”，不可用条目显示“忙碌中”。

**相关工作：**将活动支援 ID 带入既有浏览界面，绑定详情与可用状态，并通过原生管理器处理邀请及等待／冷却。

[支援完整流程](CASE_STUDY.md#flow-b-request-support-from-a-gameplay-context) · [世界交互到 UI](CODE_TOUR.md#4-a-world-interaction--support-ui) · [回调与可用状态 Bug](DEBUGGING.md)

**其他截图：[缩小组队状态条](../media/SCREENSHOTS.md#compact-team-status-notice)。**顶部条显示活动和“组队中”，并提供恢复入口，与右侧队员列表不同。[恢复与退出逻辑](CODE_TOUR.md#3-compact-status--restore-or-explicit-exit)。

## 我的工作

我开发、维护了组队与支援 gameplay 及其配套 UI，包括主面板接入、缩小状态通知、右侧队员 HUD 和后续问题修复。工作连接 Lua／UMG 呈现、C++ 系统与多人服务。

- **队伍数据接入与架构演进：**早期集中校准竞技场与副本的状态和请求；后期多人模式规划增多，再拆出按模式选择的 Adapter／Strategy。队伍数据与共同界面保持稳定，匹配差异进入专用适配器。
- **面板与缩小 HUD：**连接成员、角色、准备／匹配呈现及收起恢复；区分展示操作与离队、取消匹配等命令。
- **邀请与支援：**把玩家发现接到活动上下文、详情与离线／忙碌／等待反馈，确保请求保持支援语义。
- **战斗队员 HUD：**实现成员列表，并维护成员结构、战斗数值与玩家资料的不同更新路径。
- **逻辑层性能：**追踪原生通知到列表重填、绑定及详情请求的开销链，控制结构刷新并独立支援上下文更新，随后调整详情时效性。
- **Debug 与持续维护：**修复支援搜索回调环、可用状态刷新，并处理即时缓存提示与服务器资格判断之间的取舍。

## 三个问题与决策

### 1. 不同匹配系统如何提供一致的队伍状态？

竞技场与 PVE 副本使用不同协议、阶段和队伍数据。我先在面向 UI 的共同 Model 中集中处理转换与请求分流。模式少时，这种分支结构足够清晰，维护成本也可控。

后期多人赛马、滑翔、射击比赛和钓鱼比赛等规划增多，促使我进一步拆出模式专用 Adapter，并按模式选择对应 Strategy。适配器双向转换匹配数据和操作请求；队伍信息继续共用，匹配特有信息交给定制的展示部分。新玩法的接入者能在明确的边界定义规则，而不让公共 Model 和各个界面不断增加协议分支。

[两阶段决策故事](DECISIONS.md#1-one-ui-facing-model-over-different-matching-systems) · [后期框架重建示例与测试](../examples/matchmaking-adapters/README.md) · [面板与 HUD 流程](CASE_STUDY.md#flow-a-create-a-team-minimise-restore)。示例入口集中说明版本范围，早期代码摘录保持原样。

### 2. 如何复用玩家浏览，又保留支援动作的含义？

我把活动的支援上下文带入既有多人浏览界面，复用搜索、列表与玩家详情。条目保留支援 ID，并区分离线、忙碌和等待状态；邀请等待与冷却由原生管理器维护。

这样共用的发现能力可以服务不同目的，而不会把“已发请求”误当成“已接受邀请”。[支援流程](CASE_STUDY.md#flow-b-request-support-from-a-gameplay-context)。

### 3. 哪些数据需要刷新，什么时候刷新？

一次 iOS 性能问题让我沿原生队员通知追踪到 Lua 列表重填、条目绑定和玩家详情查询。我用 dirty 标记控制结构通知，并将支援上下文更新从成员列表刷新中分离。

详情数据采用另一种策略：绑定时允许缓存减少重复工作，后续等级显示维护又加入周期强制刷新与绑定时强制查询。成员结构、实时战斗信息和较完整的玩家资料，需要不同更新职责。[HUD 优化与维护](HUD_PERFORMANCE.md)。

## 实际结果

- 竞技场与副本流程使用共同展示语义，同时保留原服务路径。
- 后期适配器结构把模式数据转换、请求分流与匹配展示信息集中为明确的扩展职责。
- 玩家收起界面后仍能了解组队状态，并恢复当前队伍操作。
- 成员不变时避免重复传播结构刷新；支援上下文有更小的更新路径，详情保留明确刷新机会。
- 支援搜索中的回调环被移除，详情完成后不再重复发起相同请求。[问题定位](DEBUGGING.md)。

## 深入阅读

- **案例与架构：**[完整案例](CASE_STUDY.md) · [架构](ARCHITECTURE.md) · [决策](DECISIONS.md)。
- **实现：**[代码路线](CODE_TOUR.md) · [TeamModel](../Content/Lua/GameLogics/Team/TeamModel.lua)。
- **架构演进：**[Adapter／Strategy 重建示例](../examples/matchmaking-adapters/README.md)，包含共同 Model、具体适配器、模式注册、面板／HUD 呈现及测试。
- **质量与开销：**[回调与可用状态修复](DEBUGGING.md) · [HUD 性能](HUD_PERFORMANCE.md)。
- **补充取舍：**[缓存资格、即时提示与服务器权威判断](DECISIONS.md#2-immediate-feedback-is-not-authoritative-eligibility)。
- **验证：**[Portfolio 新增测试](TESTING.md) · [独立 HUD 演示模型，非原项目代码](../examples/hud-refresh/HudRefreshModel.lua)。
- **材料范围：**[历史工作、版本边界、测试与素材说明](EVIDENCE.md)。

关键词：common UI-facing model · contextual support · asynchronous correctness · refresh granularity · data freshness。

**其他案例：**[建造 UI](https://github.com/seak123/building-ui-portfolio) · [机械兽与头顶 UI](https://github.com/seak123/mechanical-workers-ui-portfolio)。
