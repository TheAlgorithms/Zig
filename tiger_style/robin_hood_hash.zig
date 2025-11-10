//! Tiger Style Robin Hood Hash Table
//!
//! Cache-efficient hash table with Robin Hood hashing for fairness.
//! Follows TigerBeetle's data structure principles:
//! - Fixed capacity (no dynamic resizing)
//! - Explicit load factor bounds
//! - Linear probing with Robin Hood swapping
//! - Heavy assertions on all invariants
//! - Bounded probe distances
//! - Cache-friendly memory layout

const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

/// Maximum load factor before rejecting inserts (bounded)
pub const MAX_LOAD_FACTOR_PERCENT: u32 = 90;

/// Maximum probe distance (bounded search)
pub const MAX_PROBE_DISTANCE: u32 = 64;

/// Robin Hood Hash Table
pub fn RobinHoodHashMap(comptime K: type, comptime V: type, comptime capacity: u32) type {
    // Preconditions
    comptime {
        assert(capacity > 0);
        assert(capacity <= 1_000_000); // Sanity limit
        // Capacity should be power of 2 for fast modulo
        assert(capacity & (capacity - 1) == 0);
    }
    
    return struct {
        const Self = @This();
        
        /// Entry in hash table
        const Entry = struct {
            key: K,
            value: V,
            occupied: bool,
            psl: u32, // Probe sequence length
            
            fn init() Entry {
                return Entry{
                    .key = undefined,
                    .value = undefined,
                    .occupied = false,
                    .psl = 0,
                };
            }
        };
        
        /// Fixed-size storage
        entries: [capacity]Entry,
        
        /// Number of occupied entries
        count: u32,
        
        /// Initialize empty hash map
        pub fn init() Self {
            var map = Self{
                .entries = undefined,
                .count = 0,
            };
            
            // Initialize all entries
            var i: u32 = 0;
            while (i < capacity) : (i += 1) {
                map.entries[i] = Entry.init();
            }
            
            // Postconditions
            assert(map.count == 0);
            assert(map.isEmpty());
            map.validate();
            
            return map;
        }
        
        /// Validate hash map invariants
        fn validate(self: *const Self) void {
            assert(self.count <= capacity);
            
            // Verify PSL invariants (in debug builds)
            if (std.debug.runtime_safety) {
                var i: u32 = 0;
                var occupied: u32 = 0;
                while (i < capacity) : (i += 1) {
                    if (self.entries[i].occupied) {
                        occupied += 1;
                        // PSL bounded
                        assert(self.entries[i].psl < MAX_PROBE_DISTANCE);
                        // PSL matches actual distance
                        const hash_index = self.hashKey(self.entries[i].key);
                        const actual_psl = self.distance(hash_index, i);
                        assert(self.entries[i].psl == actual_psl);
                    }
                }
                assert(occupied == self.count);
            }
        }
        
        /// Hash function
        fn hashKey(self: *const Self, key: K) u32 {
            _ = self;
            // Simple hash for integers - use proper hash for complex types
            comptime {
                assert(@sizeOf(K) <= 8); // Support up to 64-bit keys
            }
            const h = switch (@sizeOf(K)) {
                1 => @as(u64, @as(u8, @bitCast(key))),
                2 => @as(u64, @as(u16, @bitCast(key))),
                4 => @as(u64, @as(u32, @bitCast(key))),
                8 => @as(u64, @bitCast(key)),
                else => @compileError("Unsupported key size"),
            };
            // Multiply by golden ratio and take upper bits
            const golden = 0x9e3779b97f4a7c15;
            const hash = (h *% golden) >> 32;
            return @intCast(hash & (capacity - 1));
        }
        
        /// Calculate distance between indices (with wraparound)
        fn distance(self: *const Self, from: u32, to: u32) u32 {
            _ = self;
            assert(from < capacity);
            assert(to < capacity);
            
            if (to >= from) {
                return to - from;
            } else {
                return (capacity - from) + to;
            }
        }
        
        /// Insert key-value pair
        pub fn put(self: *Self, key: K, value: V) !void {
            // Preconditions
            self.validate();
            
            // Fail-fast: check load factor
            const load_percent = (self.count * 100) / capacity;
            if (load_percent >= MAX_LOAD_FACTOR_PERCENT) {
                return error.HashMapFull;
            }
            
            var entry = Entry{
                .key = key,
                .value = value,
                .occupied = true,
                .psl = 0,
            };
            
            var index = self.hashKey(key);
            var probes: u32 = 0;
            
            while (probes < MAX_PROBE_DISTANCE) : (probes += 1) {
                assert(index < capacity);
                
                // Empty slot - insert here
                if (!self.entries[index].occupied) {
                    self.entries[index] = entry;
                    self.count += 1;
                    
                    // Postconditions
                    assert(self.count <= capacity);
                    self.validate();
                    return;
                }
                
                // Key already exists - update value
                if (self.entries[index].key == key) {
                    self.entries[index].value = value;
                    self.validate();
                    return;
                }
                
                // Robin Hood: swap if current entry is richer (lower PSL)
                if (entry.psl > self.entries[index].psl) {
                    // Swap entries
                    const temp = self.entries[index];
                    self.entries[index] = entry;
                    entry = temp;
                }
                
                // Move to next slot
                entry.psl += 1;
                index = (index + 1) & (capacity - 1);
            }
            
            // Fail-fast: probe distance exceeded
            return error.ProbeDistanceExceeded;
        }
        
        /// Get value for key
        pub fn get(self: *const Self, key: K) ?V {
            self.validate();
            
            var index = self.hashKey(key);
            var psl: u32 = 0;
            
            while (psl < MAX_PROBE_DISTANCE) : (psl += 1) {
                assert(index < capacity);
                
                // Empty slot - key not found
                if (!self.entries[index].occupied) {
                    return null;
                }
                
                // Found key
                if (self.entries[index].key == key) {
                    return self.entries[index].value;
                }
                
                // Robin Hood: if we've probed farther than entry's PSL, key doesn't exist
                if (psl > self.entries[index].psl) {
                    return null;
                }
                
                index = (index + 1) & (capacity - 1);
            }
            
            return null;
        }
        
        /// Remove key from map
        pub fn remove(self: *Self, key: K) bool {
            self.validate();
            
            var index = self.hashKey(key);
            var psl: u32 = 0;
            
            while (psl < MAX_PROBE_DISTANCE) : (psl += 1) {
                assert(index < capacity);
                
                if (!self.entries[index].occupied) {
                    return false;
                }
                
                if (self.entries[index].key == key) {
                    // Found - now backshift to maintain Robin Hood invariant
                    self.backshift(index);
                    self.count -= 1;
                    self.validate();
                    return true;
                }
                
                if (psl > self.entries[index].psl) {
                    return false;
                }
                
                index = (index + 1) & (capacity - 1);
            }
            
            return false;
        }
        
        /// Backshift entries after removal
        fn backshift(self: *Self, start: u32) void {
            var index = start;
            var iterations: u32 = 0;
            
            while (iterations < capacity) : (iterations += 1) {
                const next_index = (index + 1) & (capacity - 1);
                
                // Stop if next is empty or has PSL of 0
                if (!self.entries[next_index].occupied or self.entries[next_index].psl == 0) {
                    self.entries[index].occupied = false;
                    self.entries[index].psl = 0;
                    return;
                }
                
                // Shift entry back and decrease PSL
                self.entries[index] = self.entries[next_index];
                self.entries[index].psl -= 1;
                
                index = next_index;
            }
            
            // Should never reach here
            unreachable;
        }
        
        /// Check if map is empty
        pub fn isEmpty(self: *const Self) bool {
            assert(self.count <= capacity);
            return self.count == 0;
        }
        
        /// Get number of entries
        pub fn len(self: *const Self) u32 {
            assert(self.count <= capacity);
            return self.count;
        }
        
        /// Clear all entries
        pub fn clear(self: *Self) void {
            self.validate();
            
            var i: u32 = 0;
            while (i < capacity) : (i += 1) {
                self.entries[i] = Entry.init();
            }
            
            self.count = 0;
            
            // Postconditions
            assert(self.isEmpty());
            self.validate();
        }
        
        /// Calculate current load factor percentage
        pub fn loadFactor(self: *const Self) u32 {
            assert(self.count <= capacity);
            return (self.count * 100) / capacity;
        }
        
        /// Get maximum PSL in table (for statistics)
        pub fn maxPSL(self: *const Self) u32 {
            var max: u32 = 0;
            var i: u32 = 0;
            while (i < capacity) : (i += 1) {
                if (self.entries[i].occupied and self.entries[i].psl > max) {
                    max = self.entries[i].psl;
                }
            }
            return max;
        }
    };
}

