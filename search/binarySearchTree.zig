const std = @import("std");
const expect = std.testing.expect;

fn Node(comptime T: type) type {
    return struct {
        value: T,
        parent: ?*Node(T) = null,
        left: ?*Node(T) = null,
        right: ?*Node(T) = null,
    };
}

fn Tree(comptime T: type) type {
    return struct {
        root: ?*Node(T) = null,

        pub fn search(node: ?*Node(T), value: T) ?*Node(T) {
            if (node == null or node.?.value == value) {
                return node;
            }
            if (value < node.?.value) {
                return search(node.?.left, value);
            } else {
                return search(node.?.right, value);
            }
        }

        pub fn insert(self: *Tree(T), z: *Node(T)) void {
            var y: ?*Node(T) = null;
            var x = self.root;
            while (x) |node| {
                y = node;
                if (z.value < node.value) {
                    x = node.left;
                } else {
                    x = node.right;
                }
            }
            z.parent = y;
            if (y == null) {
                self.root = z;
            } else if (z.value < y.?.value) {
                y.?.left = z;
            } else {
                y.?.right = z;
            }
        }
    };
}

test "search empty tree" {
    const tree = Tree(i32){};
    const result = Tree(i32).search(tree.root, 3);
    try expect(result == null);
}

test "search an existing element" {
    var tree = Tree(i32){};
    var node = Node(i32){ .value = 3 };
    tree.insert(&node);
    const result = Tree(i32).search(tree.root, 3);
    try expect(result.? == &node);
}

test "search non-existent element" {
    var tree = Tree(i32){};
    var node = Node(i32){ .value = 3 };
    tree.insert(&node);
    const result = Tree(i32).search(tree.root, 4);
    try expect(result == null);
}

test "search for an element with multiple nodes" {
    var tree = Tree(i32){};
    const values = [_]i32{ 15, 18, 17, 6, 7, 20, 3, 13, 2, 4, 9 };
    for (values) |v| {
        var node = Node(i32){ .value = v };
        tree.insert(&node);
    }
    const result = Tree(i32).search(tree.root, 9);
    try expect(result.?.value == 9);
}
