const std = @import("std");
const ziglua = @import("ziglua");

const fcgi = @import("../../fastcgi.zig");

const Stream = fcgi.Stream;
const FCGXError = fcgi.FCGXError;
const Lua = ziglua.Lua;

const funcs = [_]ziglua.FnReg{
    .{ .name = "accept", .func = ziglua.wrap(accept) },
    .{ .name = "attach", .func = ziglua.wrap(attach) },
    .{ .name = "detach", .func = ziglua.wrap(detach) },
    .{ .name = "finish", .func = ziglua.wrap(finish) },
};

const LuaRequest = extern struct {
    ptr: *fcgi.Request,
    //envMap: *std.process.EnvMap,
};

pub fn luaopen_request(lua: *Lua) i32 {
    lua.newMetatable("fcgi.Request") catch {
        lua.raiseError();
    };
    _ = lua.pushString("__funcs");
    lua.newLib(&funcs);
    lua.setTable(-3);
    _ = lua.pushString("__index");
    lua.pushFunction(ziglua.wrap(metaMethod));
    lua.setTable(-3);
    _ = lua.pushString("__pairs");
    lua.pushFunction(ziglua.wrap(pairs));
    lua.setTable(-3);
    return 0;
}

fn metaMethod(lua: *Lua) i32 {
    const req = (lua.toUserdata(LuaRequest, 1) catch {
        return lua.raiseError();
    }).ptr;
    if (!lua.isString(2)) {
        lua.typeError(2, "string");
        return 0;
    }
    const idx = lua.toString(2) catch {
        return lua.raiseError();
    };
    if (std.mem.eql(u8, idx, "input")) {
        const stream = lua.newUserdata(*Stream, 0);
        stream.* = req.in;
        _ = lua.getMetatableRegistry("fcgi.Stream");
        lua.setMetatable(-2);
        return 1;
    } else if (std.mem.eql(u8, idx, "output")) {
        const stream = lua.newUserdata(*Stream, 0);
        stream.* = req.out;
        _ = lua.getMetatableRegistry("fcgi.Stream");
        lua.setMetatable(-2);
        return 1;
    } else if (std.mem.eql(u8, idx, "error")) {
        const stream = lua.newUserdata(*Stream, 0);
        stream.* = req.err;
        _ = lua.getMetatableRegistry("fcgi.Stream");
        lua.setMetatable(-2);
        return 1;
    } else if (std.mem.eql(u8, idx, "accept")) {
        lua.pushFunction(ziglua.wrap(accept));
        return 1;
    } else if (std.mem.eql(u8, idx, "finish")) {
        lua.pushFunction(ziglua.wrap(finish));
        return 1;
    } else if (std.mem.eql(u8, idx, "attach")) {
        lua.pushFunction(ziglua.wrap(attach));
        return 1;
    } else if (std.mem.eql(u8, idx, "detach")) {
        lua.pushFunction(ziglua.wrap(detach));
        return 1;
    } else {
        if (fcgi.getParam(idx, req.envp)) |val| {
            _ = lua.pushString(val);
        } else {
            lua.pushNil();
        }
        return 1;
    }
}

fn pairs(lua: *Lua) i32 {
    lua.pushFunction(ziglua.wrap(next));
    lua.pushValue(-2);
    lua.pushNil();
    return 3;
}

fn next(lua: *Lua) i32 {
    const req = lua.toUserdata(LuaRequest, 1) catch {
        return lua.raiseError();
    };
    if (lua.isString(2)) {
        var found: bool = false;
        var ptr = req.ptr.envp;
        while (ptr[0]) |value| : (ptr += 1) {
            if (value == 0) break;
            var split = std.mem.split(u8, std.mem.span(value), "=");
            if (found) {
                _ = lua.pushString(split.first());
                _ = lua.pushString(split.rest());
                return 2;
            }
            if (std.mem.eql(u8, split.first(), lua.toString(2) catch unreachable))
                found = true;
        }
        //std.mem.startsWith(u8, req.envp, needle: []const T)
        lua.pushNil();
        return 1;
    }
    var a = std.mem.split(u8, std.mem.span(req.ptr.envp[0]), "=");
    _ = lua.pushString(a.first());
    _ = lua.pushString(a.rest());
    return 2;
}

const stub = ziglua.wrap(struct {
    fn stub(data: *anyopaque) void {
        _ = data;
    }
}.stub);

fn accept(lua: *Lua) i32 {
    const request = lua.toUserdata(LuaRequest, 1) catch {
        return lua.raiseError();
    };
    request.ptr.accept() catch {
        return lua.raiseErrorStr("{s}", .{});
    };
    return 0;
}

fn finish(lua: *Lua) i32 {
    const request = lua.toUserdata(LuaRequest, 1) catch {
        return lua.raiseError();
    };
    request.ptr.finish();
    return 0;
}

fn attach(lua: *Lua) i32 {
    const request = lua.toUserdata(LuaRequest, 1) catch {
        return lua.raiseError();
    };
    request.ptr.attach() catch {
        return lua.raiseErrorStr("{s}", .{});
    };
    return 0;
}

fn detach(lua: *Lua) i32 {
    const request = lua.toUserdata(LuaRequest, 1) catch {
        return lua.raiseError();
    };
    request.ptr.detach() catch {
        return lua.raiseErrorStr("{s}", .{});
    };
    return 0;
}

pub fn newLuaRequest(lua: *Lua, request: *fcgi.Request) !void {
    const r = lua.newUserdata(LuaRequest, 0);
    r.* = LuaRequest{
        .ptr = request,
        //.envMap = try request.getEnvMap()
    };
    _ = lua.getMetatableRegistry("fcgi.Request");
    lua.setMetatable(-2);
}
