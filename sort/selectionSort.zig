const std = @import("std");
const mem = std.mem;
const expect = std.testing.expect;

// Reference: https://www.geeksforgeeks.org/dsa/selection-sort-algorithm-2/
fn sort(A: []i64) void {
    for (0..A.len) |i| {
        var smallest: usize = i;

        for (i + 1..A.len) |j| {
            // condetion: < for ascending order and > for descending order
            if (A[j] < A[smallest]) {
                smallest = j;
            }
        }

        mem.swap(i64, &A[i], &A[smallest]);
    }
}

test "empty array" {
    var A = [_]i64{};
    sort(&A);
    for (A, 0..) |value, i| {
        try expect(value == i);
    }
}

test "single element" {
    var A = [_]i64{0};
    sort(&A);
    for (A, 0..) |value, i| {
        try expect(value == i);
    }
}

test "reverse order" {
    var A = [_]i64{ 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 };
    sort(&A);
    for (A, 0..) |value, i| {
        try expect(value == i);
    }
}

test "all same" {
    var A = [_]i64{ 0, 0, 0, 0, 0, 0 };
    const forTest = [_]i64{ 0, 0, 0, 0, 0, 0 };
    sort(&A);
    for (A, forTest) |i, j| {
        try expect(i == j);
    }
}

test "sorted" {
    var A = [_]i64{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };
    sort(&A);
    for (A, 0..) |value, i| {
        try expect(value == i);
    }
}

test "partially sorted" {
    var A = [_]i64{ 0, 1, 2, 3, 4, 9, 6, 5, 8, 7 };
    sort(&A);
    for (A, 0..) |value, i| {
        try expect(value == i);
    }
}

test "last two unordered" {
    var A = [_]i64{ 0, 1, 2, 3, 4, 5, 6, 7, 9, 8 };
    sort(&A);
    for (A, 0..) |value, i| {
        try expect(value == i);
    }
}

test "first two unordered" {
    var A = [_]i64{ 1, 0, 2, 3, 4, 5, 6, 7, 8, 9 };
    sort(&A);
    for (A, 0..) |value, i| {
        try expect(value == i);
    }
}

test "negative numbers with duplicates" {
    var A = [_]i64{ -6, -3, 6, 0, -7, 2, 1, 8, -5, 1, 6 };
    const sortedA = [_]i64{ -7, -6, -5, -3, 0, 1, 1, 2, 6, 6, 8 };
    sort(&A);
    for (A, sortedA) |i, j| {
        try expect(i == j);
    }
}
