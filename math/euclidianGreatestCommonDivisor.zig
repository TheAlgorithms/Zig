pub fn euclidianGreatestCommonDivisor(comptime T: type, a: T, b: T) T {
    return if (b == 0) a else euclidianGreatestCommonDivisor(T, b, @mod(a, b));
}

const expectEqual = @import("std").testing.expectEqual;

test "Euclidian Greatest Common Divisor - Integers" {
    try expectEqual(@as(u16, 2), euclidianGreatestCommonDivisor(u16, 34, 54));
    try expectEqual(@as(u32, 32), euclidianGreatestCommonDivisor(u32, 928, 160));
    try expectEqual(@as(u64, 1), euclidianGreatestCommonDivisor(u64, 428031, 25));
    try expectEqual(@as(u80, 1), euclidianGreatestCommonDivisor(u80, 5893436, 69));
}

test "Euclidian Greatest Common Divisor - Floats" {
    try expectEqual(@as(f32, 3.81469726e-06), euclidianGreatestCommonDivisor(f32, 45.34, 75.14));
    try expectEqual(@as(f64, 1.7053025658242404e-13), euclidianGreatestCommonDivisor(f64, 568.239, 475.814));
}
