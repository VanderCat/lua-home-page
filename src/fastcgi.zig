const std = @import("std");

pub const c = @cImport({
    @cInclude("fcgiapp.h");
});

pub const FCGXError = error{ UnsupportedVersion, ProtocolError, ParamsError, CallSeqError, SystemError, AcceptFailed, InitFailed, OpenSocketFailed, InitRequestFailed, StreamError, InvalidState, OutOfMemory };

pub fn isCGI() bool {
    return c.FCGX_IsCGI() != 0;
}

pub fn init() FCGXError!void {
    const rc = c.FCGX_Init();
    if (rc != 0) return FCGXError.InitFailed;
}

pub const Request = extern struct {
    requestId: i32 = undefined,
    role: i32 = undefined,
    in: *Stream = undefined,
    out: *Stream = undefined,
    err: *Stream = undefined,
    envp: RawParamArray = undefined,
    _paramsPtr: *anyopaque = undefined,
    _ipcFd: i32 = undefined,
    _isBeginProcessed: i32 = undefined,
    _keepConnection: i32 = undefined,
    _appStatus: i32 = undefined,
    _nWriters: i32 = undefined,
    _flags: i32 = undefined,
    _listen_sock: i32 = undefined,
    _detached: i32 = undefined,

    pub fn getEnvMap(req: *Request) FCGXError!std.process.EnvMap {
        var result = std.process.EnvMap{};
        const ptr = std.mem.span(req.envp);
        while (ptr[0]) |line| : (ptr += 1) {
            var line_i: usize = 0;
            while (line[line_i] != 0 and line[line_i] != '=') : (line_i += 1) {}
            const key = line[0..line_i];

            var end_i: usize = line_i;
            while (line[end_i] != 0) : (end_i += 1) {}
            const value = line[line_i + 1 .. end_i];

            try result.put(key, value);
        }
        return result;
    }

    pub fn init(sock: ?i32, flags: i32) FCGXError!Request {
        var r = Request{};
        const result = c.FCGX_InitRequest(@ptrCast(&r), sock orelse 0, flags);
        if (result != 0) return FCGXError.InitRequestFailed;
        return r;
    }

    pub fn accept(request: *Request) FCGXError!void {
        const rc = c.FCGX_Accept_r(@ptrCast(request));
        std.log.debug("fcgi accept returned {d}", .{rc});
        if (rc != 0) return FCGXError.AcceptFailed;
    }

    pub fn finish(request: *Request) void {
        c.FCGX_Finish_r(@ptrCast(request));
    }

    pub fn free(request: *Request, close: i32) void {
        c.FCGX_Free(@ptrCast(request), close);
    }

    pub fn attach(request: *Request) FCGXError!void {
        const rc = c.FCGX_Attach(@ptrCast(request));
        if (rc != 0) return FCGXError.InvalidState;
    }

    pub fn detach(request: *Request) FCGXError!void {
        const rc = c.FCGX_Detach(@ptrCast(request));
        if (rc != 0) return FCGXError.InvalidState;
    }
};

pub fn openSocket(name: []const u8, backlog: i32) FCGXError!i32 {
    const result = c.FCGX_OpenSocket(@ptrCast(name), backlog);
    if (result == -1) return FCGXError.OpenSocketFailed;
    return @intCast(result);
}

pub fn getParam(name: []const u8, envp: RawParamArray) ?[:0]const u8 {
    const result = c.FCGX_GetParam(@ptrCast(@alignCast(name)), @ptrCast(@alignCast(envp)));
    if (result) |r|
        return std.mem.span(r);
    return null;
}

