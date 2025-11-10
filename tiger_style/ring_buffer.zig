//! Tiger Style Ring Buffer - Bounded FIFO Queue
//!
//! Demonstrates Tiger Style for production data structures:
//! - Fixed capacity with compile-time guarantees
//! - All operations O(1) with explicit bounds
//! - Assertions on every state transition
//! - Explicit u32 indices (never usize)
//! - Fail-fast on full/empty violations
//! - Zero allocations after initialization

const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

/// Ring buffer with fixed capacity
/// Generic over element type T and capacity
pub fn RingBuffer(comptime T: type, comptime capacity: u32) type {
    // Precondition: capacity must be reasonable
    comptime {
        assert(capacity > 0);
        assert(capacity <= 1_000_000); // Sanity limit
    }
    
    return struct {
        const Self = @This();
        
        /// Fixed-size storage array
        buffer: [capacity]T,
        
        /// Index of first element (read position)
        head: u32,
        
        /// Index where next element will be written
        tail: u32,
        
        /// Number of elements currently in buffer
        count: u32,
        
        /// Initialize empty ring buffer
        pub fn init() Self {
            var self = Self{
                .buffer = undefined,
                .head = 0,
                .tail = 0,
                .count = 0,
            };
            
            // Postconditions
            assert(self.head == 0);
            assert(self.tail == 0);
            assert(self.count == 0);
            assert(self.isEmpty());
            assert(!self.isFull());
            
            return self;
        }
        
        /// Push element to back of buffer
        /// Returns error if buffer is full (fail-fast)
        pub fn push(self: *Self, item: T) error{BufferFull}!void {
            // Preconditions
            assert(self.count <= capacity);
            assert(self.head < capacity);
            assert(self.tail < capacity);
            
            // Fail-fast: buffer full
            if (self.count >= capacity) {
                return error.BufferFull;
            }
            
            assert(!self.isFull());
            
            // Write element
            self.buffer[self.tail] = item;
            
            // Advance tail with wraparound
            self.tail += 1;
            if (self.tail >= capacity) {
                self.tail = 0;
            }
            
            self.count += 1;
            
            // Postconditions
            assert(self.count <= capacity);
            assert(self.count > 0);
            assert(self.tail < capacity);
        }
        
        /// Pop element from front of buffer
        /// Returns error if buffer is empty (fail-fast)
        pub fn pop(self: *Self) error{BufferEmpty}!T {
            // Preconditions
            assert(self.count <= capacity);
            assert(self.head < capacity);
            assert(self.tail < capacity);
            
            // Fail-fast: buffer empty
            if (self.count == 0) {
                return error.BufferEmpty;
            }
            
            assert(!self.isEmpty());
            
            // Read element
            const item = self.buffer[self.head];
            
            // Advance head with wraparound
            self.head += 1;
            if (self.head >= capacity) {
                self.head = 0;
            }
            
            self.count -= 1;
            
            // Postconditions
            assert(self.count < capacity);
            assert(self.head < capacity);
            
            return item;
        }
        
        /// Peek at front element without removing
        /// Returns error if buffer is empty
        pub fn peek(self: *const Self) error{BufferEmpty}!T {
            // Preconditions
            assert(self.count <= capacity);
            assert(self.head < capacity);
            
            if (self.count == 0) {
                return error.BufferEmpty;
            }
            
            return self.buffer[self.head];
        }
        
        /// Peek at back element (most recently pushed)
        /// Returns error if buffer is empty
        pub fn peekBack(self: *const Self) error{BufferEmpty}!T {
            // Preconditions
            assert(self.count <= capacity);
            assert(self.tail < capacity);
            
            if (self.count == 0) {
                return error.BufferEmpty;
            }
            
            // Calculate index of last element
            const back_index = if (self.tail > 0) self.tail - 1 else capacity - 1;
            assert(back_index < capacity);
            
            return self.buffer[back_index];
        }
        
        /// Check if buffer is empty
        pub fn isEmpty(self: *const Self) bool {
            assert(self.count <= capacity);
            return self.count == 0;
        }
        
        /// Check if buffer is full
        pub fn isFull(self: *const Self) bool {
            assert(self.count <= capacity);
            return self.count == capacity;
        }
        
        /// Get number of elements in buffer
        pub fn len(self: *const Self) u32 {
            assert(self.count <= capacity);
            return self.count;
        }
        
        /// Get remaining capacity
        pub fn available(self: *const Self) u32 {
            assert(self.count <= capacity);
            return capacity - self.count;
        }
        
        /// Clear all elements
        pub fn clear(self: *Self) void {
            // Preconditions
            assert(self.count <= capacity);
            
            self.head = 0;
            self.tail = 0;
            self.count = 0;
            
            // Postconditions
            assert(self.isEmpty());
            assert(!self.isFull() or capacity == 0);
        }
        
        /// Get element at index (0 = front, count-1 = back)
        /// Returns error if index out of bounds
        pub fn get(self: *const Self, index: u32) error{IndexOutOfBounds}!T {
            // Preconditions
            assert(self.count <= capacity);
            assert(self.head < capacity);
            
            if (index >= self.count) {
                return error.IndexOutOfBounds;
            }
            
            // Calculate actual buffer index with wraparound
            var buffer_index = self.head + index;
            if (buffer_index >= capacity) {
                buffer_index -= capacity;
            }
            
            assert(buffer_index < capacity);
            return self.buffer[buffer_index];
        }
        
        /// Iterator for iterating over elements in FIFO order
        pub const Iterator = struct {
            buffer: *const Self,
            position: u32,
            
            pub fn next(iter: *Iterator) ?T {
                if (iter.position >= iter.buffer.count) {
                    return null;
                }
                
                const item = iter.buffer.get(iter.position) catch unreachable;
                iter.position += 1;
                
                return item;
            }
        };
        
        /// Get iterator for buffer
        pub fn iterator(self: *const Self) Iterator {
            return Iterator{
                .buffer = self,
                .position = 0,
            };
        }
    };
}

