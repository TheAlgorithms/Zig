# Tiger Style Algorithms

> "Simplicity and elegance are unpopular because they require hard work and discipline to achieve" — Edsger Dijkstra

This folder showcases **expert-level algorithmic techniques** following [TigerBeetle's Tiger Style](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md) coding principles.

## Tiger Style Principles

### 1. **Safety First**

- Heavy use of assertions (minimum 2 per function)
- Assert all preconditions, postconditions, and invariants
- Fail-fast on violations
- Assertions downgrade catastrophic bugs into liveness bugs

### 2. **Explicit Everything**

- Use explicitly-sized types: `u32`, `u64`, `i32` (never `usize`)
- Simple, explicit control flow only
- No recursion - all algorithms are iterative
- Bounded loops with explicit upper limits

### 3. **Zero Technical Debt**

- Production-quality code from the start
- No shortcuts or workarounds
- Solve problems correctly the first time
- Every abstraction must earn its place

### 4. **Deterministic Testing**

- Time simulation for reproducible tests
- Fuzz-friendly with heavy assertions
- Test edge cases exhaustively

## Implementations

### `time_simulation.zig`

**Deterministic time simulation framework** inspired by TigerBeetle's testing approach.

- Virtual clock with nanosecond precision
- Deterministic event scheduling
- Reproducible test scenarios
- Perfect for testing distributed algorithms

### `merge_sort_tiger.zig`

**Zero-recursion merge sort** with Tiger Style discipline.

- Iterative bottom-up implementation
- Explicit stack bounds
- Heavy assertions on every invariant
- No hidden allocations

### `knapsack_tiger.zig`

**0/1 Knapsack with militant assertion discipline.**

- Every array access validated
- Explicit capacity bounds
- DP table invariants checked
- Overflow protection

### `ring_buffer.zig`

**Bounded ring buffer** demonstrating fail-fast principles.

- Fixed capacity with compile-time guarantees
- All operations bounded O(1)
- Assertions on every state transition
- Production-grade reliability

### `raft_consensus.zig`

**Raft consensus algorithm** for distributed systems.

- Explicit state machine (follower/candidate/leader)
- Bounded log with fail-fast
- Leader election with majority votes
- Inspired by TigerBeetle's consensus approach

### `two_phase_commit.zig`

**Two-Phase Commit protocol** for distributed transactions.

- Coordinator with bounded participants
- Prepare and commit phases
- Timeout detection
- Atomic commit/abort decisions

### `vsr_consensus.zig`

**VSR (Viewstamped Replication)** - TigerBeetle's actual consensus.

- More sophisticated than Raft
- View change protocol
- Explicit view and op numbers
- Inspired by "Viewstamped Replication Revisited"

### `robin_hood_hash.zig`

**Cache-efficient hash table** with Robin Hood hashing.

- Fixed capacity (no dynamic resizing)
- Linear probing with fairness
- Bounded probe distances
- Explicit load factor limits

### `skip_list.zig`

**Skip list** - probabilistic ordered map.

- Foundation for LSM trees
- Deterministic randomness (seeded RNG)
- Bounded maximum level
- No recursion (iterative traversal)

## Why Tiger Style?

Tiger Style is about **engineering excellence**:

1. **Code you can trust** - Heavy assertions catch bugs during fuzzing
2. **No surprises** - Explicit bounds prevent tail latency spikes
3. **Maintainable** - Simple control flow is easy to reason about
4. **Fast** - No recursion overhead, explicit types, cache-friendly

## Running Tests

```bash
# Test individual files
zig test tiger_style/time_simulation.zig       #  7 tests
zig test tiger_style/merge_sort_tiger.zig      # 14 tests
zig test tiger_style/knapsack_tiger.zig        # 12 tests
zig test tiger_style/ring_buffer.zig           # 15 tests
zig test tiger_style/raft_consensus.zig        # 12 tests
zig test tiger_style/two_phase_commit.zig      #  9 tests
zig test tiger_style/vsr_consensus.zig         # 11 tests ⭐
zig test tiger_style/robin_hood_hash.zig       # 12 tests ⭐
zig test tiger_style/skip_list.zig             # 10 tests ⭐

# Total: 102 tests across 9 implementations!
```

## Contributing

When adding to tiger_style/:

1. **No recursion** - use iteration with explicit bounds
2. **Assert everything** - minimum 2 assertions per function
3. **Explicit types** - u32/u64/i32, never usize
4. **Bounded loops** - every loop must have a provable upper bound
5. **Fail-fast** - detect violations immediately
6. **Simple control flow** - keep it explicit and obvious

---

*"The rules act like the seat-belt in your car: initially they are perhaps a little uncomfortable, but after a while their use becomes second-nature and not using them becomes unimaginable."* — Gerard J. Holzmann
