const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const ArrayList = std.ArrayList;

// Function that returns the lower bound in O(logn)
pub fn lower_bound(arr: []const i32, key: i32) usize {
    var lo: usize = 0;
    var hi: usize = arr.len;

    while(lo < hi) {
        const mid: usize = lo + (hi - lo) / 2;
        if (key <= arr[mid]) {
            hi = mid;
        }
        else {
            lo = mid + 1;
        }
    }

    if (lo < arr.len and arr[lo] < key) {
        lo += 1;
    }

    return lo;
}

// Function that returns the length of the longest increasing subsequence of an array
// Runs in O(nlogn) using the lower bound function
pub fn lis(arr: []const i32) usize {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var v = ArrayList(i32).init(allocator);
    defer v.deinit();

    const n = arr.len;

    for (0..n) |i| {
        const it = lower_bound(v.items, arr[i]);
        if (it == v.items.len) {
            _ = v.append(arr[i]) catch return 0;
        }
        else {
            v.items[it] = arr[i];
        }
    }

    return v.items.len;
}

test "testing longest increasing subsequence function" {
    const v = [4]i32 { 1, 5, 6, 7 };
    try testing.expect(lis(&v) == 4);

    const v2 = [5]i32 { 1, -1, 5, 6, 7 };
    try testing.expect(lis(&v2) == 4);

    const v3 = [5]i32 { 1, 2, -1, 0, 1 };
    try testing.expect(lis(&v3) == 3);

    const v4 = [0]i32 {};
    try testing.expect(lis(&v4) == 0);

    const v5 = [5]i32 { 0, 0, 0, 0, 0 };
    try testing.expect(lis(&v5) == 1);
}