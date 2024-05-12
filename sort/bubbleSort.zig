const std = @import("std");
const builtin = std.builtin;
const expect = std.testing.expect;
const mem = std.mem;

pub fn sort(A: []i32) void {
    var n = A.len;
    while (n > 1) {
        var new_n: usize = 0;
        for (A[0 .. n - 1], 0..) |value, i| {
            if (value > A[i + 1]) {
                mem.swap(i32, &A[i], &A[i + 1]);
                new_n = i + 1;
            }
        }
        n = new_n;
    }
}

test "empty array" {
    const array: []i32 = &.{};
    sort(array);
    const a = array.len;
    try expect(a == 0);
}

test "array with one element" {
    var array: [1]i32 = .{5};
    sort(&array);
    const a = array.len;
    try expect(a == 1);
    try expect(array[0] == 5);
}

test "sorted array" {
    var array: [10]i32 = .{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    sort(&array);
    for (array, 0..) |value, i| {
        try expect(value == (i + 1));
    }
}

test "reverse order" {
    var array: [10]i32 = .{ 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 };
    sort(&array);
    for (array, 0..) |value, i| {
        try expect(value == (i + 1));
    }
}

test "unsorted array" {
    var array: [5]i32 = .{ 5, 3, 4, 1, 2 };
    sort(&array);
    for (array, 0..) |value, i| {
        try expect(value == (i + 1));
    }
}

test "two last unordered" {
    var array: [10]i32 = .{ 1, 2, 3, 4, 5, 6, 7, 8, 10, 9 };
    sort(&array);
    for (array, 0..) |value, i| {
        try expect(value == (i + 1));
    }
}

test "two first unordered" {
    var array: [10]i32 = .{ 2, 1, 3, 4, 5, 6, 7, 8, 9, 10 };
    sort(&array);
    for (array, 0..) |value, i| {
        try expect(value == (i + 1));
    }
}
