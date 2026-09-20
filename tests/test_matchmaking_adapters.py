"""Executable reconstruction of the later design; not historical game tests."""
from pathlib import Path
import unittest

from lupa import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class MatchmakingAdapters(unittest.TestCase):
    def setUp(self):
        self.vm = LuaRuntime(unpack_returned_tuples=True)
        self.vm.globals().examplePath = (ROOT / 'examples/matchmaking-adapters/?.lua').as_posix()
        self.vm.execute('''
            package.path = examplePath .. ";" .. package.path
            Contract = require("MatchContract")
            Presenter = require("SharedTeamPresenter")
            calls, updates = {}, {}
            arena = {
                ResolveArenaId = function(_, target) if target == 42 then return 900 end end,
                StartSolo = function(_, id) table.insert(calls, {"solo", id}); return true end,
                StartParty = function(_, id) table.insert(calls, {"party", id}); return true end,
                Cancel = function(_) table.insert(calls, {"arena_cancel"}); return true end,
            }
            team = {
                SetMatching = function(_, id, enabled)
                    table.insert(calls, {"team", id, enabled}); return true
                end,
            }
            lifecycle = {}
            function addEventPort(service, name)
                service.snapshots, service.listeners, service.nextToken = {}, {}, 0
                function service:GetSnapshot(target) return self.snapshots[target] end
                function service:Subscribe(target, callback)
                    self.nextToken = self.nextToken + 1
                    local token = self.nextToken
                    self.listeners[token] = {target = target, callback = callback}
                    table.insert(lifecycle, name .. ":subscribe")
                    return function()
                        self.listeners[token] = nil
                        table.insert(lifecycle, name .. ":unsubscribe")
                    end
                end
                function service:Emit(target, snapshot)
                    self.snapshots[target] = snapshot
                    for _, listener in pairs(self.listeners) do
                        if listener.target == target then listener.callback() end
                    end
                end
                function service:ListenerCount()
                    local count = 0
                    for _ in pairs(self.listeners) do count = count + 1 end
                    return count
                end
            end
            addEventPort(arena, "arena")
            addEventPort(team, "team")
            model, registry = require("Composition")({arena = arena, team = team}, function(view)
                table.insert(updates, view)
                panel, notice = Presenter.Panel(view), Presenter.Notice(view)
            end)
            party = {id = 7, leaderId = 11, localPlayerId = 11, members = {11, 22}}
            model:SetParty(party)
        ''')

    def test_distinct_protocols_share_searching_presentation(self):
        self.vm.execute('''
            model:SelectMode("arena", {targetId = 42})
            model:OnMatchSnapshot("arena", {queueStage = "QUEUED"})
            local arenaLabel = panel.label
            model:SelectMode("dungeon", {targetId = 42})
            model:OnMatchSnapshot("dungeon", {teamPhase = "FINDING_MEMBERS"})
            assert(panel.label == arenaLabel and notice.label == panel.label)
            assert(model:GetViewData().matchmaking.phase == "searching")
        ''')

    def test_mode_specific_details_are_not_flattened(self):
        self.vm.execute('''
            model:SelectMode("arena", {targetId = 42})
            model:OnMatchSnapshot("arena", {queueStage = "NONE", queueLabel = "Three versus three"})
            assert(panel.detailsKey == "arena_queue")
            assert(panel.details.queueLabel == "Three versus three")
            model:SelectMode("dungeon", {targetId = 42})
            model:OnMatchSnapshot("dungeon", {teamPhase = "FORMING", objective = "Clear the dungeon"})
            assert(panel.detailsKey == "dungeon_objective")
            assert(panel.details.objective == "Clear the dungeon" and panel.details.queueLabel == nil)
        ''')

    def test_party_and_matched_participants_remain_separate(self):
        self.vm.execute('''
            model:SelectMode("dungeon", {targetId = 42})
            model:OnMatchSnapshot("dungeon", {teamPhase = "READY_CHECK", matchMembers = {11, 22, 33}})
            assert(#panel.members == 2 and #panel.matchedMembers == 3 and notice.memberCount == 2)
            assert(model:GetViewData().matchmaking.phase == "awaiting_confirmation")
        ''')

    def test_arena_start_converts_target_and_routes_party_command(self):
        self.vm.execute('''
            model:SelectMode("arena", {targetId = 42})
            model:OnMatchSnapshot("arena", {queueStage = "NONE"})
            assert(model:StartMatch())
            assert(#calls == 1 and calls[1][1] == "party" and calls[1][2] == 900)
        ''')

    def test_arena_start_routes_solo_command(self):
        self.vm.execute('''
            model:SetParty({localPlayerId = 11, members = {11}})
            model:SelectMode("arena", {targetId = 42})
            model:OnMatchSnapshot("arena", {queueStage = "NONE"})
            assert(model:StartMatch() and calls[1][1] == "solo" and calls[1][2] == 900)
        ''')

    def test_dungeon_start_uses_team_service_without_arena_conversion(self):
        self.vm.execute('''
            model:SelectMode("dungeon", {targetId = 123})
            model:OnMatchSnapshot("dungeon", {teamPhase = "FORMING"})
            assert(model:StartMatch())
            assert(calls[1][1] == "team" and calls[1][2] == 123 and calls[1][3] == true)
        ''')

    def test_cancellation_uses_selected_service(self):
        self.vm.execute('''
            model:SelectMode("arena", {targetId = 42})
            model:OnMatchSnapshot("arena", {queueStage = "QUEUED"})
            assert(model:CancelMatch() and calls[1][1] == "arena_cancel")
            model:SelectMode("dungeon", {targetId = 123})
            model:OnMatchSnapshot("dungeon", {teamPhase = "FINDING_MEMBERS"})
            assert(model:CancelMatch())
            assert(calls[2][1] == "team" and calls[2][2] == 123 and calls[2][3] == false)
        ''')

    def test_dispatch_does_not_optimistically_change_match_phase(self):
        self.vm.execute('''
            model:SelectMode("dungeon", {targetId = 42})
            model:OnMatchSnapshot("dungeon", {teamPhase = "FORMING"})
            local count = #updates
            model:StartMatch()
            assert(model:GetViewData().matchmaking.phase == "idle" and #updates == count)
            model:OnMatchSnapshot("dungeon", {teamPhase = "FINDING_MEMBERS"})
            model:CancelMatch()
            assert(model:GetViewData().matchmaking.phase == "searching")
        ''')

    def test_member_role_disables_leader_commands(self):
        self.vm.execute('''
            party.localPlayerId = 22
            model:SetParty(party)
            model:SelectMode("dungeon", {targetId = 42})
            model:OnMatchSnapshot("dungeon", {teamPhase = "FORMING"})
            assert(not model:StartMatch())
            model:OnMatchSnapshot("dungeon", {teamPhase = "FINDING_MEMBERS"})
            assert(not model:CancelMatch() and #calls == 0)
        ''')

    def test_unknown_stage_is_visible_and_disables_commands(self):
        self.vm.execute('''
            model:SelectMode("arena", {targetId = 42})
            model:OnMatchSnapshot("arena", {queueStage = "NEW_SERVER_STAGE"})
            local view = model:GetViewData()
            assert(view.matchmaking.phase == "unknown")
            assert(view.matchmaking.sourceStage == "NEW_SERVER_STAGE")
            assert(not model:StartMatch() and not model:CancelMatch() and #calls == 0)
            assert(panel.label == "Status unavailable")
        ''')

    def test_mode_switch_preserves_party_and_clears_old_matching_details(self):
        self.vm.execute('''
            model:SelectMode("arena", {targetId = 42})
            model:OnMatchSnapshot("arena", {queueStage = "QUEUED", queueLabel = "old"})
            model:SelectMode("dungeon", {targetId = 123})
            assert(model:GetViewData().matchmaking.phase == "unavailable")
            assert(#panel.members == 2 and panel.detailsKey == nil and not panel.actions.cancel)
            assert(not model:OnMatchSnapshot("arena", {queueStage = "ENTERING"}))
            assert(model:GetViewData().matchmaking.phase == "unavailable")
        ''')

    def test_unsupported_mode_does_not_replace_active_mode(self):
        self.vm.execute('''
            model:SelectMode("arena", {targetId = 42})
            local ok, err = pcall(function() model:SelectMode("missing", {targetId = 12}) end)
            assert(not ok and string.find(err, "unsupported mode"))
            assert(model:GetViewData().mode == "arena")
        ''')

    def test_registration_rejects_duplicates_and_missing_contract_methods(self):
        self.vm.execute('''
            local ok = pcall(function() registry:Register("arena", function() return {} end) end)
            assert(not ok)
            registry:Register("broken", function() return {BuildState = function() end} end)
            local valid, err = pcall(function() registry:Create("broken") end)
            assert(not valid and string.find(err, "adapter missing Start"))
        ''')

    def test_new_mode_requires_registration_not_shared_model_branches(self):
        self.vm.execute('''
            registry:Register("synthetic", function()
                return {
                    BuildState = function(_, context, raw)
                        return Contract.State(raw.active and "searching" or "idle", raw.active,
                            "synthetic_detail", {value = raw.value})
                    end,
                    Start = function() table.insert(calls, {"synthetic_start"}); return true end,
                    Cancel = function() table.insert(calls, {"synthetic_cancel"}); return true end,
                    RegisterEvents = function() end,
                    UnregisterEvents = function() end,
                    ReadSnapshot = function() return nil end,
                }
            end)
            model:SelectMode("synthetic", {targetId = 321})
            model:OnMatchSnapshot("synthetic", {active = false, value = "test-only"})
            assert(panel.detailsKey == "synthetic_detail" and panel.details.value == "test-only")
            assert(model:StartMatch() and calls[1][1] == "synthetic_start")
            model:OnMatchSnapshot("synthetic", {active = true})
            assert(panel.label == notice.label and model:CancelMatch())
        ''')

    def test_snapshot_and_view_copies_do_not_mutate_model_state(self):
        self.vm.execute('''
            party.members[1] = 999
            assert(model:GetViewData().party.members[1] == 11)
            model:SelectMode("dungeon", {targetId = 42})
            local raw = {teamPhase = "READY_CHECK", matchMembers = {11, 22}}
            model:OnMatchSnapshot("dungeon", raw)
            raw.matchMembers[1] = 999
            local view = model:GetViewData()
            view.matchmaking.matchedMembers[1] = 888
            assert(model:GetViewData().matchmaking.matchedMembers[1] == 11)
        ''')

    def test_unmapped_arena_target_does_not_send_request(self):
        self.vm.execute('''
            model:SelectMode("arena", {targetId = 123})
            model:OnMatchSnapshot("arena", {queueStage = "NONE"})
            local ok, err = pcall(function() model:StartMatch() end)
            assert(not ok and string.find(err, "unmapped arena target") and #calls == 0)
        ''')

    def test_select_reads_data_that_existed_before_subscription(self):
        self.vm.execute('''
            team.snapshots[42] = {teamPhase = "READY_CHECK", matchMembers = {11,22,33}}
            model:SelectMode("dungeon", {targetId = 42})
            assert(team:ListenerCount() == 1)
            assert(model:GetViewData().matchmaking.phase == "awaiting_confirmation")
            assert(#panel.matchedMembers == 3)
        ''')

    def test_switch_unsubscribes_before_subscribing_and_follows_new_events(self):
        self.vm.execute('''
            model:SelectMode("arena", {targetId = 42})
            model:SelectMode("dungeon", {targetId = 123})
            assert(lifecycle[2] == "arena:unsubscribe" and lifecycle[3] == "team:subscribe")
            assert(arena:ListenerCount() == 0 and team:ListenerCount() == 1)
            local count = #updates
            arena:Emit(42, {queueStage = "ENTERING"})
            assert(#updates == count)
            team:Emit(123, {teamPhase = "FINDING_MEMBERS"})
            assert(panel.label == "Finding teammates")
        ''')

    def test_repeated_switches_and_disposal_release_listeners(self):
        self.vm.execute('''
            for i = 1, 5 do
                model:SelectMode("arena", {targetId = 42})
                model:SelectMode("dungeon", {targetId = 123})
            end
            assert(arena:ListenerCount() == 0 and team:ListenerCount() == 1)
            model:Dispose()
            assert(team:ListenerCount() == 0 and arena:ListenerCount() == 0)
            local count = #updates
            team:Emit(123, {teamPhase = "TRANSFERRING"})
            assert(#updates == count)
        ''')

    def test_queued_old_listener_is_ignored_even_after_returning_to_same_mode(self):
        self.vm.execute('''
            model:SelectMode("arena", {targetId = 42})
            local oldCallback
            for _, item in pairs(arena.listeners) do oldCallback = item.callback end
            model:SelectMode("dungeon", {targetId = 123})
            model:SelectMode("arena", {targetId = 42})
            local count = #updates
            oldCallback()
            assert(#updates == count)
        ''')


if __name__ == '__main__':
    unittest.main()
