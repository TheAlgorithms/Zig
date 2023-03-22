const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const op = b.option([]const u8, "algorithm", "choice algoritm to build.") orelse return;

    // Sort algorithms
    if (std.mem.eql(u8, op, "sort/quicksort"))
        build_algorithm(b, mode, target, "quickSort.zig", "sort");
    if (std.mem.eql(u8, op, "sort/bubblesort"))
        build_algorithm(b, mode, target, "bubbleSort.zig", "sort");
    if (std.mem.eql(u8, op, "sort/radixsort"))
        build_algorithm(b, mode, target, "radixSort.zig", "sort");
    if (std.mem.eql(u8, op, "sort/mergesort"))
        build_algorithm(b, mode, target, "mergeSort.zig", "sort");
    if (std.mem.eql(u8, op, "sort/insertsort"))
        build_algorithm(b, mode, target, "insertionSort.zig", "sort");

    // Search algorithms
    if (std.mem.eql(u8, op, "search/bSearchTree"))
        build_algorithm(b, mode, target, "binarySearchTree.zig", "search");
    if (std.mem.eql(u8, op, "search/rb"))
        build_algorithm(b, mode, target, "redBlackTrees.zig", "search");

    // Data Structures algorithms
    if (std.mem.eql(u8, op, "ds/linkedlist"))
        build_algorithm(b, mode, target, "linkedList.zig", "dataStructures");
    if (std.mem.eql(u8, op, "ds/lrucache"))
        build_algorithm(b, mode, target, "lruCache.zig", "dataStructures");

    // Dynamic Programming algorithms

    // Math algorithms
    if (std.mem.eql(u8, op, "math/ceil"))
        build_algorithm(b, mode, target, "ceil.zig", "math");
    if (std.mem.eql(u8, op, "math/crt"))
        build_algorithm(b, mode, target, "chineseRemainderTheorem.zig", "math");
    if (std.mem.eql(u8, op, "math/fibonacci"))
        build_algorithm(b, mode, target, "fibonacciRecursion.zig", "math");
    if (std.mem.eql(u8, op, "math/primes"))
        build_algorithm(b, mode, target, "primes.zig", "math");
    if (std.mem.eql(u8, op, "math/euclidianGCDivisor"))
        build_algorithm(b, mode, target, "euclidianGreatestCommonDivisor.zig", "math");
    if (std.mem.eql(u8, op, "math/gcd"))
        build_algorithm(b, mode, target, "gcd.zig", "math");
    if (std.mem.eql(u8, op, "math/factorial"))
        build_algorithm(b, mode, target, "factorial.zig", "math");

    // Concurrent
    if (std.mem.eql(u8, op, "threads/threadpool"))
        build_algorithm(b, mode, target, "ThreadPool.zig", "concurrency/threads");

    // Web
    if (std.mem.eql(u8, op, "web/http"))
        build_algorithm(b, mode, target, "client.zig", "web/http");
    if (std.mem.eql(u8, op, "web/tls1_3"))
        build_algorithm(b, mode, target, "X25519+Kyber768Draft00.zig", "web/tls");
}

fn build_algorithm(b: *std.build.Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget, name: []const u8, path: []const u8) void {
    const src = std.mem.concat(b.allocator, u8, &.{ path, "/", name }) catch @panic("concat error");
    const exe_tests = b.addTest(.{
        .name = name,
        .target = target,
        .optimize = mode,
        .root_source_file = .{ .path = src },
    });

    var descr = b.fmt("Test the {s} algorithm", .{name});

    const test_step = b.step("test", descr);
    test_step.dependOn(&exe_tests.step);
}
