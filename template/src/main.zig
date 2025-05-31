const sdl3 = @import("sdl3");
const std = @import("std");

/// This will be called once before anything else.
/// The argc/argv work like they always do.
/// If this returns `sdl3.AppResult.run`, the app runs.
/// If it returns `sdl3.AppResult.failure`, the app calls `SDL_AppQuit()` and terminates with an exit code that reports an error to the platform.
/// If it returns `sdl3.AppResult.success`, the app calls `SDL_AppQuit()` and terminates with an exit code that reports success to the platform.
/// This function should not go into an infinite mainloop; it should do any one-time startup it requires and then return.
///
/// If you want to, you can assign a pointer to `app_state`, and this pointer will be made available to you in later functions calls in their appstate parameter.
/// This allows you to avoid global variables, but is totally optional.
/// If you don't set this, the pointer will be `null` in later function calls.
///
/// App-implemented initial entry point for main callback apps.
///
/// ## Function Parameters
/// * `app_state`: A place where the app can optionally store a pointer for future use.
/// * `arg_count`: The standard ANSI C main's argc; number of elements in `arg_values`.
/// * `arg_values`: The standard ANSI C main's argv; array of command line arguments.
///
/// ## Return Value
/// Returns `sdl3.AppResult.failure` to terminate with an error, `sdl3.AppResult.success` to terminate with success, `sdl3.AppResult.run` to continue.
///
/// ## Remarks
/// Apps implement this function when using main callbacks.
/// If using a standard "main" function, you should not supply this.
///
/// This function is called by SDL once, at startup.
/// The function should initialize whatever is necessary, possibly create windows and open audio devices, etc.
/// The argc and argv parameters work like they would with a standard "main" function.
///
/// This function should not go into an infinite mainloop; it should do any one-time setup it requires and then return.
///
/// The app may optionally assign a pointer to `app_state`.
/// This pointer will be provided on every future call to the other entry points,
/// to allow application state to be preserved between functions without the app needing to use a global variable.
/// If this isn't set, the pointer will be `null` in future entry points.
///
/// If this function returns `sdl3.AppResult.run`, the app will proceed to normal operation,
/// and will begin receiving repeated calls to `SDL_AppIterate()` and `SDL_AppEvent()` for the life of the program.
/// If this function returns `sdl3.AppResult.failure`,
/// SDL will call `SDL_AppQuit()` and terminate the process with an exit code that reports an error to the platform.
/// If it returns `sdl3.AppResult.success`, SDL calls `SDL_AppQuit()` and terminates with an exit code that reports success to the platform.
///
/// This function is called by SDL on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub export fn SDL_AppInit(
    app_state: *?*anyopaque,
    arg_count: c_int,
    arg_values: [*][*:0]u8,
) callconv(.c) sdl3.AppResult {
    return init(@ptrCast(app_state), arg_values[0..@intCast(arg_count)]) catch return .failure;
}

/// This is called over and over, possibly at the refresh rate of the display or some other metric that the platform dictates.
/// This is where the heart of your app runs.
/// It should return as quickly as reasonably possible, but it's not a "run one memcpy and that's all the time you have" sort of thing.
/// The app should do any game updates, and render a frame of video.
/// If it returns `sdl3.AppResult.failure`, SDL will call `SDL_AppQuit()` and terminate the process with an exit code that reports an error to the platform.
/// If it returns `sdl3.AppResult.success`, the app calls `SDL_AppQuit()` and terminates with an exit code that reports success to the platform.
/// If it returns `sdl3.AppResult.run`, then `SDL_AppIterate()` will be called again at some regular frequency.
/// The platform may choose to run this more or less (perhaps less in the background, etc), or it might just call this function in a loop as fast as possible.
/// You do not check the event queue in this function (`SDL_AppEvent()` exists for that).
///
/// App-implemented iteration entry point for main callbacks apps.
///
/// ## Function Parameters
/// * `app_state`: An optional pointer, provided by the app in `SDL_AppInit()`.
///
/// ## Return Value
/// Returns `sdl3.AppResult.failure` to terminate with an error, `sdl3.AppResult.success` to terminate with success, `sdl3.AppResult.run` to continue.
///
/// ## Remarks
/// Apps implement this function when using main callbacks.
/// If using a standard "main" function, you should not supply this.
///
/// This function is called repeatedly by SDL after `SDL_AppInit()` returns `0`.
/// The function should operate as a single iteration the program's primary loop; it should update whatever state it needs and draw a new frame of video, usually.
///
/// On some platforms, this function will be called at the refresh rate of the display (which might change during the life of your app!).
/// There are no promises made about what frequency this function might run at.
/// You should use SDL's timer functions if you need to see how much time has passed since the last iteration.
///
/// There is no need to process the SDL event queue during this function; SDL will send events as they arrive in `SDL_AppEvent()`,
/// and in most cases the event queue will be empty when this function runs anyhow.
///
/// This function should not go into an infinite mainloop; it should do one iteration of whatever the program does and return.
///
/// The appstate parameter is an optional pointer provided by the app during `SDL_AppInit()`.
/// If the app never provided a pointer, this will be `null`.
///
/// If this function returns `sdl3.AppResult.run`, the app will continue normal operation,
/// receiving repeated calls to `SDL_AppIterate()` and `SDL_AppEvent()` for the life of the program.
/// If this function returns `sdl3.AppResult.failure`,
/// SDL will call `SDL_AppQuit() and terminate the process with an exit code that reports an error to the platform.
/// If it returns `sdl3.AppResult.success`, SDL calls `SDL_AppQuit()` and terminates with an exit code that reports success to the platform.
///
/// This function is called by SDL on the main thread.
///
/// ## Thread Safety
/// This function may get called concurrently with `SDL_AppEvent()` for events not pushed on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub export fn SDL_AppIterate(
    app_state: ?*anyopaque,
) callconv(.c) sdl3.AppResult {
    return iterate(@alignCast(@ptrCast(app_state))) catch return .failure;
}

