const std = @import("std");
const zzz = @import("zzz");
const http = zzz.HTTP;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var router = http.Router.init(allocator);
    defer router.deinit();

    try router.serve_route("/", http.Route.init().get(struct {
        fn base_handler(_: http.Request, response: *http.Response, _: http.Context) void {
            response.set(.{
                .status = .OK,
                .mime = http.Mime.HTML,
                .body = "This is an HTTP benchmark",
            });
        }
    }.base_handler));

    var server = http.Server(.plain).init(.{
        .allocator = allocator,
        .threading = .single_threaded,
        .size_connections_max = 2048,
    }, null);
    defer server.deinit();

    try server.bind("0.0.0.0", 3000);
    try server.listen(.{ .router = &router });
}
