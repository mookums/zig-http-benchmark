const std = @import("std");
const httpz = @import("httpz");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var server = try httpz.Server().init(allocator, .{
        .address = "0.0.0.0",
        .port = 3000,
        .workers = .{ .count = 4 },
        .thread_pool = .{ .count = 4 },
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
