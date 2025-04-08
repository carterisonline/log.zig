const std = @import("std");

pub const BuildArtifact = struct {
    root_module: *std.Build.Module,
    name: []const u8,

    pub fn addImport(artifact: *const BuildArtifact, import: BuildArtifact) void {
        artifact.root_module.addImport(import.name, import.root_module);
    }
};

pub const BuildContext = struct {
    build: *std.Build,
    resolvedTarget: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    use_llvm: bool,

    pub fn standard(b: *std.Build) BuildContext {
        return BuildContext{
            .build = b,
            .resolvedTarget = b.standardTargetOptions(.{}),
            .optimize = b.standardOptimizeOption(.{}),
            .use_llvm = !(b.option(bool, "no-llvm", "disable the LLVM backend") orelse false),
        };
    }

    pub fn createLibrary(ctx: *const BuildContext, comptime name: []const u8, linkage: std.builtin.LinkMode) BuildArtifact {
        const root_module = ctx.createModule("lib/" ++ name ++ "/root.zig");
        const compile = ctx.build.addLibrary(.{ .linkage = linkage, .name = name, .root_module = root_module });
        ctx.build.installArtifact(compile);
        return BuildArtifact{ .root_module = root_module, .name = compile.name };
    }

    pub fn createExecutable(ctx: *const BuildContext, comptime name: []const u8) BuildArtifact {
        const root_module = ctx.createModule("bin/" ++ name ++ "/main.zig");
        const compile = ctx.build.addExecutable(.{ .name = name, .root_module = root_module, .use_llvm = ctx.use_llvm });
        ctx.build.installArtifact(compile);
        const run_cmd = ctx.build.addRunArtifact(compile);
        run_cmd.step.dependOn(ctx.build.getInstallStep());
        if (ctx.build.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = ctx.build.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
        return BuildArtifact{ .root_module = root_module, .name = compile.name };
    }

    pub fn createTests(ctx: *const BuildContext, artifacts: []const BuildArtifact) void {
        const test_step = ctx.build.step("test", "Run unit tests");
        for (artifacts) |artifact| {
            const test_ = ctx.build.addTest(.{
                .root_module = artifact.root_module,
                .test_runner = .{
                    .path = ctx.build.path("build_test_runner.zig"),
                    .mode = .simple,
                },
            });
            const run_test = ctx.build.addRunArtifact(test_);
            test_step.dependOn(&run_test.step);
        }
    }

    pub fn dependency(ctx: *const BuildContext, name: []const u8) BuildArtifact {
        return .{
            .root_module = ctx.build.dependency(name, .{
                .target = ctx.resolvedTarget,
                .optimize = ctx.optimize,
            }).module(name),
            .name = name,
        };
    }

    fn createModule(ctx: *const BuildContext, sub_path: []const u8) *std.Build.Module {
        return ctx.build.createModule(.{
            .root_source_file = ctx.build.path(sub_path),
            .target = ctx.resolvedTarget,
            .optimize = ctx.optimize,
        });
    }
};
