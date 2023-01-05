const expect = @import("std").testing.expect;

fn fibonacci(comptime T: type, index: T) T {
    if (index < 2) return index;
    return fibonacci(T, index - 1) + fibonacci(T, index - 2);
}

test "fibonacci" {
    // test fibonacci at run-time
    try expect(fibonacci(u10, 7) == 13);

    // test fibonacci at compile-time
    comptime {
        try expect(fibonacci(u10, 7) == 13);
    }
}