// ============================================================================
// Tests - Exhaustive edge case coverage
// ============================================================================

test "RingBuffer: initialization" {
    const Buffer = RingBuffer(i32, 8);
    const buf = Buffer.init();
    
    try testing.expect(buf.isEmpty());
    try testing.expect(!buf.isFull());
    try testing.expectEqual(@as(u32, 0), buf.len());
    try testing.expectEqual(@as(u32, 8), buf.available());
}

test "RingBuffer: push and pop single element" {
    const Buffer = RingBuffer(i32, 8);
    var buf = Buffer.init();
    
    try buf.push(42);
    
    try testing.expect(!buf.isEmpty());
    try testing.expectEqual(@as(u32, 1), buf.len());
    
    const value = try buf.pop();
    
    try testing.expectEqual(@as(i32, 42), value);
    try testing.expect(buf.isEmpty());
}

test "RingBuffer: push to full" {
    const Buffer = RingBuffer(i32, 4);
    var buf = Buffer.init();
    
    try buf.push(1);
    try buf.push(2);
    try buf.push(3);
    try buf.push(4);
    
    try testing.expect(buf.isFull());
    try testing.expectEqual(@as(u32, 4), buf.len());
    
    // Try to push one more - should fail
    const result = buf.push(5);
    try testing.expectError(error.BufferFull, result);
}

test "RingBuffer: pop from empty" {
    const Buffer = RingBuffer(i32, 4);
    var buf = Buffer.init();
    
    const result = buf.pop();
    try testing.expectError(error.BufferEmpty, result);
}

test "RingBuffer: FIFO ordering" {
    const Buffer = RingBuffer(i32, 8);
    var buf = Buffer.init();
    
    try buf.push(10);
    try buf.push(20);
    try buf.push(30);
    
    try testing.expectEqual(@as(i32, 10), try buf.pop());
    try testing.expectEqual(@as(i32, 20), try buf.pop());
    try testing.expectEqual(@as(i32, 30), try buf.pop());
}

test "RingBuffer: wraparound" {
    const Buffer = RingBuffer(i32, 4);
    var buf = Buffer.init();
    
    // Fill buffer
    try buf.push(1);
    try buf.push(2);
    try buf.push(3);
    try buf.push(4);
    
    // Remove two
    _ = try buf.pop();
    _ = try buf.pop();
    
    // Add two more (will wrap around)
    try buf.push(5);
    try buf.push(6);
    
    // Verify order
    try testing.expectEqual(@as(i32, 3), try buf.pop());
    try testing.expectEqual(@as(i32, 4), try buf.pop());
    try testing.expectEqual(@as(i32, 5), try buf.pop());
    try testing.expectEqual(@as(i32, 6), try buf.pop());
    
    try testing.expect(buf.isEmpty());
}

