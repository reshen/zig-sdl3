const sdl3 = @import("sdl3");
const std = @import("std");

/// https://en.wikipedia.org/wiki/Ephemeral_port
/// > suggested by RFC 6335 and the Internet Assigned Numbers Authority (IANA) for dynamic or private ports. FreeBSD has used the IANA port range since release 4.6. Windows Vista, Windows 7, and Server 2008 use the IANA range by default.
const iana_dynamic_port_start: u16 = 49152;
const iana_dynamic_port_end: u16 = 65535;
/// Timeout in milliseconds for network operations that might block.
const timeout_ms: u32 = 5000;
const server_poll_timeout_ms: u32 = 100;

var server_should_stop: bool = false;
var server_ready_sem = std.Thread.Semaphore{ .permits = 0 };

fn serverThread(allocator: std.mem.Allocator, sem: *std.Thread.Semaphore, port: u16) !void {
    const out = std.io.getStdOut().writer();
    const server: sdl3.net.Server = try .init(null, port);
    defer server.deinit();
    try out.print("Server listening on port {d}\n", .{port});

    // Signal that the server is ready to accept connections.
    sem.post();

    while (!server_should_stop) {
        const sockets = &.{sdl3.net.Pollable{ .server = server }};
        const num_ready = try sdl3.net.waitUntilInputAvailable(allocator, sockets, .{ .milliseconds = server_poll_timeout_ms });
        if (num_ready > 0) {

            // A client is trying to connect.
            if (try server.accept()) |client_socket| {
                defer client_socket.deinit();

                const client_addr = try client_socket.getAddress();
                defer client_addr.deinit();

                try out.print("Server: Client connected from {s}\n", .{client_addr.getString() orelse "unknown"});

                // Wait for the client to send us a message.
                const num_client_ready = try sdl3.net.waitUntilInputAvailable(allocator, &.{sdl3.net.Pollable{ .stream = client_socket }}, .indefinite);

                if (num_client_ready > 0) {
                    var buffer: [1024]u8 = undefined;
                    const bytes_read = try client_socket.read(&buffer);

                    if (bytes_read > 0) {
                        try out.print("Server: Received '{s}'\n", .{buffer[0..bytes_read]});

                        // Send a reply.
                        try client_socket.write("Hello from server!");

                        // Wait until the data is sent before we risk closing the socket via defer.
                        _ = try client_socket.waitUntilDrained(.{ .milliseconds = timeout_ms });
                        try out.print("Server: Sent reply.\n", .{});
                    } else {
                        try out.print("Server: Client disconnected.\n", .{});
                    }
                } else {
                    try out.print("Server: Timed out waiting for data from client.\n", .{});
                }
            }
        }
    }
    try out.print("Server shutting down.\n", .{});
}

fn clientThread(allocator: std.mem.Allocator, port: u16) !void {
    const out = std.io.getStdOut().writer();

    const address: sdl3.net.Address = try .init("127.0.0.1");
    defer address.deinit();

    try out.print("Client: Resolving '127.0.0.1'\n", .{});
    if (!try address.waitUntilResolved(.{ .milliseconds = timeout_ms })) {
        try out.print("Client: Failed to resolve '127.0.0.1'.\n", .{});
        return;
    }
    try out.print("Client: Resolved to {s}\n", .{address.getString() orelse "unknown"});

    // Connect to the server.
    const client_socket: sdl3.net.StreamSocket = try .initClient(address, port);
    defer client_socket.deinit();

    try out.print("Client: Connecting\n", .{});
    if (!try client_socket.waitUntilConnected(.{ .milliseconds = timeout_ms })) {
        try out.print("Client: Failed to connect to server.\n", .{});
        return;
    }
    try out.print("Client: Connected\n", .{});

    // Send a message.
    try client_socket.write("Hello from client!");
    try out.print("Client: Sent message.\n", .{});

    // Wait for a reply.
    const num_ready = try sdl3.net.waitUntilInputAvailable(allocator, &.{sdl3.net.Pollable{ .stream = client_socket }}, .{ .milliseconds = timeout_ms });

    if (num_ready > 0) {
        var buffer: [1024]u8 = undefined;
        const bytes_read = try client_socket.read(&buffer);

        if (bytes_read > 0) {
            try out.print("Client: Received '{s}'\n", .{buffer[0..bytes_read]});
        } else {
            try out.print("Client: Server closed connection.\n", .{});
        }
    } else {
        try out.print("Client: Timed out waiting for a reply.\n", .{});
    }
    try out.print("Client shutting down.\n", .{});
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const out = std.io.getStdOut().writer();

    try sdl3.init(.{});
    defer sdl3.quit(.{});
    try sdl3.net.init();
    defer sdl3.net.quit();

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        std.crypto.random.bytes(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();
    const port_range = iana_dynamic_port_end - iana_dynamic_port_start;
    const port = rand.uintAtMost(u16, port_range) + iana_dynamic_port_start;

    try out.print("SDL_net version: {}\n", .{sdl3.net.getVersion()});

    var server_thread: std.Thread = try .spawn(.{}, serverThread, .{ allocator, &server_ready_sem, port });

    // Wait for the server to signal that it's ready before starting the client.
    server_ready_sem.wait();
    var client_thread: std.Thread = try .spawn(.{}, clientThread, .{ allocator, port });

    client_thread.join();
    server_should_stop = true;
    server_thread.join();

    try out.print("Example finished.\n", .{});
}
