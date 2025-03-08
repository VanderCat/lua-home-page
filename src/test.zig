const std = @import("std");
const fcgi = @import("fastcgi.zig");

fn PrintEnv(out: *fcgi.Stream, label: []const u8) !void {
    const env_map = try std.heap.c_allocator.create(std.process.EnvMap);
    env_map.* = try std.process.getEnvMap(std.heap.c_allocator);
    defer env_map.deinit();
    try out.formatPutS("{s}:<br>\n<pre>\n", .{label});
    var iter = env_map.iterator();
    while (iter.next()) |entry| {
        try out.formatPutS("{s}={s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
    try out.formatPutS("</pre><p>\n", .{});
}

fn PrintFcgiEnv(out: *fcgi.Stream, label: []const u8, envp: fcgi.ParamArray) !void {
    try out.formatPutS("{s}:<br>\n<pre>\n", .{label});
    _ = envp;
    // for (envp) |val| {
    //     try out.formatPutS("{s}\n", .{val});
    // }
    try out.formatPutS("</pre><p>\n", .{});
}

pub fn main() !void {
    try fcgi.init();
    const sock = try fcgi.openSocket(":7777", 10);
    var request = try fcgi.Request.init(sock, 0);

    //FCGX_ParamArray envp;
    var count: i32 = 0;

    while (true) {
        try request.accept();
        errdefer request.finish();

        const contentLength = fcgi.getParam("CONTENT_LENGTH", request.envp);
        var len: usize = 0;
        try request.out.putS("Content-type: text/html\r\n");
        try request.out.putS("\r\n");
        try request.out.putS("<title>FastCGI echo (fcgiapp version)</title>\n");
        try request.out.putS("<h1>FastCGI echo (fcgiapp version)</h1>\r\n");
        count += 1;
        const pid = std.os.linux.getpid();
        try request.out.formatPutS("Request number {d},  Process ID: {d}<p>\r\n", .{ count, pid });

        if (contentLength) |length|
            len = try std.fmt.parseInt(usize, length, 10);

        if (len <= 0)
            try request.out.formatPutS("No data from standard input.<p>\n", .{})
        else {
            try request.out.formatPutS("Standard input:<br>\n<pre>\n", .{});
            for (0..len) |_| {
                const ch = try request.in.getChar();
                if (ch < 0) {
                    try request.out.formatPutS("Error: Not enough bytes received on standard input<p>\n", .{});
                    break;
                }
                try request.out.putChar(ch);
            }
            try request.out.formatPutS("\n</pre><p>\n", .{});
        }

        try PrintFcgiEnv(request.out, "Request environment", request.envp);
        try PrintEnv(request.out, "Initial environment");
    }

    return 0;
}