// ============================================================================
// Tests - Hash table verification
// ============================================================================

test "RobinHoodHashMap: initialization" {
    const Map = RobinHoodHashMap(u32, u32, 16);
    const map = Map.init();
    
    try testing.expect(map.isEmpty());
    try testing.expectEqual(@as(u32, 0), map.len());
}

test "RobinHoodHashMap: insert and get" {
    const Map = RobinHoodHashMap(u32, u32, 16);
    var map = Map.init();
    
    try map.put(1, 100);
    try map.put(2, 200);
    try map.put(3, 300);
    
    try testing.expectEqual(@as(u32, 3), map.len());
    try testing.expectEqual(@as(u32, 100), map.get(1).?);
    try testing.expectEqual(@as(u32, 200), map.get(2).?);
    try testing.expectEqual(@as(u32, 300), map.get(3).?);
}

test "RobinHoodHashMap: update existing key" {
    const Map = RobinHoodHashMap(u32, u32, 16);
    var map = Map.init();
    
    try map.put(1, 100);
    try testing.expectEqual(@as(u32, 100), map.get(1).?);
    
    try map.put(1, 999);
    try testing.expectEqual(@as(u32, 999), map.get(1).?);
    try testing.expectEqual(@as(u32, 1), map.len());
}

test "RobinHoodHashMap: get non-existent key" {
    const Map = RobinHoodHashMap(u32, u32, 16);
    var map = Map.init();
    
    try map.put(1, 100);
    
    try testing.expectEqual(@as(?u32, null), map.get(999));
}

