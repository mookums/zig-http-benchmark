const std = @import("std");
const zap = @import("zap");
const options = @import("options");

fn on_request_minimal(r: zap.Request) void {
    r.sendBody("This is an HTTP benchmark") catch return;
}

pub fn main() !void {
    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = on_request_minimal,
        .log = false,
        .max_clients = 2048,
    });
    try listener.listen();

    // start worker threads
    zap.start(.{
        .threads = options.threads,
        .workers = options.threads,
    });
    defer zap.stop();
}
