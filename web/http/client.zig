const std = @import("std");

test "Status == 200" {
    const uri = std.Uri.parse("https://ziglang.org") catch return error.UriParsingError;
    var client = std.http.Client{
        .allocator = std.testing.allocator,
    };
    defer client.deinit();

    var req = try client.request(.GET, uri, .{});
    defer req.deinit();

    try req.sendBodiless();
    const response = try req.receiveHead(&.{});

    try std.testing.expectEqual(response.head.status, .ok);
    try std.testing.expectEqual(response.head.version, .@"HTTP/1.1");
}
