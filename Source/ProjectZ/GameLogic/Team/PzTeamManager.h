// PORTFOLIO INTERFACE OUTLINE, not the original complete class declaration.
// Signatures match the retained .cpp methods. Reflection, inheritance, engine and
// project includes are omitted. See docs/DEPENDENCIES.md; this is not buildable alone.
#pragma once

class UPzTeamManager
{
public:
    FPzTeamData GetTeamData();
    FPzTeamData GetMatchedData();
    bool IsInTeam();
    bool IsAllMemberReady();
    int32 GetTeamMemberNum();
    bool IsSelfReady();
    void UrgeMemebrsRequest();
    float GetUrgeMemebrCoolDown();
    UPzTeamComponent* GetRPCComponent(); // External transport accessor.
private:
    FPzTeamData MyTeamData;
    FPzTeamData MyMatchedTeamData;
    float UrgeMemberCoolDown;
};
