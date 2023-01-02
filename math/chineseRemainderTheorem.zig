const std = @import("std");
const math = std.math;
const testing = std.testing;

fn inverse(comptime T: type, number1: T, number2: T) T {
    // mutable vars
    var x: T = number1;
    var y: T = number2;
    var u: T = 1;
    var v: T = 0;
    var m: T = 0;
    var n: T = 0;
    var q: T = 0;
    var r: T = 0;

    while (y != 0) {
        q = @divTrunc(x, y);
        r = @rem(x, y);
        m = u - (q * v);
        n = v;
        x = y;
        y = r;
        u = v;
        v = m;
    }
    return @mod(u, number2);
}

fn mul(comptime T: type, arg_a: T, arg_b: T, arg_p: T) T {

    // mutable vars
    var a = arg_a;
    var b = arg_b;
    var p = arg_p;
    var res: T = 0;

    if (a < @as(T, 0)) {
        a += p;
    }
    if (b < @as(T, 0)) {
        b += p;
    }
    while (b != 0) {
        if ((b & @as(T, 1)) != 0) {
            res = @rem((res + a), p);
        }
        a = @rem((2 * a), p);
        b >>= @intCast(math.Log2Int(T), @as(T, 1));
    }
    return res;
}

pub fn chineseRemainder(comptime T: type, a: []T, m: []T) T {
    var n = a.len;
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
            var Mi = @divTrunc(M, m[i]);
            x += mul(T, a[i] * Mi, inverse(T, Mi, m[i]), M);
            x = @mod(x, M);
        }
    }

    return x;
}

test "Chinese Remainder Theorem" {
    var a = [_]i32{ 3, 5, 7 };
    var m = [_]i32{ 2, 3, 1 };
    try testing.expectEqual(@as(i32, 5), chineseRemainder(i32, &a, &m));

    a = [_]i32{ 1, 4, 6 };
    m = [_]i32{ 3, 5, 7 };
    try testing.expectEqual(@as(i32, 34), chineseRemainder(i32, &a, &m));

    a = [_]i32{ 5, 6, 7 };
    m = [_]i32{ 2, 7, 9 };
    try testing.expectEqual(@as(i32, 97), chineseRemainder(i32, &a, &m));

    a = [_]c_int{ 5, 1, 4 };
    m = [_]c_int{ 9, 2, 6 };
    try testing.expectEqual(@as(c_int, 60), chineseRemainder(c_int, &a, &m));
}
