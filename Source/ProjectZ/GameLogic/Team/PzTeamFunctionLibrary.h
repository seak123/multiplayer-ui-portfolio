// PORTFOLIO INTERFACE OUTLINE, not the original complete class declaration.
// Signatures match the retained .cpp methods. Reflection, inheritance, engine and
// project includes are omitted. See docs/DEPENDENCIES.md; this is not buildable alone.
#pragma once

class UPzTeamFunctionLibrary
{
public:
    static UPzTeamManager* GetTeamManager(UObject* Context);
    static void Svr_ActorReplyInviteReq(UObject* Context, const bool IsAccept, const int Target,
                                                         int64 InviterRid, int64 TeamRid);
    static void Svr_ChangeTeamTargetReq(UObject* Context, const int32 Target, const int32 Reason);
    static void Svr_SendKickOutReq(UObject* Context, const int64 TargetRid, const int64 TeamRid);
    static void Svr_TeamMatchReq(UObject* Context, const bool DoMatch, const int Target, bool bForce);
    static void Svr_TeamMemberConfirmReq(UObject* Context, const int64 LeaderRid, const int64 TeamRid,
                                                          const bool IsAgreed, const bool bMatchEnter);
    static void Svr_InviteActorReq(UObject* Context, const int64 TargetRid, const int Target);
    static void Svr_TeamMatchRelationTopNReq(UObject* Context, int Count);
    static void Svr_SendLeaveReq(UObject* Context, const int64 TeamRid);
    static void Svr_TeamLeaderEnterReq(UObject* Context, const int64 TeamRid, const int32 Target);
    static void Svr_TeamMemberReadyReq(UObject* Context, const int64 TeamRid, const int32 Target,
                                                        bool bIsReady);
    static void Svr_DismissTeamReq(UObject* Context, const int64 TeamRid);
    static void Svr_TeamLeaderUrgeReq(UObject* Context, const int64 TeamRid);
    static void Svr_ApplyJoinTeamReq(UObject* Context, const int64 TargetActorRid, const int TeamTarget);
    static void Svr_CreateTeamReq(UObject* Context, const int Target, const int CbData, const bool IsMatch);
    static int32 GetCurrentRobotID(UObject* Context);

};
