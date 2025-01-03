const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

const pairs = struct {
    cost: u32,
    capacity: u32,
};

// Function that solves the 0/1 knapsack problem
//  Arguments
//      arr: Array of pairs that holds the capacity and the cost of each element
//      capacity: The total capacity of your bag
// Determines which items to include in the collection so that the total weight is
// less than or equal to a given limit and the total value is as large as possible.
//
// Returns the collected value
pub fn knapsack(comptime arr: []const pairs, comptime capacity: u32) u32 {
    if (capacity == 0) {
        return 0;
    }

    const n: u32 = comptime arr.len;
    var dp: [n + 1][capacity + 1]u32 = undefined;
    for (0..(n + 1)) |i| {
        for (0..(capacity + 1)) |j| {
            dp[i][j] = 0;
        }
    }

    for (1..(n + 1)) |i| {
        for (0..(capacity + 1)) |j| {
            dp[i][j] = dp[i - 1][j];
            if (i == 0 or j == 0) {
                dp[i][j] = 0;
            } else if (arr[i - 1].capacity <= j) {
                dp[i][j] = @max(dp[i - 1][j], arr[i - 1].cost + dp[i - 1][j - arr[i - 1].capacity]);
            }
        }
    }

    return dp[n][capacity];
}

test "Testing knapsack function" {
    const arr = [_]pairs{ pairs{ .capacity = 10, .cost = 60 }, pairs{ .capacity = 20, .cost = 100 }, pairs{ .capacity = 30, .cost = 120 } };

    try testing.expect(knapsack(&arr, 50) == 220);

    const arr2 = [_]pairs{ pairs{ .capacity = 5, .cost = 40 }, pairs{ .capacity = 3, .cost = 20 }, pairs{ .capacity = 6, .cost = 10 }, pairs{ .capacity = 3, .cost = 30 } };
    try testing.expect(knapsack(&arr2, 10) == 70);

    const arr3 = [_]pairs{ pairs{ .capacity = 100, .cost = 100 }, pairs{ .capacity = 150, .cost = 150 } };
    try testing.expect(knapsack(&arr3, 20) == 0);
}
