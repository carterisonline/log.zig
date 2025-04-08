const std = @import("std");
const BuildContext = @import("build_simple.zig").BuildContext;

pub fn build(b: *std.Build) void {
    const ctx = BuildContext.standard(b);

    _ = ctx.createLibrary("log", .dynamic);
}