/// This will be called whenever an SDL event arrives.
/// Your app should not call `events.poll()`, `events.pump()`, etc, as SDL will manage all this for you.
/// Return values are the same as from `SDL_AppIterate()`, so you can terminate in response to `events.Type.quit`, etc.
///
/// App-implemented event entry point for main callbacks apps.
///
/// ## Function Parameters
/// * `app_state`: An optional pointer provided by the app in `SDL_AppInit()`.
/// * `event`: The new event for the app to examine.
///
/// ## Return Value
/// Returns `AppResult.failure` to terminate with an error, `AppResult.success` to terminate with success, `AppResult.run` to continue.
///
/// ## Remarks
/// Apps implement this function when using main callbacks.
/// If using a standard "main" function, you should not supply this.
///
/// This function is called as needed by SDL after `SDL_AppInit()` returns `AppResult.run`.
/// It is called once for each new event.
///
/// There is (currently) no guarantee about what thread this will be called from; whatever thread pushes an event onto SDL's queue will trigger this function.
/// SDL is responsible for pumping the event queue between each call to `SDL_AppIterate()`, so in normal operation one should only get events in a serial fashion,
/// but be careful if you have a thread that explicitly calls `events.push()` SDL itself will push events to the queue on the main thread.
///
/// Events sent to this function are not owned by the app; if you need to save the data, you should copy it.
///
/// This function should not go into an infinite mainloop; it should handle the provided event appropriately and return.
///
/// The appstate parameter is an optional pointer provided by the app during `SDL_AppInit()`.
/// If the app never provided a pointer, this will be `null`.
///
/// If this function returns `AppResult.run`, the app will continue normal operation,
/// receiving repeated calls to `SDL_AppIterate()` and `SDL_AppEvent()` for the life of the program.
/// If this function returns `AppResult.failure`, SDL will call `SDL_AppQuit()` and terminate the process with an exit code that reports an error to the platform.
/// If it returns `AppResult.success`, SDL calls `SDL_AppQuit()` and terminates with an exit code that reports success to the platform.
///
/// ## Thread Safety
/// This function may get called concurrently with `SDL_AppIterate()` or `SDL_AppQuit()` for events not pushed from the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub export fn SDL_AppEvent(
    app_state: ?*anyopaque,
    event: *sdl3.c.SDL_Event,
) callconv(.c) sdl3.AppResult {
    return eventHandler(@alignCast(@ptrCast(app_state)), sdl3.events.Event.fromSdl(event.*)) catch return .failure;
}

