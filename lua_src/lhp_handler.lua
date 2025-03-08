local handler = {}

local headers = {
    ["Content-Type"] = "text/html"
}
local buffer = ""

local function setfenv(fn, env)
    local i = 1
    while true do
        local name = debug.getupvalue(fn, i)
        if name == "_ENV" then
            debug.upvaluejoin(fn, i, (function()
            return env
            end), 1)
            break
        elseif not name then
            break
        end
    
        i = i + 1
    end
  
    return fn
end

function handler.getEnv() 
    local env = {
        print = function(...)
            local args = {...}
            for i, v in ipairs(args) do
                args[i] = tostring(v)
            end
            buffer = buffer..table.concat(args, "\t") .. "\n"
        end,
        setHeader = function (name, value)
            headers["Content-Type"] = value;
        end,
        globals = _G
    }
    ---works like require but does not cache the result
    ---@param name string
    ---@return any
    function env.embed(name)
        log.debug("embed run")
        local t = type(name)
        if t ~= "string" then
            if t == "number" then
                name = tostring(name)
            else
                error("bad argument #1 to 'embed' (string expected, got "..t..")", 3)
            end
        end
        local msg = {}
        local loader, param
        for _, searcher in ipairs(package.searchers) do
            loader, param = searcher(name)
            if type(loader) == "function" then break end
            if type(loader) == "string" then
                -- `loader` is actually an error message
                msg[#msg + 1] = loader
            end
            loader = nil
        end
        if loader == nil then
            error("module '" .. name .. "' not found: "..table.concat(msg), 2)
        end
        return setfenv(loader, env)(param)
    end
    setmetatable(env, {__index = _G})
    return env
end

function handler.printError(error)
    if Headers["Content-Type"] == "text/html" then buffer = buffer.."<pre>" end
    buffer = buffer.."Error loading Lua code: "
    buffer = buffer..tostring(error)
    if Headers["Content-Type"] == "text/html" then buffer = buffer.."</pre>" end
end

function handler:execute(code, env, name)
    buffer = ""
    
    local chunk, err = load(code, name, "t", env)
    if not chunk then
        handler.printError(err)
    end
    
    local success, err_msg = pcall(chunk or function() end)
    if not success then
        handler.printError(err)
    end
    
    return buffer
end

function handler:parse(content)
    headers = {
        ["Content-Type"] = "text/html"
    }
    local output = ""
    local start = 1
    local counter = 0
    local env = self:getEnv();
    
    while true do
        local lua_start, lua_end = string.find(content, "<%?lua", start)
        if not lua_start then
            output = output..content:sub(start)
            break
        end
        
        output = output..string.sub(content, start, lua_start - 1)
        
        local closing_start, closing_end = string.find(content, "%?%>", lua_end + 1)
        if not closing_start then
            output = output..string.sub(content, lua_start)
            break
        end
        
        local code = string.sub(content, lua_end + 1, closing_start - 1)
        counter = counter + 1
        local result = self:execute(code:gsub("^%s+", ""):gsub("%s+$", ""), env, counter)
        output = output..result
        
        start = closing_end + 1
    end
    
    return {
        headers = headers,
        contents = output
    }
end

return handler