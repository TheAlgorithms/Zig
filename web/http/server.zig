//! ref: https://github.com/ziglang/zig/blob/master/lib/std/http/test.zig
//! ref: https://ziglang.org/download/0.15.1/release-notes.html#HTTP-Client-and-Server

const std = @import("std");
const Io = std.Io;
const net = Io.net;
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
    const io = std.testing.io;
    const address = try net.IpAddress.parseIp4("127.0.0.1", 0);

    var http_server = try address.listen(io, .{
        .reuse_address = true,
    });
    const server_port = net.IpAddress.getPort(http_server.socket.address);
    defer http_server.deinit(io);

    const server_thread = try std.Thread.spawn(.{}, (struct {
        fn apply(s: *net.Server, srv_io: Io) !void {
            const connection = try s.accept(srv_io);
            defer connection.close(srv_io);

            var recv_buffer: [4000]u8 = undefined;
            var sead_buffer: [4000]u8 = undefined;
            var conn_reader = net.Stream.reader(connection, srv_io, &recv_buffer);
            var conn_writer = net.Stream.writer(connection, srv_io, &sead_buffer);
            var server = std.http.Server.init(&conn_reader.interface, &conn_writer.interface);

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
    }).apply, .{ &http_server, io });
    defer server_thread.join();

    // Make requests to server

    var client = std.http.Client{
        .allocator = allocator,
        .io = io,
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
