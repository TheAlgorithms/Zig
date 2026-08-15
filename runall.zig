const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    try runTest(io, "math/ceil");
    try runTest(io, "math/crt");
    try runTest(io, "math/primes");
    try runTest(io, "math/fibonacci");
    try runTest(io, "math/factorial");
    try runTest(io, "math/euclidianGCDivisor");
    try runTest(io, "math/gcd");

    try runTest(io, "ds/trie");
    try runTest(io, "ds/linkedlist");
    try runTest(io, "ds/doublylinkedlist");
    try runTest(io, "ds/lrucache");
    try runTest(io, "ds/stack");
    try runTest(io, "ds/heap");
    try runTest(io, "ds/queue");

    try runTest(io, "dp/coinChange");
    try runTest(io, "dp/knapsack");
    try runTest(io, "dp/longestIncreasingSubsequence");
    try runTest(io, "dp/editDistance");

    try runTest(io, "sort/quicksort");
    try runTest(io, "sort/bubblesort");
    try runTest(io, "sort/radixsort");
    try runTest(io, "sort/mergesort");
    try runTest(io, "sort/insertsort");
    try runTest(io, "sort/selectionSort");
    try runTest(io, "sort/heapSort");

    try runTest(io, "search/bSearchTree");
    try runTest(io, "search/rb");
    try runTest(io, "search/linearSearch");

    try runTest(io, "threads/threadpool");

    try runTest(io, "web/httpClient");
    try runTest(io, "web/httpServer");
    try runTest(io, "web/tls1_3");

    try runTest(io, "machine_learning/k_means_clustering");

    try runTest(io, "numerical_methods/newton_raphson");

    try runTest(io, "tiger_style/time_simulation");
    try runTest(io, "tiger_style/merge_sort_tiger");
    try runTest(io, "tiger_style/knapsack_tiger");
    try runTest(io, "tiger_style/ring_buffer");
    try runTest(io, "tiger_style/raft_consensus");
    try runTest(io, "tiger_style/two_phase_commit");
    try runTest(io, "tiger_style/vsr_consensus");
    try runTest(io, "tiger_style/robin_hood_hash");
    try runTest(io, "tiger_style/skip_list");
}

const args = [_][]const u8{
    "--summary",
    "all",
    "-freference-trace",
};

fn runTest(io: Io, comptime algorithm: []const u8) !void {
    const argv = [_][]const u8{
        "zig",
        "build",
        "test",
        "-Dalgorithm=" ++ algorithm,
    } ++ args;

    var child = try std.process.spawn(io, .{ .argv = &argv });
    _ = try child.wait(io);
}
