const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const testing = std.testing;

// Returns a binary search tree instance.
// Arguments:
//      T: the type of the info(i.e. i32, i16, u32, etc...)
//      Allocator: This is needed for the struct instance. In most cases, feel free
//                 to use std.heap.GeneralPurposeAllocator.
pub fn BinarySearchTree(comptime T: type) type {
    return struct {
        const Self = @This();

        // This is the node struct. It holds:
        // info: T
        // right: A pointer to the right child
        // left: A pointer to the left child
        pub const node = struct {
            info: T,
            right: ?*node = null,
            left: ?*node = null,
        };

        allocator: *std.mem.Allocator,
        root: ?*node = null,
        size: usize = 0,

        // Function to insert elements into the tree
        // Runs in θ(logn)/O(n), uses the helper _insert private function
        // Arguments:
        //      key: T - the key to be inserted into the tree
        pub fn insert(self: *Self, key: T) !void {
            self.root = try self._insert(self.root, key);
            self.size += 1;
        }

        // Function to remove elements from the tree
        // Runs in θ(logn)/O(n), uses the helper _remove private function
        // Arguments:
        //      key: T - the key to be removed from the tree
        pub fn remove(self: *Self, key: T) !void {
            if (self.root == null) {
                return;
            }
            self.root = try self._remove(self.root, key);
            self.size -= 1;
        }

        // Function to search if a key exists in the tree
        // Runs in θ(logn)/O(n), uses the helper _search private function
        // Arguments:
        //      key: T - the key that will be searched
        pub fn search(self: *Self, key: T) bool {
            return _search(self.root, key);
        }

        // Function that performs inorder traversal of the tree
        pub fn inorder(self: *Self, path: *ArrayList(T)) !void {
            if (self.root == null) {
                return;
            }
            try self._inorder(self.root, path);
        }

        // Function that performs preorder traversal of the tree
        pub fn preorder(self: *Self, path: *ArrayList(T)) !void {
            if (self.root == null) {
                return;
            }
            try self._preorder(self.root, path);
        }

        // Function that performs postorder traversal of the tree
        pub fn postorder(self: *Self, path: *ArrayList(T)) !void {
            if (self.root == null) {
                return;
            }
            try self._postorder(self.root, path);
        }

        // Function that destroys the allocated memory of the whole tree
        // Uses the _destroy helper private function
        pub fn destroy(self: *Self) void {
            if (self.root == null) {
                return;
            }
            self._destroy(self.root);
            self.size = 0;
        }

        // Function that generates a new node
        // Arguments:
        //      key: T - The info of the node
        fn new_node(self: *Self, key: T) !?*node {
            const nn = try self.allocator.create(node);
            nn.* = node{ .info = key, .right = null, .left = null };
            return nn;
        }

        fn _insert(self: *Self, root: ?*node, key: T) !?*node {
            if (root == null) {
                return try self.new_node(key);
            } else {
                if (root.?.info < key) {
                    root.?.right = try self._insert(root.?.right, key);
                } else {
                    root.?.left = try self._insert(root.?.left, key);
                }
            }

            return root;
        }

        fn _remove(self: *Self, root: ?*node, key: T) !?*node {
            if (root == null) {
                return root;
            }

            if (root.?.info < key) {
                root.?.right = try self._remove(root.?.right, key);
            } else if (root.?.info > key) {
                root.?.left = try self._remove(root.?.left, key);
            } else {
                if (root.?.left == null and root.?.right == null) {
                    self.allocator.destroy(root.?);
                    return null;
                } else if (root.?.left == null) {
                    const temp = root.?.right;
                    self.allocator.destroy(root.?);
                    return temp;
                } else if (root.?.right == null) {
                    const temp = root.?.left;
                    self.allocator.destroy(root.?);
                    return temp;
                } else {
                    var curr: ?*node = root.?.right;
                    while (curr.?.left != null) : (curr = curr.?.left) {}
                    root.?.info = curr.?.info;
                    root.?.right = try self._remove(root.?.right, curr.?.info);
                }
            }

            return root;
        }

        fn _search(root: ?*node, key: T) bool {
            var head: ?*node = root;
            while (head) |curr| {
                if (curr.info < key) {
                    head = curr.right;
                } else if (curr.info > key) {
                    head = curr.left;
                } else {
                    return true;
                }
            }

            return false;
        }

        fn _inorder(self: *Self, root: ?*node, path: *ArrayList(T)) !void {
            if (root != null) {
                try self._inorder(root.?.left, path);
                try path.append(root.?.info);
                try self._inorder(root.?.right, path);
            }
        }

        fn _preorder(self: *Self, root: ?*node, path: *ArrayList(T)) !void {
            if (root != null) {
                try path.append(root.?.info);
                try self._preorder(root.?.left, path);
                try self._preorder(root.?.right, path);
            }
        }

        fn _postorder(self: *Self, root: ?*node, path: *ArrayList(T)) !void {
            if (root != null) {
                try self._postorder(root.?.left, path);
                try self._postorder(root.?.right, path);
                try path.append(root.?.info);
            }
        }

        fn _destroy(self: *Self, root: ?*node) void {
            if (root != null) {
                self._destroy(root.?.left);
                self._destroy(root.?.right);
                self.allocator.destroy(root.?);
            }
        }
    };
}

test "Testing insertion" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    var t = BinarySearchTree(i32){ .allocator = &allocator };
    defer t.destroy();

    try t.insert(10);
    try t.insert(5);
    try t.insert(25);
    try t.insert(3);
    try t.insert(12);
    try testing.expect(t.size == 5);
    try testing.expect(t.search(10) == true);
    try testing.expect(t.search(15) == false);
}

test "Testing bst removal" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    var t = BinarySearchTree(i32){ .allocator = &allocator };
    defer t.destroy();

    try t.insert(10);
    try t.insert(5);
    try t.insert(3);
    try t.insert(15);
    try testing.expect(t.size == 4);
    try testing.expect(t.search(15) == true);
    try t.remove(10);
    try testing.expect(t.size == 3);
    try testing.expect(t.search(10) == false);
}

test "Testing traversal methods" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    var t = BinarySearchTree(i32){ .allocator = &allocator };
    defer t.destroy();

    try t.insert(5);
    try t.insert(25);
    try t.insert(3);
    try t.insert(12);
    try t.insert(15);

    var ino = ArrayList(i32).init(allocator);
    defer ino.deinit();

    const check_ino = [_]i32{ 3, 5, 12, 15, 25 };
    try t.inorder(&ino);
    try testing.expect(std.mem.eql(i32, ino.items, &check_ino));

    var pre = ArrayList(i32).init(allocator);
    defer pre.deinit();

    const check_pre = [_]i32{ 5, 3, 25, 12, 15 };
    try t.preorder(&pre);

    try testing.expect(std.mem.eql(i32, pre.items, &check_pre));

    var post = ArrayList(i32).init(allocator);
    defer post.deinit();

    const check_post = [_]i32{ 3, 15, 12, 25, 5 };
    try t.postorder(&post);

    try testing.expect(std.mem.eql(i32, post.items, &check_post));
}


test "Testing operations on empty trees" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    var t = BinarySearchTree(i32){ .allocator = &allocator };
    defer t.destroy();

    try testing.expect(t.size == 0);
    try testing.expect(t.search(10) == false);
    try t.remove(10);
    try testing.expect(t.search(10) == false);
}
