const std = @import("std");
const expectEqual = std.testing.expectEqual;
const rng = std.rand.DefaultPrng;

fn swap(a: *i32, b: *i32) void {
    const tmp = a.*;
    a.* = b.*;
    b.* = tmp;
}

pub fn selection(arr: []i32) void {
    var step: u32 = 0;
    while (step < arr.len) : (step += 1) {
        var min_index = step;
        var i = step + 1;
        while (i < arr.len) : (i += 1) {
            if (arr[i] < arr[min_index]) {
                min_index = i;
            }
        }
        swap(&arr[min_index], &arr[step]);
    }
}

pub fn partition(arr: []i32, left: i32, right: i32, randomize: bool) i32 {
    var low = @intCast(u32, left);
    var high = @intCast(u32, right);

    var rnd = rng.init(0);
    var pivot = arr[if (randomize == true) rnd.random().intRangeAtMost(u32, low, high) else low];

    if (arr.len == 0) {
        return 0;
    }
    while (low < high) {
        while (arr[low] < pivot) {
            low += 1;
        }
        while (arr[high] > pivot) {
            high -= 1;
        }
        if (arr[low] == arr[high]) {
            return @intCast(i32, low);
        }
        if (low < high) {
            swap(&arr[low], &arr[high]);
        }
    }
    return @intCast(i32, low);
}

pub fn quicksort_recursive(arr: []i32, left: i32, right: i32, randomize: bool) void {
    if (left < right) {
        var pivot = partition(arr, left, right, randomize);
        quicksort_recursive(arr, left, pivot - 1, randomize);
        quicksort_recursive(arr, pivot + 1, right, randomize);
    }
}

pub fn quicksort(arr: []i32, random_piv: bool) void {
    if (arr.len < 1) {
        return;
    }
    quicksort_recursive(arr, 0, @intCast(i32, (arr.len - 1)), random_piv);
}

test "QuickSort - random" {
    var arr = [_]i32{ 32, 56, 78, 2, 67, 34, 7, 89, 34 };
    quicksort(&arr, true);
    try expectEqual(arr, [_]i32{ 2, 7, 34, 32, 34, 56, 67, 78, 89 });
}

test "QuickSort - no random" {
    var arr = [_]i32{ 32, 56, 78, 34, 2, 67, 7, 89 };
    quicksort(&arr, false);
    try expectEqual(arr, [_]i32{ 2, 7, 32, 34, 56, 67, 78, 89 });
}

test "Quicksort Recursive - random" {
    var arr = [_]i32{ 65, 87, 98, 9, 54, 34, 67, 879, 98 };
    quicksort_recursive(&arr, 0, @intCast(i32, (arr.len - 1)), true);
    try expectEqual(arr, [_]i32{ 65, 87, 98, 9, 34, 54, 67, 98, 879 });
}

test "Quicksort Recursive - no random" {
    var arr = [_]i32{ 65, 87, 98, 9, 54, 34, 67, 879, 98 };
    quicksort_recursive(&arr, 0, @intCast(i32, (arr.len - 1)), false);
    try expectEqual(arr, [_]i32{ 9, 34, 54, 65, 98, 67, 87, 98, 879 });
}
