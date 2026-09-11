-- PORTFOLIO SOURCE EXCERPT | original file/module names retained.
-- Implementation map: docs/source-manifest.json.
-- Not a standalone game: original framework/assets/services are external.
local MultiPlayerWorldList, superClass = CreateUIBehaviourFromListView("MultiPlayerWorldList")
local super = superClass
local InteractionTable = GetTableDefine("InteractionTable")
local PlayWorldData = ModelManager:GetModel("PlayWorldData")
local MultiPlayerMgr = UE4.PzMultiPlayerLibrary.GetMultiPlayerManager(_G.GlobalContext)
local MultiPlayerModel = ModelManager:GetModel("MultiPlayerModel")
local FriendIntimacyModel = ModelManager:GetModel("FriendIntimacyModel")
local CONTENT_STATE = {
    LIST = 0,
    EMPTY = 1,
}
local PanelSetting =
{
    Elements =
    {
        { Name = "UIWorldList", Alias = "NativeListView", },
    },
    Events =
    {

    }
}
function MultiPlayerWorldList:_init(go)
    super._init(self, go, PanelSetting)
end
function MultiPlayerWorldList:OnInitialize()
end
function MultiPlayerWorldList:OnDestroy()
end
function MultiPlayerWorldList:GetBriefDataList(SubTabID)
	local BriefDataList = {}
	if SubTabID == InteractionTable.WorldPageType.WorldBriefListPage then
		BriefDataList = PlayWorldData:GetWorldBriefDataList()
	elseif SubTabID == InteractionTable.WorldPageType.WorldFavoriteListPage then
		BriefDataList = PlayWorldData:WorldFavoriteList_Get()
	elseif SubTabID == InteractionTable.WorldPageType.WorldHistoryListPage then
		BriefDataList = PlayWorldData:WorldHistoryList_Get()
	elseif SubTabID == InteractionTable.WorldPageType.WorldTraceDataListPage then
		BriefDataList = PlayWorldData:GetWorldTraceDataList()
	elseif SubTabID == InteractionTable.WorldPageType.WorldIntimacyListPage then
		BriefDataList = FriendIntimacyModel:GetIntimacyRelationData()
	end
	
	return BriefDataList
end

function MultiPlayerWorldList:CreatePlayerWorldItemData(singleBrief, index, isVisitBtn, SubTabID, bShowRecommendPlayer)
	local itemData = {}

	itemData.Index = index --这里的序号从1开始
	itemData.WorldGUID = singleBrief.WorldGUID
	itemData.WorldDesc = singleBrief.WorldDesc
	itemData.WorldJoinRule = singleBrief.WorldJoinRule
	itemData.TribeMemberJoinRule = singleBrief.TribeMemberJoinRule
	itemData.OwnerRID = singleBrief.OwnerRID
	itemData.OwnerName = singleBrief.OwnerName
	if singleBrief.IsNameChanged then
		itemData.WorldName = singleBrief.WorldName
	else
		itemData.WorldName = singleBrief.OwnerName .. InteractionTable.WorldNameSuffix.str
	end

	itemData.IsVisitBtn = isVisitBtn
	itemData.IsFavorite = PlayWorldData:WorldFavoriteList_IsExist(singleBrief.WorldGUID)
	itemData.VisitTimestamp = 0
	itemData.LastOnlineTime = 0
	if SubTabID == InteractionTable.WorldPageType.WorldHistoryListPage then
		itemData.VisitTimestamp = MultiPlayerMgr:GetMyVisitTime(singleBrief.OwnerRID)
	else
		itemData.LastOnlineTime = singleBrief.LastOnlineTime and singleBrief.LastOnlineTime:ToUnixTimestamp() or 0
	end
	itemData.OwnerLevel = singleBrief.OwnerLevel
	itemData.OwnerGender = singleBrief.OwnerGender
	itemData.IsRecvPermissionApply = singleBrief.IsRecvPermissionApply
	itemData.IsShowRecommendPlayer = bShowRecommendPlayer and true or false
	itemData.IsOnline = singleBrief.IsOnline
	if MultiPlayerModel.HeadIconIndexCache[singleBrief.OwnerRID] ~= nil and MultiPlayerModel.HeadIconIndexCache[singleBrief.OwnerRID] ~= singleBrief.IconIdx then
	end
	if MultiPlayerModel.HeadIconIndexCache[singleBrief.OwnerRID] ~= nil and (singleBrief.IconIdx == nil or singleBrief.IconIdx == 0) then
		itemData.IconIdx = MultiPlayerModel.HeadIconIndexCache[singleBrief.OwnerRID]
	else
		itemData.IconIdx = singleBrief.IconIdx
	end
	MultiPlayerModel.HeadIconIndexCache[singleBrief.OwnerRID] = singleBrief.IconIdx
	
	itemData.SubTabID = SubTabID
	itemData.PlayerName = singleBrief.PlayerName or singleBrief.OwnerName
	
	return itemData
end
function MultiPlayerWorldList:FillWorldList(SubTabID, isVisitBtn, bShowRecommendPlayer, itemDatas)
	self:ClearListItems()
	if SubTabID == -1 then
		return
    end
	local BriefDataList = {}
	if itemDatas then
		BriefDataList = itemDatas
	else
		BriefDataList = self:GetBriefDataList(SubTabID)
	end

    local itemDataList = {}
	local playerTagIds = {}
	for _, singleBrief in pairs(BriefDataList) do
		table.insert(playerTagIds, singleBrief.OwnerRID)

		local itemData = self:CreatePlayerWorldItemData(singleBrief, i, isVisitBtn, SubTabID, bShowRecommendPlayer)
        if itemData.OwnerName ~= nil and itemData.OwnerName ~= "" then
            itemDataList[#itemDataList + 1] = itemData
        end
    end
	if #playerTagIds > 0 then
		OtherPlayerModel.ReqGatherPlayerQuery(OtherPlayerTable.EGatherClientType.MultiplayerManagerPanel,
			{ UE4.EPzPlayerInfoAggregatedQueryType.SigAndTag }, playerTagIds)
	end
    self:SetListItems(itemDataList)
    self:SetChildPage(SubTabID, BriefDataCount)
end
function MultiPlayerWorldList:SetChildPage(subTabID, briefDataCount)
	if subTabID == InteractionTable.WorldPageType.WorldBriefListPage then
		if briefDataCount == 0 and self.ParentPanel.state == 3 then
			self.ParentPanel.EmptyLabel:SetText("没有找到对应的玩家")
			self.ParentPanel:SetActiveWidgetEmpty()
		else
			self.ParentPanel:SetActiveWidgetSearch()
		end
	end
end
return MultiPlayerWorldList
