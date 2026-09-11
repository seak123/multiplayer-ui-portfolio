// PORTFOLIO SOURCE EXCERPT. Retained implementation; omitted project dependencies.
// See matching .h interface outline and docs/DEPENDENCIES.md. Not standalone UE code.
#include "PzTeamFunctionLibrary.h"

UPzTeamManager* UPzTeamFunctionLibrary::GetTeamManager(UObject* Context)
{
	return GameUtil::GetGameInstanceSubsystem<UPzTeamManager>(Context);
}

void UPzTeamFunctionLibrary::Svr_ActorReplyInviteReq(UObject* Context, const bool IsAccept, const int Target,
                                                     int64 InviterRid, int64 TeamRid)
{
	UPzTeamFunctionLibrary::GetTeamManager(Context)->GetRPCComponent()->Svr_ActorReplyInviteReq(
		IsAccept, Target, InviterRid, TeamRid);
}

void UPzTeamFunctionLibrary::Svr_ChangeTeamTargetReq(UObject* Context, const int32 Target, const int32 Reason)
{
	UPzTeamFunctionLibrary::GetTeamManager(Context)->GetRPCComponent()->Svr_ChangeTeamTargetReq(
		Target, Reason);
}

void UPzTeamFunctionLibrary::Svr_SendKickOutReq(UObject* Context, const int64 TargetRid, const int64 TeamRid)
{
	UPzTeamFunctionLibrary::GetTeamManager(Context)->GetRPCComponent()->Svr_SendKickOutReq(
		TargetRid, TeamRid);
}

void UPzTeamFunctionLibrary::Svr_TeamMatchReq(UObject* Context, const bool DoMatch, const int Target, bool bForce)
{
	UPzTeamFunctionLibrary::GetTeamManager(Context)->GetRPCComponent()->Svr_TeamMatchReq(
		DoMatch, Target, bForce);
}

void UPzTeamFunctionLibrary::Svr_TeamMemberConfirmReq(UObject* Context, const int64 LeaderRid, const int64 TeamRid,
                                                      const bool IsAgreed, const bool bMatchEnter)
{
	UPzTeamFunctionLibrary::GetTeamManager(Context)->GetRPCComponent()->Svr_TeamMemberConfirmReq(
		LeaderRid, TeamRid, IsAgreed, bMatchEnter);
}

void UPzTeamFunctionLibrary::Svr_InviteActorReq(UObject* Context, const int64 TargetRid, const int Target)
{
	UPzTeamFunctionLibrary::GetTeamManager(Context)->GetRPCComponent()->Svr_InviteActorReq(
		TargetRid, Target);
}

void UPzTeamFunctionLibrary::Svr_TeamMatchRelationTopNReq(UObject* Context, int Count)
{
	UPzTeamFunctionLibrary::GetTeamManager(Context)->GetRPCComponent()->Svr_TeamMatchRelationTopNReq(
		Count);
}

void UPzTeamFunctionLibrary::Svr_SendLeaveReq(UObject* Context, const int64 TeamRid)
{
	UPzTeamFunctionLibrary::GetTeamManager(Context)->GetRPCComponent()->Svr_SendLeaveReq(
		TeamRid);
}

void UPzTeamFunctionLibrary::Svr_TeamLeaderEnterReq(UObject* Context, const int64 TeamRid, const int32 Target)
{
	UPzTeamFunctionLibrary::GetTeamManager(Context)->GetRPCComponent()->Svr_TeamLeaderEnterReq();
}

void UPzTeamFunctionLibrary::Svr_TeamMemberReadyReq(UObject* Context, const int64 TeamRid, const int32 Target,
                                                    bool bIsReady)
{
	UPzTeamFunctionLibrary::GetTeamManager(Context)->GetRPCComponent()->Svr_TeamMemberReadyReq(
		TeamRid, Target, bIsReady);
}

void UPzTeamFunctionLibrary::Svr_DismissTeamReq(UObject* Context, const int64 TeamRid)
{
	UPzTeamFunctionLibrary::GetTeamManager(Context)->GetRPCComponent()->Svr_DismissTeamReq(
		TeamRid);
}

void UPzTeamFunctionLibrary::Svr_TeamLeaderUrgeReq(UObject* Context, const int64 TeamRid)
{
	UPzTeamFunctionLibrary::GetTeamManager(Context)->GetRPCComponent()->Svr_TeamLeaderUrgeReq(
		TeamRid);
}

void UPzTeamFunctionLibrary::Svr_ApplyJoinTeamReq(UObject* Context, const int64 TargetActorRid, const int TeamTarget)
{
	UPzTeamFunctionLibrary::GetTeamManager(Context)->GetRPCComponent()->Svr_ApplyJoinTeamReq(
		TargetActorRid, TeamTarget);
}

void UPzTeamFunctionLibrary::Svr_CreateTeamReq(UObject* Context, const int Target, const int CbData, const bool IsMatch)
{
	UPzTeamFunctionLibrary::GetTeamManager(Context)->GetRPCComponent()->Svr_CreateTeamReq(
		Target,CbData,IsMatch);
}

int32 UPzTeamFunctionLibrary::GetCurrentRobotID(UObject* Context)
{
	if(APzGameState* PzGameState = Cast<APzGameState>(GameUtil::GetGameState(Context)))
	{
		return PzGameState->AssistRobotId;
	}
	return 0;
}
