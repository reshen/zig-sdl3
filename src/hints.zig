const c = @import("c.zig").c;
const errors = @import("errors.zig");
const std = @import("std");

/// A callback used to send notifications of hint value changes.
///
/// ## Function Parameters
/// * `user_data`: User-data passed to `hints.addCallback()`.
/// * `name`: Hint name passed to `hints.addCallback()`. The type can be gathered with the `hints.Type.fromSdl()` function.
/// * `old_value`: The previous hint value.
/// * `new_value`: The new value hint is to be set to.
///
/// ## Remarks
/// This is called an initial time during `hints.addCallback()` with the hint's current value, and then again each time the hint's value changes.
///
/// This callback is fired from whatever thread is setting a new hint value.
/// SDL holds a lock on the hint subsystem when calling this callback.
///
/// ## Version
/// This datatype is available since SDL 3.2.0.
pub const Callback = *const fn (
    user_data: ?*anyopaque,
    name: [*c]const u8,
    old_value: [*c]const u8,
    new_value: [*c]const u8,
) callconv(.c) void;

/// An enumeration of hint priorities.
///
/// ## Version
/// This enum is available since SDL 3.2.0.
pub const Priority = enum(c_uint) {
    Default = c.SDL_HINT_DEFAULT,
    Normal = c.SDL_HINT_NORMAL,
    Override = c.SDL_HINT_OVERRIDE,
};

