//! Reference: https://github.com/ziglang/zig/pull/14920
//! by: https://github.com/bwesterb

test "HTTPS Client - X25519+Kyber768Draft00" {
    var buf: [1000]u8 = undefined;
    var header_buf: [8192]u8 = undefined;
    const uri = try std.Uri.parse("https://cloudflare.com/cdn-cgi/trace");
    var client = std.http.Client{
        .allocator = testing.allocator,
    };
    defer client.deinit();

    var req = try client.open(.POST, uri, .{
        .server_header_buffer = &header_buf,
    });
    defer req.deinit();
    try req.send();
    try req.wait();
    const read = try req.read(&buf);

    var strings = std.mem.splitAny(u8, buf[0..read], "\n");
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
            try testing.expectEqualStrings("uag=zig/0.13.0 (std.http)", content);
        // zig master/nightly change per build (e.g.: zig/0.11.0-dev.2868+1a455b2dd (std.http))
        if (startW(u8, content, "tls="))
            try testing.expectEqualStrings("tls=TLSv1.3", content);
    }
}

const std = @import("std");
const testing = std.testing;
const startW = std.mem.startsWith;
