// PORTFOLIO INTERFACE OUTLINE, not the original complete class declaration.
// Signatures match the retained .cpp methods. Reflection, inheritance, engine and
// project includes are omitted. See docs/DEPENDENCIES.md; this is not buildable alone.
#pragma once

class UPzBossAssistCallFuncObject
{
public:
    void ExecuteNpcFunc_Implementation();
    bool CheckValidInternal_Implementation();
private:
    int32 AssistId; // Designer-authored support configuration key.
    // OwnerNpc and actor lifecycle are inherited in the project.
};
