# 组队、匹配与支援 UI：组队操作与场景内反馈

**Evan（Yaxin）Ge · Lua / C++ / UMG · ProjectZ**

[English](../README.md) · [完整截图与来源](../media/SCREENSHOTS.md) · [代码导览](CODE_TOUR.md)

## 功能与界面

**Team window（组队窗口）**涵盖邀请、目标选择与匹配，之后进入对应玩法的准备确认窗口和 Level。窗口缩小时，由 **Compact team notice（缩小组队状态条）**保留状态与恢复入口。

右侧的 **Party HUD（小队 HUD）**是另一套界面：世界 Boss 区域显示相关参与玩家，副本内显示队员。Boss 区域的支援按钮会打开复用的 **Support browser（支援玩家浏览界面）**，邀请其他玩家过来帮忙。

### 组队窗口与邀请

![组队成员槽位与邀请列表](../media/screenshots/Team_MainUI.png)

皇冠表示队长，当前显示“等待开始”。可以从推荐、好友、最近和世界寻找玩家；收起窗口不等于离队或取消匹配。

[完整流程与缩小状态条](CASE_STUDY.md#flow-a-create-a-team-minimise-restore) · [不同匹配协议的适配](DECISIONS.md#1-one-ui-facing-model-over-different-matching-systems)

### 小队 HUD

![战斗画面右侧的玩家列表](../media/screenshots/HUD_TeamPanel.png)

显示对应场景的玩家、等级、血量与距离。我开发了该面板并维护数据更新，后期又加入可切换的战斗统计。**这张图展示成员列表，不是统计模式。**

[更新策略](HUD_PERFORMANCE.md) · [后期战斗统计设计](COMBAT_STATISTICS.md)

### 支援玩家浏览界面

![支援邀请与可用状态](../media/screenshots/SupportUI.png)

复用玩家搜索、筛选、收藏与详情，保留活动支援 ID，并区分可用、忙碌与等待反馈。发出邀请不等于对方已经接受。

[支援流程与不同入口](CASE_STUDY.md#flow-b-request-support-from-a-gameplay-context)

[第四张图：缩小组队状态条](../media/SCREENSHOTS.md#compact-team-status-notice)。它位于顶部中央，不是右侧小队 HUD。

## 我的工作

- 组队协议接入，以及后期按模式选择的 Adapter／Strategy 拆分。
- 组队窗口、缩小状态条与玩法状态的连接；切换监听和首次刷新。
- 支援上下文、玩家浏览复用、详情与可用状态更新。
- 小队 HUD 的成员、战斗数值和资料更新策略。
- 后期 DS 战斗统计系统，以及统计结果到 HUD 的接入。
- 从组队进图报告追到副本初始化依赖的跨层排查，以及 UI 日常维护。

## 三个关键决定

### 1. 不同匹配协议如何提供一致体验？

模式少时，在 TeamModel 集中转换即可。后期多人赛马、滑翔等规划增多，我将匹配数据和命令交给模式专用 Adapter，UI 按模式选择 Strategy，队伍信息与共用展示仍保持统一。

[架构演进](DECISIONS.md#1-one-ui-facing-model-over-different-matching-systems) · [明确标注的框架重建示例](../examples/matchmaking-adapters/README.md)

### 2. 切换模式时，UI 怎样正确接上玩法数据？

数据由玩法 Component／Manager 维护，UI 管理显示状态。切换 Adapter 时先注销旧监听，再注册新监听，并主动读取当前状态，不等下一次广播才显示已有数据。

[框架与生命周期](ARCHITECTURE.md#later-matchmaking-adapter-boundary)

### 3. 不同数据怎样选择更新方式？

依据玩家用途、可接受延迟和成本：战斗值及时，显示详情相对低频，邀请详情结合定期和操作刷新，名单与支援响应变化，统计按显示类型同步。早期通知门控和缓存优化是这个持续演进过程的一部分。

[UX 与更新策略](HUD_PERFORMANCE.md) · [邀请缓存取舍](DECISIONS.md#2-immediate-feedback-is-not-authoritative-eligibility) · [统计生命周期](COMBAT_STATISTICS.md)

## 结果与深入阅读

匹配差异有了明确扩展点，窗口显示与玩法命令保持分离；HUD 可以继续增加内容，而不要求所有数据共用刷新频率。统计累计与显示分开；跨层排查纠正了多人进图的数据依赖。

建议阅读：**功能背景 → Adapter 与生命周期 → 更新策略 → 统计或 Debug**。

[案例](CASE_STUDY.md) · [架构](ARCHITECTURE.md) · [代码导览](CODE_TOUR.md) · [跨层 Debug](DEBUGGING.md) · [验证](TESTING.md) · [证据范围](EVIDENCE.md)

保留代码摘录与重建示例分别标注，省略完整实现细节。测试为 Portfolio 后加，不是原项目历史性能测量。
