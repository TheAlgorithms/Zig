const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

// Minimum cost function that solves the coin change problem(https://en.wikipedia.org/wiki/Change-making_problem)
// Arguments:
//      arr: the array that contains the coins
//      N: the total amount of money that you have
pub fn min_cost(arr: []const u32, comptime N: i32) i32 {
    const max_of: i32 = N + 1;

    var dp: [N + 1]i32 = undefined;
    for (&dp) |*x| {
        x.* = max_of;
    }

    dp[0] = 0;
    for (0..(N + 1)) |i| {
        for (arr[0..arr.len]) |x| {
            if (x <= i) {
                dp[i] = @min(dp[i], 1 + dp[i - x]);
            }
        }
    }

    return if(dp[N] > N) -1 else dp[N];
}

test "Testing min_cost algorithm" {
    const v = [3]u32{ 1, 2, 5 };
    try testing.expect(min_cost(&v, 11) == 3);

    const v2 = [1]u32{ 2 };
    try testing.expect(min_cost(&v2, 3) == -1);

    const v3 = [1]u32{ 1 };
    try testing.expect(min_cost(&v3, 0) == 0);
}
