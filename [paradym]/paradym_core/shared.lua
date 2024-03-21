Utils = {}

Utils.DebugTypes = {
    INFO = '^5[paradym_core]^2',
    WARN = '^5[paradym_core]^3',
    ERROR = '^5[paradym_core]^1',
    TABLE = '^5[paradym_core]^7'
}

Utils.DebugPrint = function(type, ...)
    if not Utils.DebugTypes[type] then type = 'INFO' end
    print(('%s [%s] %s'):format(Utils.DebugTypes[type], type, ...))
end

Utils.DebugTable = function(table)
    Utils.DebugPrint('TABLE', json.encode(table, {indent = true}))
end