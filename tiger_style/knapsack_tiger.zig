//! Tiger Style 0/1 Knapsack - Militant Assertion Discipline
//!
//! Demonstrates Tiger Style dynamic programming:
//! - Every array access validated with assertions
//! - Explicit u32 capacity bounds (never usize)
//! - DP table invariants checked at every step
//! - Overflow protection on all arithmetic
//! - Bounded loops with provable upper bounds
//! - Simple, explicit control flow

const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

/// Maximum number of items (must be bounded)
pub const MAX_ITEMS: u32 = 10000;

/// Maximum knapsack capacity (must be bounded)
pub const MAX_CAPACITY: u32 = 100000;

/// Item with weight and value
pub const Item = struct {
    weight: u32,
    value: u32,

    /// Validate item invariants
    pub fn validate(self: Item) void {
        // Items must have positive weight (zero weight items are degenerate)
        assert(self.weight > 0);
        assert(self.weight <= MAX_CAPACITY);
        // Value can be zero but should fit in u32
        assert(self.value <= std.math.maxInt(u32));
    }
};

/// Solve 0/1 knapsack problem using dynamic programming
/// Returns maximum value achievable within capacity
///
/// Time: O(n * capacity)
/// Space: O(n * capacity) for DP table
pub fn knapsack(items: []const Item, capacity: u32, allocator: std.mem.Allocator) !u32 {
    // Preconditions - validate all inputs
    assert(items.len <= MAX_ITEMS);
    assert(capacity <= MAX_CAPACITY);

    const n: u32 = @intCast(items.len);

    // Validate all items
    for (items) |item| {
        item.validate();
    }

    // Handle trivial cases
    if (n == 0 or capacity == 0) {
        return 0;
    }

    // Allocate DP table: dp[i][w] = max value with first i items and capacity w
    // Using explicit u32 dimensions
    const rows = n + 1;
    const cols = capacity + 1;

    // Bounds check before allocation
    assert(rows <= MAX_ITEMS + 1);
    assert(cols <= MAX_CAPACITY + 1);

    // Allocate as flat array to avoid double pointer indirection
    const table_size: usize = @as(usize, rows) * @as(usize, cols);
    const dp = try allocator.alloc(u32, table_size);
    defer allocator.free(dp);

    // Helper to access dp[i][w]
    const getDP = struct {
        fn get(table: []u32, row: u32, col: u32, num_cols: u32, num_rows: u32) u32 {
            assert(row < num_rows);
            assert(col < num_cols);
            const index: usize = @as(usize, row) * @as(usize, num_cols) + @as(usize, col);
            assert(index < table.len);
            return table[index];
        }

        fn set(table: []u32, row: u32, col: u32, num_cols: u32, num_rows: u32, value: u32) void {
            assert(row < num_rows);
            assert(col < num_cols);
            const index: usize = @as(usize, row) * @as(usize, num_cols) + @as(usize, col);
            assert(index < table.len);
            table[index] = value;
        }
    };

    // Initialize base case: dp[0][w] = 0 for all w
    // (zero items = zero value)
    var w: u32 = 0;
    while (w <= capacity) : (w += 1) {
        assert(w < cols);
        getDP.set(dp, 0, w, cols, rows, 0);

        // Invariant: base case initialized
        assert(getDP.get(dp, 0, w, cols, rows) == 0);
    }

    // Fill DP table
    var i: u32 = 1;
    while (i <= n) : (i += 1) {
        assert(i > 0);
        assert(i <= n);
        assert(i < rows);

        const item_index = i - 1;
        assert(item_index < items.len);

        const item = items[item_index];
        item.validate(); // Revalidate during computation

        w = 0;
        while (w <= capacity) : (w += 1) {
            assert(w < cols);

            // Get value without including current item
            const without_item = getDP.get(dp, i - 1, w, cols, rows);

            // Can we include this item?
            if (w >= item.weight) {
                // Yes - check if including it is better
                assert(w >= item.weight);
                const remaining_capacity = w - item.weight;
                assert(remaining_capacity <= w);

                const with_item_prev = getDP.get(dp, i - 1, remaining_capacity, cols, rows);

                // Check for overflow before adding
                const max_value = std.math.maxInt(u32);
                if (with_item_prev <= max_value - item.value) {
                    const with_item = with_item_prev + item.value;
                    const best = @max(without_item, with_item);

                    getDP.set(dp, i, w, cols, rows, best);

                    // Invariant: DP value is non-decreasing with capacity
                    if (w > 0) {
                        const prev_w_value = getDP.get(dp, i, w - 1, cols, rows);
                        assert(getDP.get(dp, i, w, cols, rows) >= prev_w_value);
                    }

                    // Invariant: DP value never decreases with more items
                    assert(getDP.get(dp, i, w, cols, rows) >= getDP.get(dp, i - 1, w, cols, rows));
                } else {
                    // Overflow would occur, use without_item
                    getDP.set(dp, i, w, cols, rows, without_item);
                }
            } else {
                // Cannot include item (too heavy)
                assert(w < item.weight);
                getDP.set(dp, i, w, cols, rows, without_item);

                // Invariant: same as without item
                assert(getDP.get(dp, i, w, cols, rows) == getDP.get(dp, i - 1, w, cols, rows));
            }
        }
    }

    // Get final answer
    const result = getDP.get(dp, n, capacity, cols, rows);

    // Postconditions
    assert(result <= std.math.maxInt(u32));
    // Result should not exceed sum of all values (sanity check)
    var total_value: u64 = 0;
    for (items) |item| {
        total_value += item.value;
    }
    assert(result <= total_value);

    return result;
}

