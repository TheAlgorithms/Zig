const std = @import("std");
const testing = std.testing;

const errors = error{EmptyList};

// Returns a stack instance.
// Arguments:
//      T: the type of the info(i.e. i32, i16, u8, etc...)
//      Allocator: This is needed for the struct instance. In most cases,
//                 feel free to use std.heap.GeneralPurposeAllocator
pub fn stack(comptime T: type) type {
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

        allocator: *std.mem.Allocator,
        root: ?*node = null,
        size: usize = 0,

        // Function that inserts elements to the stack
        // Runs in O(1)
        // Arguments:
        //      key: T - the key to be inserted to the stack
        pub fn push(self: *Self, key: T) !void {
            const nn = try self.allocator.create(node);
            nn.* = node{ .info = key };

            if (self.root == null) {
                self.root = nn;
                self.size += 1;
                return;
            } else {
                self.root.?.next = nn;
                nn.prev = self.root;
                self.root = nn;
                self.size += 1;
            }
        }

        // Function that returns the top of the stack
        // Runs in O(1)
        // Returns an EmptyList error if the list is empty
        pub fn top(self: *Self) errors!T {
            return if (self.root != null) self.root.?.info else errors.EmptyList;
        }

        // Function that removes the top of the stack
        // Runs in O(1)
        // Returns an EmptyList error if the list is empty
        pub fn pop(self: *Self) errors!void {
            if (self.root == null) {
                return errors.EmptyList;
            }

            const curr: *node = self.root.?;
            defer self.allocator.destroy(curr);

            self.root = self.root.?.prev;
            self.size -= 1;
        }

        // Function that destroys the allocated memory of the whole stack
        pub fn destroy(self: *Self) !void {
            while (self.size != 0) : (try self.pop()) {}
            self.size = 0;
        }
    };
}

test "Testing insertion/popping in stack" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    var s = stack(i32){ .allocator = &allocator };

    try s.push(10);
    try s.push(20);
    try s.push(30);
    try testing.expect(try s.top() == 30);
    try s.pop();
    try testing.expect(try s.top() == 20);
    try s.pop();
    try testing.expect(try s.top() == 10);
    try s.pop();
    s.pop() catch |err| {
        try testing.expect(err == error.EmptyList);
        return;
    };

    try s.destroy();
}

test "Testing other formats" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    var s = stack(u8){ .allocator = &allocator };

    try s.push('a');
    try s.push('b');
    try s.push('c');

    try testing.expect(try s.top() == 'c');
    try s.pop();
    try testing.expect(try s.top() == 'b');
    try s.push('w');
    try testing.expect(try s.top() == 'w');

    try s.destroy();
}
