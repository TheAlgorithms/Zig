//! Tiger Style Two-Phase Commit Protocol
//!
//! Implements distributed transaction commit protocol with Tiger Style:
//! - Explicit state machine transitions
//! - Bounded participant list
//! - Heavy assertions on all state changes
//! - Fail-fast on protocol violations
//! - All timeouts explicitly bounded

const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;

/// Maximum participants in transaction (must be bounded)
pub const MAX_PARTICIPANTS: u32 = 64;

/// Transaction ID
pub const TransactionId = u64;

/// Participant ID
pub const ParticipantId = u32;

/// Two-phase commit coordinator state
pub const CoordinatorState = enum(u8) {
    init,
    preparing,
    committed,
    aborted,

    pub fn validate(self: CoordinatorState) void {
        assert(@intFromEnum(self) <= 3);
    }
};

/// Participant response
pub const ParticipantVote = enum(u8) {
    vote_commit,
    vote_abort,
    no_response,

    pub fn validate(self: ParticipantVote) void {
        assert(@intFromEnum(self) <= 2);
    }
};

/// Two-Phase Commit Coordinator
pub const Coordinator = struct {
    /// Transaction ID
    txn_id: TransactionId,

    /// Current state
    state: CoordinatorState,

    /// Number of participants
    participant_count: u32,

    /// Participant votes
    votes: [MAX_PARTICIPANTS]ParticipantVote,

    /// Number of votes received
    votes_received: u32,

    /// Number of commit votes
    commit_votes: u32,

    /// Start time (for timeout detection)
    start_time: u64,

    /// Timeout in milliseconds
    timeout_ms: u64,

    /// Initialize coordinator
    pub fn init(txn_id: TransactionId, participant_count: u32, timeout_ms: u64) Coordinator {
        // Preconditions
        assert(txn_id > 0);
        assert(participant_count > 0);
        assert(participant_count <= MAX_PARTICIPANTS);
        assert(timeout_ms > 0);

        var coord = Coordinator{
            .txn_id = txn_id,
            .state = .init,
            .participant_count = participant_count,
            .votes = undefined,
            .votes_received = 0,
            .commit_votes = 0,
            .start_time = 0,
            .timeout_ms = timeout_ms,
        };

        // Initialize all votes to no_response
        var i: u32 = 0;
        while (i < MAX_PARTICIPANTS) : (i += 1) {
            coord.votes[i] = .no_response;
        }

        // Postconditions
        assert(coord.state == .init);
        assert(coord.votes_received == 0);
        coord.validate();

        return coord;
    }

    /// Validate coordinator invariants
    pub fn validate(self: *const Coordinator) void {
        self.state.validate();
        assert(self.txn_id > 0);
        assert(self.participant_count > 0);
        assert(self.participant_count <= MAX_PARTICIPANTS);
        assert(self.votes_received <= self.participant_count);
        assert(self.commit_votes <= self.votes_received);
        assert(self.timeout_ms > 0);
    }

    /// Start prepare phase
    pub fn prepare(self: *Coordinator, current_time: u64) void {
        // Preconditions
        self.validate();
        assert(self.state == .init);

        self.state = .preparing;
        self.start_time = current_time;

        // Postconditions
        assert(self.state == .preparing);
        self.validate();
    }

    /// Record participant vote
    pub fn recordVote(self: *Coordinator, participant: ParticipantId, vote: ParticipantVote) !void {
        // Preconditions
        self.validate();
        assert(self.state == .preparing);
        assert(participant < self.participant_count);
        vote.validate();

        // Fail-fast: already voted
        if (self.votes[participant] != .no_response) {
            return error.AlreadyVoted;
        }

        self.votes[participant] = vote;
        self.votes_received += 1;

        if (vote == .vote_commit) {
            self.commit_votes += 1;
        }

        // Postconditions
        assert(self.votes_received <= self.participant_count);
        self.validate();
    }

    /// Check if all votes received
    pub fn allVotesReceived(self: *const Coordinator) bool {
        self.validate();
        return self.votes_received == self.participant_count;
    }

    /// Commit transaction
    pub fn commit(self: *Coordinator) !void {
        // Preconditions
        self.validate();
        assert(self.state == .preparing);
        assert(self.allVotesReceived());

        // Can only commit if all voted commit
        if (self.commit_votes != self.participant_count) {
            return error.CannotCommit;
        }

        self.state = .committed;

        // Postconditions
        assert(self.state == .committed);
        self.validate();
    }

    /// Abort transaction
    pub fn abort(self: *Coordinator) void {
        // Preconditions
        self.validate();
        assert(self.state == .preparing);

        self.state = .aborted;

        // Postconditions
        assert(self.state == .aborted);
        self.validate();
    }

    /// Check if transaction timed out
    pub fn isTimedOut(self: *const Coordinator, current_time: u64) bool {
        self.validate();
        if (self.state != .preparing) return false;

        const elapsed = current_time - self.start_time;
        return elapsed > self.timeout_ms;
    }

    /// Decide commit or abort based on votes
    pub fn decide(self: *Coordinator) !void {
        // Preconditions
        self.validate();
        assert(self.state == .preparing);
        assert(self.allVotesReceived());

        // Check if any aborts
        var i: u32 = 0;
        var has_abort = false;
        while (i < self.participant_count) : (i += 1) {
            if (self.votes[i] == .vote_abort) {
                has_abort = true;
                break;
            }
        }

        if (has_abort) {
            self.abort();
        } else {
            try self.commit();
        }

        // Postconditions
        assert(self.state == .committed or self.state == .aborted);
        self.validate();
    }
};

