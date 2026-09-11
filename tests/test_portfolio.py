"""Tests added for this portfolio; never represented as production test history.

Run from the repository root: python -m unittest discover -s tests -v
"""
from pathlib import Path
import hashlib
import itertools
import json
import re
import unittest
from lupa import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
LUA = ROOT / 'Content/Lua/GameLogics'

def runtime():
    vm = LuaRuntime(unpack_returned_tuples=True)
    vm.execute((ROOT/'tests/runtime.lua').read_text(encoding='utf-8'))
    return vm

def load(vm, path):
    code = path.read_text(encoding='utf-8')
    # Keep documentation placeholders readable, but fail if a test enters one.
    code = code.replace('-- Implementation omitted.', 'error("Omitted implementation reached")')
    return vm.execute(code)

class SourceIntegrity(unittest.TestCase):
    def test_all_lua_files_parse_without_running_game_services(self):
        vm = LuaRuntime()
        compile_only = vm.eval('function(code, name) local f,e=load(code,name); assert(f,e) end')
        for path in ROOT.rglob('*.lua'):
            with self.subTest(file=str(path.relative_to(ROOT))):
                compile_only(path.read_text(encoding='utf-8'), path.name)

    def test_omitted_body_is_rejected_by_test_loader(self):
        vm = runtime()
        model = load(vm, LUA/'Team/TeamModel.lua')
        with self.assertRaisesRegex(Exception, 'Omitted implementation reached'):
            model.CanTracePlayer(model)

    def test_implementation_map_has_no_project_revision_fields(self):
        manifest = json.loads((ROOT/'docs/source-manifest.json').read_text(encoding='utf-8'))
        self.assertEqual(set(manifest), {'description', 'sources'})
        for item in manifest['sources']:
            self.assertEqual(set(item), {'path', 'retained_methods', 'omitted_bodies', 'sha256'})

    def test_export_hashes_match_manifest(self):
        manifest = json.loads((ROOT/'docs/source-manifest.json').read_text(encoding='utf-8'))
        for item in manifest['sources']:
            with self.subTest(path=item['path']):
                # Manifest hashes use UTF-8 text with LF line endings, independent of checkout OS.
                content=(ROOT/item['path']).read_text(encoding='utf-8').encode('utf-8')
                self.assertEqual(hashlib.sha256(content).hexdigest(),item['sha256'])

    def test_local_document_links_resolve(self):
        for path in ROOT.rglob('*.md'):
            for link in re.findall(r'\]\(([^)]+)\)', path.read_text(encoding='utf-8')):
                if '://' in link or link.startswith('#'):
                    continue
                with self.subTest(file=path.name,link=link):
                    self.assertTrue((path.parent/link.split('#')[0]).exists())

class TeamPresentation(unittest.TestCase):
    def setUp(self):
        self.vm = runtime()
        load(self.vm,LUA/'Team/TeamTypes.lua')
        self.model=load(self.vm,LUA/'Team/TeamModel.lua')
        self.model._init(self.model)
        self.vm.globals().instrumentFrames(self.model)

    def test_role_readiness_and_matching_state_matrix(self):
        g=self.vm.globals()
        for matching,in_team,leader,ready,all_ready,count in itertools.product(
                [False,True],[False,True],[False,True],[False,True],[False,True],[1,2]):
            with self.subTest(matching=matching,in_team=in_team,leader=leader,
                              ready=ready,all_ready=all_ready,count=count):
                g.state.inTeam=in_team
                g.state.selfReady=ready
                g.state.allReady=all_ready
                g.state.count=count
                self.model.teamStage=2 if matching else 1
                self.model.myTeamRid=123 if in_team else 0
                self.model.myTeamLeaderRid=101 if leader else 202
                self.model.UpdateTeamFrameViewState(self.model)
                expected=3 if matching else (4 if leader and all_ready and count>1 else 2) if in_team and leader else (2 if ready else 1) if in_team else 2
                self.assertEqual(self.model.HUDState,expected)

    def test_hide_restore_and_matching_view_policy(self):
        g=self.vm.globals()
        self.model.myTeamRid=123
        self.model.teamStage=1
        self.model.UpdateTeamFrameViewState(self.model)
        self.assertIsNotNone(g.frames[20], 'absent full panel allows notice')
        g.frames[10]=g.widget()
        self.model.UpdateTeamFrameViewState(self.model)
        self.assertIsNone(g.frames[20], 'non-matching full panel suppresses notice')
        self.model.teamStage=2
        self.model.UpdateTeamFrameViewState(self.model)
        self.assertIsNotNone(g.frames[20], 'matching can retain both views')
        g.state.visible=False
        self.model.UpdateTeamFrameViewState(self.model)
        self.assertIsNone(g.frames[10])
        self.assertIsNone(g.frames[20])

    def test_no_team_clears_views(self):
        g=self.vm.globals()
        g.frames[10]=g.widget()
        g.frames[20]=g.widget()
        self.model.UpdateTeamFrameViewState(self.model)
        self.assertIsNone(g.frames[10])
        self.assertIsNone(g.frames[20])

    def test_native_matching_signal_is_considered(self):
        self.model.teamStage=0
        self.vm.globals().state.csq=9
        self.assertTrue(self.model.IsMatching(self.model))

