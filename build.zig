const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const log = b.addModule("log", .{
        .root_source_file = b.path("lib/log/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const compile = b.addLibrary(.{ .linkage = .dynamic, .name = "log", .root_module = log });
    b.installArtifact(compile);
}
