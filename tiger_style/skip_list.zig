//! Tiger Style Skip List
//!
//! Probabilistic data structure for ordered sets/maps.
//! Foundation for LSM trees and databases.
//! Follows Tiger Style with:
//! - Bounded maximum level
//! - Deterministic randomness for testing
//! - No recursion (iterative traversal)
//! - Heavy assertions on all operations
//! - Explicit memory management

const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

/// Maximum level in skip list (must be bounded)
pub const MAX_LEVEL: u32 = 16;

/// Probability for level promotion (1/4 for good balance)
const PROMOTION_PROBABILITY: u32 = 4;

/// Skip List Node
fn SkipListNode(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();

        key: K,
        value: V,
        level: u32,
        forward: [MAX_LEVEL]?*Self,

        fn init(key: K, value: V, level: u32, allocator: std.mem.Allocator) !*Self {
            assert(level > 0);
            assert(level <= MAX_LEVEL);

            const node = try allocator.create(Self);
            node.* = Self{
                .key = key,
                .value = value,
                .level = level,
                .forward = undefined,
            };

            // Initialize forward pointers
            var i: u32 = 0;
            while (i < MAX_LEVEL) : (i += 1) {
                node.forward[i] = null;
            }

            return node;
        }

        fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            allocator.destroy(self);
        }
    };
}

