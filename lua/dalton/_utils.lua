--- @package
local M = {}

--- Filter values from a table (and keep their keys)
---
--- @param tbl table Key-value table to filter
--- @param predicate function Function(k, v): boolean
--- @return table
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
