const c = @import("c.zig").c;
const errors = @import("errors.zig");
const std = @import("std");
const stdinc = @import("stdinc.zig");

/// Callback run on the main thread.
///
/// ## Function Parameters
/// * `user_data`: An app-controlled pointer that is passed to the callback.
///
/// ## Versions
/// This datatype is available since SDL 3.2.0.
pub const MainThreadCallback = *const fn (
    user_data: ?*anyopaque,
) callconv(.c) void;

/// These are the flags which may be passed to `init.init()`.
///
/// ## Remarks
/// You should specify the subsystems which you will be using in your application.
///
/// ## Version
/// This datatype is available since SDL 3.2.0.
pub const Flags = struct {
    /// Implies `events`.
    audio: bool = false,
    /// Implies `events`, should be initialized on the main thread.
    video: bool = false,
    /// Implies `events`, should be initialized on the same thread as `video` on Windows if you don't set the `joystick_thread` hint.
    joystick: bool = false,
    haptic: bool = false,
    /// Implies `joystick`.
    gamepad: bool = false,
    events: bool = false,
    /// Implies `events`.
    sensor: bool = false,
    /// Implies `events`.
    camera: bool = false,
    /// Initializes all subsystems.
    pub const everything = Flags{
        .audio = true,
        .video = true,
        .joystick = true,
        .haptic = true,
        .gamepad = true,
        .events = true,
        .sensor = true,
        .camera = true,
    };

    /// Convert from an SDL value.
    pub fn fromSdl(flags: c.SDL_InitFlags) Flags {
        return .{
            .audio = (flags & c.SDL_INIT_AUDIO) != 0,
            .video = (flags & c.SDL_INIT_VIDEO) != 0,
            .joystick = (flags & c.SDL_INIT_JOYSTICK) != 0,
            .haptic = (flags & c.SDL_INIT_HAPTIC) != 0,
            .gamepad = (flags & c.SDL_INIT_GAMEPAD) != 0,
            .events = (flags & c.SDL_INIT_EVENTS) != 0,
            .sensor = (flags & c.SDL_INIT_SENSOR) != 0,
            .camera = (flags & c.SDL_INIT_CAMERA) != 0,
        };
    }

    /// Convert to an SDL value.
    pub fn toSdl(self: Flags) c.SDL_InitFlags {
        return (if (self.audio) @as(c.SDL_InitFlags, c.SDL_INIT_AUDIO) else 0) |
            (if (self.video) @as(c.SDL_InitFlags, c.SDL_INIT_VIDEO) else 0) |
            (if (self.joystick) @as(c.SDL_InitFlags, c.SDL_INIT_JOYSTICK) else 0) |
            (if (self.haptic) @as(c.SDL_InitFlags, c.SDL_INIT_HAPTIC) else 0) |
            (if (self.gamepad) @as(c.SDL_InitFlags, c.SDL_INIT_GAMEPAD) else 0) |
            (if (self.events) @as(c.SDL_InitFlags, c.SDL_INIT_EVENTS) else 0) |
            (if (self.sensor) @as(c.SDL_InitFlags, c.SDL_INIT_SENSOR) else 0) |
            (if (self.camera) @as(c.SDL_InitFlags, c.SDL_INIT_CAMERA) else 0) |
            0;
    }
};