/// Solve knapsack and also return which items to include
/// Returns tuple of (max_value, selected_items)
pub fn knapsackWithItems(
    items: []const Item,
    capacity: u32,
    allocator: std.mem.Allocator,
) !struct { value: u32, selected: []bool } {
    // Preconditions
    assert(items.len <= MAX_ITEMS);
    assert(capacity <= MAX_CAPACITY);

    const n: u32 = @intCast(items.len);

    if (n == 0 or capacity == 0) {
        const selected = try allocator.alloc(bool, items.len);
        @memset(selected, false);
        return .{ .value = 0, .selected = selected };
    }

    // Allocate DP table
    const rows = n + 1;
    const cols = capacity + 1;
    const table_size: usize = @as(usize, rows) * @as(usize, cols);
    const dp = try allocator.alloc(u32, table_size);
    defer allocator.free(dp);

    // Helper functions
    const getDP = struct {
        fn get(table: []u32, row: u32, col: u32, num_cols: u32, num_rows: u32) u32 {
            assert(row < num_rows);
            assert(col < num_cols);
            const index: usize = @as(usize, row) * @as(usize, num_cols) + @as(usize, col);
            assert(index < table.len);
            return table[index];
        }

        fn set(table: []u32, row: u32, col: u32, num_cols: u32, num_rows: u32, value: u32) void {
            assert(row < num_rows);
            assert(col < num_cols);
            const index: usize = @as(usize, row) * @as(usize, num_cols) + @as(usize, col);
            assert(index < table.len);
            table[index] = value;
        }
    };

    // Fill DP table (same as knapsack function)
    var w: u32 = 0;
    while (w <= capacity) : (w += 1) {
        getDP.set(dp, 0, w, cols, rows, 0);
    }

    var i: u32 = 1;
    while (i <= n) : (i += 1) {
        const item = items[i - 1];
        item.validate();

        w = 0;
        while (w <= capacity) : (w += 1) {
            const without = getDP.get(dp, i - 1, w, cols, rows);

            if (w >= item.weight) {
                const with_prev = getDP.get(dp, i - 1, w - item.weight, cols, rows);
                const max_value = std.math.maxInt(u32);

                if (with_prev <= max_value - item.value) {
                    const with = with_prev + item.value;
                    getDP.set(dp, i, w, cols, rows, @max(without, with));
                } else {
                    getDP.set(dp, i, w, cols, rows, without);
                }
            } else {
                getDP.set(dp, i, w, cols, rows, without);
            }
        }
    }

    // Backtrack to find selected items
    const selected = try allocator.alloc(bool, items.len);
    @memset(selected, false);

    var current_capacity = capacity;
    var current_item: u32 = n;

    // Bounded backtracking loop
    while (current_item > 0) {
        assert(current_item <= n);
        assert(current_capacity <= capacity);

        const item_index = current_item - 1;
        assert(item_index < items.len);

        const item = items[item_index];
        const current_value = getDP.get(dp, current_item, current_capacity, cols, rows);
        const prev_value = getDP.get(dp, current_item - 1, current_capacity, cols, rows);

        // Was this item included?
        if (current_value != prev_value) {
            // Yes, item was included
            assert(current_capacity >= item.weight);
            selected[item_index] = true;
            current_capacity -= item.weight;
        }

        current_item -= 1;
    }

    const result_value = getDP.get(dp, n, capacity, cols, rows);

    return .{ .value = result_value, .selected = selected };
}

// ============================================================================
// Tests - Exhaustive edge case coverage
// ============================================================================

test "knapsack: empty items" {
    const items: []const Item = &.{};
    const result = try knapsack(items, 100, testing.allocator);
    try testing.expectEqual(@as(u32, 0), result);
}

