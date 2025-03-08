const std = @import("std");
const ziglua = @import("ziglua");
pub const request = @import("request.zig");
pub const stream = @import("stream.zig");

pub fn luaopen_fcgi(lua: *ziglua.Lua) i32 {
    _ = request.luaopen_request(lua);
    _ = stream.luaopen_stream(lua);
    return 0;
}