/// An app's metadata property to get or set.
///
/// ## Version
/// This is provided by zig-sdl3.
pub const AppMetadataProperty = enum {
    /// The human-readable name of the application, like "My Game 2: Bad Guy's Revenge!".
    /// This will show up anywhere the OS shows the name of the application separately from window titles, such as volume control applets, etc.
    /// This defaults to "SDL Application".
    name,
    /// The version of the app that is running; there are no rules on format, so "1.0.3beta2" and "April 22nd, 2024" and a git hash are all valid options.
    /// This has no default.
    version,
    /// A unique string that identifies this app.
    /// This must be in reverse-domain format, like "com.example.mygame2".
    /// This string is used by desktop compositors to identify and group windows together, as well as match applications with associated desktop settings and icons.
    /// If you plan to package your application in a container such as Flatpak, the app ID should match the name of your Flatpak container as well.
    /// This has no default.
    identifier,
    /// The human-readable name of the creator/developer/maker of this app, like "MojoWorkshop, LLC"
    creator,
    /// The human-readable copyright notice, like "Copyright (c) 2024 MojoWorkshop, LLC" or whatnot.
    /// Keep this to one line, don't paste a copy of a whole software license in here.
    /// This has no default.
    copyright,
    /// A URL to the app on the web.
    /// Maybe a product page, or a storefront, or even a GitHub repository, for user's further information.
    /// This has no default.
    url,
    /// The type of application this is.
    /// Currently this string can be "game" for a video game, "mediaplayer" for a media player, or generically "application" if nothing else applies.
    /// Future versions of SDL might add new types.
    /// This defaults to "application".
    program_type,

    /// Convert from an SDL string.
    pub fn fromSdl(val: [:0]const u8) AppMetadataProperty {
        if (std.mem.eql(u8, c.SDL_PROP_APP_METADATA_NAME_STRING, val))
            return .name;
        if (std.mem.eql(u8, c.SDL_PROP_APP_METADATA_VERSION_STRING, val))
            return .version;
        if (std.mem.eql(u8, c.SDL_PROP_APP_METADATA_IDENTIFIER_STRING, val))
            return .identifier;
        if (std.mem.eql(u8, c.SDL_PROP_APP_METADATA_CREATOR_STRING, val))
            return .creator;
        if (std.mem.eql(u8, c.SDL_PROP_APP_METADATA_COPYRIGHT_STRING, val))
            return .copyright;
        if (std.mem.eql(u8, c.SDL_PROP_APP_METADATA_URL_STRING, val))
            return .url;
        if (std.mem.eql(u8, c.SDL_PROP_APP_METADATA_TYPE_STRING, val))
            return .program_type;
        return .name;
    }

    /// Convert to an SDL string.
    pub fn toSdl(self: AppMetadataProperty) [:0]const u8 {
        return switch (self) {
            .name => c.SDL_PROP_APP_METADATA_NAME_STRING,
            .version => c.SDL_PROP_APP_METADATA_VERSION_STRING,
            .identifier => c.SDL_PROP_APP_METADATA_IDENTIFIER_STRING,
            .creator => c.SDL_PROP_APP_METADATA_CREATOR_STRING,
            .copyright => c.SDL_PROP_APP_METADATA_COPYRIGHT_STRING,
            .url => c.SDL_PROP_APP_METADATA_URL_STRING,
            .program_type => c.SDL_PROP_APP_METADATA_TYPE_STRING,
        };
    }
};

/// Initialize the SDL library.
///
/// ## Function Parameters
/// * `flags`: Subsystem initialization flags.
///
/// ## Remarks
/// The file I/O (for example: `io.fromFile()`) and threading (`thread.create()`) subsystems are initialized by default.
/// Message boxes (`message_box.showSimpleMessageBox()`) also attempt to work without initializing the video subsystem,
/// in hopes of being useful in showing an error dialog when `init.init()` fails.
/// You must specifically initialize other subsystems if you use them in your application.
///
/// Logging (such as `log`) works without initialization, too.
///
/// Subsystem initialization is ref-counted, you must call `init.quit()` for each `init.init()` to correctly shutdown a subsystem manually (or call `init.quit()` to force shutdown).
/// If a subsystem is already loaded then this call will increase the ref-count and return.
///
/// Consider reporting some basic metadata about your application before calling `init.init()`, using either `init.setAppMetadata()` or `init.setAppMetadataProperty()`.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn init(
    flags: Flags,
) !void {
    const ret = c.SDL_Init(
        flags.toSdl(),
    );
    return errors.wrapCallBool(ret);
}

