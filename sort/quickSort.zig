const std = @import("std");
const builtin = std.builtin;
const expect = std.testing.expect;
const mem = std.mem;

///References: https://en.wikipedia.org/wiki/Quicksort
pub fn sort(A: []i32, lo: usize, hi: usize) void {
    if (lo < hi) {
        const p = partition(A, lo, hi);
        sort(A, lo, @min(p, p -% 1));
        sort(A, p + 1, hi);
    }
}

pub fn partition(A: []i32, lo: usize, hi: usize) usize {
    //Pivot can be chosen otherwise, for example try picking the first or random
    //and check in which way that affects the performance of the sorting
    const pivot = A[hi];
    var i = lo;
    var j = lo;
    while (j < hi) : (j += 1) {
        if (A[j] < pivot) {
            mem.swap(i32, &A[i], &A[j]);
            i = i + 1;
        }
    }
    mem.swap(i32, &A[i], &A[hi]);
    return i;
}

test "empty array" {
    const array: []i32 = &.{};
    sort(array, 0, 0);
    const a = array.len;
    try expect(a == 0);
}

test "array with one element" {
    var array: [1]i32 = .{5};
    sort(&array, 0, array.len - 1);
    const a = array.len;
    try expect(a == 1);
    try expect(array[0] == 5);
}

test "sorted array" {
    var array: [10]i32 = .{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    sort(&array, 0, array.len - 1);
    for (array, 0..) |value, i| {
        try expect(value == (i + 1));
    }
}

test "reverse order" {
    var array: [10]i32 = .{ 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 };
    sort(&array, 0, array.len - 1);
    for (array, 0..) |value, i| {
        try expect(value == (i + 1));
    }
}

test "unsorted array" {
    var array: [5]i32 = .{ 5, 3, 4, 1, 2 };
    sort(&array, 0, array.len - 1);
    for (array, 0..) |value, i| {
        try expect(value == (i + 1));
    }
}

test "two last unordered" {
    var array: [10]i32 = .{ 1, 2, 3, 4, 5, 6, 7, 8, 10, 9 };
    sort(&array, 0, array.len - 1);
    for (array, 0..) |value, i| {
        try expect(value == (i + 1));
    }
}

test "two first unordered" {
    var array: [10]i32 = .{ 2, 1, 3, 4, 5, 6, 7, 8, 9, 10 };
    sort(&array, 0, array.len - 1);
    for (array, 0..) |value, i| {
        try expect(value == (i + 1));
    }
}