/// Skip List - ordered map
pub fn SkipList(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();
        const Node = SkipListNode(K, V);

        /// Sentinel head node
        head: *Node,

        /// Current maximum level
        max_level: u32,

        /// Number of elements
        count: u32,

        /// RNG for level generation (deterministic seed for testing)
        rng: std.Random.DefaultPrng,

        /// Allocator
        allocator: std.mem.Allocator,

        /// Initialize skip list
        pub fn init(allocator: std.mem.Allocator, seed: u64) !Self {
            // Create sentinel head with maximum level
            const head = try Node.init(undefined, undefined, MAX_LEVEL, allocator);

            var list = Self{
                .head = head,
                .max_level = 1,
                .count = 0,
                .rng = std.Random.DefaultPrng.init(seed),
                .allocator = allocator,
            };

            // Postconditions
            assert(list.count == 0);
            assert(list.max_level > 0);
            assert(list.max_level <= MAX_LEVEL);
            list.validate();

            return list;
        }

        /// Deinitialize skip list
        pub fn deinit(self: *Self) void {
            self.validate();

            // Free all nodes iteratively (no recursion!)
            var current = self.head.forward[0];
            var iterations: u32 = 0;
            const max_iterations = self.count + 1;

            while (current) |node| : (iterations += 1) {
                assert(iterations <= max_iterations);
                const next = node.forward[0];
                node.deinit(self.allocator);
                current = next;
            }

            // Free head
            self.head.deinit(self.allocator);
        }

        /// Validate skip list invariants
        fn validate(self: *const Self) void {
            assert(self.max_level > 0);
            assert(self.max_level <= MAX_LEVEL);

            if (std.debug.runtime_safety) {
                // Verify count matches actual nodes
                var current = self.head.forward[0];
                var actual_count: u32 = 0;
                var prev_key: ?K = null;

                while (current) |node| : (actual_count += 1) {
                    assert(actual_count <= self.count); // Prevent infinite loop
                    assert(node.level > 0);
                    assert(node.level <= MAX_LEVEL);

                    // Verify ordering
                    if (prev_key) |pk| {
                        assert(pk < node.key);
                    }
                    prev_key = node.key;

                    current = node.forward[0];
                }

                assert(actual_count == self.count);
            }
        }

        /// Generate random level for new node (deterministic with seed)
        fn randomLevel(self: *Self) u32 {
            var level: u32 = 1;

            // Bounded loop for level generation
            while (level < MAX_LEVEL) : (level += 1) {
                const r = self.rng.random().int(u32);
                if (r % PROMOTION_PROBABILITY != 0) {
                    break;
                }
            }

            assert(level > 0);
            assert(level <= MAX_LEVEL);
            return level;
        }

        /// Insert key-value pair
        pub fn insert(self: *Self, key: K, value: V) !void {
            // Preconditions
            self.validate();

            // Track path for insertion
            var update: [MAX_LEVEL]?*Node = undefined;
            var i: u32 = 0;
            while (i < MAX_LEVEL) : (i += 1) {
                update[i] = null;
            }

            // Find insertion point (iterative, no recursion!)
            var current = self.head;
            var level = self.max_level;

            while (level > 0) {
                level -= 1;

                var iterations: u32 = 0;
                while (current.forward[level]) |next| : (iterations += 1) {
                    assert(iterations <= self.count + 1); // Bounded search

                    if (next.key >= key) break;
                    current = next;
                }

                update[level] = current;
            }

            // Check if key already exists
            if (current.forward[0]) |existing| {
                if (existing.key == key) {
                    // Update existing value
                    existing.value = value;
                    self.validate();
                    return;
                }
            }

            // Generate level for new node
            const new_level = self.randomLevel();

            // Update max_level if needed
            if (new_level > self.max_level) {
                var l = self.max_level;
                while (l < new_level) : (l += 1) {
                    update[l] = self.head;
                }
                self.max_level = new_level;
            }

            // Create new node
            const new_node = try Node.init(key, value, new_level, self.allocator);

            // Insert node at all levels
            var insert_level: u32 = 0;
            while (insert_level < new_level) : (insert_level += 1) {
                if (update[insert_level]) |prev| {
                    new_node.forward[insert_level] = prev.forward[insert_level];
                    prev.forward[insert_level] = new_node;
                }
            }

            self.count += 1;

            // Postconditions
            assert(self.count > 0);
            self.validate();
        }

        /// Search for key
        pub fn get(self: *const Self, key: K) ?V {
            self.validate();

            var current: ?*Node = self.head;
            var level = self.max_level;

            while (level > 0 and current != null) {
                level -= 1;

                var iterations: u32 = 0;
                while (current.?.forward[level]) |next| : (iterations += 1) {
                    assert(iterations <= self.count + 1); // Bounded search

                    if (next.key == key) {
                        return next.value;
                    }
                    if (next.key > key) break;

                    current = next;
                }
            }

            return null;
        }

        /// Remove key from skip list
        pub fn remove(self: *Self, key: K) bool {
            self.validate();

            // Track nodes to update
            var update: [MAX_LEVEL]?*Node = undefined;
            var i: u32 = 0;
            while (i < MAX_LEVEL) : (i += 1) {
                update[i] = null;
            }

            // Find node to remove
            var current = self.head;
            var level = self.max_level;

            while (level > 0) {
                level -= 1;

                var iterations: u32 = 0;
                while (current.forward[level]) |next| : (iterations += 1) {
                    assert(iterations <= self.count + 1);

                    if (next.key >= key) break;
                    current = next;
                }

                update[level] = current;
            }

            // Check if key exists
            const target = if (current.forward[0]) |n|
                if (n.key == key) n else null
            else
                null;

            if (target == null) return false;

            // Remove node from all levels
            var remove_level: u32 = 0;
            while (remove_level < target.?.level) : (remove_level += 1) {
                if (update[remove_level]) |prev| {
                    prev.forward[remove_level] = target.?.forward[remove_level];
                }
            }

            // Free node
            target.?.deinit(self.allocator);
            self.count -= 1;

            // Update max_level if needed
            while (self.max_level > 1 and self.head.forward[self.max_level - 1] == null) {
                self.max_level -= 1;
            }

            // Postconditions
            self.validate();
            return true;
        }

        /// Check if skip list is empty
        pub fn isEmpty(self: *const Self) bool {
            assert(self.count <= std.math.maxInt(u32));
            return self.count == 0;
        }

        /// Get number of elements
        pub fn len(self: *const Self) u32 {
            assert(self.count <= std.math.maxInt(u32));
            return self.count;
        }
    };
}

// ============================================================================
// Tests
// ============================================================================

test "SkipList: initialization" {
    const List = SkipList(u32, u32);
    var list = try List.init(testing.allocator, 42);
    defer list.deinit();

    try testing.expect(list.isEmpty());
    try testing.expectEqual(@as(u32, 0), list.len());
}

test "SkipList: insert and get" {
    const List = SkipList(u32, u32);
    var list = try List.init(testing.allocator, 42);
    defer list.deinit();

    try list.insert(10, 100);
    try list.insert(20, 200);
    try list.insert(30, 300);

    try testing.expectEqual(@as(u32, 3), list.len());
    try testing.expectEqual(@as(u32, 100), list.get(10).?);
    try testing.expectEqual(@as(u32, 200), list.get(20).?);
    try testing.expectEqual(@as(u32, 300), list.get(30).?);
}

