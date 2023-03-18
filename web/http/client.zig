const std = @import("std");

test "Status == 200" {
    const uri = std.Uri.parse("https://ziglang.org/") catch unreachable;
    var client: std.http.Client = .{ .allocator = std.testing.allocator };
    defer client.deinit();

    var req = try client.request(uri, .{}, .{});
    defer req.deinit();

    try std.testing.expect(req.response.headers.status == .ok);
}
