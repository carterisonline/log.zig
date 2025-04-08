# log.zig

A simple logging library for Zig.

## Installation

Fetch `log.zig` from github:
```sh
zig fetch --save git+https://github.com/carterisonline/log.zig
```

Add `log.zig` to your `build.zig`:
```zig
    const log = b.dependency("log", .{
        .target = target,
        .optimize = optimize,
    });
    ...
    exe.root_module.addImport("log", log.module("log"));
```

## Usage

`log.zig` is very similar to `std.debug.print`:
```zig
const log = @import("log").log;

pub fn main() !void {
    log(.Info, "log.zig is {s}!", .{"working"});
}
```

Set the log level using the `LOG_LEVEL` variable:
```sh
# can be CRITICAL, ERROR, WARN, INFO, DEBUG, or TRACE.
# defaults to ERROR if not set.
LOG_LEVEL=INFO zig build run
```

Forcefully disable text styling by setting the `LOG_NOSTYLE` variable:
```sh
export LOG_NOSTYLE
zig build run

## or:
LOG_NOSTYLE="" zig build run
```