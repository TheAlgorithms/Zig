const std = @import("std");
const print = std.debug.print;
const testing = std.testing;

// Returns a doubly linked list instance.
// Arguments:
//      T: the type of the info(i.e. i32, i16, u32, etc...)
//      Allocator: This is needed for the struct instance. In most cases, feel free
//                 to use std.heap.GeneralPurposeAllocator
pub fn DoublyLinkedList(comptime T: type) type {
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
        tail: ?*node = null,
        size: usize = 0,

        // Function that inserts elements to the tail of the list
        // Runs in O(1)
        // Arguments:
        //      key: T - the key to be inserted to the list
        pub fn push_back(self: *Self, key: T) !void {
            const nn = try self.allocator.create(node);
            nn.* = node{ .info = key, .next = null, .prev = self.tail };

            if (self.tail != null) {
                self.tail.?.next = nn;
            }
            if (self.root == null) {
                self.root = nn;
            }

            self.tail = nn;
            self.size += 1;
        }

        // Function that inserts elements to the front of the list
        // Runs in O(1)
        // Arguments:
        //      key: T - the key to be inserted to the list
        pub fn push_front(self: *Self, key: T) !void {
            const nn = try self.allocator.create(node);
            nn.* = node{ .info = key, .next = self.root, .prev = null };

            if (self.root != null) {
                self.root.?.prev = nn;
            }
            if (self.tail == null) {
                self.tail = nn;
            }

            self.root = nn;
            self.size += 1;
        }

        // Function that removes the front of the list
        // Runs in O(1)
        pub fn pop_front(self: *Self) void {
            if (self.root == null) {
                return;
            }

            const temp: *node = self.root.?;
            defer self.allocator.destroy(temp);

            self.root = self.root.?.next;
            self.size -= 1;
        }

        // Function that removes the back of the list
        // Runs in O(1)
        pub fn pop_back(self: *Self) void {
            if (self.root == null) {
                return;
            }

            const temp: *node = self.tail.?;
            defer self.allocator.destroy(temp);

            self.tail = self.tail.?.prev;

            if (self.tail != null) {
                self.tail.?.next = null;
            } else {
                self.root = null;
            }

            self.size -= 1;
        }

        // Function that returns true if the list is empty
        pub fn empty(self: *Self) bool {
            return (self.size == 0);
        }

        // Function to search if a key exists in the list
        // Runs in O(n)
        // Arguments:
        //      key: T - the key that will be searched
        pub fn search(self: *Self, key: T) bool {
            if (self.root == null) {
                return false;
            }

            var head: ?*node = self.root;
            while (head) |curr| {
                if (curr.info == key) {
                    return true;
                }

                head = curr.next;
            }

            return false;
        }

        // Function that removes elements from the list
        // Runs in O(n)
        // Arguments:
        //      key: T - the key to be removed from the list(if it exists)
        pub fn remove(self: *Self, key: T) void {
            if (self.root == null) {
                return;
            }

            var head: ?*node = self.root;
            var prev: ?*node = null;
            while (head) |curr| {
                if (curr.info == key) {
                    const temp: *node = curr;
                    if (prev == null) {
                        self.root = self.root.?.next;
                    } else {
                        prev.?.next = curr.next;
                    }

                    self.allocator.destroy(temp);
                    self.size -= 1;
                    return;
                }
                prev = curr;
                head = curr.next.?;
            }
        }

        // Function that prints the list
        pub fn printList(self: *Self) void {
            if (self.root == null) {
                return;
            }

            var head: ?*node = self.root;
            while (head) |curr| {
                print("{} -> ", .{curr.info});
                head = curr.next;
            }
            print("\n", .{});
        }

        // Function that destroys the allocated memory of the whole list
        pub fn destroy(self: *Self) void {
            var head: ?*node = self.root;

            while (head) |curr| {
                const next = curr.next;
                self.allocator.destroy(curr);
                head = next;
            }

            self.root = null;
            self.tail = null;
            self.size = 0;
        }
    };
}

test "Testing Doubly Linked List" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    var list = DoublyLinkedList(i32){ .allocator = &allocator };
    defer list.destroy();

    try list.push_front(10);
    try list.push_front(20);
    try list.push_front(30);

    try testing.expect(list.search(10) == true);
    try testing.expect(list.search(30) == true);

    list.remove(20);
    try testing.expect(list.search(20) == false);

    var list2 = DoublyLinkedList(i32){ .allocator = &allocator };
    defer list2.destroy();

    inline for (0..4) |el| {
        try list2.push_back(el);
    }

    inline for (0..4) |el| {
        try testing.expect(list2.search(el) == true);
    }

    try testing.expect(list2.size == 4);

    list2.pop_front();
    try testing.expect(list2.search(0) == false);

    list2.pop_back();

    try testing.expect(list2.size == 2);
    try testing.expect(list2.search(3) == false);
}
