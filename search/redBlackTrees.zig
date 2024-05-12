const std = @import("std");
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;
const Error = Allocator.Error;

const RED: bool = true;
const BLACK: bool = false;

fn Node(comptime T: type) type {
    return struct {
        value: T,
        parent: ?*Node(T) = null,
        left: ?*Node(T) = null,
        right: ?*Node(T) = null,
        color: bool,
    };
}

fn Tree(comptime T: type) type {
    return struct {
        root: ?*Node(T) = null,

        pub fn search(self: *Tree(T), value: T) ?*Node(T) {
            var node = self.root;
            while (node) |x| {
                if (value < x.value) {
                    node = x.left;
                } else if (value > x.value) {
                    node = x.right;
                } else {
                    return x;
                }
            }
            return null;
        }

        pub fn insert(self: *Tree(T), value: T, allocator: Allocator) !void {
            self.root = try insertNode(self.root, value, allocator);
            self.root.?.color = BLACK;
        }

        fn isRed(h: ?*Node(T)) bool {
            if (h) |v| {
                return v.color == RED;
            }
            return false;
        }

        fn flipColors(h: *Node(T)) void {
            h.color = !h.color;
            h.left.?.color = !h.left.?.color;
            h.right.?.color = !h.right.?.color;
        }

        fn rotateLeft(h: *Node(T)) *Node(T) {
            var x = h.right;
            h.right = x.?.left;
            x.?.left = h;
            x.?.color = h.color;
            h.color = RED;
            return x.?;
        }

        fn rotateRight(h: *Node(T)) *Node(T) {
            var x = h.left;
            h.left = x.?.right;
            x.?.right = h;
            x.?.color = h.color;
            h.color = RED;
            return x.?;
        }

        fn insertNode(node: ?*Node(T), value: T, allocator: Allocator) Error!*Node(T) {
            if (node != null) {
                var h = node.?;
                if (isRed(h.left) and isRed(h.right)) {
                    flipColors(h);
                }
                if (value == h.value) {
                    h.value = value;
                } else if (value < h.value) {
                    h.left = try insertNode(h.left, value, allocator);
                } else {
                    h.right = try insertNode(h.right, value, allocator);
                }

                if (isRed(h.right) and !isRed(h.left)) {
                    h = rotateLeft(h);
                }
                if (isRed(h.left) and isRed(h.left.?.left)) {
                    h = rotateRight(h);
                }
                return h;
            } else {
                var new_node = try allocator.create(Node(T));
                new_node.value = value;
                new_node.parent = null;
                new_node.left = null;
                new_node.right = null;
                new_node.color = RED;
                return new_node;
            }
        }
    };
}

test "search empty tree" {
    var tree = Tree(i32){};
    const result = tree.search(3);
    try expect(result == null);
}

test "search an existing element" {
    var tree = Tree(i32){};
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const allocator = arena_allocator.allocator();
    try tree.insert(3, allocator);
    const result = tree.search(3);
    try expect(result.?.value == 3);
    try expect(result.?.color == BLACK);
}

test "search non-existent element" {
    var tree = Tree(i32){};
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const allocator = arena_allocator.allocator();
    try tree.insert(3, allocator);
    const result = tree.search(4);
    try expect(result == null);
}

test "search for an element with multiple nodes" {
    var tree = Tree(i32){};
    const values = [_]i32{ 15, 18, 17, 6, 7, 20, 3, 13, 2, 4, 9 };
    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_allocator.deinit();
    const allocator = arena_allocator.allocator();
    for (values) |v| {
        try tree.insert(v, allocator);
    }
    const result = tree.search(4);
    try expect(result.?.value == 4);
}
