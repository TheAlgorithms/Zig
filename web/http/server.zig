//! ref: https://github.com/ziglang/zig/blob/master/lib/std/http/test.zig
//! ref: https://ziglang.org/download/0.12.0/release-notes.html#Reworked-HTTP

const std = @import("std");
const expect = std.testing.expect;

test "client requests server" {
    const builtin = @import("builtin");

    // This test requires spawning threads.
    if (builtin.single_threaded) {
        return error.SkipZigTest;
    }

    const native_endian = comptime builtin.cpu.arch.endian();
    if (builtin.zig_backend == .stage2_llvm and native_endian == .big) {
        // https://github.com/ziglang/zig/issues/13782
        return error.SkipZigTest;
    }

    if (builtin.os.tag == .wasi) return error.SkipZigTest;

    // Start Server
    const address = try std.net.Address.parseIp4("127.0.0.1", 0);

    var http_server = try address.listen(.{
        .reuse_port = true,
    });
    const server_port = http_server.listen_address.getPort();
    defer http_server.deinit();

    const server_thread = try std.Thread.spawn(.{}, (struct {
        fn apply(s: *std.net.Server) !void {
            const connection = try s.accept();
            defer connection.stream.close();

            var read_buffer: [8000]u8 = undefined;
            var server = std.http.Server.init(connection, &read_buffer);

            var request = try server.receiveHead();

            // Accept request
            const reader = try request.reader();
            var buffer: [100]u8 = undefined;
            const read_num = try reader.readAll(&buffer);
            try std.testing.expectEqualStrings(buffer[0..read_num], "Hello, World!\n");

            // Respond
            const server_body: []const u8 = "message from server!\n";
            try request.respond(server_body, .{
                .keep_alive = false,
                .extra_headers = &.{
                    .{ .name = "content-type", .value = "text/plain" },
                },
            });
        }
    }).apply, .{&http_server});
    defer server_thread.join();

    // Make requests to server

    var client = std.http.Client{
        .allocator = std.testing.allocator,
    };
    defer client.deinit();
    const uri = uri: {
        const uri_size = comptime std.fmt.count("http://127.0.0.1:{d}", .{std.math.maxInt(u16)});
        var uri_buf: [uri_size]u8 = undefined;
        const uri = try std.Uri.parse(try std.fmt.bufPrint(&uri_buf, "http://127.0.0.1:{d}", .{server_port}));
        break :uri uri;
    };

    var buffer: [4 * 1024]u8 = undefined;
    var req = try client.open(.POST, uri, .{
        .server_header_buffer = &buffer,
    });
    req.transfer_encoding = .{ .content_length = 14 };
    defer req.deinit();

    try req.send();
    try req.writeAll("Hello, ");
    try req.writeAll("World!\n");
    try req.finish();

    try req.wait();

    var read_buffer: [100]u8 = undefined;
    const read_num = try req.readAll(&read_buffer);

    try std.testing.expectEqualStrings(read_buffer[0..read_num], "message from server!\n");
}