/// Return whether this is the main thread.
///
/// ## Return Value
/// Returns true if this thread is the main thread, or false otherwise.
///
/// ## Remarks
/// On Apple platforms, the main thread is the thread that runs your program's main() entry point. On other platforms, the main thread is the one that calls SDL_Init(SDL_INIT_VIDEO), which should usually be the one that runs your program's main() entry point. If you are using the main callbacks, SDL_AppInit(), SDL_AppIterate(), and SDL_AppQuit() are all called on the main thread.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn isMainThread() bool {
    return c.SDL_IsMainThread();
}

/// Shut down specific SDL subsystems.
///
/// ## Function Parameters
/// * `flags`: Flags used by the `init.init()` function.
///
/// ## Remarks
/// You still need to call `init.shutdown()` even if you close all open subsystems with `sdl.quit()`.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn quit(
    flags: Flags,
) void {
    c.SDL_QuitSubSystem(
        flags.toSdl(),
    );
}

/// Call a function on the main thread during event processing.
///
/// ## Function Parameters
/// * `callback`: The callback to call on the main thread.
/// * `user_data`: A pointer that is passed to callback.
/// * `wait_complete`: True to wait for the callback to complete, false to return immediately.
///
/// ## Remarks
/// If this is called on the main thread, the callback is executed immediately.
/// If this is called on another thread, this callback is queued for execution on the main thread during event processing.
///
/// Be careful of deadlocks when using this functionality.
/// ou should not have the main thread wait for the current thread while this function is being called with `wait_complete` true.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn runOnMainThread(
    callback: MainThreadCallback,
    user_data: ?*anyopaque,
    wait_complete: bool,
) !void {
    const ret = c.SDL_RunOnMainThread(callback, user_data, wait_complete);
    return errors.wrapCallBool(ret);
}

/// Clean up all initialized subsystems.
///
/// ## Remarks
/// You should call this function even if you have already shutdown each initialized subsystem with `init.quit()`.
/// It is safe to call this function even in the case of errors in initialization.
///
/// You can use this function with `atexit()` to ensure that it is run when your application is shutdown,
/// but it is not wise to do this from a library or other dynamically loaded code.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn shutdown() void {
    c.SDL_Quit();
}

/// Specify basic metadata about your app.
///
/// ## Function Parameters
/// * `app_name`: The name of the application ("My Game 2: Bad Guy's Revenge!").
/// * `app_version`: The version of the application ("1.0.0beta5" or a git hash, or whatever makes sense).
/// * `app_identifier`: A unique string in reverse-domain format that identifies this app ("com.example.mygame2").
///
/// ## Remarks
/// You can optionally provide metadata about your app to SDL.
/// This is not required, but strongly encouraged.
///
/// There are several locations where SDL can make use of metadata (an "About" box in the macOS menu bar, the name of the app can be shown on some audio mixers, etc).
/// Any piece of metadata can be left as null, if a specific detail doesn't make sense for the app.
///
/// This function should be called as early as possible, before `init.init()`.
/// Multiple calls to this function are allowed, but various state might not change once it has been set up with a previous call to this function.
///
/// Passing a null removes any previous metadata.
///
/// This is a simplified interface for the most important information.
/// You can supply significantly more detailed metadata with `init.SetAppMetadataProperty()`.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn setAppMetadata(
    app_name: ?[:0]const u8,
    app_version: ?[:0]const u8,
    app_identifier: ?[:0]const u8,
) !void {
    const ret = c.SDL_SetAppMetadata(
        if (app_name) |str_capture| str_capture.ptr else null,
        if (app_version) |str_capture| str_capture.ptr else null,
        if (app_identifier) |str_capture| str_capture.ptr else null,
    );
    return errors.wrapCallBool(ret);
}

