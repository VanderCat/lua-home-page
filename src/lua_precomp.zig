pub const main = @embedFile("main.luac");
pub const __utils = @embedFile("__utils.luac");
pub const error_handler = @embedFile("error_handler.luac");
pub const lhp_handler = @embedFile("lhp_handler.luac");
pub const echo = @embedFile("echo.luac");

const utils = @import("utils.zig");
const ziglua = @import("ziglua");

pub fn AddToPreload(lua: *ziglua.Lua) !void {
    try utils.addScriptToLuaPreload(lua, main, "main");
    try utils.addScriptToLuaPreload(lua, __utils, "__utils");
    try utils.addScriptToLuaPreload(lua, error_handler, "error_handler");
    try utils.addScriptToLuaPreload(lua, lhp_handler, "lhp_handler");
}