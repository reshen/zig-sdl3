const sdl3 = @import("sdl3");
const std = @import("std");

// Use main callbacks.
comptime {
    _ = sdl3.main_callbacks;
}

// https://www.pexels.com/photo/green-trees-on-the-field-1630049/
const my_image = @embedFile("data/trees.jpeg");

const FPS = 60;
const WINDOW_WIDTH = 640;
const WINDOW_HEIGHT = 480;

// Disable main hack.
pub const _start = void;
pub const WinMainCRTStartup = void;

/// Allocator we will use.
const allocator = std.heap.smp_allocator;

/// For logging system messages.
const log_app = sdl3.log.Category.application;

/// Sample structure to use to hold our app state.
const AppState = struct {
    frame_capper: sdl3.extras.FramerateCapper(f32),
    window: sdl3.video.Window,
    renderer: sdl3.render.Renderer,
    tree_tex: sdl3.render.Texture,
};

/// An example function to handle errors from SDL.
///
/// ## Function Parameters
/// * `err`: A slice to an error message, or `null` if the error message is not known.
///
/// ## Remarks
/// Remember that the error callback is thread-local, thus you need to set it for each thread!
fn sdlErr(
    err: ?[]const u8,
) void {
    if (err) |val| {
        std.debug.print("******* [Error! {s}] *******\n", .{val});
    } else {
        std.debug.print("******* [Unknown Error!] *******\n", .{});
    }
}

/// An example function to log with SDL.
///
/// ## Function Parameters
/// * `user_data`: User data provided to the logging function.
/// * `category`: Which category SDL is logging under, for example "video".
/// * `priority`: Which priority the log message is.
/// * `message`: Actual message to log. This should not be `null`.
fn sdlLog(
    user_data: ?*void,
    category: ?sdl3.log.Category,
    priority: ?sdl3.log.Priority,
    message: [:0]const u8,
) void {
    _ = user_data;
    const category_str: ?[]const u8 = if (category) |val| switch (val) {
        .application => "Application",
        .errors => "Errors",
        .assert => "Assert",
        .system => "System",
        .audio => "Audio",
        .video => "Video",
        .render => "Render",
        .input => "Input",
        .testing => "Testing",
        .gpu => "Gpu",
        else => null,
    } else null;
    const priority_str: [:0]const u8 = if (priority) |val| switch (val) {
        .trace => "Trace",
        .verbose => "Verbose",
        .debug => "Debug",
        .info => "Info",
        .warn => "Warn",
        .err => "Error",
        .critical => "Critical",
    } else "Unknown";
    if (category_str) |val| {
        std.debug.print("[{s}:{s}] {s}\n", .{ val, priority_str, message });
    } else if (category) |val| {
        std.debug.print("[Custom_{d}:{s}] {s}\n", .{ @intFromEnum(val), priority_str, message });
    } else {
        std.debug.print("Unknown:{s}] {s}\n", .{ priority_str, message });
    }
}

/// Do our initialization logic here.
///
/// ## Function Parameters
/// * `app_state`: Where to store a pointer representing the state to use for the application.
/// * `args`: Slice of arguments provided to the application.
///
/// ## Return Value
/// Returns if the app should continue running, or result in success or failure.
///
/// ## Remarks
/// Note that for further callbacks (except for `quit()`), we assume that we did end up setting `app_state`.
/// If this function does not return `AppResult.run` or errors, then `quit()` will be invoked.
/// Do not worry about logging errors from SDL yourself and just use `try` and `catch` as you please.
/// If you set the error callback for every thread, then zig-sdl3 will be automatically logging errors.
pub fn init(
    app_state: *?*AppState,
    args: [][*:0]u8,
) !sdl3.AppResult {
    _ = args;

    // Setup logging.
    sdl3.errors.error_callback = &sdlErr;
    sdl3.log.setAllPriorities(.info);
    sdl3.log.setLogOutputFunction(void, &sdlLog, null);

    try log_app.logInfo("Starting application...", .{});

    // Prepare app state.
    const state = try allocator.create(AppState);
    errdefer allocator.destroy(state);

    // Setup initial data.
    const window_renderer = try sdl3.render.Renderer.initWithWindow(
        "Hello SDL3",
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        .{},
    );
    errdefer window_renderer.renderer.deinit();
    errdefer window_renderer.window.deinit();
    var frame_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .unlimited = {} } };
    window_renderer.renderer.setVSync(.{ .adaptive = {} }) catch {

        // We don't want to run at unlimited FPS, cap frame rate to the default FPS if vsync is not available so we don't burn CPU time.
        frame_capper.mode = .{ .limited = FPS };
    };
    const tree_tex = try sdl3.image.loadTextureIo(
        window_renderer.renderer,
        try sdl3.io_stream.Stream.initFromConstMem(my_image),
        true,
    );
    errdefer tree_tex.deinit();

    // Prove error handling works.
    const dummy: ?sdl3.video.Window = sdl3.video.Window.fromId(99999) catch null;
    _ = dummy;

    // Set app state.
    state.* = .{
        .frame_capper = frame_capper,
        .window = window_renderer.window,
        .renderer = window_renderer.renderer,
        .tree_tex = tree_tex,
    };
    app_state.* = state;

    try log_app.logInfo("Finished initializing", .{});
    return .run;
}

