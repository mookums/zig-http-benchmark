const std = @import("std");
const zzz = @import("zzz");
const options = @import("options");
const http = zzz.HTTP;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

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

    const conn_per_thread = try std.math.divCeil(u16, 2000, options.threads);

    var server = http.Server(.plain, .auto).init(.{
        .allocator = allocator,
        .threading = .{ .multi = options.threads },
        .size_connections_max = conn_per_thread,
        .size_completions_reap_max = @min(conn_per_thread, 256),
        .size_socket_buffer = 512,
    });
    defer server.deinit();

    try server.bind("0.0.0.0", 3000);
    try server.listen(.{
        .router = &router,
        .num_header_max = 16,
        .num_captures_max = 0,
    });
}
