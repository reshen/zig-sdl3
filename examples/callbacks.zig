const sdl3 = @import("sdl3");
const std = @import("std");

const allocator = std.heap.smp_allocator;

const SCREEN_WIDTH = 640;
const SCREEN_HEIGHT = 480;

const AppState = struct {
    window: sdl3.video.Window,
};

fn init(
    app_state: *?*AppState,
    args: [][*:0]u8,
) !sdl3.AppResult {
    const window = try sdl3.video.Window.init(std.mem.span(args[0]), SCREEN_WIDTH, SCREEN_HEIGHT, .{});
    errdefer window.deinit();

    const state = try allocator.create(AppState);
    state.* = .{
        .window = window,
    };
    app_state.* = state;
    return .run;
}

fn iterate(
    app_state: ?*AppState,
) !sdl3.AppResult {
    const state = app_state orelse return .failure;

    const surface = try state.window.getSurface();
    try surface.fillRect(null, surface.mapRgb(128, 30, 255));
    try state.window.updateSurface();
    return .run;
}

fn event(
    app_state: ?*AppState,
    curr_event: sdl3.events.Event,
) !sdl3.AppResult {
    _ = app_state;

    return switch (curr_event) {
        .quit => .success,
        .terminating => .success,
        else => .run,
    };
}

fn quit(
    app_state: ?*AppState,
    result: sdl3.AppResult,
) void {
    _ = result;
    if (app_state) |state| {
        state.window.deinit();
        allocator.destroy(state);
    }
}

pub fn main() u8 {
    sdl3.main_funcs.setMainReady();
    var args = [_:null]?[*:0]u8{
        @constCast("Hello SDL3"),
    };
    return sdl3.main_funcs.enterAppMainCallbacks(&args, AppState, init, iterate, event, quit);
}
