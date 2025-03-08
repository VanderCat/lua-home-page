require "__utils"
local errorResponse = require "error_handler";
local lhp = require "lhp_handler"

local a = request["SCRIPT_FILENAME"];
log.debug("loading script "..a);
Headers = {} 
for key, value in pairs(request) do
    if string.startswith(key, "HTTP_") then
        local new = string.replace(key, "HTTP_", "")
        new = string.replace(new, "_", "-")
        new = string.capitalize(string.lower(new))
        Headers[new] = value
    end
end
---@type Response
local result

if (a:endswith(".lhp")) then
    local f = io.open(a, "r")
    if not f then
        result = errorResponse("script not found");
    else
        local c = f:read("a")
        f:close()
        result = lhp:parse(c)
    end
else
    ---@type boolean
    local status

    status, result = pcall(dofile, a);
    if not status then
        result = errorResponse(result);
    end
end

for key, value in pairs(result.headers) do
    request.output:putString(key..": "..value.."\r\n")
end
request.output:putString("\r\n")
request.output:putString(result.contents);