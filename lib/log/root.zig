const std = @import("std");
const eql = std.mem.eql;

const DateTime = @import("./datetime.zig");

pub const LogLevel = enum {
    Critical,
    Error,
    Warn,
    Info,
    Debug,
    Trace,
};

fn logLevelColor(log_level: LogLevel) *const [2:0]u8 {
    return switch (log_level) {
        .Critical => "31", // Dark Red
        .Error => "91", // Red
        .Warn => "93", // Yellow
        .Info => "96", // Cyan
        .Debug => "95", // Magenta
        .Trace => "37", // Light Grey
    };
}

var global_log_level = LogLevel.Error;
var use_style = true;
var env_initialized = false;

const stderr_file = std.fs.File.stdout();
const stderr_buf: [0x1000]u8 = undefined;
var stderr = stderr_file.writer(@constCast(&stderr_buf));

pub fn log(log_level: LogLevel, comptime fmt: []const u8, args: anytype) void {
    if (!env_initialized) {
        // this only happens once per program, so we can hold a temporary allocator here
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        const env_log_level = std.process.getEnvVarOwned(allocator, "LOG_LEVEL") catch "";

        if (eql(u8, env_log_level, "CRITICAL")) {
            global_log_level = .Critical;
        } else if (eql(u8, env_log_level, "WARN")) {
            global_log_level = .Warn;
        } else if (eql(u8, env_log_level, "INFO")) {
            global_log_level = .Info;
        } else if (eql(u8, env_log_level, "DEBUG")) {
            global_log_level = .Debug;
        } else if (eql(u8, env_log_level, "TRACE")) {
            global_log_level = .Trace;
        }

        const env_nostyle = std.process.getEnvVarOwned(allocator, "LOG_NOSTYLE") catch null;
        const is_tty = stderr_file.isTty() or stderr_file.isCygwinPty();
        if (env_nostyle != null or !is_tty) {
            use_style = false;
        }

        env_initialized = true;
    }

    if (@intFromEnum(global_log_level) >= @intFromEnum(log_level)) {
        const datetime = DateTime.fromMillis(std.time.milliTimestamp());
        if (use_style) {
            stderr.interface.print("\x1b[90m{f}\x1b[{2s};1m   [{s}]\x1b[22m\t", .{
                datetime,
                @tagName(log_level),
                logLevelColor(log_level),
            }) catch return;
            stderr.interface.print(fmt, args) catch return;
            stderr.interface.print("\n\x1b[0m", .{}) catch return;
            nosuspend stderr.interface.flush() catch return;
        } else {
            stderr.interface.print("{f}   [{s}]\t", .{ datetime, @tagName(log_level) }) catch return;
            stderr.interface.print(fmt, args) catch return;
            stderr.interface.print("\n", .{}) catch return;
        }

        nosuspend stderr.interface.flush() catch return;
    }
}
