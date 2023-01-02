const expectEqual = @import("std").testing.expectEqual;

fn factorial(comptime T: type, n: T) T {
    var res: T = @as(T, 1);
    var i: T = @as(T, 2);
    while (i <= n) : (i += 1) res *= i;
    return res;
}

fn factorialRecursive(comptime T: type, n: T) T {
    if (n < 2 and n > 0) return 1 else return n * factorial(T, n - 1);
}

pub fn factorialComptime(comptime T: type, n: T) T {
    comptime var i = @as(T, 0);
    inline while (i < 12) : (i += 1) if (i == n) return comptime factorial(T, i);
    return 1;
}

test "Factorial Comptime" {
    try expectEqual(@as(u32, 120), factorialComptime(u32, 5));
    try expectEqual(@as(u64, 5040), factorialComptime(u64, 7));
    try expectEqual(@as(c_int, 720), factorialComptime(c_int, 6));
    try expectEqual(@as(usize, 362880), factorialComptime(usize, 9));
}

test "Factorial Recursive" {
    try expectEqual(@as(u32, 120), factorialRecursive(u32, 5));
    try expectEqual(@as(u64, 5040), factorialRecursive(u64, 7));
    try expectEqual(@as(c_int, 720), factorialRecursive(c_int, 6));
    try expectEqual(@as(usize, 362880), factorialRecursive(usize, 9));
}
