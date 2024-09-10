const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zap = b.dependency("zap", .{
        .target = target,
        .optimize = optimize,
    }).module("zap");

    const httpz = b.dependency("httpz", .{
        .target = target,
        .optimize = optimize,
    }).module("httpz");

    const zzz = b.dependency("zzz", .{
        .target = target,
        .optimize = optimize,
    }).module("zzz");

    add_benchmark(b, "zigstd", target, optimize, null, b.path("impl/zigstd/main.zig"));
    add_benchmark(b, "zap", target, optimize, .{ .name = "zap", .module = zap }, b.path("impl/zap/main.zig"));
    add_benchmark(b, "httpz", target, optimize, .{ .name = "httpz", .module = httpz }, b.path("impl/httpz/main.zig"));
    add_benchmark(b, "zzz", target, optimize, .{ .name = "zzz", .module = zzz }, b.path("impl/zzz/main.zig"));
}

const Library = struct {
    name: []const u8,
    module: *std.Build.Module,
};

fn add_benchmark(
    b: *std.Build,
    name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    library: ?Library,
    file: std.Build.LazyPath,
) void {
    const exe = b.addExecutable(.{
        .name = name,
        .target = target,
        .optimize = optimize,
        .root_source_file = file,
    });

    if (library) |lib| {
        exe.root_module.addImport(lib.name, lib.module);
    }

    const install = b.addInstallArtifact(exe, .{});
    b.getInstallStep().dependOn(&install.step);

    const build_step = b.step(b.fmt("{s}", .{name}), b.fmt("build the {s} benchmark", .{name}));
    build_step.dependOn(&install.step);
}
