// PORTFOLIO SOURCE EXCERPT. Retained implementation; omitted project dependencies.
// See matching .h interface outline and docs/DEPENDENCIES.md. Not standalone UE code.
#include "PzMultiPlayerManager.h"

void UPzMultiPlayerManager::Tick( float DeltaTime )
{
	for(auto Iter = AssistRequestTimers.CreateIterator();Iter;++Iter)
	{
		float CoolDown = Iter->Value - DeltaTime;
		if(CoolDown<=0)
		{
			Iter.RemoveCurrent();
			PZ_FIRE_EVENT_LUA(this,"OnInviteAssistRefresh");
		}else
		{
			Iter->Value = CoolDown;
		}
	}
}

void UPzMultiPlayerManager::RequestAssistPlayer(uint64 RoleID, const int AssistId)
{
	const FRES_INVITE_ASSIST* ResCfg = FPzBinInviteAssistTable::GetConfigByID(this, AssistId);
	if (ResCfg == nullptr) return;

	if(AssistRequestTimers.Num() > 4)
	{
		PZ_FIRE_EVENT_LUA_TwoParams(this, "AppendNotice", EKGNoticeType::Normal, "到达邀请上限,请稍后再试");
		return;
	}
	

	if(const APzPlayerState* PlayerState = Cast<APzPlayerState>(GameUtil::GetSelfPlayerState(this)))
	{
		PlayerState->MultiPlayerComponent->Svr_InviteAssistReq(RoleID,ResCfg->stAssist_item.iAssist_type,AssistId);
	}
	AssistRequestTimers.Emplace(RoleID,10.f);
	PZ_FIRE_EVENT_LUA(this,"OnInviteAssistRefresh");
}

bool UPzMultiPlayerManager::IsAssistPlayerValid(uint64 RoleID)
{
	return !AssistRequestTimers.Contains(RoleID);
}

void UPzMultiPlayerManager::ResetAssistRequestTimer(uint64 RoleID)
{
	if(AssistRequestTimers.Contains(RoleID))
	{
		AssistRequestTimers.Remove(RoleID);
		PZ_FIRE_EVENT_LUA(this,"OnInviteAssistRefresh");
	}
}