test "RingBuffer: peek" {
    const Buffer = RingBuffer(i32, 4);
    var buf = Buffer.init();
    
    try buf.push(100);
    try buf.push(200);
    
    // Peek should not remove element
    try testing.expectEqual(@as(i32, 100), try buf.peek());
    try testing.expectEqual(@as(u32, 2), buf.len());
    
    // Verify element still there
    try testing.expectEqual(@as(i32, 100), try buf.pop());
}

test "RingBuffer: peekBack" {
    const Buffer = RingBuffer(i32, 4);
    var buf = Buffer.init();
    
    try buf.push(100);
    try buf.push(200);
    try buf.push(300);
    
    try testing.expectEqual(@as(i32, 300), try buf.peekBack());
    try testing.expectEqual(@as(u32, 3), buf.len());
}

test "RingBuffer: clear" {
    const Buffer = RingBuffer(i32, 4);
    var buf = Buffer.init();
    
    try buf.push(1);
    try buf.push(2);
    try buf.push(3);
    
    buf.clear();
    
    try testing.expect(buf.isEmpty());
    try testing.expectEqual(@as(u32, 0), buf.len());
    
    // Can push again after clear
    try buf.push(10);
    try testing.expectEqual(@as(i32, 10), try buf.pop());
}

test "RingBuffer: get by index" {
    const Buffer = RingBuffer(i32, 8);
    var buf = Buffer.init();
    
    try buf.push(10);
    try buf.push(20);
    try buf.push(30);
    
    try testing.expectEqual(@as(i32, 10), try buf.get(0));
    try testing.expectEqual(@as(i32, 20), try buf.get(1));
    try testing.expectEqual(@as(i32, 30), try buf.get(2));
    
    // Out of bounds
    const result = buf.get(3);
    try testing.expectError(error.IndexOutOfBounds, result);
}

test "RingBuffer: iterator" {
    const Buffer = RingBuffer(i32, 8);
    var buf = Buffer.init();
    
    try buf.push(1);
    try buf.push(2);
    try buf.push(3);
    try buf.push(4);
    
    var iter = buf.iterator();
    
    try testing.expectEqual(@as(i32, 1), iter.next().?);
    try testing.expectEqual(@as(i32, 2), iter.next().?);
    try testing.expectEqual(@as(i32, 3), iter.next().?);
    try testing.expectEqual(@as(i32, 4), iter.next().?);
    try testing.expectEqual(@as(?i32, null), iter.next());
}

test "RingBuffer: stress test - many operations" {
    const Buffer = RingBuffer(i32, 64);
    var buf = Buffer.init();
    
    // Perform many push/pop operations
    var i: i32 = 0;
    while (i < 1000) : (i += 1) {
        // Only push if not full
        if (!buf.isFull()) {
            try buf.push(i);
        }
        
        // Pop every other iteration
        if (@rem(i, 2) == 0 and !buf.isEmpty()) {
            _ = try buf.pop();
        }
    }
    
    // Buffer should have some elements
    try testing.expect(!buf.isEmpty());
}

test "RingBuffer: capacity 1" {
    const Buffer = RingBuffer(i32, 1);
    var buf = Buffer.init();
    
    try buf.push(42);
    try testing.expect(buf.isFull());
    
    try testing.expectEqual(@as(i32, 42), try buf.pop());
    try testing.expect(buf.isEmpty());
}

test "RingBuffer: different types - u64" {
    const Buffer = RingBuffer(u64, 4);
    var buf = Buffer.init();
    
    try buf.push(1000000000000);
    try testing.expectEqual(@as(u64, 1000000000000), try buf.pop());
}

test "RingBuffer: struct type" {
    const Point = struct { x: i32, y: i32 };
    const Buffer = RingBuffer(Point, 4);
    var buf = Buffer.init();
    
    try buf.push(.{ .x = 10, .y = 20 });
    try buf.push(.{ .x = 30, .y = 40 });
    
    const p1 = try buf.pop();
    try testing.expectEqual(@as(i32, 10), p1.x);
    try testing.expectEqual(@as(i32, 20), p1.y);
    
    const p2 = try buf.pop();
    try testing.expectEqual(@as(i32, 30), p2.x);
    try testing.expectEqual(@as(i32, 40), p2.y);
}
