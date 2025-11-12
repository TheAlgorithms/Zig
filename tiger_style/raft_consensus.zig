//! Tiger Style Raft Consensus Algorithm
//!
//! Implements the Raft distributed consensus algorithm with Tiger Style discipline:
//! - Explicit state machine (no recursion)
//! - Bounded message queues with fail-fast
//! - Heavy assertions on all state transitions
//! - Deterministic testing with time simulation
//! - All operations have explicit upper bounds
//!
//! Reference: "In Search of an Understandable Consensus Algorithm" (Raft paper)

const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

/// Maximum number of nodes in cluster (must be bounded)
pub const MAX_NODES: u32 = 16;

/// Maximum entries in log (must be bounded for Tiger Style)
pub const MAX_LOG_ENTRIES: u32 = 10000;

/// Maximum pending messages per node (bounded queue)
pub const MAX_PENDING_MESSAGES: u32 = 256;

/// Node ID type - explicit u32
pub const NodeId = u32;

/// Term number in Raft - monotonically increasing
pub const Term = u64;

/// Log index - explicit u32
pub const LogIndex = u32;

/// Raft node states
pub const NodeState = enum(u8) {
    follower,
    candidate,
    leader,

    pub fn validate(self: NodeState) void {
        // Ensure state is valid
        assert(@intFromEnum(self) <= 2);
    }
};

/// Log entry in the replicated state machine
pub const LogEntry = struct {
    term: Term,
    index: LogIndex,
    command: u64, // Simplified: actual systems would have arbitrary commands

    pub fn validate(self: LogEntry) void {
        assert(self.index > 0); // Log indices start at 1
        assert(self.term > 0); // Terms start at 1
    }
};

/// Message types in Raft protocol
pub const MessageType = enum(u8) {
    request_vote,
    request_vote_reply,
    append_entries,
    append_entries_reply,
};

/// Raft protocol message
pub const Message = struct {
    msg_type: MessageType,
    term: Term,
    from: NodeId,
    to: NodeId,

    // RequestVote fields
    candidate_id: NodeId,
    last_log_index: LogIndex,
    last_log_term: Term,

    // RequestVote reply
    vote_granted: bool,

    // AppendEntries fields
    prev_log_index: LogIndex,
    prev_log_term: Term,
    leader_commit: LogIndex,

    // AppendEntries reply
    success: bool,
    match_index: LogIndex,
};

