const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;

const searchErrors = error{KeyNotFound};

// returns the index of the first occurrence of key
fn search(arr: []i32, key: i32) !usize {
    for (arr, 0..) |v, i| {
        if (v == key) {
            return i;
        }
    }
    return searchErrors.KeyNotFound;
}

test "empty array" {
    var A = [_]i32{};
    try expectError(searchErrors.KeyNotFound, search(A[0..], 5));
}

test "single element array, key not in array" {
    var A = [_]i32{2};
    try expectError(searchErrors.KeyNotFound, search(A[0..], 5));
}

// to test off-by-one errors
test "2 element array" {
    var A = [_]i32{ 2, 8 };
    try expect(try search(A[0..], 8) == 1);
}

test "key at last" {
    var A = [_]i32{ 2, 3, 6, 0, 1, 7, 8, 9 };
    try expect(try search(A[0..], 9) == 7);
}

test "key not in array" {
    var A = [_]i32{ 2, 3, 6, 0, 1, 7, 8, 9 };
    try expectError(searchErrors.KeyNotFound, search(A[0..], 5));
}

test "duplicate elements in array" {
    var A = [_]i32{ 2, 3, 6, 0, 1, 7, 8, 1, 9 };
    try expect(try search(A[0..], 1) == 4);
}

test "negative numbers" {
    var A = [_]i32{ 2, -3, 6, 0, 1, -7, 8, -1, 9 };
    try expect(try search(A[0..], -1) == 7);
}

test "identical elements" {
    var A = [_]i32{ 0, 0, 0, 0, 0, 0, 0, 0 };
    try expect(try search(A[0..], 0) == 0);
}