/// Do our render and update logic here.
///
/// ## Function Parameters
/// * `app_state`: Application state set from `init()`.
///
/// ## Return Value
/// Returns if the app should continue running, or result in success or failure.
///
/// ## Remarks
/// If this function does not return `AppResult.run` or errors, then `quit()` will be invoked.
/// We assume that `app_state` was set by `init()`.
/// If this function takes too long, your application will lag.
pub fn iterate(
    app_state: *AppState,
) !sdl3.AppResult {
    const dt = app_state.frame_capper.delay();
    _ = dt; // We don't need dt for this example, but might be useful to you.

    // Draw main scene.
    try app_state.renderer.setDrawColor(.{ .r = 128, .g = 30, .b = 255, .a = 255 });
    try app_state.renderer.clear();
    const border = 10;
    try app_state.renderer.renderTexture(app_state.tree_tex, null, .{
        .x = border,
        .y = border,
        .w = WINDOW_WIDTH - border * 2,
        .h = WINDOW_HEIGHT - border * 2,
    });
    try app_state.renderer.setDrawColor(.{ .r = 0, .g = 0, .b = 0, .a = 255 });

    // Draw debug FPS.
    var fps_text_buf: [32]u8 = undefined;
    const fps_text = std.fmt.bufPrintZ(&fps_text_buf, "FPS: {d}", .{app_state.frame_capper.getObservedFps()}) catch "[Err]";
    try app_state.renderer.renderDebugText(.{ .x = 0, .y = 0 }, fps_text);

    // Finish and return.
    try app_state.renderer.present();
    return .run;
}

/// Handle events here.
///
/// ## Function Parameter
/// * `app_state`: Application state set from `init()`.
/// * `event`: Event that the application has just received.
///
/// ## Return Value
/// Returns if the app should continue running, or result in success or failure.
///
/// ## Remarks
/// If this function does not return `AppResult.run` or errors, then `quit()` will be invoked.
/// We assume that `app_state` was set by `init()`.
/// If this function takes too long, your application will lag.
pub fn event(
    app_state: *AppState,
    curr_event: sdl3.events.Event,
) !sdl3.AppResult {
    _ = app_state;
    switch (curr_event) {
        .terminating => return .success,
        .quit => return .success,
        else => {},
    }
    return .run;
}

/// Quit logic here.
///
/// ## Function Parameters
/// * `app_state`: Application state if it was set by `init()`, or `null` if `init()` did not set it (because of say an error).
/// * `result`: Result indicating the success of the application. Should never be `AppResult.run`.
///
/// ## Remarks
/// Make sure you clean up any resources here.
/// Or don't the OS would take care of it anyway but any leak detection you use will yell at you :>
pub fn quit(
    app_state: ?*AppState,
    result: sdl3.AppResult,
) void {
    _ = result;
    if (app_state) |val| {
        val.tree_tex.deinit();
        val.renderer.deinit();
        val.window.deinit();
        allocator.destroy(val);
    }
}
