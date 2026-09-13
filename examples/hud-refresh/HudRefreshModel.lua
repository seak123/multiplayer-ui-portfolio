-- Independently written portfolio model, NOT a production implementation.
-- Native notification, Lua roster binding and detail policy are represented in
-- one Lua module to make their separate costs testable without Unreal.
-- One tracking-reason group; no network, async lifetime, rendering or pooling.
local Model = {}
Model.__index = Model

function Model.new(details, options)
    options = options or {}
    assert(type(details.query) == "function", "detail service required")
    return setmetatable({
        details = details,
        gated = options.gated ~= false,
        force_on_bind = options.force_on_bind == true,
        detail_interval = options.detail_interval,
        detail_elapsed = 0,
        members = {},
        reason_exists = false,
        dirty = false,
        assist_id = 0,
        rows = {},
        counts = {
            notifications = 0, list_rebuilds = 0, row_bindings = 0,
            detail_api_calls = 0, forced_detail_calls = 0,
            detail_presentations = 0, overlay_updates = 0,
            vital_presentations = 0,
        },
    }, Model)
end

function Model:add_member(id)
    self.reason_exists = true
    if not self.members[id] then
        self.members[id] = true
        self.dirty = true
    end
end

function Model:remove_member(id)
    if self.reason_exists then
        self.members[id] = nil
        -- Intentionally conservative, like the reviewed removal branch:
        -- an existing group marks dirty even when this member was absent.
        self.dirty = true
    end
end

function Model:request_detail(id, force)
    self.counts.detail_api_calls = self.counts.detail_api_calls + 1
    if force then
        self.counts.forced_detail_calls = self.counts.forced_detail_calls + 1
    end
    -- A synchronous test service only. API call count is NOT packet count.
    local record = self.details:query(id, force)
    if record and self.rows[id] then
        self.rows[id].level = record.level
        self.counts.detail_presentations = self.counts.detail_presentations + 1
    end
end

function Model:refresh_roster()
    self.counts.list_rebuilds = self.counts.list_rebuilds + 1
    self.rows = {}
    for id in pairs(self.members) do
        self.rows[id] = {}
        self.counts.row_bindings = self.counts.row_bindings + 1
        self:request_detail(id, self.force_on_bind)
    end
    self:refresh_overlay()
end

function Model:tick()
    if not self.gated or self.dirty then
        self.dirty = false
        self.counts.notifications = self.counts.notifications + 1
        self:refresh_roster()
    end
end

function Model:refresh_overlay()
    self.counts.overlay_updates = self.counts.overlay_updates + 1
    self.support_visible = self.assist_id > 0
end

function Model:set_assist_id(id)
    if id ~= self.assist_id then
        self.assist_id = id
        self:refresh_overlay()
    end
end

function Model:refresh_vitals(id, health, distance)
    if self.rows[id] then
        self.rows[id].health = health
        self.rows[id].distance = distance
        self.counts.vital_presentations = self.counts.vital_presentations + 1
    end
end

function Model:advance_detail_clock(seconds)
    -- Separate deterministic scheduler; not the engine's per-widget timers.
    assert(seconds >= 0)
    if not self.detail_interval then return end
    assert(self.detail_interval > 0)
    self.detail_elapsed = self.detail_elapsed + seconds
    while self.detail_elapsed >= self.detail_interval do
        self.detail_elapsed = self.detail_elapsed - self.detail_interval
        for id in pairs(self.rows) do
            self:request_detail(id, true)
        end
    end
end

return Model
