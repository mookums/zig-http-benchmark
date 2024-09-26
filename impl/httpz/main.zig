const std = @import("std");
const httpz = @import("httpz");
const options = @import("options");

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    var server = try httpz.Server().init(allocator, .{
        .address = "0.0.0.0",
        .port = 3000,
        .workers = .{
            .count = options.threads,
            .max_conn = 2000,
        },
        .thread_pool = .{ .count = options.threads },
    });
    defer server.deinit();
    defer server.stop();

    var router = server.router();

    router.get("/", struct {
        fn base_handler(_: *httpz.Request, res: *httpz.Response) !void {
            res.body = "This is an HTTP benchmark";
        }
    }.base_handler);

    try server.listen();
}
