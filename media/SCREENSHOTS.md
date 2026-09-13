# Screenshot guide and footage credits

[Portfolio overview](../README.md) · [Featured views](../README.md#gameplay-footage-and-screenshots)

Jump to: [Team panel](#team-setup-and-invitations) · [Party HUD](#in-game-party-hud) · [Support](#support-player-selection) · [Compact notice](#compact-team-status-notice)

These screenshots were supplied from public Bilibili gameplay footage, not captured from a locally running build. They illustrate different interface views, not consecutive steps from one session. Images are retained unchanged, including visible creator watermarks and broadcast overlays. English explanations remain outside the images to preserve the original interface.

## Team setup and invitations

![Team member slots and the player-invitation list.](screenshots/Team_MainUI.png)

[Panel and HUD flow](../docs/CASE_STUDY.md#flow-a-create-a-team-minimise-restore) · [Common-state decision](../docs/DECISIONS.md#1-one-ui-facing-model-over-different-matching-systems)

[Team_MainUI.png](screenshots/Team_MainUI.png) shows three members, an empty fourth slot and the invitation browser. A crown marks the team leader.

Key labels: 推荐 — Recommended; 好友 — Friends; 最近 — Recent; 世界 — World; 在线 — Online; 邀请 — Invite; 收起 — Minimise; 等待开始 — Waiting to start.

## In-game party HUD

![The right-side party roster during combat, showing levels, health and distance.](screenshots/HUD_TeamPanel.png)

[HUD performance and data freshness](../docs/HUD_PERFORMANCE.md) · [Code-reading route](../docs/CODE_TOUR.md#7-hud-performance-read-the-cost-chain-then-run-the-model)

[HUD_TeamPanel.png](screenshots/HUD_TeamPanel.png) shows the compact roster on the right: member levels, names, health bars and distances in metres. This case focuses on the party panel rather than the surrounding HUD and environment. The full image provides combat context; open it at full size to inspect the small roster.

## Support-player selection

![Support invitations, player availability, filters and search.](screenshots/SupportUI.png)

[Contextual support flow](../docs/CASE_STUDY.md#flow-b-request-support-from-a-gameplay-context) · [Callback and state fixes](../docs/DEBUGGING.md)

[SupportUI.png](screenshots/SupportUI.png) shows support invitations and availability feedback inside the multiplayer player browser. The Busy row illustrates an unavailable player; the image does not show every pending/offline state discussed in the code study.

Key labels: 多人游戏 / 玩家列表 — Multiplayer / Player list; 推荐玩家 — Recommended players; 我的收藏 — Favourites; 访问历史 — Visit history; 邀请助战 — Invite for support; 忙碌中 — Busy; 标签筛选 — Tag filters; 刷新列表 — Refresh list; 输入玩家名称搜索 — Search by player name.

## Compact team-status notice

![A blue team-status banner at the top centre of the gameplay screen.](screenshots/TeamHUD.png)

[Minimise and restore flow](../docs/CASE_STUDY.md#flow-a-create-a-team-minimise-restore) · [Compact-notice implementation](../docs/CODE_TOUR.md#3-compact-status--restore-or-explicit-exit)

[TeamHUD.png](screenshots/TeamHUD.png) shows the blue activity banner at the top centre. 组队中 indicates team formation; it is not labelled Matchmaking. The notice and the right-side party roster are distinct views. Minimise/restore behaviour is explained by the implementation, not demonstrated by this still image.

## Footage credits

- **Source recording supplied by Evan Ge:** [Public gameplay livestream recording on Bilibili](https://www.bilibili.com/video/BV1NDLUzqELh/). This is the source link supplied for the screenshot set; the visible credits for individual images are retained below.
- `Team_MainUI.png`, `HUD_TeamPanel.png` and `TeamHUD.png`: Bilibili footage bearing the **小鬼将军** creator watermark.
- `SupportUI.png`: Bilibili footage bearing the **11的游戏世界** creator watermark.
- Exact playback timestamps and the per-image match to the recording have not been independently verified; game build/version is unverified. The linked recording is not attributed to every visible creator solely on the basis of this source note.
- Game visuals and UI artwork belong to their respective rights holders. Footage credit is separate from engineering-contribution statements; no ownership of the recordings or surrounding artwork is claimed.

The images provide visual context, not performance measurements or a complete interaction recording. Diagrams elsewhere in the repository explain engineering relationships and are not game screenshots.
