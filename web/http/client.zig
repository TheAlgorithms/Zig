const std = @import("std");

test "Status == 200" {
    const uri = std.Uri.parse("https://ziglang.org") catch unreachable;
    var client: std.http.Client = .{ .allocator = std.testing.allocator };
    defer client.deinit();
    var h = std.http.Headers{ .allocator = std.testing.allocator };
    defer h.deinit();

    var req = try client.request(.GET, uri, h, .{});
    defer req.deinit();
    try req.start(); // start request
    try req.wait(); // wait response
    try std.testing.expect(req.response.status == .ok);
    try std.testing.expect(req.response.version == .@"HTTP/1.1");
}