/// Specify metadata about your app through a set of properties.
///
/// ## Function Parameters
/// * `property`: Property to set.
/// * `value`: Value to set the property to. This may be null to clear it.
///
/// ## Remarks
/// You can optionally provide metadata about your app to SDL.
/// This is not required, but strongly encouraged.
///
/// There are several locations where SDL can make use of metadata (an "About" box in the macOS menu bar, the name of the app can be shown on some audio mixers, etc).
/// Any piece of metadata can be left out, if a specific detail doesn't make sense for the app.
///
/// This function should be called as early as possible, before `init.init()`.
/// Multiple calls to this function are allowed, but various state might not change once it has been set up with a previous call to this function.
///
/// Once set, this metadata can be read using `init.getAppMetadataProperty()`.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn setAppMetadataProperty(
    property: AppMetadataProperty,
    value: ?[:0]const u8,
) !void {
    const ret = c.SDL_SetAppMetadataProperty(
        property.toSdl(),
        if (value) |str_capture| str_capture.ptr else null,
    );
    return errors.wrapCallBool(ret);
}

/// Get metadata about your app.
///
/// ## Function Parameters
/// * `property`: The metadata property to get.
///
/// ## Return Value
/// Returns the current value of the metadata property, or the default if it is not set, `null` for properties with no default.
///
/// ## Remarks
/// This returns metadata previously set using `init.setAppMetadata()` or `init.setAppMetadataProperty()`.
/// See `init.setAppMetadataProperty()` for the list of available properties and their meanings.
///
/// ## Thread Safety
/// It is safe to call this function from any thread,
/// although the string returned is not protected and could potentially be freed if you call `init.setAppMetadataProperty()` to set that property from another thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getAppMetadataProperty(
    property: AppMetadataProperty,
) ?[:0]const u8 {
    const ret = c.SDL_GetAppMetadataProperty(
        property.toSdl(),
    );
    if (ret == null)
        return null;
    return std.mem.span(ret);
}

/// Get which given systems have been initialized.
///
/// ## Function Parameters
/// * `flags`: Flags to mask the result with.
///
/// ## Return Value
/// Returns the mask of the argument with flags that have been initialized.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn wasInit(
    flags: Flags,
) Flags {
    const ret = c.SDL_WasInit(
        flags.toSdl(),
    );
    return Flags.fromSdl(ret);
}

fn testRunOnMainThreadCb(user_data: ?*anyopaque) callconv(.c) void {
    const ptr: *i32 = @ptrCast(@alignCast(user_data.?));
    ptr.* = -1;
}

// Ensure the init subsystem works as expected.
test "Init" {
    std.testing.refAllDeclsRecursive(@This());
    // stdinc.custom_allocator = std.testing.allocator;
    // defer stdinc.custom_allocator = null;
    // try stdinc.setMemoryFunctionsByAllocator();
    // defer stdinc.restoreMemoryFunctions() catch {};

    defer shutdown();
    const flags = Flags{
        .video = true,
        .events = true,
        .camera = true,
    };
    try setAppMetadata("SDL3 Test", null, "!Testing");
    try init(flags);
    defer quit(flags);
    try std.testing.expect(isMainThread());
    var data: i32 = 1;
    try runOnMainThread(testRunOnMainThreadCb, &data, true);
    try std.testing.expectEqual(-1, data);
    try std.testing.expectEqual(flags, wasInit(flags));
    try std.testing.expectEqualStrings("SDL3 Test", getAppMetadataProperty(.name).?);
    try std.testing.expectEqual(null, getAppMetadataProperty(.version));
    try std.testing.expectEqualStrings("!Testing", getAppMetadataProperty(.identifier).?);
    try setAppMetadataProperty(.creator, "Gota7");
    try std.testing.expectEqualStrings("Gota7", getAppMetadataProperty(.creator).?);
    try setAppMetadataProperty(.creator, null);
    try std.testing.expectEqual(null, getAppMetadataProperty(.creator));
    try std.testing.expectEqual(null, getAppMetadataProperty(.url));
}