class HistoricalRefresh(unittest.TestCase):
    def fixture(self,label,busy=False):
        vm=runtime()
        item=load(vm,ROOT/f'tests/fixtures/assist_refresh_{label}.lua')
        vm.globals().attachItem(item)
        vm.globals().activeItem=item
        vm.globals().state.busy=busy
        vm.execute('EventSystem.Fire=function(name) if name=="OnAssistPlayerWatchCompleted" then activeItem:OnAssistPlayerWatchCompleted() end end')
        return vm,item

    def test_before_fix_feedback_loop_remains_after_bounded_drain(self):
        vm,item=self.fixture('before')
        item.RefreshAssistGroup(item)
        processed,pending=vm.globals().drain(12)
        self.assertEqual(processed,12)
        self.assertGreater(pending,0)
        self.assertGreater(vm.globals().requests,12)

    def test_after_fix_completion_does_not_request_again(self):
        vm,item=self.fixture('after')
        item.RefreshAssistGroup(item)
        self.assertEqual(vm.globals().drain(12),(1,0))
        self.assertEqual(vm.globals().requests,1)
        self.assertEqual(item.UIReqAssistSwitcher.index,0)

    def test_busy_branch_preserved_after_fix(self):
        vm,item=self.fixture('after',busy=True)
        item.RefreshAssistGroup(item)
        self.assertEqual(vm.globals().drain(12),(1,0))
        self.assertEqual(item.UIReqAssistSwitcher.index,3)

class CurrentSupportPresentation(unittest.TestCase):
    def setUp(self):
        self.vm=runtime()
        self.item=load(self.vm,LUA/'MultiPlayer/MultiPlayerWorldItem.lua')
        self.vm.globals().attachItem(self.item)

    def test_complete_availability_states(self):
        g=self.vm.globals()
        for online,busy,pending,expected in [
                (False,False,False,4),(False,True,True,4),
                (True,True,False,3),(True,False,False,0),(True,False,True,1)]:
            with self.subTest(online=online,busy=busy,pending=pending):
                self.item.data.IsOnline=online
                g.state.busy=busy
                g.state.pending=pending
                self.item.RefreshAssistState(self.item)
                self.assertEqual(self.item.UIReqAssistSwitcher.index,expected)

    def test_current_completion_terminates(self):
        self.item.RefreshAssistGroup(self.item)
        self.assertEqual(self.vm.globals().drain(12),(1,0))
        self.assertEqual(self.vm.globals().requests,1)

    def test_global_invite_refresh_preserves_offline_state(self):
        self.item.data.IsOnline=False
        self.item.OnInviteAssistRefresh(self.item)
        self.assertEqual(self.item.UIReqAssistSwitcher.index,4)

    def test_robot_branch_does_not_query_real_player_details(self):
        self.item.RobotID=55
        self.vm.globals().state.robot=55
        self.item.RefreshAssistGroup(self.item)
        self.assertEqual(self.item.UIReqAssistSwitcher.index,2)
        self.assertEqual(self.vm.globals().requests,0)

    @unittest.expectedFailure
    def test_known_cache_miss_assumption_for_online_item(self):
        # Documents a real limitation; does not silently rewrite exported source.
        self.vm.globals().records[101]=None
        self.item.RefreshAssistState(self.item)
        self.assertEqual(self.item.UIReqAssistSwitcher.index,4)

if __name__ == '__main__':
    unittest.main(verbosity=2)
