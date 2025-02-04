const std = @import("std");
const options = @import("options");

const zzz = @import("zzz");
const http = zzz.HTTP;

const tardy = zzz.tardy;
const Tardy = tardy.Tardy(.poll);
const Runtime = tardy.Runtime;
const Socket = tardy.Socket;

const Server = http.Server;
const Router = http.Router;
const Context = http.Context;
const Route = http.Route;
const Middleware = http.Middleware;

const Next = http.Next;
const Response = http.Response;
const Respond = http.Respond;

pub fn main() !void {
    const host: []const u8 = "0.0.0.0";
    const port: u16 = 3000;

    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const count = try std.math.divCeil(usize, 1800, options.threads);

    var t = try Tardy.init(allocator, .{
        .threading = .{ .multi = options.threads },
        .pooling = .static,
        .size_tasks_initial = count,
        .size_aio_reap_max = count,
    });
    defer t.deinit();

    var router = try Router.init(allocator, &.{
        Route.init("/").get({}, base_handler).layer(),
    }, .{});
    defer router.deinit(allocator);

    // create socket for tardy
    var socket = try Socket.init(.{ .tcp = .{ .host = host, .port = port } });
    defer socket.close_blocking();
    try socket.bind();
    try socket.listen(4096);

    const EntryParams = struct {
        router: *const Router,
        socket: Socket,
        count: u32,
    };

    try t.entry(
        EntryParams{ .router = &router, .socket = socket, .count = @intCast(count) },
        struct {
            fn entry(rt: *Runtime, p: EntryParams) !void {
                var server = Server.init(rt.allocator, .{
                    .stack_size = 1024 * 8,
                    .socket_buffer_bytes = 512,
                    .keepalive_count_max = null,
                    .connection_count_max = p.count,

                    .header_count_max = 8,
                    .capture_count_max = 0,
                    .query_count_max = 0,
                });
                try server.serve(rt, p.router, p.socket);
            }
        }.entry,
    );
}

fn base_handler(_: *const Context, _: void) !Respond {
    return .{ .standard = .{
        .status = .OK,
        .mime = http.Mime.HTML,
        .body = "This is an HTTP benchmark",
    } };
}
