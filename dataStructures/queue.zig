const std = @import("std");
const testing = std.testing;

const errors = error{EmptyList};

// Returns a queue instance.
// Arguments:
//      T: the type of the info(i.e. i32, i16, u8, etc...)
//      Allocator: This is needed for the struct instance. In most cases,
//                 feel free to use std.heap.GeneralPurposeAllocator
pub fn queue(comptime T: type) type {
    return struct {
        const Self = @This();

        // This is the node struct. It holds:
        // info: T
        // next: A pointer to the next element
        // prev: A pointer to the previous element
        pub const node = struct {
            info: T,
            next: ?*node = null,
            prev: ?*node = null,
        };

        allocator: std.mem.Allocator,
        head: ?*node = null,
        tail: ?*node = null,
        size: usize = 0,

        // Function that inserts elements to the queue (enqueue)
        // Runs in O(1)
        // Arguments:
        //      key: T - the key to be inserted to the queue
        pub fn push(self: *Self, key: T) !void {
            const nn = try self.allocator.create(node);
            nn.* = node{ .info = key };

            if (self.tail == null) {
                self.head = nn;
                self.tail = nn;
            } else {
                self.tail.?.next = nn;
                nn.prev = self.tail;
                self.tail = nn;
            }
            self.size += 1;
        }

        // Function that returns the front of the queue
        // Runs in O(1)
        // Returns an EmptyList error if the list is empty
        pub fn front(self: *Self) errors!T {
            return if (self.head != null) self.head.?.info else errors.EmptyList;
        }

        // Function that removes the front of the queue (dequeue)
        // Runs in O(1)
        // Returns an EmptyList error if the list is empty
        pub fn pop(self: *Self) errors!void {
            if (self.head == null) {
                return errors.EmptyList;
            }

            const curr: *node = self.head.?;
            defer self.allocator.destroy(curr);

            self.head = self.head.?.next;
            if (self.head == null) {
                self.tail = null;
            } else {
                self.head.?.prev = null;
            }
            self.size -= 1;
        }

        // Function that destroys the allocated memory of the whole queue
        pub fn destroy(self: *Self) !void {
            while (self.size != 0) : (try self.pop()) {}
        }
    };
}

test "Testing insertion/popping in queue" {
    const allocator = std.testing.allocator;

    var q = queue(i32){ .allocator = allocator };

    try q.push(10);
    try q.push(20);
    try q.push(30);
    try testing.expect(try q.front() == 10);
    try testing.expect(q.size == 3);
    try q.pop();
    try testing.expect(try q.front() == 20);
    try testing.expect(q.size == 2);
    try q.pop();
    try testing.expect(try q.front() == 30);
    try testing.expect(q.size == 1);
    try q.pop();
    q.pop() catch |err| {
        try testing.expect(err == errors.EmptyList);
        return;
    };
    try testing.expect(q.size == 0);
    try q.destroy();
}

test "Testing other formats" {
    const allocator = std.testing.allocator;

    var q = queue(u8){ .allocator = allocator };

    try q.push('a');
    try q.push('b');
    try q.push('c');

    try testing.expect(try q.front() == 'a');
    try q.pop();
    try testing.expect(try q.front() == 'b');
    try q.push('w');
    try testing.expect(try q.front() == 'b');

    try q.destroy();
}
