const std = @import("std");
const expect = std.testing.expect;
const assert = std.debug.assert;

pub fn sort(A: []i32, B: []i32) void {
    assert(A.len == B.len);
    copy_array(A, 0, A.len, B);
    split_merge(B, 0, A.len, A);
}

fn split_merge(B: []i32, begin: usize, end: usize, A: []i32) void {
    if (end - begin <= 1) {
        return;
    }
    const middle = (end + begin) / 2;
    split_merge(A, begin, middle, B);
    split_merge(A, middle, end, B);
    merge(B, begin, middle, end, A);
}

fn merge(A: []i32, begin: usize, middle: usize, end: usize, B: []i32) void {
    var i = begin;
    var k = begin;
    var j = middle;

    while (k < end) : (k += 1) {
        if (i < middle and (j >= end or A[i] <= A[j])) {
            B[k] = A[i];
            i = i + 1;
        } else {
            B[k] = A[j];
            j = j + 1;
        }
    }
}

fn copy_array(A: []i32, begin: usize, end: usize, B: []i32) void {
    var k = begin;
    while (k < end) : (k += 1) {
        B[k] = A[k];
    }
}

test "empty array" {
    const array: []i32 = &.{};
    const work_array: []i32 = &.{};
    sort(array, work_array);
    const a = array.len;
    try expect(a == 0);
}

test "array with one element" {
    var array: [1]i32 = .{5};
    var work_array: [1]i32 = .{0};
    sort(&array, &work_array);
    const a = array.len;
    try expect(a == 1);
    try expect(array[0] == 5);
}

test "sorted array" {
    var array: [10]i32 = .{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    var work_array: [10]i32 = .{0} ** 10;
    sort(&array, &work_array);
    for (array, 0..) |value, i| {
        try expect(value == (i + 1));
    }
}

test "reverse order" {
    var array: [10]i32 = .{ 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 };
    var work_array: [10]i32 = .{0} ** 10;
    sort(&array, &work_array);
    for (array, 0..) |value, i| {
        try expect(value == (i + 1));
    }
}

test "unsorted array" {
    var array: [5]i32 = .{ 5, 3, 4, 1, 2 };
    var work_array: [5]i32 = .{0} ** 5;
    sort(&array, &work_array);
    for (array, 0..) |value, i| {
        try expect(value == (i + 1));
    }
}

test "two last unordered" {
    var array: [10]i32 = .{ 1, 2, 3, 4, 5, 6, 7, 8, 10, 9 };
    var work_array: [10]i32 = .{0} ** 10;
    sort(&array, &work_array);
    for (array, 0..) |value, i| {
        try expect(value == (i + 1));
    }
}

test "two first unordered" {
    var array: [10]i32 = .{ 2, 1, 3, 4, 5, 6, 7, 8, 9, 10 };
    var work_array: [10]i32 = .{0} ** 10;
    sort(&array, &work_array);
    for (array, 0..) |value, i| {
        try expect(value == (i + 1));
    }
}
