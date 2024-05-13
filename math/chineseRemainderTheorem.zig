const std = @import("std");
const testing = std.testing;

// Computes the inverse of a mod m.
pub fn InverseMod(comptime T: type, a: T, m: T) T {
    const y: T = @mod(a, m);
    var x: T = @as(T, 1);

    while (x < m) {
        defer x += 1;
        if (@rem((y * x), m) == 1)
            return x;
    }
    return 0;
}

pub fn chineseRemainder(comptime T: type, a: []T, m: []T) T {
    const n = a.len;
    var M: T = 1;
    var x: T = 0;
    var i: usize = undefined;
    {
        i = 0;
        while (i < n) : (i += 1) {
            M *= m[i];
        }
    }
    {
        i = 0;
        while (i < n) : (i += 1) {
            const Mi = @divTrunc(M, m[i]);
            const z = InverseMod(T, Mi, m[i]);
            x = @mod((x + a[i] * Mi * z), M);
        }
    }

    return x;
}

test "Chinese Remainder Theorem" {
    {
        var a = [_]u32{ 3, 5, 7 };
        var m = [_]u32{ 2, 3, 1 };
        try testing.expectEqual(@as(u32, 5), chineseRemainder(u32, &a, &m));
    }

    var a = [_]i32{ 1, 4, 6 };
    var m = [_]i32{ 3, 5, 7 };
    try testing.expectEqual(@as(i32, 34), chineseRemainder(i32, &a, &m));

    a = [_]c_int{ 5, 6, 7 };
    m = [_]c_int{ 2, 7, 9 };
    try testing.expectEqual(@as(c_int, 97), chineseRemainder(c_int, &a, &m));
}