test "SkipList: ordered insertion" {
    const List = SkipList(u32, u32);
    var list = try List.init(testing.allocator, 42);
    defer list.deinit();

    // Insert out of order
    try list.insert(30, 300);
    try list.insert(10, 100);
    try list.insert(20, 200);

    // Should still be accessible
    try testing.expectEqual(@as(u32, 100), list.get(10).?);
    try testing.expectEqual(@as(u32, 200), list.get(20).?);
    try testing.expectEqual(@as(u32, 300), list.get(30).?);
}

test "SkipList: update existing key" {
    const List = SkipList(u32, u32);
    var list = try List.init(testing.allocator, 42);
    defer list.deinit();

    try list.insert(10, 100);
    try testing.expectEqual(@as(u32, 100), list.get(10).?);

    try list.insert(10, 999);
    try testing.expectEqual(@as(u32, 999), list.get(10).?);
    try testing.expectEqual(@as(u32, 1), list.len());
}

test "SkipList: get non-existent key" {
    const List = SkipList(u32, u32);
    var list = try List.init(testing.allocator, 42);
    defer list.deinit();

    try list.insert(10, 100);

    try testing.expectEqual(@as(?u32, null), list.get(999));
}

test "SkipList: remove" {
    const List = SkipList(u32, u32);
    var list = try List.init(testing.allocator, 42);
    defer list.deinit();

    try list.insert(10, 100);
    try list.insert(20, 200);
    try list.insert(30, 300);

    try testing.expect(list.remove(20));
    try testing.expectEqual(@as(u32, 2), list.len());
    try testing.expectEqual(@as(?u32, null), list.get(20));
    try testing.expectEqual(@as(u32, 100), list.get(10).?);
    try testing.expectEqual(@as(u32, 300), list.get(30).?);
}

test "SkipList: remove non-existent" {
    const List = SkipList(u32, u32);
    var list = try List.init(testing.allocator, 42);
    defer list.deinit();

    try list.insert(10, 100);

    try testing.expect(!list.remove(999));
    try testing.expectEqual(@as(u32, 1), list.len());
}

test "SkipList: deterministic with same seed" {
    const List = SkipList(u32, u32);

    // First list with seed 42
    var list1 = try List.init(testing.allocator, 42);
    defer list1.deinit();

    try list1.insert(10, 100);
    try list1.insert(20, 200);
    try list1.insert(30, 300);

    const max_level1 = list1.max_level;

    // Second list with same seed
    var list2 = try List.init(testing.allocator, 42);
    defer list2.deinit();

    try list2.insert(10, 100);
    try list2.insert(20, 200);
    try list2.insert(30, 300);

    const max_level2 = list2.max_level;

    // Should have same structure
    try testing.expectEqual(max_level1, max_level2);
}

test "SkipList: stress test" {
    const List = SkipList(u32, u32);
    var list = try List.init(testing.allocator, 42);
    defer list.deinit();

    // Insert many elements
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        try list.insert(i, i * 10);
    }

    try testing.expectEqual(@as(u32, 100), list.len());

    // Verify all present
    i = 0;
    while (i < 100) : (i += 1) {
        try testing.expectEqual(i * 10, list.get(i).?);
    }

    // Remove every other element
    i = 0;
    while (i < 100) : (i += 2) {
        try testing.expect(list.remove(i));
    }

    try testing.expectEqual(@as(u32, 50), list.len());

    // Verify correct elements remain
    i = 0;
    while (i < 100) : (i += 1) {
        if (i % 2 == 0) {
            try testing.expectEqual(@as(?u32, null), list.get(i));
        } else {
            try testing.expectEqual(i * 10, list.get(i).?);
        }
    }
}

test "SkipList: bounded levels" {
    const List = SkipList(u32, u32);
    var list = try List.init(testing.allocator, 42);
    defer list.deinit();

    // Insert many elements
    var i: u32 = 0;
    while (i < 1000) : (i += 1) {
        try list.insert(i, i);
    }

    // Max level should be bounded
    try testing.expect(list.max_level <= MAX_LEVEL);
}