/// This is called once before terminating the app--assuming the app isn't being forcibly killed or crashed--as a last chance to clean up.
/// After this returns, SDL will call `init.shutdown()` so the app doesn't have to (but it's safe for the app to call it, too).
/// Process termination proceeds as if the app returned normally from main(), so atexit handles will run, if your platform supports that.
///
/// If you set `app_state` during `SDL_AppInit()`, this is where you should free that data, as this pointer will not be provided to your app again.
///
/// The `SDL_AppResult` value that terminated the app is provided here, in case it's useful to know if this was a successful or failing run of the app.
///
/// App-implemented deinit entry point for main callbacks apps.
///
/// ## Function Parameters
/// * `app_state`: An optional pointer, provided by the app in `SDL_AppInit()`.
/// * `result`: The result code that terminated the app (success or failure).
///
/// ## Remarks
/// Apps implement this function when using main callbacks.
/// If using a standard "main" function, you should not supply this.
///
/// This function is called once by SDL before terminating the program.
///
/// This function will be called no matter what, even if `SDL_AppInit()` requests termination.
///
/// This function should not go into an infinite mainloop; it should deinitialize any resources necessary, perform whatever shutdown activities, and return.
///
/// You do not need to call `SDL_Quit()` in this function, as SDL will call it after this function returns and before the process terminates,
/// but it is safe to do so.
///
/// The appstate parameter is an optional pointer provided by the app during `SDL_AppInit()`.
/// If the app never provided a pointer, this will be `null`.
/// This function call is the last time this pointer will be provided, so any resources to it should be cleaned up here.
///
/// This function is called by SDL on the main thread.
///
/// ## Thread Safety
/// SDL_AppEvent() may get called concurrently with this function if other threads that push events are still active.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub export fn SDL_AppQuit(
    app_state: ?*anyopaque,
    result: sdl3.AppResult,
) callconv(.c) void {
    quit(@alignCast(@ptrCast(app_state)), result);
}

// =====================================================================================
// |                             Custom Application Code Here                          |
// =====================================================================================

// https://www.pexels.com/photo/green-trees-on-the-field-1630049/
const my_image = @embedFile("data/trees.jpeg");

const WINDOW_WIDTH = 640;
const WINDOW_HEIGHT = 480;

// Disable main hack.
pub const _start = void;
pub const WinMainCRTStartup = void;

/// Allocator we will use.
/// You probably want a different one for your applications.
const allocator = std.heap.c_allocator;

/// For logging system messages.
const log_app = sdl3.log.Category.application;

/// Sample structure to use to hold our app state.
const AppState = struct {
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
///
/// ## Remarks
/// Since SDL's logging callbacks must be C-compatible, you may have to wrap the `category` and `priority` to managed types for convenience.
fn sdlLog(
    user_data: ?*anyopaque,
    category: c_int,
    priority: sdl3.c.SDL_LogPriority,
    message: [*c]const u8,
) callconv(.c) void {
    _ = user_data;
    const category_managed = sdl3.log.Category.fromSdl(category);
    const category_str: ?[]const u8 = if (category_managed) |val| switch (val.value) {
        sdl3.log.Category.application.value => "Application",
        sdl3.log.Category.errors.value => "Errors",
        sdl3.log.Category.assert.value => "Assert",
        sdl3.log.Category.system.value => "System",
        sdl3.log.Category.audio.value => "Audio",
        sdl3.log.Category.video.value => "Video",
        sdl3.log.Category.render.value => "Render",
        sdl3.log.Category.input.value => "Input",
        sdl3.log.Category.testing.value => "Testing",
        sdl3.log.Category.gpu.value => "Gpu",
        else => null,
    } else null;
    const priority_managed = sdl3.log.Priority.fromSdl(priority);
    const priority_str: [:0]const u8 = if (priority_managed) |val| switch (val) {
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
    } else {
        std.debug.print("[Custom_{d}:{s}] {s}\n", .{ category, priority_str, message });
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
fn init(
    app_state: *?*AppState,
    args: [][*:0]u8,
) !sdl3.AppResult {
    _ = args;

    // Setup logging.
    sdl3.errors.error_callback = &sdlErr;
    sdl3.log.setAllPriorities(.info);
    sdl3.log.setLogOutputFunction(&sdlLog, null);

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
    const tree_tex = try sdl3.image.loadTextureIo(
        window_renderer.renderer,
        try sdl3.io_stream.Stream.initFromConstMem(my_image),
        true,
    );
    errdefer tree_tex.deinit();

    // Prove error handling works.
    const dummy: ?sdl3.video.Window = sdl3.video.Window.fromID(99999) catch null;
    _ = dummy;

    // Set app state.
    state.* = .{
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
fn iterate(
    app_state: *AppState,
) !sdl3.AppResult {
    try app_state.renderer.setDrawColor(.{ .r = 128, .g = 30, .b = 255 });
    try app_state.renderer.clear();
    const border = 10;
    try app_state.renderer.renderTexture(app_state.tree_tex, null, .{
        .x = border,
        .y = border,
        .w = WINDOW_WIDTH - border * 2,
        .h = WINDOW_HEIGHT - border * 2,
    });
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
fn eventHandler(
    app_state: *AppState,
    event: sdl3.events.Event,
) !sdl3.AppResult {
    _ = app_state;
    switch (event) {
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
fn quit(
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
