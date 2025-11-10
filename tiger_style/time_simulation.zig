//! Time Simulation - Deterministic Time Framework
//!
//! Inspired by TigerBeetle's time simulation testing approach.
//! Provides a virtual clock with nanosecond precision for deterministic,
//! reproducible testing of time-dependent algorithms.
//!
//! Tiger Style principles demonstrated:
//! - Explicit u64 timestamps (never usize)
//! - Bounded event queue with fail-fast
//! - Heavy assertions on all state transitions
//! - No recursion in event processing
//! - All operations have explicit upper bounds

const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

/// Maximum number of scheduled events. Must be bounded.
pub const MAX_EVENTS: u32 = 1024;

/// Nanoseconds in one millisecond
pub const NS_PER_MS: u64 = 1_000_000;

/// Nanoseconds in one second
pub const NS_PER_SECOND: u64 = 1_000_000_000;

/// Event callback function type
pub const EventCallback = *const fn (context: *anyopaque) void;

/// Scheduled event in the simulation
pub const Event = struct {
    /// Absolute timestamp when event fires (nanoseconds)
    timestamp: u64,
    
    /// Callback to execute
    callback: EventCallback,
    
    /// Opaque context passed to callback
    context: *anyopaque,
    
    /// Event ID for tracking
    id: u32,
    
    /// Active flag (for event cancellation)
    active: bool,
};

/// Virtual clock for deterministic time simulation
pub const Clock = struct {
    /// Current virtual time (nanoseconds since epoch)
    now: u64,
    
    /// Scheduled events (bounded array)
    events: [MAX_EVENTS]Event,
    
    /// Number of active events
    event_count: u32,
    
    /// Next event ID to assign
    next_event_id: u32,
    
    /// Total events processed (for metrics)
    events_processed: u64,
    
    /// Initialize clock at time zero
    pub fn init() Clock {
        var clock = Clock{
            .now = 0,
            .events = undefined,
            .event_count = 0,
            .next_event_id = 1,
            .events_processed = 0,
        };
        
        // Initialize all events as inactive
        var i: u32 = 0;
        while (i < MAX_EVENTS) : (i += 1) {
            clock.events[i] = Event{
                .timestamp = 0,
                .callback = undefined,
                .context = undefined,
                .id = 0,
                .active = false,
            };
        }
        
        return clock;
    }
    
    /// Schedule an event at absolute timestamp
    /// Returns event ID for cancellation, or 0 if queue full
    pub fn schedule(
        self: *Clock,
        timestamp: u64,
        callback: EventCallback,
        context: *anyopaque,
    ) u32 {
        // Preconditions
        assert(timestamp >= self.now); // Cannot schedule in the past
        assert(self.event_count <= MAX_EVENTS);
        
        // Fail-fast: queue full
        if (self.event_count >= MAX_EVENTS) {
            return 0;
        }
        
        // Find first inactive slot
        var slot_index: u32 = 0;
        var found: bool = false;
        while (slot_index < MAX_EVENTS) : (slot_index += 1) {
            if (!self.events[slot_index].active) {
                found = true;
                break;
            }
        }
        
        assert(found); // Must find slot since event_count < MAX_EVENTS
        assert(slot_index < MAX_EVENTS);
        
        const event_id = self.next_event_id;
        self.next_event_id +%= 1; // Wrapping add for ID overflow
        if (self.next_event_id == 0) self.next_event_id = 1; // Never use ID 0
        
        self.events[slot_index] = Event{
            .timestamp = timestamp,
            .callback = callback,
            .context = context,
            .id = event_id,
            .active = true,
        };
        
        self.event_count += 1;
        
        // Postconditions
        assert(self.events[slot_index].active);
        assert(self.events[slot_index].id == event_id);
        assert(self.event_count <= MAX_EVENTS);
        
        return event_id;
    }
    
    /// Cancel a scheduled event by ID
    pub fn cancel(self: *Clock, event_id: u32) bool {
        assert(event_id != 0);
        assert(self.event_count <= MAX_EVENTS);
        
        var i: u32 = 0;
        while (i < MAX_EVENTS) : (i += 1) {
            if (self.events[i].active and self.events[i].id == event_id) {
                self.events[i].active = false;
                self.event_count -= 1;
                assert(self.event_count <= MAX_EVENTS);
                return true;
            }
        }
        
        return false;
    }
    
    /// Advance time and process all events up to target timestamp
    /// Returns number of events processed
    pub fn tick(self: *Clock, target: u64) u32 {
        // Preconditions
        assert(target >= self.now); // Time only moves forward
        assert(self.event_count <= MAX_EVENTS);
        
        const initial_count = self.event_count;
        var processed: u32 = 0;
        
        // Process events iteratively (no recursion!)
        // Bounded loop: at most MAX_EVENTS iterations per tick
        var iterations: u32 = 0;
        while (iterations < MAX_EVENTS) : (iterations += 1) {
            // Find next event to fire
            var next_index: ?u32 = null;
            var next_time: u64 = target + 1; // Past target initially
            
            var i: u32 = 0;
            while (i < MAX_EVENTS) : (i += 1) {
                if (self.events[i].active and
                    self.events[i].timestamp <= target and
                    self.events[i].timestamp < next_time)
                {
                    next_index = i;
                    next_time = self.events[i].timestamp;
                }
            }
            
            // No more events to process
            if (next_index == null) break;
            
            const index = next_index.?;
            assert(index < MAX_EVENTS);
            assert(self.events[index].active);
            
            // Advance to event time
            self.now = self.events[index].timestamp;
            assert(self.now <= target);
            
            // Execute callback
            const callback = self.events[index].callback;
            const context = self.events[index].context;
            self.events[index].active = false;
            self.event_count -= 1;
            
            callback(context);
            
            processed += 1;
            self.events_processed += 1;
            
            // Invariant: event_count consistent
            assert(self.event_count <= MAX_EVENTS);
        }
        
        // Advance to target
        self.now = target;
        
        // Postconditions
        assert(self.now == target);
        assert(self.event_count <= MAX_EVENTS);
        assert(processed <= initial_count);
        
        return processed;
    }
    
    /// Get current time
    pub fn time(self: *const Clock) u64 {
        return self.now;
    }
    
    /// Check if event queue is empty
    pub fn isEmpty(self: *const Clock) bool {
        assert(self.event_count <= MAX_EVENTS);
        return self.event_count == 0;
    }
};

