const std = @import("std");
const ziglua = @import("ziglua");

pub fn addFuncToLuaPreload(lua: *ziglua.Lua, func: ziglua.CFn, name: []const u8) !void {
    try lua.getGlobal("package");
    lua.getField(-1, "preload");
    lua.remove(-2);
    lua.pushString(name);
    lua.pushFunction(func);
    lua.setTable(-3);
    lua.remove(-1);
    //std.debug.print("Added {s} to preload!", .{name});
}

pub fn addScriptToLuaPreload(lua: *ziglua.Lua, bc: []const u8, name: [:0]const u8) !void {
    _ = try lua.getGlobal("package");
    _ = lua.getField(-1, "preload");
    lua.remove(-2);
    _ = lua.pushString(name);
    try lua.loadBuffer(bc, name, .binary_text);
    lua.setTable(-3);
    lua.remove(-1);
    std.log.debug("Added {s} to preload!", .{name});
}

pub fn doLuaFile(lua: *ziglua.Lua, name: [:0]const u8) !void {
    lua.doFile(name) catch |err|{
            const errorstr = try lua.toString(-1);
            std.debug.print("An error occured while loading a file: {s}", .{errorstr});
            // const errorpos = strstr(error, ":");
            // int length = errorpos-error;
            // char* file = (char*) malloc(sizeof(char)*(length+1));
            // strncpy(file, error, length);
            // *(file+length)='\0';
            // log_log(LOG_ERROR, file, strtol(errorpos+1, NULL, 10), strstr(errorpos+1, ":")+2);
            return err;
        }; //TODO: Make it not crash when file is not present
}