/// Participant in two-phase commit
pub const Participant = struct {
    id: ParticipantId,
    txn_id: TransactionId,
    prepared: bool,
    committed: bool,
    aborted: bool,

    pub fn init(id: ParticipantId, txn_id: TransactionId) Participant {
        assert(txn_id > 0);

        return Participant{
            .id = id,
            .txn_id = txn_id,
            .prepared = false,
            .committed = false,
            .aborted = false,
        };
    }

    pub fn validate(self: *const Participant) void {
        assert(self.txn_id > 0);
        // Can't be both committed and aborted
        assert(!(self.committed and self.aborted));
    }

    pub fn prepare(self: *Participant) ParticipantVote {
        self.validate();
        assert(!self.prepared);

        self.prepared = true;

        // Simplified: always vote commit for testing
        // Real system would check local constraints
        return .vote_commit;
    }

    pub fn commitTransaction(self: *Participant) void {
        self.validate();
        assert(self.prepared);
        assert(!self.aborted);

        self.committed = true;
        self.validate();
    }

    pub fn abortTransaction(self: *Participant) void {
        self.validate();
        assert(!self.committed);

        self.aborted = true;
        self.validate();
    }
};

// ============================================================================
// Tests
// ============================================================================

test "Coordinator: initialization" {
    const coord = Coordinator.init(1, 3, 1000);

    try testing.expectEqual(@as(TransactionId, 1), coord.txn_id);
    try testing.expectEqual(CoordinatorState.init, coord.state);
    try testing.expectEqual(@as(u32, 3), coord.participant_count);
    try testing.expectEqual(@as(u32, 0), coord.votes_received);
}

test "Coordinator: successful commit" {
    var coord = Coordinator.init(1, 3, 1000);

    coord.prepare(100);
    try testing.expectEqual(CoordinatorState.preparing, coord.state);

    // All participants vote commit
    try coord.recordVote(0, .vote_commit);
    try coord.recordVote(1, .vote_commit);
    try coord.recordVote(2, .vote_commit);

    try testing.expect(coord.allVotesReceived());

    try coord.decide();
    try testing.expectEqual(CoordinatorState.committed, coord.state);
}

test "Coordinator: abort on single no vote" {
    var coord = Coordinator.init(1, 3, 1000);

    coord.prepare(100);

    // One participant votes abort
    try coord.recordVote(0, .vote_commit);
    try coord.recordVote(1, .vote_abort);
    try coord.recordVote(2, .vote_commit);

    try coord.decide();
    try testing.expectEqual(CoordinatorState.aborted, coord.state);
}

test "Coordinator: timeout detection" {
    var coord = Coordinator.init(1, 3, 1000);

    coord.prepare(100);

    try testing.expect(!coord.isTimedOut(500));
    try testing.expect(coord.isTimedOut(1200));
}

test "Coordinator: cannot vote twice" {
    var coord = Coordinator.init(1, 3, 1000);

    coord.prepare(100);

    try coord.recordVote(0, .vote_commit);

    // Try to vote again
    const result = coord.recordVote(0, .vote_commit);
    try testing.expectError(error.AlreadyVoted, result);
}

test "Coordinator: bounded participants" {
    const coord = Coordinator.init(1, MAX_PARTICIPANTS, 1000);
    try testing.expectEqual(MAX_PARTICIPANTS, coord.participant_count);
}

test "Participant: prepare and commit" {
    var p = Participant.init(1, 100);

    const vote = p.prepare();
    try testing.expectEqual(ParticipantVote.vote_commit, vote);
    try testing.expect(p.prepared);

    p.commitTransaction();
    try testing.expect(p.committed);
    try testing.expect(!p.aborted);
}

test "Participant: prepare and abort" {
    var p = Participant.init(1, 100);

    _ = p.prepare();

    p.abortTransaction();
    try testing.expect(p.aborted);
    try testing.expect(!p.committed);
}

test "Two-phase commit: full protocol" {
    var coord = Coordinator.init(1, 3, 1000);
    var participants: [3]Participant = undefined;

    // Initialize participants
    var i: u32 = 0;
    while (i < 3) : (i += 1) {
        participants[i] = Participant.init(i, 1);
    }

    // Phase 1: Prepare
    coord.prepare(100);

    i = 0;
    while (i < 3) : (i += 1) {
        const vote = participants[i].prepare();
        try coord.recordVote(i, vote);
    }

    // Phase 2: Commit
    try coord.decide();
    try testing.expectEqual(CoordinatorState.committed, coord.state);

    // Participants commit
    i = 0;
    while (i < 3) : (i += 1) {
        participants[i].commitTransaction();
        try testing.expect(participants[i].committed);
    }
}
