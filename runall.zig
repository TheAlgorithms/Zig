const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Math algorithms
    try runTest(allocator, "math/ceil");
    try runTest(allocator, "math/crt");
    try runTest(allocator, "math/primes");
    try runTest(allocator, "math/fibonacci");
    try runTest(allocator, "math/factorial");
    try runTest(allocator, "math/euclidianGCDivisor");
    try runTest(allocator, "math/gcd");

    // Data Structures
    try runTest(allocator, "ds/trie");
    try runTest(allocator, "ds/linkedlist");
    try runTest(allocator, "ds/doublylinkedlist");
    try runTest(allocator, "ds/lrucache");
    try runTest(allocator, "ds/stack");

    // Dynamic Programming
    try runTest(allocator, "dp/coinChange");
    try runTest(allocator, "dp/knapsack");
    try runTest(allocator, "dp/longestIncreasingSubsequence");
    try runTest(allocator, "dp/editDistance");

    // Sort
    try runTest(allocator, "sort/quicksort");
    try runTest(allocator, "sort/bubblesort");
    try runTest(allocator, "sort/radixsort");
    try runTest(allocator, "sort/mergesort");
    try runTest(allocator, "sort/insertsort");
    try runTest(allocator, "sort/selectionSort");

    // Search
    try runTest(allocator, "search/bSearchTree");
    try runTest(allocator, "search/rb");

    // Threads
    try runTest(allocator, "threads/threadpool");

    // Web
    try runTest(allocator, "web/httpClient");
    try runTest(allocator, "web/httpServer");
    try runTest(allocator, "web/tls1_3");

    // Machine Learning
    try runTest(allocator, "machine_learning/k_means_clustering");

    // Numerical Methods
    try runTest(allocator, "numerical_methods/newton_raphson");

    // Tiger Style
    try runTest(allocator, "tiger_style/time_simulation");
    try runTest(allocator, "tiger_style/merge_sort_tiger");
    try runTest(allocator, "tiger_style/knapsack_tiger");
    try runTest(allocator, "tiger_style/ring_buffer");
    try runTest(allocator, "tiger_style/raft_consensus");
    try runTest(allocator, "tiger_style/two_phase_commit");
    try runTest(allocator, "tiger_style/vsr_consensus");
    try runTest(allocator, "tiger_style/robin_hood_hash");
    try runTest(allocator, "tiger_style/skip_list");
}

fn runTest(allocator: std.mem.Allocator, comptime algorithm: []const u8) !void {
    var child = std.process.Child.init(&[_][]const u8{
        "zig",
        "build",
        "test",
        "-Dalgorithm=" ++ algorithm,
    } ++ args, allocator);

    child.stderr = std.fs.File.stderr();
    child.stdout = std.fs.File.stdout();

    _ = try child.spawnAndWait();
}

const args = [_][]const u8{
    "--summary",
    "all",
    "-freference-trace",
};