pub const Stream = opaque {
    pub fn getChar(stream: *Stream) FCGXError!u8 {
        const result = c.FCGX_GetChar(@ptrCast(@alignCast(stream)));
        if (result == -1) {
            try stream.getError();
            return FCGXError.StreamError;
        }
        return @intCast(result);
    }

    pub fn unGetChar(stream: *Stream, char: u8) FCGXError!void {
        const result = c.FCGX_UnGetChar(char, @ptrCast(@alignCast(stream)));
        if (result == -1) {
            try stream.getError();
            return FCGXError.StreamError;
        }
    }

    pub fn getStr(stream: *Stream, size: i32) FCGXError![]u8 {
        var alloc = try std.heap.c_allocator.alloc(u8, @intCast(size));
        const result = c.FCGX_GetStr(alloc.ptr, @intCast(alloc.len), @ptrCast(@alignCast(stream)));
        std.log.debug("{s}", .{alloc});
        if (result == -1) {
            try stream.getError();
            return FCGXError.StreamError;
        }
        return alloc[0..@intCast(result)];
    }

    pub fn getLine(stream: *Stream, str: *[]u8) FCGXError!?[]const u8 {
        const result = c.FCGX_GetLine(str.ptr, @intCast(str.len), @ptrCast(@alignCast(stream)));
        if (result == null) return null;
        str.* = std.mem.span(result);
        return str.*;
    }

    pub fn putChar(stream: *Stream, char: u8) FCGXError!void {
        const result = c.FCGX_PutChar(char, @ptrCast(@alignCast(stream)));
        if (result == -1) {
            try stream.getError();
            return FCGXError.StreamError;
        }
    }

    pub fn putStr(stream: *Stream, str: []const u8) FCGXError!void {
        const result = c.FCGX_PutStr(str.ptr, @intCast(str.len), @ptrCast(@alignCast(stream)));
        if (result == -1) {
            try stream.getError();
            return FCGXError.StreamError;
        }
    }

    pub fn putS(stream: *Stream, str: [:0]const u8) FCGXError!void {
        const result = c.FCGX_PutS(str, @ptrCast(@alignCast(stream)));
        if (result == -1) {
            try stream.getError();
            return FCGXError.StreamError;
        }
    }

    pub fn fPrintF(stream: *Stream, format: [:0]const u8, args: anytype) FCGXError!void {
        const result = @call(.auto, c.FCGX_FPrintF, .{ @as([*c]c.FCGX_Stream, @ptrCast(@alignCast(stream))), format } ++ args);
        if (result == -1) {
            try stream.getError();
            return FCGXError.StreamError;
        }
    }
    pub fn formatPutS(stream: *Stream, comptime format: []const u8, args: anytype) (FCGXError || std.fmt.AllocPrintError)!void {
        const str = try std.fmt.allocPrintZ(std.heap.c_allocator, format, args);
        try stream.putS(str);
    }

    pub fn fFlush(stream: *Stream) FCGXError!void {
        const result = c.FCGX_FFlush(@ptrCast(@alignCast(stream)));
        if (result == -1) {
            try stream.getError();
            return FCGXError.StreamError;
        }
    }

    pub fn fClose(stream: *Stream) FCGXError!void {
        const result = c.FCGX_FClose(@ptrCast(@alignCast(stream)));
        if (result == -1) {
            try stream.getError();
            return FCGXError.StreamError;
        }
    }

    pub fn startFilterData(stream: *Stream) FCGXError!void {
        const result = c.FCGX_StartFilterData(@ptrCast(@alignCast(stream)));
        if (result < 0) return FCGXError.CallSeqError;
    }

    pub fn setExitStatus(stream: *Stream, status: c_int) void {
        c.FCGX_SetExitStatus(status, @ptrCast(@alignCast(stream)));
    }

    pub fn hasSeenEOF(stream: *Stream) bool {
        return !(c.FCGX_HasSeenEOF(@ptrCast(@alignCast(stream))) != 0);
    }

    fn getError(stream: *Stream) FCGXError!void {
        const err = c.FCGX_GetError(@ptrCast(@alignCast(stream)));
        if (err == 0) return;

        return switch (err) {
            c.FCGX_UNSUPPORTED_VERSION => FCGXError.UnsupportedVersion,
            c.FCGX_PROTOCOL_ERROR => FCGXError.ProtocolError,
            c.FCGX_PARAMS_ERROR => FCGXError.ParamsError,
            c.FCGX_CALL_SEQ_ERROR => FCGXError.CallSeqError,
            // else => if (err > 0)
            //     std.posix.unexpectedErrno(@intCast(err))
            else => FCGXError.StreamError,
        };
    }
};

pub const RawParamArray = [*c][*c]u8;
pub const ParamArray = []const std.process.EnvMap;

pub fn shutdownPending() void {
    c.FCGX_ShutdownPending();
}

pub fn accept(in: *?*Stream, out: *?*Stream, err: *?*Stream, envp: *?RawParamArray) FCGXError!void {
    const rc = c.FCGX_Accept(@ptrCast(@alignCast(in)), @ptrCast(@alignCast(out)), @ptrCast(@alignCast(err)), @ptrCast(@alignCast(envp)));
    if (rc != -1) {
        return FCGXError.AcceptFailed;
    }
}

pub fn finish() void {
    c.FCGX_Finish();
}
