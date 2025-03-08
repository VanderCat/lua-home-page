---@param error string
---@return Response
local function errorResponse(error)
    return {
        headers = {
            ["Status"] = 500,
            ["Content-Type"] = "text/plain",
        },
        contents = error
    }
end

return errorResponse