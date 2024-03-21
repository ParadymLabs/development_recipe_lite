
---@class Datastore : OxClass
---@field key string
---@field data table
local Datastore = lib.class('Datastore')

function Datastore:constructor(key)
    self.private.key = key
    self.data = self:load()
end

function Datastore:save(data)
    self.data = data
    SetResourceKvp(self.private.key, json.encode(data))
end

function Datastore:load()
    local data = GetResourceKvpString(self.private.key)
    return json.decode(data)
end

function Datastore:clear()
    DeleteResourceKvp(self.private.key)
end

return Datastore