/// Configuration hints for the library. May or may not be useful depending on the platform.
pub const Type = enum {
    /// By default, SDL emulates Alt+Tab functionality while the keyboard is grabbed and your window is full-screen.
    /// This prevents the user from getting stuck in your application if you've enabled keyboard grab.
    ///
    /// ## Remarks
    /// The variable can be set to the following values:
    ///
    /// * "0": SDL will not handle Alt+Tab. Your application is responsible for handling Alt+Tab while the keyboard is grabbed.
    /// * "1": SDL will minimize your window when Alt+Tab is pressed (default).
    ///
    /// This hint can be set anytime.
    ///
    /// ## Version
    /// This hint is available since SDL 3.2.0.
    AllowAltTabWhileGrabbed,

    /// A variable to control whether the SDL activity is allowed to be re-created.
    ///
    /// ## Remarks
    /// If this hint is true, the activity can be recreated on demand by the OS, and Java static data and C++ static data remain with their current values.
    /// If this hint is false, then SDL will call `exit()` when you return from your main function and the application will be terminated and then started fresh each time.
    ///
    /// The variable can be set to the following values:
    ///
    /// * "0": The application starts fresh at each launch. (default)
    /// * "1": The application activity can be recreated by the OS.
    ///
    /// This hint can be set anytime.
    ///
    /// ## Version
    /// This hint is available since SDL 3.2.0.
    AndroidAllowRecreateActivity,

    /// A variable to control whether the event loop will block itself when the app is paused.
    ///
    /// ## Remarks
    /// The variable can be set to the following values:
    ///
    /// * "0": Non blocking.
    /// * "1": Blocking. (default)
    ///
    /// This hint should be set before SDL is initialized.
    ///
    /// ## Version
    /// This hint is available since SDL 3.2.0.
    AndroidBlockOnPause,

    /// A variable to control whether low latency audio should be enabled.
    ///
    /// ## Remarks
    /// Some devices have poor quality output when this is enabled, but this is usually an improvement in audio latency.
    ///
    /// The variable can be set to the following values:
    ///
    /// * "0": Low latency audio is not enabled.
    /// * "1": Low latency audio is enabled. (default)
    ///
    /// This hint should be set before SDL audio is initialized.
    ///
    /// ## Version
    /// This hint is available since SDL 3.2.0.
    AndroidLowLatencyAudio,

    /// A variable to control whether we trap the Android back button to handle it manually.
    ///
    /// ## Remarks
    /// This is necessary for the right mouse button to work on some Android devices, or to be able to trap the back button for use in your code reliably.
    /// If this hint is true, the back button will show up as an `events.Event.key_down` / `events.Event.key_up` pair with a keycode of `scancode.ac_back`.
    ///
    /// The variable can be set to the following values:
    ///
    /// * "0": Back button will be handled as usual for system. (default)
    /// * "1": Back button will be trapped, allowing you to handle the key press manually. (This will also let right mouse click work on systems where the right mouse button functions as back.)
    ///
    /// This hint can be set anytime.
    ///
    /// ## Version
    /// This hint is available since SDL 3.2.0.
    AndroidTrapBackButton,

    /// A variable setting the app ID string.
    ///
    /// ## Remarks
    /// This string is used by desktop compositors to identify and group windows together, as well as match applications with associated desktop settings and icons.
    ///
    /// This will override `app_metadata_identifier_string`, if set by the application.
    ///
    /// This hint should be set before SDL is initialized.
    ///
    /// ## Version
    /// This hint is available since SDL 3.2.0.
    AppID,

    /// A variable setting the application name.
    ///
    /// ## Remarks
    /// This hint lets you specify the application name sent to the OS when required.
    /// For example, this will often appear in volume control applets for audio streams, and in lists of applications which are inhibiting the screensaver.
    /// You should use a string that describes your program ("My Game 2: The Revenge").
    ///
    /// This will override `app_metadata_name_string`, if set by the application.
    ///
    /// This hint should be set before SDL is initialized.
    ///
    /// ## Version
    /// This hint is available since SDL 3.2.0.
    AppName,

    /// A variable controlling whether controllers used with the Apple TV generate UI events.
    ///
    /// ## Remarks
    /// When UI events are generated by controller input, the app will be backgrounded when the Apple TV remote's menu button is pressed, and when the pause or B buttons on gamepads are pressed.
    ///
    /// More information about properly making use of controllers for the Apple TV can be found here: https://developer.apple.com/tvos/human-interface-guidelines/remote-and-controllers/
    /// The variable can be set to the following values:
    ///
    /// * "0": Controller input does not generate UI events. (default)
    /// * "1": Controller input generates UI events.
    ///
    /// This hint can be set anytime.
    ///
    /// ## Version
    /// This hint is available since SDL 3.2.0.
    AppleTvControllerUiEvents,

    // TODO: REST OF HINTS!!!

    /// Convert from an SDL string.
    pub fn fromSdl(val: [:0]const u8) Type {
        if (std.mem.eql(u8, c.SDL_HINT_ALLOW_ALT_TAB_WHILE_GRABBED, val))
            return .AllowAltTabWhileGrabbed;
        if (std.mem.eql(u8, c.SDL_HINT_ANDROID_ALLOW_RECREATE_ACTIVITY, val))
            return .AndroidAllowRecreateActivity;
        if (std.mem.eql(u8, c.SDL_HINT_ANDROID_BLOCK_ON_PAUSE, val))
            return .AndroidBlockOnPause;
        if (std.mem.eql(u8, c.SDL_HINT_ANDROID_LOW_LATENCY_AUDIO, val))
            return .AndroidLowLatencyAudio;
        if (std.mem.eql(u8, c.SDL_HINT_ANDROID_TRAP_BACK_BUTTON, val))
            return .AndroidTrapBackButton;
        if (std.mem.eql(u8, c.SDL_HINT_APP_ID, val))
            return .AppID;
        if (std.mem.eql(u8, c.SDL_HINT_APP_NAME, val))
            return .AppName;
        if (std.mem.eql(u8, c.SDL_HINT_APPLE_TV_CONTROLLER_UI_EVENTS, val))
            return .AppleTvControllerUiEvents;
        return .AllowAltTabWhileGrabbed;
    }

    /// Convert to an SDL string.
    pub fn toSdl(self: Type) [:0]const u8 {
        return switch (self) {
            .AllowAltTabWhileGrabbed => c.SDL_HINT_ALLOW_ALT_TAB_WHILE_GRABBED,
            .AndroidAllowRecreateActivity => c.SDL_HINT_ANDROID_ALLOW_RECREATE_ACTIVITY,
            .AndroidBlockOnPause => c.SDL_HINT_ANDROID_BLOCK_ON_PAUSE,
            .AndroidLowLatencyAudio => c.SDL_HINT_ANDROID_LOW_LATENCY_AUDIO,
            .AndroidTrapBackButton => c.SDL_HINT_ANDROID_TRAP_BACK_BUTTON,
            .AppID => c.SDL_HINT_APP_ID,
            .AppName => c.SDL_HINT_APP_NAME,
            .AppleTvControllerUiEvents => c.SDL_HINT_APPLE_TV_CONTROLLER_UI_EVENTS,
        };
    }
};

/// Add a function to watch a particular hint.
///
/// ## Function Parameters
/// * `hint`: Hint to watch.
/// * `callback`: An `hints.Callback` function that will be called when the hint value changes.
/// * `user_data`: A pointer to pass to the callback function.
///
/// ## Remarks
/// The callback function is called *during* this function, to provide it an initial value, and again each time the hint's value changes.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn addCallback(
    hint: Type,
    callback: Callback,
    user_data: ?*anyopaque,
) !void {
    const ret = c.SDL_AddHintCallback(
        hint.toSdl(),
        callback,
        user_data,
    );
    return errors.wrapCallBool(ret);
}

/// Get the value of a hint.
///
/// ## Function Parameters
/// * `hint`: The hint to query.
///
/// ## Return Value
/// Returns the string value of a hint or `null` if the hint isn't set.
///
/// ## Thread Safety
/// It is safe to call this function from any thread, however the return value only remains valid until the hint is changed;
/// if another thread might do so, the app should supply locks and/or make a copy of the string.
/// Note that using a hint callback instead is always thread-safe, as SDL holds a lock on the thread subsystem during the callback.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn get(
    hint: Type,
) ?[:0]const u8 {
    const ret = c.SDL_GetHint(
        hint.toSdl(),
    );
    if (ret == null)
        return null;
    return std.mem.span(ret);
}

