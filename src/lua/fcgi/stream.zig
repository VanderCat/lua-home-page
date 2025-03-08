const std = @import("std");
const ziglua = @import("ziglua");

const fcgi = @import("../../fastcgi.zig");

const Stream = fcgi.Stream;
const FCGXError = fcgi.FCGXError;
const Lua = ziglua.Lua;

const funcs = [_]ziglua.FnReg{
    .{ .name = "getChar", .func = ziglua.wrap(getChar) },
    .{ .name = "unGetChar", .func = ziglua.wrap(unGetChar) },
    .{ .name = "getString", .func = ziglua.wrap(getString) },
    .{ .name = "getLine", .func = ziglua.wrap(getLine) },
    .{ .name = "putChar", .func = ziglua.wrap(putChar) },
    .{ .name = "putString", .func = ziglua.wrap(putString) },
    .{ .name = "fFlush", .func = ziglua.wrap(fFlush) },
    .{ .name = "fClose", .func = ziglua.wrap(fClose) },
    .{ .name = "startFilterData", .func = ziglua.wrap(startFilterData) },
    .{ .name = "setExitStatus", .func = ziglua.wrap(setExitStatus) },
    .{ .name = "hasSeenEOF", .func = ziglua.wrap(hasSeenEOF) },
};

pub fn luaopen_stream(lua: *Lua) i32 {
    lua.newMetatable("fcgi.Stream") catch {
        lua.raiseError();
    };
    _ = lua.pushString("__index");
    lua.newLib(&funcs);
    lua.setTable(-3);
    return 0;
}

fn getChar(lua: *Lua) i32 {
    const stream = (lua.toUserdata(*Stream, 1) catch {
        lua.argError(1, "failed to get userdata");
        return 0;
    }).*;
    const c: [1:0]u8 = .{stream.getChar() catch |err| {
        return lua.raiseErrorStr("getChar error: %s", .{@errorName(err).ptr});
    }};
    _ = lua.pushString(&c);
    return 1;
}

fn unGetChar(lua: *Lua) i32 {
    const stream = (lua.toUserdata(*Stream, 1) catch {
        lua.argError(1, "failed to get userdata");
        return 0;
    }).*;

    const char = lua.toString(2) catch {
        lua.argError(1, "failed to get char");
        return 0;
    };
    stream.unGetChar(char[0]) catch {
        return lua.raiseErrorStr("unGetChar error: {s}", .{});
    };
    return 0;
}

pub fn getString(lua: *Lua) i32 {
    const stream = (lua.toUserdata(*Stream, 1) catch {
        lua.argError(1, "failed to get userdata");
        return 0;
    }).*;
    const bufferSize = 256;
    const allocator = lua.allocator();
    var buffer: []u8 = allocator.alloc(u8, 0) catch {
        return lua.raiseErrorStr("Out of memory", .{});
    };
    while (true) {
        std.log.debug("sting loop", .{});
        const str = stream.getStr(bufferSize) catch {
            return lua.raiseErrorStr("getStr error: {s}", .{});
        };
        std.log.debug("got str \"{s}\" with length {d}", .{ str, str.len });
        if (str.len < bufferSize) break;
        buffer = std.mem.concat(allocator, u8, &.{ buffer, str }) catch {
            return lua.raiseErrorStr("Out of memory", .{});
        };
    }
    _ = lua.pushString(buffer);
    return 1;
}

pub fn getLine(lua: *Lua) i32 {
    const stream = (lua.toUserdata(*Stream, 1) catch {
        lua.argError(1, "failed to get userdata");
        return 0;
    }).*;

    const max_len = lua.toInteger(2) catch {
        lua.argError(2, "invalid buffer size");
        return 0;
    };
    var a = std.mem.zeroes([]u8)[0..@intCast(max_len)];
    const result = stream.getLine(&a) catch {
        return lua.raiseErrorStr("getLine error: {s}", .{});
    };
    if (result) |line| {
        _ = lua.pushString(line);
    } else {
        lua.pushNil();
    }
    return 1;
}

pub fn putChar(lua: *Lua) i32 {
    const stream = (lua.toUserdata(*Stream, 1) catch {
        lua.argError(1, "failed to get userdata");
        return 0;
    }).*;
    const char_str = lua.toString(2) catch {
        lua.argError(2, "invalid character");
        return 0;
    };
    if (char_str.len == 0) {
        lua.argError(2, "empty character string");
        return 0;
    }
    stream.putChar(char_str[0]) catch {
        lua.raiseErrorStr("putChar error: {s}", .{});
        return 1;
    };
    return 0;
}

pub fn putString(lua: *Lua) i32 {
    const stream = (lua.toUserdata(*Stream, 1) catch {
        lua.argError(1, "failed to get userdata");
        return 0;
    }).*;

    const str = lua.toString(2) catch {
        lua.argError(2, "invalid string");
        return 0;
    };
    stream.putS(str) catch {
        return lua.raiseErrorStr("putS error: {s}", .{});
    };
    return 0;
}

pub fn fFlush(lua: *Lua) i32 {
    const stream = (lua.toUserdata(*Stream, 1) catch {
        lua.argError(1, "failed to get userdata");
        return 0;
    }).*;

    stream.fFlush() catch {
        return lua.raiseErrorStr("fFlush error: {s}", .{});
    };
    return 0;
}

pub fn fClose(lua: *Lua) i32 {
    const stream = (lua.toUserdata(*Stream, 1) catch {
        lua.argError(1, "failed to get userdata");
        return 0;
    }).*;

    stream.fClose() catch {
        //const err1: [:0]const u8 = @errorName(err);
        return lua.raiseErrorStr("fClose error: {s}", .{});
    };
    return 0;
}

pub fn startFilterData(lua: *Lua) i32 {
    const stream = (lua.toUserdata(*Stream, 1) catch {
        lua.argError(1, "failed to get userdata");
        return 0;
    }).*;

    stream.startFilterData() catch {
        return lua.raiseError();
        //return lua.raiseErrorStr("startFilterData error: {s}", .{});
    };
    return 0;
}

pub fn setExitStatus(lua: *Lua) i32 {
    const stream = (lua.toUserdata(*Stream, 1) catch {
        lua.argError(1, "failed to get userdata");
        return 0;
    }).*;

    const status = lua.toInteger(2) catch {
        lua.argError(2, "invalid exit status");
        return 0;
    };
    stream.setExitStatus(@intCast(status));
    return 0;
}

fn hasSeenEOF(lua: *Lua) i32 {
    const stream = (lua.toUserdata(*Stream, 1) catch {
        lua.argError(1, "failed to get userdata");
        return 0;
    }).*;
    lua.pushBoolean(stream.hasSeenEOF());
    return 1;
}
