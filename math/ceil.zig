const std = @import("std");
const testing = std.testing;

pub fn ceil(comptime T: type, x: T) T {
    const x_rounded_towards_zero = x;
    if (x < 0 or x_rounded_towards_zero == x) {
        return x_rounded_towards_zero;
    } else {
        return x_rounded_towards_zero + @as(T, 1);
    }
}

test "Test Ceil" {
    try testing.expectEqual(@as(u32, 1), ceil(u32, 1));
    try testing.expectEqual(@as(f32, 2.3), ceil(f32, 2.3));
    try testing.expectEqual(@as(f80, 3263.56), ceil(f80, 3263.56));
    try testing.expectEqual(@as(f64, 643.87), ceil(f64, 643.87));
    try testing.expectEqual(@as(u32, 128), ceil(u32, 128));
    try testing.expectEqual(@as(u5, 7), ceil(u5, 7));
    try testing.expectEqual(@as(u5, 8), ceil(u5, 8));
    try testing.expectEqual(@as(u5, 16), ceil(u5, 16));
    try testing.expectEqual(@as(u4, 9), ceil(u4, 9));
}