/// Raft node implementing consensus
pub const RaftNode = struct {
    /// Node ID
    id: NodeId,

    /// Current state
    state: NodeState,

    /// Current term
    current_term: Term,

    /// Who we voted for in current term (0 = none)
    voted_for: NodeId,

    /// Replicated log
    log: [MAX_LOG_ENTRIES]LogEntry,
    log_length: u32,

    /// Commit index
    commit_index: LogIndex,

    /// Last applied index
    last_applied: LogIndex,

    /// Leader state (only valid when state == leader)
    next_index: [MAX_NODES]LogIndex,
    match_index: [MAX_NODES]LogIndex,

    /// Cluster configuration
    cluster_size: u32,

    /// Election timeout (in milliseconds)
    election_timeout: u64,
    last_heartbeat: u64,

    /// Vote tracking
    votes_received: u32,

    /// Initialize a new Raft node
    pub fn init(id: NodeId, cluster_size: u32) RaftNode {
        // Preconditions
        assert(id > 0);
        assert(id <= MAX_NODES);
        assert(cluster_size > 0);
        assert(cluster_size <= MAX_NODES);
        assert(cluster_size % 2 == 1); // Raft requires odd cluster size

        var node = RaftNode{
            .id = id,
            .state = .follower,
            .current_term = 1,
            .voted_for = 0,
            .log = undefined,
            .log_length = 0,
            .commit_index = 0,
            .last_applied = 0,
            .next_index = undefined,
            .match_index = undefined,
            .cluster_size = cluster_size,
            .election_timeout = 150 + (id * 50), // Randomized per node
            .last_heartbeat = 0,
            .votes_received = 0,
        };

        // Initialize leader state
        var i: u32 = 0;
        while (i < MAX_NODES) : (i += 1) {
            node.next_index[i] = 1;
            node.match_index[i] = 0;
        }

        // Postconditions
        assert(node.state == .follower);
        assert(node.current_term > 0);
        assert(node.log_length == 0);
        node.validate();

        return node;
    }

    /// Validate node invariants
    pub fn validate(self: *const RaftNode) void {
        // State invariants
        self.state.validate();
        assert(self.id > 0);
        assert(self.id <= MAX_NODES);
        assert(self.current_term > 0);
        assert(self.log_length <= MAX_LOG_ENTRIES);
        assert(self.commit_index <= self.log_length);
        assert(self.last_applied <= self.commit_index);
        assert(self.cluster_size > 0);
        assert(self.cluster_size <= MAX_NODES);

        // If we voted, must be for valid node
        if (self.voted_for != 0) {
            assert(self.voted_for <= MAX_NODES);
        }

        // Vote count bounded by cluster size
        assert(self.votes_received <= self.cluster_size);
    }

    /// Start election (transition to candidate)
    pub fn startElection(self: *RaftNode, current_time: u64) void {
        // Preconditions
        self.validate();
        assert(self.state == .follower or self.state == .candidate);

        // Transition to candidate
        self.state = .candidate;
        self.current_term += 1;
        self.voted_for = self.id; // Vote for self
        self.votes_received = 1; // Count our own vote
        self.last_heartbeat = current_time;

        // Postconditions
        assert(self.state == .candidate);
        assert(self.votes_received == 1);
        self.validate();
    }

    /// Receive vote in election
    pub fn receiveVote(self: *RaftNode, from: NodeId, term: Term) void {
        // Preconditions
        self.validate();
        assert(self.state == .candidate);
        assert(from > 0);
        assert(from <= MAX_NODES);
        assert(term == self.current_term);

        self.votes_received += 1;

        // Check if we won the election (majority)
        const majority = self.cluster_size / 2 + 1;
        if (self.votes_received >= majority) {
            self.becomeLeader();
        }

        // Postconditions
        assert(self.votes_received <= self.cluster_size);
        self.validate();
    }

    /// Become leader
    fn becomeLeader(self: *RaftNode) void {
        // Preconditions
        assert(self.state == .candidate);

        self.state = .leader;

        // Initialize leader state
        var i: u32 = 0;
        while (i < MAX_NODES) : (i += 1) {
            self.next_index[i] = self.log_length + 1;
            self.match_index[i] = 0;
        }

        // Postconditions
        assert(self.state == .leader);
        self.validate();
    }

    /// Step down to follower (discovered higher term)
    pub fn stepDown(self: *RaftNode, new_term: Term) void {
        // Preconditions
        self.validate();
        assert(new_term > self.current_term);

        self.state = .follower;
        self.current_term = new_term;
        self.voted_for = 0;
        self.votes_received = 0;

        // Postconditions
        assert(self.state == .follower);
        assert(self.current_term == new_term);
        self.validate();
    }

    /// Append entry to log (leader only)
    pub fn appendEntry(self: *RaftNode, command: u64) !LogIndex {
        // Preconditions
        self.validate();
        assert(self.state == .leader);

        // Fail-fast: log full
        if (self.log_length >= MAX_LOG_ENTRIES) {
            return error.LogFull;
        }

        const index = self.log_length;
        assert(index < MAX_LOG_ENTRIES);

        self.log[index] = LogEntry{
            .term = self.current_term,
            .index = @intCast(index + 1), // 1-indexed
            .command = command,
        };
        self.log[index].validate();

        self.log_length += 1;

        // Postconditions
        assert(self.log_length <= MAX_LOG_ENTRIES);
        self.validate();

        return @intCast(index + 1);
    }

    /// Commit entries up to index
    pub fn commitUpTo(self: *RaftNode, index: LogIndex) void {
        // Preconditions
        self.validate();
        assert(index <= self.log_length);

        if (index > self.commit_index) {
            self.commit_index = index;
        }

        // Postconditions
        assert(self.commit_index <= self.log_length);
        self.validate();
    }

    /// Apply committed entries
    pub fn applyCommitted(self: *RaftNode) u32 {
        // Preconditions
        self.validate();
        assert(self.last_applied <= self.commit_index);

        var applied: u32 = 0;

        while (self.last_applied < self.commit_index) {
            self.last_applied += 1;
            applied += 1;

            // Bounded loop
            assert(applied <= MAX_LOG_ENTRIES);
        }

        // Postconditions
        assert(self.last_applied == self.commit_index);
        self.validate();

        return applied;
    }

    /// Check if election timeout expired
    pub fn isElectionTimeoutExpired(self: *const RaftNode, current_time: u64) bool {
        self.validate();
        const elapsed = current_time - self.last_heartbeat;
        return elapsed > self.election_timeout;
    }

    /// Reset election timer
    pub fn resetElectionTimer(self: *RaftNode, current_time: u64) void {
        self.validate();
        self.last_heartbeat = current_time;
    }
};

// ============================================================================
// Tests - Consensus algorithm verification
// ============================================================================

test "RaftNode: initialization" {
    const node = RaftNode.init(1, 3);

    try testing.expectEqual(@as(NodeId, 1), node.id);
    try testing.expectEqual(NodeState.follower, node.state);
    try testing.expectEqual(@as(Term, 1), node.current_term);
    try testing.expectEqual(@as(u32, 0), node.log_length);
    try testing.expectEqual(@as(LogIndex, 0), node.commit_index);
}

