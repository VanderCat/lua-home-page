const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "lph",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const ziglua = b.dependency("ziglua", .{ .target = target, .optimize = optimize, .lang = .lua54 });

    exe.root_module.addImport("ziglua", ziglua.module("ziglua"));

    exe.linkSystemLibrary("fcgi");
    exe.linkLibC();

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    compileLua(b, exe, "main");
    compileLua(b, exe, "__utils");
    compileLua(b, exe, "echo");
    compileLua(b, exe, "error_handler");
    compileLua(b, exe, "lhp_handler");
}

fn compileLua(b: *std.Build, exe: *std.Build.Step.Compile, comptime name: []const u8) void {
    const luac_run = b.addSystemCommand(&.{"luac"});
    luac_run.addArg("-o");
    const output = luac_run.addOutputFileArg(name++".luac");
    luac_run.addFileArg(b.path("lua_src/"++name++".lua"));
    exe.root_module.addAnonymousImport(name++".luac", .{
        .root_source_file = output,
    });
}