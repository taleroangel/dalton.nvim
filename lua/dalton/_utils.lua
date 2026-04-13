--- @package
local M = {}

--- Filter values from a table (and keep their keys)
---
--- @generic K, V
--- @param tbl table<K, V> Key-value table to filter
--- @param predicate fun(k: K, v: V): boolean Returns true to keep element
--- @return table<K, V>
---     Table without filtered values
function M.tbl_kfilter(tbl, predicate)
    local result = {}
    for k, v in pairs(tbl) do
        if predicate(k, v) then
            result[k] = v
        end
    end
    return result
end

return M
