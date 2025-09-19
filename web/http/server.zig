//! ref: https://github.com/ziglang/zig/blob/master/lib/std/http/test.zig
//! ref: https://ziglang.org/download/0.15.1/release-notes.html#HTTP-Client-and-Server

const std = @import("std");
const expect = std.testing.expect;

test "client requests server" {
    const builtin = @import("builtin");

    const allocator = std.testing.allocator;

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
        .reuse_address = true,
    });
    const server_port = http_server.listen_address.getPort();
    defer http_server.deinit();

    const server_thread = try std.Thread.spawn(.{}, (struct {
        fn apply(s: *std.net.Server) !void {
            const connection = try s.accept();
            defer connection.stream.close();

            var recv_buffer: [4000]u8 = undefined;
            var sead_buffer: [4000]u8 = undefined;
            var conn_reader = connection.stream.reader(&recv_buffer);
            var conn_writer = connection.stream.writer(&sead_buffer);
            var server = std.http.Server.init(conn_reader.interface(), &conn_writer.interface);

            var request = try server.receiveHead();

            // Accept request
            var reader = try request.readerExpectContinue(&.{});
            const body = try reader.allocRemaining(allocator, .unlimited);
            defer allocator.free(body);

            try std.testing.expectEqualStrings(body, "Hello, World!\n");

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
        .allocator = allocator,
    };
    defer client.deinit();
    const uri = uri: {
        const uri_size = comptime std.fmt.count("http://127.0.0.1:{d}", .{std.math.maxInt(u16)});
        var uri_buf: [uri_size]u8 = undefined;
        const uri = try std.Uri.parse(try std.fmt.bufPrint(&uri_buf, "http://127.0.0.1:{d}", .{server_port}));
        break :uri uri;
    };

    var req = try client.request(.POST, uri, .{});
    req.transfer_encoding = .{ .content_length = 14 };
    defer req.deinit();

    var body_writer = try req.sendBody(&.{});

    try body_writer.writer.writeAll("Hello, ");
    try body_writer.writer.writeAll("World!\n");
    try body_writer.end();

    var response = try req.receiveHead(&.{});
    const body = try response.reader(&.{}).allocRemaining(allocator, .unlimited);
    defer allocator.free(body);

    try std.testing.expectEqualStrings(body, "message from server!\n");
}
