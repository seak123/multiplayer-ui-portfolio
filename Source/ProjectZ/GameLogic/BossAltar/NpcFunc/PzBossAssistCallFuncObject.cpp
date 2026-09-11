// PORTFOLIO SOURCE EXCERPT. Retained implementation; omitted project dependencies.
// See matching .h interface outline and docs/DEPENDENCIES.md. Not standalone UE code.
#include "PzBossAssistCallFuncObject.h"

void UPzBossAssistCallFuncObject::ExecuteNpcFunc_Implementation()
{
	APzCharacterInteractiveNPC* NpcCharacter = OwnerNpc.Get();

	if (NpcCharacter && !NpcCharacter->IsPendingKillPending())
	{
		PZ_FIRE_EVENT_LUA_OneParam(this, "OnRequestOpenAssistPanel", AssistId);
	}
}

bool UPzBossAssistCallFuncObject::CheckValidInternal_Implementation()
{
	const FRES_INVITE_ASSIST* ResCfg = FPzBinInviteAssistTable::GetConfigByID(this, AssistId);
	if (ResCfg)
	{
		tagE_INVITE_ASSIST_ITEM_TYPE AssistType = static_cast<tagE_INVITE_ASSIST_ITEM_TYPE>(ResCfg->stAssist_item.
			iAssist_type);

		if (AssistType == tagE_INVITE_ASSIST_ITEM_TYPE::E_INVITE_ASSIST_ITEM_TYPE_BOSS_PROGRESS_ID)
		{
			if (GameUtil::GetGameInstanceSubsystem<UPzBossProgressManager>(this)->GetBossInfoDataByInfoId(
				ResCfg->stAssist_item.iAssist_param).State != proto::PZ_BOSS_STATE_FOUND)
			{
				return false;
			}
		}
	}

	if (APzCharacterInteractiveNPC* NpcCharacter = OwnerNpc.Get())
	{
		if (APzBossAltarCharacterNPC* BossAltarCharacter = Cast<APzBossAltarCharacterNPC>(NpcCharacter))
		{
			APzPlayerController* PC = Cast<APzPlayerController>(GameUtil::GetSelfPlayerController(this));
			check(PC);
			if (BossAltarCharacter->CanShowInteractionCheck(PC, true) != 0)return false;
		}
	}
	return true;
}