test "RobinHoodHashMap: remove" {
    const Map = RobinHoodHashMap(u32, u32, 16);
    var map = Map.init();
    
    try map.put(1, 100);
    try map.put(2, 200);
    try map.put(3, 300);
    
    try testing.expect(map.remove(2));
    try testing.expectEqual(@as(u32, 2), map.len());
    try testing.expectEqual(@as(?u32, null), map.get(2));
    try testing.expectEqual(@as(u32, 100), map.get(1).?);
    try testing.expectEqual(@as(u32, 300), map.get(3).?);
}

test "RobinHoodHashMap: remove non-existent" {
    const Map = RobinHoodHashMap(u32, u32, 16);
    var map = Map.init();
    
    try map.put(1, 100);
    
    try testing.expect(!map.remove(999));
    try testing.expectEqual(@as(u32, 1), map.len());
}

test "RobinHoodHashMap: clear" {
    const Map = RobinHoodHashMap(u32, u32, 16);
    var map = Map.init();
    
    try map.put(1, 100);
    try map.put(2, 200);
    
    map.clear();
    
    try testing.expect(map.isEmpty());
    try testing.expectEqual(@as(?u32, null), map.get(1));
}

test "RobinHoodHashMap: load factor" {
    const Map = RobinHoodHashMap(u32, u32, 16);
    var map = Map.init();
    
    try map.put(1, 100);
    try testing.expectEqual(@as(u32, 6), map.loadFactor()); // 1/16 = 6%
    
    try map.put(2, 200);
    try map.put(3, 300);
    try testing.expectEqual(@as(u32, 18), map.loadFactor()); // 3/16 = 18%
}

test "RobinHoodHashMap: bounded load factor" {
    const Map = RobinHoodHashMap(u32, u32, 16);
    var map = Map.init();
    
    // Fill to 90% capacity
    var i: u32 = 0;
    while (i < 14) : (i += 1) { // 14/16 = 87.5%
        try map.put(i, i * 100);
    }
    
    try testing.expect(map.loadFactor() < MAX_LOAD_FACTOR_PERCENT);
    
    // One more should still work
    try map.put(100, 999);
    
    // But filling beyond 90% should fail
    const result = map.put(200, 888);
    try testing.expectError(error.HashMapFull, result);
}

test "RobinHoodHashMap: Robin Hood swapping" {
    const Map = RobinHoodHashMap(u32, u32, 16);
    var map = Map.init();
    
    // Insert elements that will cause collisions
    try map.put(0, 100);   // hash to slot 0
    try map.put(16, 200);  // hash to slot 0, gets displaced
    try map.put(32, 300);  // hash to slot 0, gets displaced further
    
    // All should be retrievable
    try testing.expectEqual(@as(u32, 100), map.get(0).?);
    try testing.expectEqual(@as(u32, 200), map.get(16).?);
    try testing.expectEqual(@as(u32, 300), map.get(32).?);
    
    // PSL should be bounded
    try testing.expect(map.maxPSL() < MAX_PROBE_DISTANCE);
}

test "RobinHoodHashMap: stress test" {
    const Map = RobinHoodHashMap(u32, u32, 128);
    var map = Map.init();
    
    // Insert many elements
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        try map.put(i, i * 10);
    }
    
    // Verify all present
    i = 0;
    while (i < 100) : (i += 1) {
        try testing.expectEqual(i * 10, map.get(i).?);
    }
    
    // Remove some
    i = 0;
    while (i < 50) : (i += 2) {
        try testing.expect(map.remove(i));
    }
    
    // Verify correct ones remain
    i = 0;
    while (i < 100) : (i += 1) {
        if (i % 2 == 0 and i < 50) {
            try testing.expectEqual(@as(?u32, null), map.get(i));
        } else {
            try testing.expectEqual(i * 10, map.get(i).?);
        }
    }
}

test "RobinHoodHashMap: different value types" {
    const Map = RobinHoodHashMap(u32, [4]u8, 16);
    var map = Map.init();
    
    try map.put(1, [_]u8{ 'a', 'b', 'c', 'd' });
    try map.put(2, [_]u8{ 'x', 'y', 'z', 'w' });
    
    const val = map.get(1).?;
    try testing.expectEqual(@as(u8, 'a'), val[0]);
    try testing.expectEqual(@as(u8, 'd'), val[3]);
}
