const std = @import("std");
const testing = std.testing;

// Function that computes the minimum distance(or operations) to make 2 strings equal
// Well known as the edit distance dp function.
// Arguments:
//      word1: The first passed string
//      word2: The second passed string
// Returns u32: The minimum operations to make the 2 strings equal
pub fn minDist(comptime word1: []const u8, comptime word2: []const u8) u32 {
    if (word1.len == 0 and word2.len == 0) { return 0; }
    if (word1.len == 0 and word2.len != 0) { return @as(u32, @intCast(word2.len)); }
    if (word1.len != 0 and word2.len == 0) { return @as(u32, @intCast(word1.len)); }

    const n: usize = word1.len;
    const w: usize = word2.len;

    var dp: [n + 1][w + 1]u32 = undefined;
    for (0..(n + 1)) |i| {
        dp[i][0] = @as(u32, @intCast(i));
    }

    for (0..(w + 1)) |i| {
        dp[0][i] = @as(u32, @intCast(i));
    }

    for (1..(n + 1)) |i| {
        for (1..(w + 1)) |j| {
            if (word1[i - 1] == word2[j - 1]) {
                dp[i][j] = dp[i - 1][j - 1];
            }
            else {
                dp[i][j] = @min(dp[i - 1][j - 1], @min(dp[i - 1][j], dp[i][j - 1])) + 1;
            }
        }
    }

    return dp[n][w];
}

test "Testing edit distance function" {
    const word1 = "hello";
    const word2 = "world";

    try testing.expect(minDist(word1, word2) == 4);

    const word3 = "Hell0There";
    const word4 = "hellothere";

    try testing.expect(minDist(word3, word4) == 3);

    const word5 = "abcdefg";
    const word6 = "abcdefg";

    try testing.expect(minDist(word5, word6) == 0);

    const word7 = "";
    const word8 = "abasda";

    try testing.expect(minDist(word7, word8) == 6);

    const word9 = "abcsa";
    const word10 = "";

    try testing.expect(minDist(word9, word10) == 5);

    const word11 = "sdasdafda";
    const word12 = "sdasdbbba";

    try testing.expect(minDist(word11, word12) == 3);
}