test "knapsack: zero capacity" {
    const items = [_]Item{
        .{ .weight = 10, .value = 60 },
        .{ .weight = 20, .value = 100 },
    };

    const result = try knapsack(&items, 0, testing.allocator);
    try testing.expectEqual(@as(u32, 0), result);
}

test "knapsack: single item fits" {
    const items = [_]Item{
        .{ .weight = 10, .value = 60 },
    };

    const result = try knapsack(&items, 50, testing.allocator);
    try testing.expectEqual(@as(u32, 60), result);
}

test "knapsack: single item doesn't fit" {
    const items = [_]Item{
        .{ .weight = 100, .value = 500 },
    };

    const result = try knapsack(&items, 50, testing.allocator);
    try testing.expectEqual(@as(u32, 0), result);
}

test "knapsack: classic example" {
    const items = [_]Item{
        .{ .weight = 10, .value = 60 },
        .{ .weight = 20, .value = 100 },
        .{ .weight = 30, .value = 120 },
    };

    const result = try knapsack(&items, 50, testing.allocator);
    try testing.expectEqual(@as(u32, 220), result);
}

test "knapsack: all items fit exactly" {
    const items = [_]Item{
        .{ .weight = 10, .value = 10 },
        .{ .weight = 20, .value = 20 },
        .{ .weight = 30, .value = 30 },
    };

    const result = try knapsack(&items, 60, testing.allocator);
    try testing.expectEqual(@as(u32, 60), result);
}

test "knapsack: fractional knapsack would be better" {
    // Tests that we get 0/1 solution, not fractional
    const items = [_]Item{
        .{ .weight = 10, .value = 20 }, // ratio: 2.0
        .{ .weight = 15, .value = 25 }, // ratio: 1.67
    };

    // Fractional would take all of first + 5 units of second = 20 + 8.33 = 28.33
    // 0/1 takes the second item (best value that fits)
    const result = try knapsack(&items, 15, testing.allocator);
    try testing.expectEqual(@as(u32, 25), result);
}

test "knapsack: with item selection" {
    const items = [_]Item{
        .{ .weight = 5, .value = 40 },
        .{ .weight = 3, .value = 20 },
        .{ .weight = 6, .value = 10 },
        .{ .weight = 3, .value = 30 },
    };

    const result = try knapsackWithItems(&items, 10, testing.allocator);
    defer testing.allocator.free(result.selected);

    try testing.expectEqual(@as(u32, 70), result.value);

    // Should select items 0, 1, 3 (weights: 5+3+3=11... wait that's > 10)
    // Actually should select items 0 and 3 (weights: 5+3=8, values: 40+30=70)
    // Or items 0, 1 (weights: 5+3=8, values: 40+20=60) - no
    // Let's verify the selection is optimal
    var selected_weight: u32 = 0;
    var selected_value: u32 = 0;

    for (items, result.selected) |item, selected| {
        if (selected) {
            selected_weight += item.weight;
            selected_value += item.value;
        }
    }

    try testing.expect(selected_weight <= 10);
    try testing.expectEqual(result.value, selected_value);
}

test "knapsack: large capacity" {
    const items = [_]Item{
        .{ .weight = 1000, .value = 5000 },
        .{ .weight = 2000, .value = 8000 },
        .{ .weight = 1500, .value = 6000 },
    };

    const result = try knapsack(&items, 5000, testing.allocator);
    try testing.expectEqual(@as(u32, 19000), result);
}

test "knapsack: many small items" {
    var items: [100]Item = undefined;
    for (&items, 0..) |*item, i| {
        item.* = Item{
            .weight = @intCast(i + 1),
            .value = @intCast((i + 1) * 10),
        };
    }

    const result = try knapsack(&items, 500, testing.allocator);

    // Result should be positive and bounded
    try testing.expect(result > 0);
    try testing.expect(result <= 50500); // Sum of all values
}

test "knapsack: duplicate weights different values" {
    const items = [_]Item{
        .{ .weight = 10, .value = 100 },
        .{ .weight = 10, .value = 50 },
        .{ .weight = 10, .value = 150 },
    };

    const result = try knapsack(&items, 20, testing.allocator);
    try testing.expectEqual(@as(u32, 250), result); // Best two
}

test "knapsack: stress test - no stack overflow" {
    var items: [1000]Item = undefined;
    for (&items, 0..) |*item, i| {
        item.* = Item{
            .weight = @intCast((i % 100) + 1),
            .value = @intCast((i % 100) * 10),
        };
    }

    const result = try knapsack(&items, 5000, testing.allocator);

    // Just verify it completes without overflow
    try testing.expect(result >= 0);
}