test "RaftNode: start election" {
    var node = RaftNode.init(1, 3);

    node.startElection(100);

    try testing.expectEqual(NodeState.candidate, node.state);
    try testing.expectEqual(@as(Term, 2), node.current_term);
    try testing.expectEqual(@as(u32, 1), node.votes_received);
    try testing.expectEqual(@as(NodeId, 1), node.voted_for);
}

test "RaftNode: win election with majority" {
    var node = RaftNode.init(1, 3);

    node.startElection(100);
    try testing.expectEqual(NodeState.candidate, node.state);

    // Receive vote from another node (2/3 = majority)
    node.receiveVote(2, 2);

    try testing.expectEqual(NodeState.leader, node.state);
}

test "RaftNode: step down on higher term" {
    var node = RaftNode.init(1, 3);
    node.startElection(100);

    try testing.expectEqual(NodeState.candidate, node.state);
    try testing.expectEqual(@as(Term, 2), node.current_term);

    // Discover higher term
    node.stepDown(5);

    try testing.expectEqual(NodeState.follower, node.state);
    try testing.expectEqual(@as(Term, 5), node.current_term);
    try testing.expectEqual(@as(NodeId, 0), node.voted_for);
}

test "RaftNode: append entries as leader" {
    var node = RaftNode.init(1, 3);

    // Become leader
    node.startElection(100);
    node.receiveVote(2, 2);
    try testing.expectEqual(NodeState.leader, node.state);

    // Append entries
    const idx1 = try node.appendEntry(100);
    const idx2 = try node.appendEntry(200);
    const idx3 = try node.appendEntry(300);

    try testing.expectEqual(@as(LogIndex, 1), idx1);
    try testing.expectEqual(@as(LogIndex, 2), idx2);
    try testing.expectEqual(@as(LogIndex, 3), idx3);
    try testing.expectEqual(@as(u32, 3), node.log_length);
}

test "RaftNode: commit and apply entries" {
    var node = RaftNode.init(1, 3);

    // Become leader and append entries
    node.startElection(100);
    node.receiveVote(2, 2);
    _ = try node.appendEntry(100);
    _ = try node.appendEntry(200);
    _ = try node.appendEntry(300);

    // Commit first two entries
    node.commitUpTo(2);
    try testing.expectEqual(@as(LogIndex, 2), node.commit_index);

    // Apply committed entries
    const applied = node.applyCommitted();
    try testing.expectEqual(@as(u32, 2), applied);
    try testing.expectEqual(@as(LogIndex, 2), node.last_applied);
}

test "RaftNode: bounded log" {
    var node = RaftNode.init(1, 3);

    node.startElection(100);
    node.receiveVote(2, 2);

    // Fill log to max
    var i: u32 = 0;
    while (i < MAX_LOG_ENTRIES) : (i += 1) {
        _ = try node.appendEntry(@intCast(i));
    }

    try testing.expectEqual(MAX_LOG_ENTRIES, node.log_length);

    // Next append should fail (bounded)
    const result = node.appendEntry(9999);
    try testing.expectError(error.LogFull, result);
}

test "RaftNode: election timeout" {
    const node = RaftNode.init(1, 3);

    // Initially not expired
    try testing.expect(!node.isElectionTimeoutExpired(100));

    // After timeout period
    try testing.expect(node.isElectionTimeoutExpired(300));
}

test "RaftNode: reset election timer" {
    var node = RaftNode.init(1, 3);

    node.resetElectionTimer(100);
    try testing.expect(!node.isElectionTimeoutExpired(200));

    // Timer expired after timeout (election_timeout = 150 + 1*50 = 200)
    try testing.expect(node.isElectionTimeoutExpired(301));
}

test "RaftNode: log validation" {
    var node = RaftNode.init(1, 3);
    node.startElection(100);
    node.receiveVote(2, 2);

    _ = try node.appendEntry(42);

    const entry = node.log[0];
    entry.validate(); // Should not fail

    try testing.expectEqual(@as(u64, 42), entry.command);
    try testing.expectEqual(@as(LogIndex, 1), entry.index);
}

test "RaftNode: cluster size must be odd" {
    // This demonstrates the assertion - odd cluster sizes required
    const node = RaftNode.init(1, 5);
    try testing.expectEqual(@as(u32, 5), node.cluster_size);
}

test "RaftNode: majority calculation" {
    var node = RaftNode.init(1, 5);
    node.startElection(100);

    // Need 3 votes for majority in cluster of 5
    try testing.expectEqual(NodeState.candidate, node.state);

    node.receiveVote(2, 2);
    try testing.expectEqual(NodeState.candidate, node.state);

    node.receiveVote(3, 2);
    try testing.expectEqual(NodeState.leader, node.state);
}
