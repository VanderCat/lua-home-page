---@meta

---@class Stream
stream = {
    ---@param self Stream
    ---@return string
    getChar = function(self) end,
    ---@param self Stream
    unGetChar = function(self) end,
    ---@param self Stream
    ---@return string
    getString = function(self) end,
    ---@param self Stream
    ---@return string
    getLine = function(self) end,
    ---@param self Stream
    ---@param char string
    putChar = function(self, char) end,
    ---@param self Stream
    ---@param string string
    putString = function(self, string) end,
    ---@param self Stream
    fFlush = function(self) end,
    ---@param self Stream
    fClose = function(self) end,
    ---@param self Stream
    startFilterData = function(self) end,
    ---@param self Stream
    setExitStatus = function(self) end,
    ---@param self Stream
    ---@return boolean
    hasSeenEOF = function(self) end
}

---@class Request
---@field input Stream
---@field output Stream
---@field error Stream
---@field [string] string
request = {
    ---@param self Request
    accept = function(self) end,
    ---@param self Request
    attach = function(self) end,
    ---@param self Request
    detach = function(self) end,
    ---@param self Request
    finish = function(self) end,
}

---@class log
log = {
    err = function (string) end,
    warn = function (string) end,
    info = function (string) end,
    debug = function (string) end,
}

---@class Response
---@field headers { [string]: string }
---@field contents string