//! Tiger Style Merge Sort - Zero Recursion Implementation
//!
//! Demonstrates Tiger Style principles:
//! - Iterative bottom-up merge sort (no recursion)
//! - Explicit u32 indices (never usize)
//! - Heavy assertions on all array accesses
//! - Bounded loops with provable upper bounds
//! - Fail-fast on invalid inputs
//! - Simple, explicit control flow

const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

/// Maximum array size we support (must be bounded)
pub const MAX_ARRAY_SIZE: u32 = 1_000_000;

/// Tiger Style merge sort - sorts array A using work buffer B
/// Both arrays must have identical length <= MAX_ARRAY_SIZE
/// Time: O(n log n), Space: O(n) for work buffer
pub fn sort(comptime T: type, A: []T, B: []T) void {
    // Preconditions - assert all inputs
    assert(A.len == B.len);
    assert(A.len <= MAX_ARRAY_SIZE);

    const n: u32 = @intCast(A.len);

    // Handle trivial cases
    if (n <= 1) {
        // Postcondition: trivial arrays are already sorted
        return;
    }

    // Copy A to B for initial pass
    copyArray(T, A, 0, n, B);

    // Bottom-up iterative merge sort
    // No recursion! Loop bound: log2(n) iterations
    var width: u32 = 1;
    var iteration: u32 = 0;
    const max_iterations: u32 = 32; // log2(MAX_ARRAY_SIZE) = ~20, use 32 for safety

    while (width < n) : (iteration += 1) {
        // Assert bounded loop
        assert(iteration < max_iterations);
        assert(width > 0);
        assert(width <= n);

        // Merge subarrays of size 'width'
        var i: u32 = 0;
        const merge_count_max = n / width + 1; // Upper bound on merges this iteration
        var merge_count: u32 = 0;

        while (i < n) : (merge_count += 1) {
            // Assert bounded inner loop
            assert(merge_count <= merge_count_max);
            assert(i < n);

            const left = i;
            const middle = @min(i + width, n);
            const right = @min(i + 2 * width, n);

            // Invariants
            assert(left < middle);
            assert(middle <= right);
            assert(right <= n);

            // Merge on alternating passes
            if (iteration % 2 == 0) {
                merge(T, B, left, middle, right, A);
            } else {
                merge(T, A, left, middle, right, B);
            }

            i = right;
        }

        width = width * 2;

        // Postcondition: width increased
        assert(width > 0); // Check for overflow
    }

    // If even number of iterations, result is in B, copy back to A
    if (iteration % 2 == 0) {
        copyArray(T, B, 0, n, A);
    }

    // Postcondition: array is sorted (verified in tests)
}

/// Merge two sorted subarrays from A into B
/// Merges A[begin..middle) with A[middle..end) into B[begin..end)
fn merge(
    comptime T: type,
    A: []const T,
    begin: u32,
    middle: u32,
    end: u32,
    B: []T,
) void {
    // Preconditions
    assert(begin <= middle);
    assert(middle <= end);
    assert(end <= A.len);
    assert(end <= B.len);
    assert(A.len <= MAX_ARRAY_SIZE);
    assert(B.len <= MAX_ARRAY_SIZE);

    var i: u32 = begin; // Index for left subarray
    var j: u32 = middle; // Index for right subarray
    var k: u32 = begin; // Index for output

    // Merge with explicit bounds
    const iterations_max = end - begin;
    var iterations: u32 = 0;

    while (k < end) : ({
        k += 1;
        iterations += 1;
    }) {
        // Assert bounded loop
        assert(iterations <= iterations_max);
        assert(k < end);
        assert(k < B.len);

        // Choose from left or right subarray
        if (i < middle and (j >= end or A[i] <= A[j])) {
            // Take from left
            assert(i < A.len);
            B[k] = A[i];
            i += 1;
        } else {
            // Take from right
            assert(j < A.len);
            assert(j < end);
            B[k] = A[j];
            j += 1;
        }

        // Invariants
        assert(i <= middle);
        assert(j <= end);
    }

    // Postconditions
    assert(k == end);
    assert(i == middle or j == end); // One subarray exhausted
}

/// Copy elements from A to B in range [begin, end)
fn copyArray(
    comptime T: type,
    A: []const T,
    begin: u32,
    end: u32,
    B: []T,
) void {
    // Preconditions
    assert(begin <= end);
    assert(end <= A.len);
    assert(end <= B.len);
    assert(A.len <= MAX_ARRAY_SIZE);
    assert(B.len <= MAX_ARRAY_SIZE);

    var k: u32 = begin;
    const iterations_max = end - begin;
    var iterations: u32 = 0;

    while (k < end) : ({
        k += 1;
        iterations += 1;
    }) {
        // Assert bounded loop
        assert(iterations <= iterations_max);
        assert(k < A.len);
        assert(k < B.len);

        B[k] = A[k];
    }

    // Postcondition
    assert(k == end);
}