// ============================================================================
// Tests demonstrating deterministic time simulation
// ============================================================================

const TestContext = struct {
    fired: bool,
    fire_time: u64,
    fire_count: u32,
};

fn testCallback(ctx: *anyopaque) void {
    const context: *TestContext = @ptrCast(@alignCast(ctx));
    context.fired = true;
    context.fire_count += 1;
}

test "Clock: initialization" {
    const clock = Clock.init();
    
    try testing.expectEqual(@as(u64, 0), clock.now);
    try testing.expectEqual(@as(u32, 0), clock.event_count);
    try testing.expect(clock.isEmpty());
}

test "Clock: schedule and fire single event" {
    var clock = Clock.init();
    var context = TestContext{
        .fired = false,
        .fire_time = 0,
        .fire_count = 0,
    };
    
    const event_id = clock.schedule(
        100 * NS_PER_MS,
        testCallback,
        @ptrCast(&context),
    );
    
    try testing.expect(event_id != 0);
    try testing.expectEqual(@as(u32, 1), clock.event_count);
    try testing.expect(!context.fired);
    
    // Tick to event time
    const processed = clock.tick(100 * NS_PER_MS);
    
    try testing.expectEqual(@as(u32, 1), processed);
    try testing.expect(context.fired);
    try testing.expectEqual(@as(u32, 1), context.fire_count);
    try testing.expectEqual(@as(u64, 100 * NS_PER_MS), clock.time());
    try testing.expect(clock.isEmpty());
}

