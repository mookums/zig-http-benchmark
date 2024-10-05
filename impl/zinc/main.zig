const std = @import("std");
const zinc = @import("zinc");
const options = @import("options");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};

    var tsa = std.heap.ThreadSafeAllocator{
        .child_allocator = gpa.allocator(),
    };

    const allocator = tsa.allocator();
    const cpuCount = options.threads;

    var z = try zinc.init(.{
        .port = 3000,
        .allocator = allocator,
        .num_threads = 16 * cpuCount,
    });

    var router = z.getRouter();

    try router.use(&.{setupHeader});
    try router.get("/", benchmark);

    z.run() catch |err| std.debug.print("Error: {any}\n", .{err});
}

fn benchmark(ctx: *zinc.Context) anyerror!void {
    try ctx.text("This is an HTTP benchmark", .{});
}

fn setupHeader(ctx: *zinc.Context) anyerror!void {
    try ctx.setHeader("Server", "Zinc");
    try ctx.setHeader("Connection", "keep-alive");
}
