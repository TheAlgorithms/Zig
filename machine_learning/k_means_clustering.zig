const KMeansError = error{SmallK};

const Point2D = struct {
    x: f32,
    y: f32,
    const zero: Point2D = .{ .x = 0, .y = 0 };
    fn eq(self: Point2D, other: Point2D) bool {
        return self.x == other.x and self.y == other.y;
    }
    fn add(self: Point2D, other: Point2D) Point2D {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }
    fn div(self: Point2D, scalar: f32) Point2D {
        return .{ .x = self.x / scalar, .y = self.y / scalar };
    }
};
const Cluster = struct {
    point: Point2D,
    count: usize,
    const zero: Cluster = .{ .point = .zero, .count = 0 };
    fn eq(self: Cluster, other: Cluster) bool {
        return self.point.eq(other.point) and self.count == other.count;
    }
};

fn distanceSquared(a: Point2D, b: Point2D) f32 {
    const y = a.y - b.y;
    const x = a.x - b.x;
    return x * x + y * y;
}

fn calculateNearest(point: Point2D, clusters: anytype) usize {
    var min_distance = distanceSquared(point, clusters[0].point);
    var closest_cluster_idx: usize = 0;
    for (1..clusters.len) |cluster_idx| {
        const distance = distanceSquared(clusters[cluster_idx].point, point);
        if (distance < min_distance) {
            min_distance = distance;
            closest_cluster_idx = cluster_idx;
        }
    }
    return closest_cluster_idx;
}

pub fn KMeans(data: []const Point2D, comptime k: usize) ![k]Cluster {
    if (data.len < k) {
        return KMeansError.SmallK;
    }
    // assign clusters to different data points
    var old_clusters: [k]Cluster = undefined;
    for (0..old_clusters.len) |i| {
        old_clusters[i].point = data[i];
        old_clusters[i].count = 0;
    }
    while (true) {
        var new_clusters: [k]Cluster = .{Cluster.zero} ** k;
        for (data) |point| {
            const cluster_idx = calculateNearest(point, old_clusters);
            const new = &new_clusters[cluster_idx];
            new.point = new.point.add(point);
            new.count += 1;
        }
        for (&new_clusters) |*cluster| {
            const count_as_f32: f32 = @floatFromInt(cluster.count);
            cluster.point = cluster.point.div(count_as_f32);
        }
        check_equal: {
            for (old_clusters, new_clusters) |old, new| {
                if (!old.eq(new)) {
                    break :check_equal;
                }
            }
            return new_clusters;
        }
        old_clusters = new_clusters;
    }
}

const std = @import("std");
const expectEqual = std.testing.expectEqual;
test "Kmeans" {
    try expectEqual(
        [_]Cluster{
            .{ .point = .{ .x = 34.0, .y = 34.0 }, .count = 1 },
        },
        try KMeans(
            &[_]Point2D{
                .{ .x = 34.0, .y = 34.0 },
            },
            1,
        ),
    );
    try expectEqual(
        [_]Cluster{
            .{ .point = .{ .x = 33.0, .y = 33.0 }, .count = 2 },
        },
        try KMeans(
            &[_]Point2D{
                .{ .x = 33.0, .y = 33.0 },
                .{ .x = 33.0, .y = 33.0 },
            },
            1,
        ),
    );
    try expectEqual(
        [_]Cluster{
            .{ .point = .{ .x = 33.0, .y = 34.0 }, .count = 2 },
        },
        try KMeans(
            &[_]Point2D{
                .{ .x = 32.0, .y = 33.0 },
                .{ .x = 34.0, .y = 35.0 },
            },
            1,
        ),
    );
    try expectEqual(
        [_]Cluster{
            .{ .point = .{ .x = 0.0, .y = 0.5 }, .count = 3 },
            .{ .point = .{ .x = 2.0, .y = 0.5 }, .count = 3 },
        },
        try KMeans(
            &[_]Point2D{
                .{ .x = 0.0, .y = 1.0 },
                .{ .x = 2.0, .y = 1.0 },
                .{ .x = 0.0, .y = 0.5 },
                .{ .x = 0.0, .y = 0.0 },
                .{ .x = 2.0, .y = 0.5 },
                .{ .x = 2.0, .y = 0.0 },
            },
            2,
        ),
    );
}
