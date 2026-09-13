# 组队、匹配与支援 UI：从找到队友到共同游戏

![组队主界面：成员槽位与邀请列表](../media/screenshots/Team_MainUI.png)

把组队、邀请、匹配与支援连接成跨越面板和游戏内 HUD 的连续体验，让不同界面与实时多人状态保持一致。

**Evan（Yaxin）Ge · Lua / C++ / UMG · ProjectZ**

[English](../README.md) · [四张截图与英文图注](../README.md#gameplay-footage-and-screenshots)

*成员、队长标记与邀请来源集中在同一面板；收起界面可以返回游戏而不离队，图中操作为“等待开始”。[素材署名与标签翻译](../media/SCREENSHOTS.md)。*

## 我的工作

我开发、维护了组队与支援 gameplay 及其配套 UI，包括主面板接入、缩小状态通知、右侧队员 HUD 和后续问题修复。工作连接 Lua／UMG 呈现、C++ 系统与多人服务。

重点是跨界面的连续体验、带上下文的邀请、异步正确性，以及实时数据的刷新成本。

## 三个问题与决策

### 1. 不同匹配系统如何提供一致的队伍状态？

竞技场与 PVE 副本使用不同协议、阶段和队伍数据。我引入面向 UI 的共同 Model 边界，校准不同来源的状态，同时保留各模式自己的匹配与取消请求路径。

完整面板和缩小 HUD 从共同状态派生显示；隐藏／恢复界面与离队／取消匹配分开处理。[决策故事](DECISIONS.md#1-one-ui-facing-model-over-different-matching-systems) · [面板与 HUD 流程](CASE_STUDY.md#flow-a-create-a-team-minimise-restore)。

### 2. 如何复用玩家浏览，又保留支援动作的含义？

我把活动的支援上下文带入既有多人浏览界面，复用搜索、列表与玩家详情。条目保留支援 ID，并区分离线、忙碌和等待状态；邀请等待与冷却由原生管理器维护。

这样共用的发现能力可以服务不同目的，而不会把“已发请求”误当成“已接受邀请”。[支援流程](CASE_STUDY.md#flow-b-request-support-from-a-gameplay-context)。

### 3. 哪些数据需要刷新，什么时候刷新？

一次 iOS 性能问题让我沿原生队员通知追踪到 Lua 列表重填、条目绑定和玩家详情查询。我用 dirty 标记控制结构通知，并将支援上下文更新从成员列表刷新中分离。

详情数据采用另一种策略：绑定时允许缓存减少重复工作，后续等级显示维护又加入周期强制刷新与绑定时强制查询。成员结构、实时战斗信息和较完整的玩家资料，需要不同更新职责。[HUD 优化与维护](HUD_PERFORMANCE.md)。

## 实际结果

- 竞技场与副本流程使用共同展示语义，同时保留原服务路径。
- 玩家收起界面后仍能了解组队状态，并恢复当前队伍操作。
- 成员不变时避免重复传播结构刷新；支援上下文有更小的更新路径，详情保留明确刷新机会。
- 支援搜索中的回调环被移除，详情完成后不再重复发起相同请求。[问题定位](DEBUGGING.md)。

## 深入阅读

- **案例与架构：**[完整案例](CASE_STUDY.md) · [架构](ARCHITECTURE.md) · [决策](DECISIONS.md)。
- **实现：**[代码路线](CODE_TOUR.md) · [TeamModel](../Content/Lua/GameLogics/Team/TeamModel.lua)。
- **质量与开销：**[回调与可用状态修复](DEBUGGING.md) · [HUD 性能](HUD_PERFORMANCE.md)。
- **补充取舍：**[缓存资格、即时提示与服务器权威判断](DECISIONS.md#2-immediate-feedback-is-not-authoritative-eligibility)。
- **验证：**[Portfolio 新增测试](TESTING.md) · [独立 HUD 演示模型，非原项目代码](../examples/hud-refresh/HudRefreshModel.lua)。
- **材料范围：**[历史工作、版本边界、测试与素材说明](EVIDENCE.md)。

关键词：common UI-facing model · contextual support · asynchronous correctness · refresh granularity · data freshness。

**其他案例：**[建造 UI](https://github.com/seak123/building-ui-portfolio) · [机械兽与头顶 UI](https://github.com/seak123/mechanical-workers-ui-portfolio)。
