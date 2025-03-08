const std = @import("std");
const ziglua = @import("ziglua");

const utils = @import("utils.zig");
const fcgi = @import("fastcgi.zig");

const Lua = ziglua.Lua;

const lualog = @import("lua/log.zig");
const luafcgi = @import("lua/fcgi/main.zig");
const lua_precomp = @import("lua_precomp.zig");

const options = @import("build_options");

pub const std_options = .{
    // Set the log level to info
    .log_level = .debug,

    // Define logFn to override the std implementation
    .logFn = @import("log.zig").LogFn,
};

pub fn main() !void {
    const allocator = std.heap.c_allocator;
    std.log.info("Starting up", .{});
    const act = std.posix.Sigaction{
        .handler = .{ .handler = handle },
        .mask = std.posix.empty_sigset,
        .flags = 0,
    };
    try std.posix.sigaction(std.posix.SIG.INT, &act, null);

    std.log.debug("Initializing Lua", .{});
    var lua = try Lua.init(allocator);
    defer {
        std.log.debug("Shutting down Lua", .{});
        lua.deinit();
    }
    std.log.debug("Opening libs", .{});
    lua.openLibs();
    lua.pushGlobalTable();
    std.log.debug("Adding to preload", .{});
    try lua_precomp.AddToPreload(lua);
    _ = lua.pushString("log");
    _ = lualog.luaopen_log(lua);
    lua.setTable(-3);
    _ = luafcgi.luaopen_fcgi(lua);
    std.log.info("Loading conf.lua", .{});
    _ = lua.pushString("settings");
    lua.createTable(0, 0);
    lua.setTable(-3);

    var settings = Settings{ .socketPath = ":7777", .threadCount = 8 };

    if (utils.doLuaFile(lua, "conf.lua")) |_| {
        _ = try lua.getGlobal("settings");
        switch (lua.getField(-1, "socket")) {
            .string => settings.socketPath = try lua.toString(-1),
            else => {},
        }
        lua.remove(-1);
        switch (lua.getField(-1, "threadcount")) {
            .string => settings.threadCount = @intCast(try lua.toInteger(-1)),
            else => {},
        }
    } else |_| {
        std.log.warn("conf.lua failed to load", .{});
    }

    std.log.info("starting up fcgi at {s} with {d} thread count", .{ settings.socketPath, settings.threadCount });
    try fcgi.init();
    const socket = try fcgi.openSocket(settings.socketPath, 20);
    std.log.debug("opened socket", .{});

    //const thread = try std.Thread.spawn(.{}, answer, .{settings, socket, lua});
    //std.log.info("Loading main.lua", .{});
    //try utils.doLuaFile(lua, "main.lua");
    lua.setTop(0);
    try answer(settings, socket, lua);
    //thread.join();
}

var ShuttingDown = false;

fn handle(_: i32) callconv(.C) void {
    if (!ShuttingDown) {
        std.log.warn("received SIGINT, shutting down", .{});
        ShuttingDown = true;
    } else {
        std.log.warn("received second SIGINT, forcefully shutting down", .{});
        std.process.exit(0);
    }
}

const Settings = struct { socketPath: [:0]const u8, threadCount: i16 };
var answerMutex = std.Thread.Mutex{};

fn answer(settings: Settings, socket: i32, lua: *Lua) !void {
    const debug = (@import("builtin").mode == .Debug);
    _ = settings;
    var request = try fcgi.Request.init(socket, 0);
    std.log.debug("Request initialized", .{});

    while (!ShuttingDown) {
        std.log.debug("Trying to accept new request", .{});
        answerMutex.lock();
        try request.accept();
        answerMutex.unlock();
        std.log.debug("request accepted", .{});

        //print all Headers
        // try request.out.putS("Content-type: text/html\r\n");
        // try request.out.putS("\r\n");
        std.log.debug("asking lua", .{});
        lua.pushGlobalTable();
        _ = lua.pushString("request");
        try luafcgi.request.newLuaRequest(lua, &request);
        lua.setTable(-3);
        _ = lua.getField(-1, "package");
        _ = lua.getField(-1, "preload");
        _ = lua.getField(-1, "main");
        lua.protectedCall(.{ .args = 0 }) catch {
            std.log.err("could not load main.lua", .{});
            try request.out.putS("Content-type: text/html\r\n");
            try request.out.putS("Status: 500\r\n");
            try request.out.putS("\r\n");
            try request.out.putS("<h1>Internal Server Error</h1>\n\r");
            if (debug) {
                try request.out.putS("<p>");
                try request.out.putS(lua.toString(-1) catch "Unknown error");
                try request.out.putS("</p>");
            }
            request.finish();
            continue;
        };
        lua.pop(3);
        //_ = lua.doFile("main.lua") 
    }
}
