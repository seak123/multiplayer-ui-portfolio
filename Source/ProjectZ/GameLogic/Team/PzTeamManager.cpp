// PORTFOLIO SOURCE EXCERPT. Retained implementation; omitted project dependencies.
// See matching .h interface outline and docs/DEPENDENCIES.md. Not standalone UE code.
#include "PzTeamManager.h"

FPzTeamData UPzTeamManager::GetTeamData()
{
	return MyTeamData;
}

FPzTeamData UPzTeamManager::GetMatchedData()
{
	return MyMatchedTeamData;
}

bool UPzTeamManager::IsInTeam()
{
	return TEAM_IS_VALID_ID64(MyTeamData.TeamRid);
}

bool UPzTeamManager::IsAllMemberReady()
{
	for (int32 Index = 0; Index < MyTeamData.Member.Num(); ++Index)
	{
		if (!MyTeamData.Member[Index].bReady)return false;
	}
	return true;
}

int32 UPzTeamManager::GetTeamMemberNum()
{
	return MyTeamData.Member.Num();
}

bool UPzTeamManager::IsSelfReady()
{
	for (int32 Index = 0; Index < MyTeamData.Member.Num(); ++Index)
	{
		if (MyTeamData.Member[Index].ActorRid == GameUtil::GetSelfRoleId(this) && MyTeamData.Member[Index].bReady)
			return true;
	}
	return false;
}

void UPzTeamManager::UrgeMemebrsRequest()
{
	if (FMath::IsNearlyZero(UrgeMemberCoolDown))
	{
		UrgeMemberCoolDown = 15.f;
		GetRPCComponent()->Svr_TeamLeaderUrgeReq(MyTeamData.TeamRid);
	}
}

float UPzTeamManager::GetUrgeMemebrCoolDown()
{
	return UrgeMemberCoolDown;
}
