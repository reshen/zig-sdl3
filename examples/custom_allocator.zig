const sdl3 = @import("sdl3");
const std = @import("std");

const fps = 60;
const screen_width = 640;
const screen_height = 480;

var debug = std.heap.DebugAllocator(.{}).init;

pub fn main() !void {
    defer sdl3.shutdown();

    // Setup custom allocator.
    const allocator = debug.allocator();
    try sdl3.setMemoryFunctionsByAllocator(allocator);

    // Initialize SDL with subsystems you need here.
    const init_flags = sdl3.InitFlags{ .video = true };
    try sdl3.init(init_flags);
    defer sdl3.quit(init_flags);

    // Initial window setup.
    const window = try sdl3.video.Window.init("Hello SDL3", screen_width, screen_height, .{});
    defer window.deinit();

    // Useful for limiting the FPS and getting the delta time.
    var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .limited = fps } };

    while (true) {

        // Update logic.
        const surface = try window.getSurface();
        try surface.fillRect(null, surface.mapRgb(128, 30, 255));
        try window.updateSurface();

        // Event logic.
        if (sdl3.events.poll()) |event|
            switch (event) {
                .quit => break,
                .terminating => break,
                else => {},
            };

        // Delay to limit the FPS, returned delta time not needed.
        _ = fps_capper.delay();
    }

    // Prove no leaks.
    _ = debug.detectLeaks();
}
