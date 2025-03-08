const std = @import("std");
const ziglua = @import("ziglua");

const funcs = [_]ziglua.FnReg{
    .{ .name = "err", .func = ziglua.wrap(logErr) },
    .{ .name = "warn", .func = ziglua.wrap(logWarn) },
    .{ .name = "debug", .func = ziglua.wrap(logDebug) },
    .{ .name = "info", .func = ziglua.wrap(logInfo) },
};

pub fn luaopen_log(lua: *ziglua.Lua) i32 {
    lua.newLib(&funcs);
    lua.newMetatable("ziglua.log") catch {
        return lua.raiseError();
    };
    _ = lua.pushString("__call");
    _ = lua.getField(-3, "log");
    lua.setTable(-3);
    lua.setMetatable(-2);
    return 1;
}

const luaLogger = std.log.scoped(.lua);

fn logErr(lua: *ziglua.Lua) i32 {
    const str = lua.toString(1) catch {
        return lua.raiseErrorStr("could not convert to string", .{});
    };
    luaLogger.err("{s}", .{str});
    return 0;
}

fn logDebug(lua: *ziglua.Lua) i32 {
    const str = lua.toString(1) catch {
        return lua.raiseErrorStr("could not convert to string", .{});
    };
    luaLogger.err("{s}", .{str});
    return 0;
}

fn logWarn(lua: *ziglua.Lua) i32 {
    const str = lua.toString(1) catch {
        return lua.raiseErrorStr("could not convert to string", .{});
    };
    luaLogger.err("{s}", .{str});
    return 0;
}

fn logInfo(lua: *ziglua.Lua) i32 {
    const str = lua.toString(1) catch {
        return lua.raiseErrorStr("could not convert to string", .{});
    };
    luaLogger.err("{s}", .{str});
    return 0;
}
