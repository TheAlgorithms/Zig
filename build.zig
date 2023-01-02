const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    b.prominent_compile_errors = true;

    const op = b.option([]const u8, "algorithm", "choice algoritm to build.") orelse undefined;

    // Sort algorithms
    if (std.mem.eql(u8, op, "sort/quicksort"))
        build_algorithm(b, mode, target, "quickSort.zig", "sort");
    if (std.mem.eql(u8, op, "sort/bubblesort"))
        build_algorithm(b, mode, target, "bubbleSort.zig", "sort");
    if (std.mem.eql(u8, op, "sort/radixsort"))
        build_algorithm(b, mode, target, "radixSort.zig", "sort");

    // Search algorithms
    if (std.mem.eql(u8, op, "search/bSearchTree"))
        build_algorithm(b, mode, target, "binarySearchTree.zig", "search");

    // Data Structures algorithms
    if (std.mem.eql(u8, op, "ds/linkedlist"))
        build_algorithm(b, mode, target, "linkedList.zig", "dataStructures");

    // Dynamic Programming algorithms
    if (std.mem.eql(u8, op, "dp/fibonacci"))
        build_algorithm(b, mode, target, "fibonacciRecursion.zig", "dynamicProgramming");

    // Math algorithms
    if (std.mem.eql(u8, op, "math/ceil"))
        build_algorithm(b, mode, target, "ceil.zig", "math");
    if (std.mem.eql(u8, op, "math/crt"))
        build_algorithm(b, mode, target, "chineseRemainderTheorem.zig", "math");
    if (std.mem.eql(u8, op, "math/primes"))
        build_algorithm(b, mode, target, "primes.zig", "math");
    if (std.mem.eql(u8, op, "math/euclidianGCDivisor"))
        build_algorithm(b, mode, target, "euclidianGreatestCommonDivisor.zig", "math");
    if (std.mem.eql(u8, op, "math/gcd"))
        build_algorithm(b, mode, target, "gcd.zig", "math");
}

fn build_algorithm(b: *std.build.Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget, name: []const u8, path: []const u8) void {
    var bf: [100]u8 = undefined;
    std.debug.print("Building {s}\n", .{name});

    const example = b.addExecutable(name, path);
    example.setBuildMode(mode);
    example.setTarget(target);
    example.install();

    const run_cmd = example.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const src = std.mem.concat(std.heap.page_allocator, u8, &.{ path, "/", name }) catch "math";
    const exe_tests = b.addTest(src);
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    var descr = std.fmt.bufPrintZ(&bf, "Test the {s} algorithm", .{name}) catch unreachable;

    const test_step = b.step("test", descr);
    test_step.dependOn(&exe_tests.step);
}
