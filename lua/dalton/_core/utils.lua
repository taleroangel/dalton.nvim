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

--- Wrap an async function into a blocking coroutine
---
--- Call only from a coroutine!
---
--- @param blocking fun(resume: fun(...))
---     Blocking function call, use the `resume` callback to return a value
--- @return ... Parameters passed to `resume`
function M.await(blocking)
    local co = coroutine.running()
    if not co then
        error("Cannot await from main thread!")
    end
    blocking(function(...)
        coroutine.resume(co, ...)
    end)
    return coroutine.yield()
end

--- Run a function in a separate coroutine other than Main
---
--- If the function is already running in a coroutine,
--- then it calls `body` directly
---
--- @param body function Code to run in a separate thread
function M.async(body)
    local co = coroutine.running()
    if not co then
        coroutine.wrap(body)()
    else
        body()
    end
end

return M
