//! Reference: https://github.com/ziglang/zig/pull/14920
//! by: https://github.com/bwesterb

test "HTTPS Client - X25519+Kyber768Draft00" {
    const uri = try std.Uri.parse("https://cloudflare.com/cdn-cgi/trace");
    var client = std.http.Client{
        .allocator = testing.allocator,
    };
    defer client.deinit();

    var req = try client.request(.GET, uri, .{
        .headers = .{
            .accept_encoding = .{ .override = "text/plain" },
        },
    });
    defer req.deinit();

    try req.sendBodiless();
    var response = try req.receiveHead(&.{});

    var reader_buffer: [1000]u8 = undefined;
    const body_reader = response.reader(&reader_buffer);
    const body = try body_reader.allocRemaining(testing.allocator, .unlimited);
    defer testing.allocator.free(body);

    var strings = std.mem.splitAny(u8, body, "\n");
    var index = strings.index.?;
    while (index < strings.rest().len) : (index += 1) {
        const content = strings.next().?;
        if (startW(u8, content, "h="))
            try testing.expectEqualStrings("h=cloudflare.com", content);
        if (startW(u8, content, "visit_scheme="))
            try testing.expectEqualStrings("visit_scheme=https", content);
        if (startW(u8, content, "http="))
            try testing.expectEqualStrings("http=http/1.1", content);
        if (startW(u8, content, "uag="))
            try testing.expectEqualStrings("uag=zig/" ++ zig_version_string ++ " (std.http)", content);
        if (startW(u8, content, "tls="))
            try testing.expectEqualStrings("tls=TLSv1.3", content);
    }
}

const std = @import("std");
const testing = std.testing;
const startW = std.mem.startsWith;
const zig_version_string = @import("builtin").zig_version_string;
