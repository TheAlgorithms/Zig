const std = @import("std");
const testing = std.testing;

/// Returns a Heap type.
/// Arguments:
///     T: the type of the elements
///     compare: function that returns true if a should be higher in the heap than b (e.g. for MinHeap, a < b)
pub fn Heap(comptime T: type, comptime compare: fn (a: T, b: T) bool) type {
    return struct {
        const Self = @This();

        items: std.ArrayList(T),
        allocator: std.mem.Allocator,

        /// Initialize the heap with an allocator
        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .items = .empty,
                .allocator = allocator,
            };
        }

        /// Free the memory used by the heap
        pub fn deinit(self: *Self) void {
            self.items.deinit(self.allocator);
        }

        /// Insert an element into the heap
        /// Runs in O(log n)
        pub fn insert(self: *Self, item: T) !void {
            try self.items.append(self.allocator, item);
            self.siftUp(self.items.items.len - 1);
        }

        /// Peek at the top element of the heap (min/max depending on compare)
        /// Runs in O(1)
        pub fn peek(self: Self) ?T {
            if (self.items.items.len == 0) return null;
            return self.items.items[0];
        }

        /// Extract the top element from the heap
        /// Runs in O(log n)
        pub fn extract(self: *Self) ?T {
            if (self.items.items.len == 0) return null;

            const root = self.items.items[0];
            const last = self.items.pop().?;

            if (self.items.items.len > 0) {
                self.items.items[0] = last;
                self.siftDown(0);
            }

            return root;
        }

        /// Get the current number of elements
        pub fn size(self: Self) usize {
            return self.items.items.len;
        }

        fn siftUp(self: *Self, start_index: usize) void {
            var index = start_index;
            const items = self.items.items;

            while (index > 0) {
                const parent_idx = (index - 1) / 2;
                if (!compare(items[index], items[parent_idx])) break;

                std.mem.swap(T, &items[index], &items[parent_idx]);
                index = parent_idx;
            }
        }

        fn siftDown(self: *Self, start_index: usize) void {
            var index = start_index;
            const items = self.items.items;
            const len = items.len;

            while (true) {
                const left_child = 2 * index + 1;
                const right_child = 2 * index + 2;
                var swap_idx = index;

                if (left_child < len and compare(items[left_child], items[swap_idx])) {
                    swap_idx = left_child;
                }

                if (right_child < len and compare(items[right_child], items[swap_idx])) {
                    swap_idx = right_child;
                }

                if (swap_idx == index) break;

                std.mem.swap(T, &items[index], &items[swap_idx]);
                index = swap_idx;
            }
        }
    };
}

fn lessThan(a: i32, b: i32) bool {
    return a < b;
}

fn greaterThan(a: i32, b: i32) bool {
    return a > b;
}

test "MinHeap operations" {
    const MinHeap = Heap(i32, lessThan);
    var heap = MinHeap.init(testing.allocator);
    defer heap.deinit();

    try heap.insert(5);
    try heap.insert(3);
    try heap.insert(10);
    try heap.insert(1);

    try testing.expect(4 == heap.size());

    try testing.expectEqual(@as(?i32, 1), heap.peek());
    try testing.expectEqual(@as(?i32, 1), heap.extract());
    try testing.expectEqual(@as(?i32, 3), heap.extract());
    try testing.expectEqual(@as(?i32, 5), heap.extract());
    try testing.expectEqual(@as(?i32, 10), heap.extract());
    try testing.expectEqual(@as(?i32, null), heap.extract());
}

test "MaxHeap operations" {
    const MaxHeap = Heap(i32, greaterThan);
    var heap = MaxHeap.init(testing.allocator);
    defer heap.deinit();

    try heap.insert(5);
    try heap.insert(3);

    try testing.expect(2 == heap.size());

    try heap.insert(10);
    try heap.insert(1);

    try testing.expect(4 == heap.size());

    try testing.expectEqual(@as(?i32, 10), heap.peek());
    try testing.expectEqual(@as(?i32, 10), heap.extract());
    try testing.expectEqual(@as(?i32, 5), heap.extract());
    try testing.expectEqual(@as(?i32, 3), heap.extract());
    try testing.expectEqual(@as(?i32, 1), heap.extract());
    try testing.expectEqual(@as(?i32, null), heap.extract());
}
