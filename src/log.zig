const std = @import("std");
const t = @cImport({
    @cInclude("time.h");
});
const ansi = @import("ansicolor.zig");

fn getColor(comptime self: std.log.Level) []const u8 {
    return switch (self) {
        .debug => comptime ansi.setStyle(.reset, .cyan, null),
        .info => comptime ansi.setStyle(.reset, .green, null),
        .warn => comptime ansi.setStyle(.reset, .yellow, null),
        .err => comptime ansi.setStyle(.reset, .red, null),
    };
}

fn getName(comptime self: std.log.Level) []const u8 {
    return switch (self) {
        .debug => "DEBUG",
        .info => "INFO ",
        .warn => "WARN ",
        .err => "ERROR",
    };
}

pub fn LogFn(
    comptime level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    // Ignore all non-error logging from sources other than
    // .my_project, .nice_library and the default
    // const scope_prefix = switch (scope) {
    //     .my_project, .nice_library, std.log.default_log_scope => @tagName(scope),
    //     else => if (@intFromEnum(level) <= @intFromEnum(std.log.Level.err))
    //         @tagName(scope)
    //     else
    //         return,
    // };
    const scope_prefix = @tagName(scope);
    var time: t.time_t = 0;
    _ = t.time(&time);
    const timeinfo: *t.tm = @ptrCast(t.localtime(&time));
    const timeStr = std.fmt.allocPrint(std.heap.c_allocator, comptime ansi.setStyle(.dim, .white, null) ++ "{d}:{d}:{d}" ++ ansi.removeStyle(.dim), .{ timeinfo.tm_hour, timeinfo.tm_min, timeinfo.tm_sec }) catch "error";
    defer std.heap.c_allocator.free(timeStr);
    const prefix = "{s} " ++ (comptime getColor(level)) ++ (comptime getName(level)) ++ (comptime ansi.removeStyle(.bold)) ++ (comptime ansi.setStyle(.dim, .white, null)) ++ " " ++ scope_prefix ++ (comptime ansi.removeStyle(.reset));

    // Print the message to stderr, silently ignoring any errors
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();
    const stderr = std.io.getStdErr().writer();
    nosuspend stderr.print(prefix ++ " " ++ format ++ "\n", .{timeStr} ++ args) catch return;
}
