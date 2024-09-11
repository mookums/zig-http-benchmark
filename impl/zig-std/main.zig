const std = @import("std");

pub fn main() !void {
    const address = try std.net.Address.parseIp("0.0.0.0", 3000);
    var http_server = try address.listen(.{
        .reuse_address = true,
    });

    var read_buffer: [2048]u8 = undefined;

    while (true) {
        const connection = try http_server.accept();
        defer connection.stream.close();
        var server = std.http.Server.init(connection, &read_buffer);

        var request = try server.receiveHead();
        const server_body: []const u8 = "This is an HTTP benchmark\n";

        try request.respond(server_body, .{
            .extra_headers = &.{
                .{ .name = "content_type", .value = "text/plain" },
                .{ .name = "connection", .value = "close" },
            },
        });
    }
}
