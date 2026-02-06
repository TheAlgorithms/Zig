const std = @import("std");
const expect = std.testing.expect;

pub fn sort(arr: []i32) void {
    const n = arr.len;
    if (n <= 1) return;

    // Build heap (rearrange array)
    var i: usize = n / 2;
    while (i > 0) {
        i -= 1;
        heapify(arr, n, i);
    }

    // One by one extract an element from heap
    var end = n - 1;
    while (end > 0) : (end -= 1) {
        // Move current root to end
        std.mem.swap(i32, &arr[0], &arr[end]);

        // call max heapify on the reduced heap
        heapify(arr, end, 0);
    }
}

// To heapify a subtree rooted with node i which is
// an index in arr[]. n is size of heap
fn heapify(arr: []i32, n: usize, start_index: usize) void {
    var i = start_index;

    while (true) {
        var largest = i; // Initialize largest as root
        const l = 2 * i + 1; // left = 2*i + 1
        const r = 2 * i + 2; // right = 2*i + 2

        // If left child is larger than root
        if (l < n and arr[l] > arr[largest])
            largest = l;

        // If right child is larger than largest so far
        if (r < n and arr[r] > arr[largest])
            largest = r;

        // If largest is not root
        if (largest != i) {
            std.mem.swap(i32, &arr[i], &arr[largest]);
            i = largest;
        } else {
            break;
        }
    }
}

test "empty array" {
    const array: []i32 = &.{};
    sort(array);
    try expect(array.len == 0);
}

test "array with one element" {
    var array: [1]i32 = .{5};
    sort(&array);
    try expect(array.len == 1);
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