/// Verify array is sorted in ascending order
fn isSorted(comptime T: type, array: []const T) bool {
    assert(array.len <= MAX_ARRAY_SIZE);

    if (array.len <= 1) return true;

    const n: u32 = @intCast(array.len);
    var i: u32 = 1;

    while (i < n) : (i += 1) {
        assert(i < array.len);
        if (array[i - 1] > array[i]) {
            return false;
        }
    }

    return true;
}

// ============================================================================
// Tests - Exhaustive edge case coverage
// ============================================================================

test "sort: empty array" {
    const array: []i32 = &.{};
    const work: []i32 = &.{};

    sort(i32, array, work);

    try testing.expect(isSorted(i32, array));
}

test "sort: single element" {
    var array: [1]i32 = .{42};
    var work: [1]i32 = .{0};

    sort(i32, &array, &work);

    try testing.expect(isSorted(i32, &array));
    try testing.expectEqual(@as(i32, 42), array[0]);
}

test "sort: two elements sorted" {
    var array: [2]i32 = .{ 1, 2 };
    var work: [2]i32 = .{0} ** 2;

    sort(i32, &array, &work);

    try testing.expect(isSorted(i32, &array));
    try testing.expectEqual(@as(i32, 1), array[0]);
    try testing.expectEqual(@as(i32, 2), array[1]);
}

test "sort: two elements reversed" {
    var array: [2]i32 = .{ 2, 1 };
    var work: [2]i32 = .{0} ** 2;

    sort(i32, &array, &work);

    try testing.expect(isSorted(i32, &array));
    try testing.expectEqual(@as(i32, 1), array[0]);
    try testing.expectEqual(@as(i32, 2), array[1]);
}

test "sort: already sorted" {
    var array: [10]i32 = .{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    var work: [10]i32 = .{0} ** 10;

    sort(i32, &array, &work);

    try testing.expect(isSorted(i32, &array));
    for (array, 0..) |value, i| {
        try testing.expectEqual(@as(i32, @intCast(i + 1)), value);
    }
}

test "sort: reverse order" {
    var array: [10]i32 = .{ 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 };
    var work: [10]i32 = .{0} ** 10;

    sort(i32, &array, &work);

    try testing.expect(isSorted(i32, &array));
    for (array, 0..) |value, i| {
        try testing.expectEqual(@as(i32, @intCast(i + 1)), value);
    }
}

test "sort: duplicates" {
    var array: [8]i32 = .{ 5, 2, 8, 2, 9, 1, 5, 5 };
    var work: [8]i32 = .{0} ** 8;

    sort(i32, &array, &work);

    try testing.expect(isSorted(i32, &array));
    // Verify specific values
    try testing.expectEqual(@as(i32, 1), array[0]);
    try testing.expectEqual(@as(i32, 2), array[1]);
    try testing.expectEqual(@as(i32, 2), array[2]);
}

test "sort: all same elements" {
    var array: [10]i32 = .{7} ** 10;
    var work: [10]i32 = .{0} ** 10;

    sort(i32, &array, &work);

    try testing.expect(isSorted(i32, &array));
    for (array) |value| {
        try testing.expectEqual(@as(i32, 7), value);
    }
}

test "sort: negative numbers" {
    var array: [6]i32 = .{ -5, -1, -10, 0, -3, -7 };
    var work: [6]i32 = .{0} ** 6;

    sort(i32, &array, &work);

    try testing.expect(isSorted(i32, &array));
    try testing.expectEqual(@as(i32, -10), array[0]);
    try testing.expectEqual(@as(i32, 0), array[5]);
}

test "sort: large array power of 2" {
    var array: [256]i32 = undefined;
    var work: [256]i32 = undefined;

    // Initialize with reverse order
    for (&array, 0..) |*elem, i| {
        elem.* = @intCast(255 - i);
    }

    sort(i32, &array, &work);

    try testing.expect(isSorted(i32, &array));
    for (array, 0..) |value, i| {
        try testing.expectEqual(@as(i32, @intCast(i)), value);
    }
}

test "sort: large array non-power of 2" {
    var array: [1000]i32 = undefined;
    var work: [1000]i32 = undefined;

    // Initialize with pseudorandom pattern
    for (&array, 0..) |*elem, i| {
        elem.* = @intCast((i * 7919) % 1000);
    }

    sort(i32, &array, &work);

    try testing.expect(isSorted(i32, &array));
}

test "sort: stress test - verify no recursion stack overflow" {
    // This would overflow stack with recursive implementation
    var array: [10000]i32 = undefined;
    var work: [10000]i32 = undefined;

    // Worst case: reverse sorted
    for (&array, 0..) |*elem, i| {
        elem.* = @intCast(9999 - i);
    }

    sort(i32, &array, &work);

    try testing.expect(isSorted(i32, &array));
}

test "sort: different types - u32" {
    var array: [5]u32 = .{ 5, 2, 8, 1, 9 };
    var work: [5]u32 = .{0} ** 5;

    sort(u32, &array, &work);

    try testing.expect(isSorted(u32, &array));
}

test "sort: different types - u64" {
    var array: [5]u64 = .{ 5, 2, 8, 1, 9 };
    var work: [5]u64 = .{0} ** 5;

    sort(u64, &array, &work);

    try testing.expect(isSorted(u64, &array));
}
