const std = @import("std");
const zap = @import("zap");

fn on_request_minimal(r: zap.Request) void {
    r.sendBody("This is an HTTP benchmark") catch return;
}

pub fn main() !void {
    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = on_request_minimal,
        .log = false,
        .max_clients = 100000,
    });
    try listener.listen();

    std.debug.print("Listening on 0.0.0.0:3000\n", .{});

    // start worker threads
    zap.start(.{
        .threads = 4,
        .workers = 4, // empirical tests: yield best perf on my machine
    });
}