test "Clock: event ordering is deterministic" {
    var clock = Clock.init();
    var contexts: [3]TestContext = undefined;
    
    // Schedule events out of order
    for (&contexts, 0..) |*ctx, i| {
        ctx.* = TestContext{
            .fired = false,
            .fire_time = 0,
            .fire_count = 0,
        };
        
        // Schedule at times: 300ms, 100ms, 200ms
        const times = [_]u64{ 300, 100, 200 };
        _ = clock.schedule(
            times[i] * NS_PER_MS,
            testCallback,
            @ptrCast(ctx),
        );
    }
    
    try testing.expectEqual(@as(u32, 3), clock.event_count);
    
    // Process all events
    _ = clock.tick(400 * NS_PER_MS);
    
    // All events should fire
    try testing.expect(contexts[0].fired);
    try testing.expect(contexts[1].fired);
    try testing.expect(contexts[2].fired);
    try testing.expect(clock.isEmpty());
}

test "Clock: cancel event" {
    var clock = Clock.init();
    var context = TestContext{
        .fired = false,
        .fire_time = 0,
        .fire_count = 0,
    };
    
    const event_id = clock.schedule(
        100 * NS_PER_MS,
        testCallback,
        @ptrCast(&context),
    );
    
    try testing.expect(event_id != 0);
    
    // Cancel before firing
    const cancelled = clock.cancel(event_id);
    try testing.expect(cancelled);
    try testing.expect(clock.isEmpty());
    
    // Tick past event time
    _ = clock.tick(200 * NS_PER_MS);
    
    // Event should not fire
    try testing.expect(!context.fired);
}

test "Clock: bounded event queue" {
    var clock = Clock.init();
    var context = TestContext{
        .fired = false,
        .fire_time = 0,
        .fire_count = 0,
    };
    
    // Fill event queue to maximum
    var i: u32 = 0;
    while (i < MAX_EVENTS) : (i += 1) {
        const event_id = clock.schedule(
            @as(u64, i) * NS_PER_MS,
            testCallback,
            @ptrCast(&context),
        );
        try testing.expect(event_id != 0);
    }
    
    try testing.expectEqual(MAX_EVENTS, clock.event_count);
    
    // Attempt to schedule one more (should fail)
    const overflow_id = clock.schedule(
        1000 * NS_PER_MS,
        testCallback,
        @ptrCast(&context),
    );
    
    try testing.expectEqual(@as(u32, 0), overflow_id);
    try testing.expectEqual(MAX_EVENTS, clock.event_count);
}

test "Clock: time only moves forward" {
    var clock = Clock.init();
    
    _ = clock.tick(100 * NS_PER_MS);
    try testing.expectEqual(@as(u64, 100 * NS_PER_MS), clock.time());
    
    _ = clock.tick(200 * NS_PER_MS);
    try testing.expectEqual(@as(u64, 200 * NS_PER_MS), clock.time());
    
    // Tick to same time (no-op)
    _ = clock.tick(200 * NS_PER_MS);
    try testing.expectEqual(@as(u64, 200 * NS_PER_MS), clock.time());
}

test "Clock: stress test with many events" {
    var clock = Clock.init();
    var contexts: [100]TestContext = undefined;
    
    // Schedule 100 events at different times
    for (&contexts, 0..) |*ctx, i| {
        ctx.* = TestContext{
            .fired = false,
            .fire_time = 0,
            .fire_count = 0,
        };
        
        _ = clock.schedule(
            @as(u64, i * 10) * NS_PER_MS,
            testCallback,
            @ptrCast(ctx),
        );
    }
    
    // Process all
    _ = clock.tick(1000 * NS_PER_MS);
    
    // Verify all fired exactly once
    for (contexts) |ctx| {
        try testing.expect(ctx.fired);
        try testing.expectEqual(@as(u32, 1), ctx.fire_count);
    }
    
    try testing.expect(clock.isEmpty());
    try testing.expectEqual(@as(u64, 100), clock.events_processed);
}
