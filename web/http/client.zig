const std = @import("std");

test "Status == 200" {
    const uri = std.Uri.parse("https://ziglang.org") catch return error.UriParsingError;
    var client = std.http.Client{
        .allocator = std.testing.allocator,
    };
    defer client.deinit();
    var buffer: [4 * 1024]u8 = undefined;
    var req = try client.open(.GET, uri, .{
        .server_header_buffer = &buffer,
    });
    defer req.deinit();

    try req.send();
    try req.wait();

    try std.testing.expectEqual(req.response.status, .ok);
    try std.testing.expectEqual(req.response.version, .@"HTTP/1.1");
}
