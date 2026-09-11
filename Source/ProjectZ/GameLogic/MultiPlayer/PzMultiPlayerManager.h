// PORTFOLIO INTERFACE OUTLINE, not the original complete class declaration.
// Signatures match the retained .cpp methods. Reflection, inheritance, engine and
// project includes are omitted. See docs/DEPENDENCIES.md; this is not buildable alone.
#pragma once

class UPzMultiPlayerManager
{
public:
    void Tick( float DeltaTime );
    void RequestAssistPlayer(uint64 RoleID, const int AssistId);
    bool IsAssistPlayerValid(uint64 RoleID);
    void ResetAssistRequestTimer(uint64 RoleID);
    void PullAssistRecommendData(const int AssistId); // External recommendation service.
private:
    TMap<uint64, float> AssistRequestTimers;
};