/// Get the boolean value of a hint variable.
///
/// ## Function Parameters
/// * `hint`: The hint to query.
///
/// ## Return Value
/// Returns the boolean value of a hint or `null` if the hint does not exist.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getBoolean(
    hint: Type,
) ?bool {
    const ret = c.SDL_GetHintBoolean(
        hint.toSdl(),
        false,
    );
    if (get(hint) == null) return null;
    return ret;
}

/// Remove a function watching a particular hint.
///
/// ## Function Parameters
/// * `hint`: The hint to watch.
/// * `callback`: A `hint.Callback` function that will be called when the hint value changes.
/// * `user_data`: A pointer being passed to the callback function.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn removeCallback(
    hint: Type,
    callback: Callback,
    user_data: ?*anyopaque,
) void {
    c.SDL_RemoveHintCallback(
        hint.toSdl(),
        callback,
        user_data,
    );
}

/// Reset a hint to the default value.
///
/// ## Function Parameters
/// * `hint`: The hint to reset.
///
/// ## Remarks
/// This will reset a hint to the value of the environment variable, or `null` if the environment isn't set.
/// Callbacks will be called normally with this change.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn reset(
    hint: Type,
) !void {
    const ret = c.SDL_ResetHint(
        hint.toSdl(),
    );
    return errors.wrapCallBool(ret);
}

/// Reset all hints to the default values.
///
/// ## Remarks
/// This will reset all hints to the value of the associated environment variable, or `null` if the environment isn't set.
/// Callbacks will be called normally with this change.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn resetAll() void {
    c.SDL_ResetHints();
}

/// Set a hint with normal priority.
///
/// ## Function Parameters
/// * `hint`: The hint to set.
/// * `value:` The value of the hint variable.
///
/// ## Remarks
/// Hints will not be set if there is an existing override hint or environment variable that takes precedence.
/// You can use `hints.setWithPriority()` to set the hint with override priority instead.
pub fn set(
    hint: Type,
    value: [:0]const u8,
) !void {
    const ret = c.SDL_SetHint(
        hint.toSdl(),
        value.ptr,
    );
    return errors.wrapCallBool(ret);
}

/// Set a hint with a specific priority.
///
/// ## Function Parameters
/// * `hint`: The hint to set.
/// * `value:` The value of the hint variable.
/// * `priority`: The `hint.Priority` level for the hint.
///
/// ## Remarks
/// The priority controls the behavior when setting a hint that already has a value.
/// Hints will replace existing hints of their priority and lower.
/// Environment variables are considered to have override priority.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn setWithPriority(
    hint: Type,
    value: [:0]const u8,
    priority: Priority,
) !void {
    const ret = c.SDL_SetHintWithPriority(
        hint.toSdl(),
        value.ptr,
        @intFromEnum(priority),
    );
    return errors.wrapCallBool(ret);
}

fn testHintCb(user_data: ?*anyopaque, name: [*c]const u8, old_value: [*c]const u8, new_value: [*c]const u8) callconv(.c) void {
    const ctr_ptr: *i32 = @ptrCast(@alignCast(user_data));
    _ = name;
    _ = old_value;
    _ = new_value;
    ctr_ptr.* = ctr_ptr.* + 1;
}

// Test hint functions.
test "Hints" {
    var ctr: i32 = 0;
    try addCallback(.AppName, testHintCb, &ctr);
    try std.testing.expectEqual(1, ctr);
    try std.testing.expectEqual(null, get(.AppName));
    try std.testing.expectEqual(null, getBoolean(.AppName));
    try set(.AppName, "True");
    try std.testing.expectEqual(2, ctr);
    try std.testing.expectEqualStrings("True", get(.AppName).?);
    try std.testing.expectEqual(true, getBoolean(.AppName));
    try setWithPriority(.AppName, "False", .Override);
    try std.testing.expectEqual(3, ctr);
    try std.testing.expectEqualStrings("False", get(.AppName).?);
    try std.testing.expectEqual(false, getBoolean(.AppName));
    try reset(.AppName);
    try std.testing.expectEqual(4, ctr);
    try std.testing.expectEqual(null, get(.AppName));
    try std.testing.expectEqual(null, getBoolean(.AppName));
    try set(.AppName, "Reset Again");
    removeCallback(.AppName, testHintCb, &ctr);
    resetAll();
    try std.testing.expectEqual(5, ctr);
    try std.testing.expectEqual(null, get(.AppName));
    try std.testing.expectEqual(null, getBoolean(.AppName));
}
