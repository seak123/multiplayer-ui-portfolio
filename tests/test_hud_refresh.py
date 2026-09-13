"""Synthetic work/freshness checks, not production profiling or game tests."""
from pathlib import Path
import unittest
from lupa import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class HudRefreshModelTests(unittest.TestCase):
    def model(self, **options):
        vm = LuaRuntime(unpack_returned_tuples=True)
        model_type = vm.execute(
            (ROOT / 'examples/hud-refresh/HudRefreshModel.lua').read_text(encoding='utf-8'))
        service = vm.execute('''
            local service = {cache = {}, live = {}}
            function service:query(id, force)
                if force or not self.cache[id] then
                    local value = self.live[id]
                    self.cache[id] = value and {level = value.level} or nil
                end
                return self.cache[id]
            end
            return service
        ''')
        instance = model_type.new(service, vm.table_from(options))
        # Retain VM with its objects for the duration of each test.
        return vm, service, instance

    def test_stable_roster_stops_repeated_structural_work(self):
        for gated, expected in [(False, 600), (True, 1)]:
            with self.subTest(gated=gated):
                vm, service, model = self.model(gated=gated)
                for role in range(1, 5):
                    model.add_member(model, role)
                for _ in range(600):
                    model.tick(model)
                self.assertEqual(model.counts.notifications, expected)
                self.assertEqual(model.counts.list_rebuilds, expected)
                self.assertEqual(model.counts.row_bindings, expected * 4)
                self.assertEqual(model.counts.detail_api_calls, expected * 4)

    def test_multiple_additions_coalesce_at_next_dispatch(self):
        vm, service, model = self.model()
        model.add_member(model, 1)
        model.add_member(model, 2)
        self.assertEqual(model.counts.notifications, 0)
        model.tick(model)
        self.assertEqual(model.counts.notifications, 1)
        self.assertEqual(model.counts.row_bindings, 2)
        self.assertFalse(model.dirty)

    def test_duplicate_add_does_not_invalidate_roster(self):
        vm, service, model = self.model()
        model.add_member(model, 1)
        model.tick(model)
        for _ in range(10):
            model.add_member(model, 1)
            model.tick(model)
        self.assertEqual(model.counts.notifications, 1)

    def test_removal_refreshes_structure(self):
        vm, service, model = self.model()
        model.add_member(model, 1)
        model.add_member(model, 2)
        model.tick(model)
        model.remove_member(model, 1)
        model.tick(model)
        self.assertIsNone(model.rows[1])
        self.assertIsNotNone(model.rows[2])
        self.assertEqual(model.counts.notifications, 2)

    def test_noop_removal_retains_conservative_historical_boundary(self):
        vm, service, model = self.model()
        model.remove_member(model, 999)
        model.tick(model)
        self.assertEqual(model.counts.notifications, 0)  # No group yet.
        model.add_member(model, 1)
        model.tick(model)
        model.remove_member(model, 999)  # Existing group; absent member.
        model.tick(model)
        self.assertEqual(model.counts.notifications, 2)
        self.assertIsNotNone(model.rows[1])

    def test_support_context_does_not_rebuild_roster(self):
        vm, service, model = self.model()
        model.add_member(model, 1)
        model.tick(model)
        model.set_assist_id(model, 8)
        self.assertTrue(model.support_visible)
        model.set_assist_id(model, 8)
        model.set_assist_id(model, 0)
        self.assertFalse(model.support_visible)
        model.tick(model)
        self.assertEqual(model.counts.overlay_updates, 3)  # Bind, enter, leave.
        self.assertEqual(model.counts.list_rebuilds, 1)
        self.assertEqual(model.counts.detail_api_calls, 1)

    def test_vitals_refresh_independently_of_membership(self):
        vm, service, model = self.model()
        model.add_member(model, 1)
        model.tick(model)
        model.refresh_vitals(model, 1, 0.5, 12)
        model.refresh_vitals(model, 1, 0.25, 18)
        self.assertEqual(model.rows[1].health, 0.25)
        self.assertEqual(model.rows[1].distance, 18)
        self.assertEqual(model.counts.vital_presentations, 2)
        self.assertEqual(model.counts.list_rebuilds, 1)
        self.assertEqual(model.counts.detail_api_calls, 1)

    def test_cache_permitted_binding_can_present_stale_level(self):
        vm, service, model = self.model()
        service.cache[1] = vm.table_from({'level': 10})
        service.live[1] = vm.table_from({'level': 11})
        model.add_member(model, 1)
        model.tick(model)
        model.advance_detail_clock(model, 10)
        self.assertEqual(model.rows[1].level, 10)
        self.assertEqual(model.counts.forced_detail_calls, 0)

    def test_forced_binding_updates_level(self):
        vm, service, model = self.model(force_on_bind=True)
        service.cache[1] = vm.table_from({'level': 10})
        service.live[1] = vm.table_from({'level': 11})
        model.add_member(model, 1)
        model.tick(model)
        self.assertEqual(model.rows[1].level, 11)
        self.assertEqual(model.counts.forced_detail_calls, 1)

    def test_periodic_details_refresh_without_structural_rebind(self):
        vm, service, model = self.model(detail_interval=2)
        service.live[1] = vm.table_from({'level': 10})
        model.add_member(model, 1)
        model.tick(model)
        service.live[1] = vm.table_from({'level': 11})
        model.advance_detail_clock(model, 1)
        self.assertEqual(model.rows[1].level, 10)
        model.advance_detail_clock(model, 1)
        self.assertEqual(model.rows[1].level, 11)
        self.assertEqual(model.counts.list_rebuilds, 1)
        self.assertEqual(model.counts.row_bindings, 1)
        self.assertEqual(model.counts.detail_api_calls, 2)
        self.assertEqual(model.counts.forced_detail_calls, 1)

    def test_cache_miss_can_fetch_without_force(self):
        vm, service, model = self.model()
        service.live[1] = vm.table_from({'level': 12})
        model.add_member(model, 1)
        model.tick(model)
        self.assertEqual(model.rows[1].level, 12)
        self.assertEqual(model.counts.forced_detail_calls, 0)
        self.assertEqual(model.counts.detail_api_calls, 1)


if __name__ == '__main__':
    unittest.main(verbosity=2)
