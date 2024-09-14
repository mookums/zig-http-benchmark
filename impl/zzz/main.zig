const std = @import("std");
const zzz = @import("zzz");
const options = @import("options");
const http = zzz.HTTP;

pub fn main() !void {
    const allocator = std.heap.c_allocator;

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

    // Calculates the nearest power of two for dividing the total number
    // of connections by the allocated number of threads.
    //
    // This should probably be done automatically in zzz...
    const conn_per_thread: u16 = std.math.pow(u16, 2, @intFromFloat(
        @ceil(@log(2048.0 / @as(f32, @floatFromInt(options.threads))) / @log(2.0)),
    ));

    var server = http.Server(.plain).init(.{
        .allocator = allocator,
        .threading = .{ .multi_threaded = .{ .count = options.threads } },
        .size_connections_max = conn_per_thread,
        .size_socket_buffer = 512,
    }, null);
    defer server.deinit();

    try server.bind("0.0.0.0", 3000);
    try server.listen(.{
        .router = &router,
        .num_header_max = 8,
        .num_captures_max = 0,
    });
}
