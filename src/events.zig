const audio = @import("audio.zig");
const c = @import("c.zig").c;
const camera = @import("camera.zig");
const errors = @import("errors.zig");
const sdl3 = @import("sdl3.zig");
const std = @import("std");
const video = @import("video.zig");
const keyboard = @import("keyboard.zig");
const keycode = @import("keycode.zig");
const scancode = @import("scancode.zig");
const mouse = @import("mouse.zig");

/// The type of action to request from `events.peep()`.
///
/// ## Version
/// This enum is available since SDL 3.2.0.
pub const Action = enum(c_uint) {
    /// Add events to the back of the queue.
    add,
    /// Check but don't remove events from the queue front.
    peek,
    /// Retrieve/remove events from the front of the queue.
    get,
};

/// A function pointer used for callbacks that watch the event queue.
///
/// ## Function Parameters
/// * `user_data`: What was passed as `user_data` to `events.setFilter()` or `events.addWatch()`.
/// * `event`: The event that triggered the callback.
///
/// ## Return Value
/// Returns true to permit event to be added to the queue, and false to disallow it.
/// When used with `events.addWatch()`, the return value is ignored.
///
/// ## Thread Safety
/// SDL may call this callback at any time from any thread; the application is responsible for locking resources the callback touches that need to be protected.
///
/// ## Version
/// This datatype is available since SDL 3.2.0.
pub fn Filter(comptime UserData: type) type {
    return *const fn (
        user_data: ?*UserData,
        event: *Event,
    ) bool;
}

/// A function pointer used for callbacks that watch the event queue.
///
/// ## Function Parameters
/// * `user_data`: What was passed as `user_data` to `events.setFilter()` or `events.addWatch()`.
/// * `event`: The event that triggered the callback.
///
/// ## Return Value
/// Returns true to permit event to be added to the queue, and false to disallow it.
/// When used with `events.addWatch()`, the return value is ignored.
///
/// ## Thread Safety
/// SDL may call this callback at any time from any thread; the application is responsible for locking resources the callback touches that need to be protected.
///
/// ## Version
/// This datatype is available since SDL 3.2.0.
pub const FilterC = *const fn (user_data: ?*anyopaque, event: [*c]c.SDL_Event) callconv(.c) bool;

/// For clearing out a group of events.
///
/// ## Version
/// This enum is provided by zig-sdl3.
pub const Group = enum {
    /// Clear all events.
    all,
    /// Application based events.
    application,
    /// Display events.
    display,
    /// Window events.
    window,
    /// Keyboard events.
    keyboard,
    /// Mouse events.
    mouse,
    /// Joystick events.
    joystick,
    /// Gamepad events.
    gamepad,
    /// Touch events.
    touch,
    /// Clipboard events.
    clipboard,
    /// Drag and drop events.
    drag_and_drop,
    /// Audio hotplug events.
    audio,
    /// Sensor events.
    sensor,
    /// Pressure-sensitive pen events.
    pen,
    /// Camera hotplug events.
    camera,
    /// Render events.
    render,
    /// Reserved events for private platforms.
    reserved,
    /// Internal events.
    internal,
    /// User events.
    user,

    /// Iterate over all event types in the group.
    ///
    /// ## Version
    /// Provided by zig-sdl3.
    pub const Iterator = struct {
        curr: c.SDL_EventType,
        max: c.SDL_EventType,

        /// Get the next event type in the iterator.
        ///
        /// ## Function Parameters
        /// * `self`: The group iterator.
        ///
        /// ## Return Value
        /// Returns the next event type in the iterator, or `null` if none left.
        ///
        /// ## Thread Safety
        /// This function is not thread safe.
        ///
        /// ## Version
        /// Provided by zig-sdl3.
        pub fn next(
            self: *Iterator,
        ) ?c.SDL_EventType {
            if (self.curr <= self.max) {
                const ret = self.curr;
                self.curr += 1;
                return ret;
            }
            return null;
        }
    };

    /// Check if an event type is in a group.
    ///
    /// ## Function Parameters
    /// * `self`: Group to check the event is in.
    /// * `event_type`: Type of the event to see if it is in a specified group.
    ///
    /// ## Return Value
    /// Returns if the `event_type` is in the `self` group.
    ///
    /// ## Thread Safety
    /// This function may be called from any thread.
    ///
    /// ## Version
    /// Provided by zig-sdl3.
    pub fn eventIn(
        self: Group,
        event_type: Type,
    ) bool {
        const raw: c.SDL_EventType = @intFromEnum(event_type);
        const minmax = self.minMax();
        return raw >= minmax.min and raw <= minmax.max;
    }

    /// Create an iterator for every type in the group.
    ///
    /// ## Function Parameters
    /// * `self`: Group to iterate over.
    ///
    /// ## Return Value
    /// Returns an iterator that can iterate all over SDL event types.
    ///
    /// ## Thread Safety
    /// This function is thread safe.
    ///
    /// ## Version
    /// Provided by zig-sdl3.
    pub fn iterator(
        self: Group,
    ) Iterator {
        const minmax = self.minMax();
        return Iterator{
            .curr = minmax.min,
            .max = minmax.max,
        };
    }

    /// Get the minimum and maximum `c.SDL_EventType` for the provided group.
    ///
    /// ## Function Parameters
    /// * `self`: Group to get the min and max types for.
    ///
    /// ## Return Value
    /// Returns the minimum and maximum SDL event types for its raw enum.
    ///
    /// ## Thread Safety
    /// This function may be called from any thread.
    ///
    /// ## Version
    /// Provided by zig-sdl3.
    pub fn minMax(
        self: Group,
    ) struct { min: c.SDL_EventType, max: c.SDL_EventType } {
        return switch (self) {
            .all => .{ .min = 0, .max = std.math.maxInt(c.SDL_EventType) },
            .application => .{ .min = c.SDL_EVENT_QUIT, .max = c.SDL_EVENT_SYSTEM_THEME_CHANGED },
            .display => .{ .min = c.SDL_EVENT_DISPLAY_FIRST, .max = c.SDL_EVENT_DISPLAY_LAST },
            .window => .{ .min = c.SDL_EVENT_WINDOW_FIRST, .max = c.SDL_EVENT_WINDOW_LAST },
            .keyboard => .{ .min = c.SDL_EVENT_KEY_DOWN, .max = c.SDL_EVENT_TEXT_EDITING_CANDIDATES },
            .mouse => .{ .min = c.SDL_EVENT_MOUSE_MOTION, .max = c.SDL_EVENT_MOUSE_REMOVED },
            .joystick => .{ .min = c.SDL_EVENT_JOYSTICK_AXIS_MOTION, .max = c.SDL_EVENT_JOYSTICK_UPDATE_COMPLETE },
            .gamepad => .{ .min = c.SDL_EVENT_GAMEPAD_AXIS_MOTION, .max = c.SDL_EVENT_GAMEPAD_STEAM_HANDLE_UPDATED },
            .touch => .{ .min = c.SDL_EVENT_FINGER_DOWN, .max = c.SDL_EVENT_FINGER_CANCELED },
            .clipboard => .{ .min = c.SDL_EVENT_CLIPBOARD_UPDATE, .max = c.SDL_EVENT_CLIPBOARD_UPDATE },
            .drag_and_drop => .{ .min = c.SDL_EVENT_DROP_FILE, .max = c.SDL_EVENT_DROP_POSITION },
            .audio => .{ .min = c.SDL_EVENT_AUDIO_DEVICE_ADDED, .max = c.SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED },
            .sensor => .{ .min = c.SDL_EVENT_SENSOR_UPDATE, .max = c.SDL_EVENT_SENSOR_UPDATE },
            .pen => .{ .min = c.SDL_EVENT_PEN_PROXIMITY_IN, .max = c.SDL_EVENT_PEN_AXIS },
            .camera => .{ .min = c.SDL_EVENT_CAMERA_DEVICE_ADDED, .max = c.SDL_EVENT_CAMERA_DEVICE_DENIED },
            .render => .{ .min = c.SDL_EVENT_RENDER_TARGETS_RESET, .max = c.SDL_EVENT_RENDER_DEVICE_LOST },
            .reserved => .{ .min = c.SDL_EVENT_PRIVATE0, .max = c.SDL_EVENT_PRIVATE3 },
            .internal => .{ .min = c.SDL_EVENT_POLL_SENTINEL, .max = c.SDL_EVENT_POLL_SENTINEL },
            .user => .{ .min = c.SDL_EVENT_USER, .max = c.SDL_EVENT_LAST },
        };
    }
};

/// The types of events that can be delivered.
///
/// ## Version
/// This enum is available since SDL 3.2.0.
pub const Type = enum(c.SDL_EventType) {
    /// User-requested quit.
    quit = c.SDL_EVENT_QUIT,
    /// The application is being terminated by the OS.
    /// This event must be handled in a callback set with `events.addWatch()`.
    /// Called on iOS in `applicationWillTerminate()`.
    /// Called on Android in `onDestroy()`.
    terminating = c.SDL_EVENT_TERMINATING,
    // /// The application is low on memory, free memory if possible.
    // /// This event must be handled in a callback set with `events.addWatch()`.
    // low_memory = c.SDL_EVENT_LOW_MEMORY,
    // /// The application is about to enter the background.
    // /// This event must be handled in a callback set with `events.addWatch()`.
    // /// Called on iOS in `applicationWillResignActive()`.
    // /// Called on Android in `onPause()`.
    // WillEnterBackground = c.SDL_EVENT_WILL_ENTER_BACKGROUND,
    // DidEnterBackground,
    // WillEnterForeground,
    // DidEnterForeground,
    // LocaleChanged,
    // SystemThemeChanged,
    // DisplayOrientation,
    // DisplayAdded,
    // DisplayRemoved,
    // DisplayMoved,
    // DisplayDesktopModeChanged,
    // DisplayCurrentModeChanged,
    // DisplayContentScaleChanged,
    // WindowShown,
    // WindowHidden,
    // WindowExposed,
    // WindowMoved,
    /// Window has been resized
    window_resized,
    // WindowPixelSizeChanged,
    // WindowMetalViewResized,
    // WindowMinimized,
    // WindowMaximized,
    // WindowRestored,
    // WindowMouseEnter,
    // WindowMouseLeave,
    // WindowFocusGained,
    // WindowFocusLost,
    // WindowCloseRequested,
    // WindowHitTest,
    // WindowIccProfChanged,
    // WindowDisplayChanged,
    // WindowDisplayScaleChanged,
    // WindowSafeAreaChanged,
    // WindowOccluded,
    // WindowEnterFullscreen,
    // WindowLeaveFullscreen,
    // WindowDestroyed,
    // WindowHdrStateChanged,
    /// Key pressed.
    key_down = c.SDL_EVENT_KEY_DOWN,
    /// Key released.
    key_up = c.SDL_EVENT_KEY_UP,
    // TextEditing,
    // TextInput,
    // KeymapChanged,
    // KeyboardAdded,
    // KeyboardRemoved,
    // TextEditingCandidates,
    /// Mouse moved.
    mouse_motion = c.SDL_EVENT_MOUSE_MOTION,
    /// Mouse button pressed.
    mouse_button_down = c.SDL_EVENT_MOUSE_BUTTON_DOWN,
    /// Mouse button released.
    mouse_button_up = c.SDL_EVENT_MOUSE_BUTTON_UP,
    /// Mouse wheel motion.
    mouse_wheel = c.SDL_EVENT_MOUSE_WHEEL,
    // MouseAdded,
    // MouseRemoved,
    // JoystickAxisMotion,
    // JoystickBallMotion,
    // JoystickHatMotion,
    // JoystickButtonDown,
    // JoystickButtonUp,
    // JoystickAdded,
    // JoystickRemoved,
    // JoystickBatteryUpdated,
    // JoystickUpdateComplete,
    // GamepadAxisMotion,
    // GamepadButtonDown,
    // GamepadButtonUp,
    // GamepadAdded,
    // GamepadRemoved,
    // GamepadRemapped,
    // GamepadTouchpadDown,
    // GamepadTouchpadMotion,
    // GamepadTouchpadUp,
    // GamepadSensorUpdate,
    // GamepadUpdateComplete,
    // GamepadSteamHandleUpdate,
    // FingerDown,
    // FingerUp,
    // FingerMotion,
    // FingerCanceled,
    // ClipboardUpdate,
    // DropFile,
    // DropText,
    // DropBegin,
    // DropComplete,
    // DropPosition,
    /// A new audio device is available.
    audio_device_added = c.SDL_EVENT_AUDIO_DEVICE_ADDED,
    /// An audio device has been removed.
    audio_device_removed = c.SDL_EVENT_AUDIO_DEVICE_REMOVED,
    /// An audio device's format has been changed by the system.
    audio_device_format_changed = c.SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED,
    // SensorUpdate,
    // PenProximityIn,
    // PenProximityOut,
    // PenDown,
    // PenUp,
    // PenButtonDown,
    // PenButtonUp,
    // PenMotion,
    // PenAxis,
    /// A new camera device is available.
    camera_device_added = c.SDL_EVENT_CAMERA_DEVICE_ADDED,
    /// A camera device has been removed.
    camera_device_removed = c.SDL_EVENT_CAMERA_DEVICE_REMOVED,
    /// A camera device has been approved for use by the user.
    camera_device_approved = c.SDL_EVENT_CAMERA_DEVICE_APPROVED,
    /// A camera device has been denied for use by the user.
    camera_device_denied = c.SDL_EVENT_CAMERA_DEVICE_DENIED,
    // RenderTargetsReset,
    // RenderDeviceReset,
    // RenderDeviceLost,
    // Private0,
    // Private1,
    // Private2,
    // Private3,
    /// User events, should be allocated with `events.register()`.
    user,
    /// An unknown event type.
    unknown = c.SDL_EVENT_FIRST,
    /// For padding out the union.
    padding = c.SDL_EVENT_ENUM_PADDING,
    // _,
};

/// Audio device event structure.
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const AudioDevice = struct {
    /// Common event information.
    common: Common,
    /// Device being added or removed or changing.
    device: audio.Device,
    /// False if a playback device, true if a recording device.
    recording: bool,
};

/// Camera device event structure.
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const CameraDevice = struct {
    /// Common event information.
    common: Common,
    /// The device being added or removed or changing.
    device: camera.ID,
};

/// An event triggered when the clipboard contents have changed (event.clipboard.*).
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const Clipboard = struct {
    /// Common event information.
    common: Common,
    /// Are we owning the clipboard (internal update)?
    owner: bool,
    /// Mime types.
    mime_types: [][:0]const u8,
};

/// Fields shared by every event.
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const Common = struct {
    /// In nanoseconds, populated using `timer.getNanosecondsSinceInit()`.
    timestamp: u64,

    /// Create a common event from an SDL one.
    fn fromSdl(event: *const c.SDL_Event) Common {
        return .{ .timestamp = event.common.timestamp };
    }
};

/// An unknown event.
pub const Unknown = struct {
    /// Common event information.
    common: Common,
    /// Event type that was not known.
    event_type: c.SDL_EventType,
};

/// A user-defined event type (event.user.*).
///
/// ## Remarks
/// This event is unique; it is never created by SDL, but only by the application.
/// The event can be pushed onto the event queue using `events.push()`.
/// The contents of the structure members are completely up to the programmer;
/// the only requirement is that '''type''' is a value obtained from `events.register()`.
///
/// ## Version
/// This struct is available since SDL 3.2.0.
///
/// ## Code Examples
/// ```zig
/// const event_type = events.register(1);
/// if (event_type) |val| {
///     try events.push(.{
///         .common = .{ .timestamp = timer.getNanosecondsSinceInit() },
///         .event_type = val,
///         .code = 0,
///     });
/// }
/// ```
pub const User = struct {
    /// Common event information.
    common: Common,
    /// The event type.
    event_type: c.SDL_EventType,
    /// Associated window if any.
    window_id: ?video.WindowID = null,
    /// User defined event code.
    code: i32,
    /// User defined pointer 1.
    data1: ?*anyopaque = null,
    /// User defined pointer 2.
    data2: ?*anyopaque = null,
};

/// Mouse motion event structure (event.motion.*)
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const MouseMotion = struct {
    /// Common event information.
    common: Common,
    /// Associated window if any.
    window_id: ?video.WindowID = null,
    /// The mouse instance ID in relative mode, `mouse.ID.touch` for touch events, or `null`.
    which: ?mouse.ID = null,
    /// The current button state.
    state: mouse.ButtonFlags,
    /// X coordinate, relative to window.
    x: f32,
    /// Y coordinate, relative to window.
    y: f32,
    /// The relative motion in the X direction.
    x_rel: f32,
    /// The relative motion in the Y direction.
    y_rel: f32,
};

/// Mouse button event structure (event.button.*)
///
/// ## Version
/// This struct is available since SDL 3.2.0.
///
/// ## Code Examples
/// ```zig
///     const mouse_button = if (ev == .mouse_button_down) ev.mouse_button_down.button else break :event_handle;
///     if (mouse_button == .left) {
///         std.debug.print("left click\n", .{});
///     } else if (mouse_button == .right) {
///         std.debug.print("right click\n", .{});
///     }
/// ```
pub const MouseButton = struct {
    /// Common event information.
    common: Common,
    /// Associated window if any.
    window_id: ?video.WindowID = null,
    /// The mouse instance ID in relative mode, `mouse.ID.touch` for touch events, or `null`.
    which: ?mouse.ID = null,
    /// The mouse button index.
    button: mouse.Button,
    /// If the button is pressed.
    down: bool,
    /// 1 for single-click, 2 for double-click, etc.
    clicks: u8,
    /// X coordinate, relative to window.
    x: f32,
    /// Y coordinate, relative to window.
    y: f32,
};

/// Mouse wheel event structure (event.wheel.*)
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const MouseWheel = struct {
    /// Common event information.
    common: Common,
    /// Associated window if any.
    window_id: ?video.WindowID = null,
    /// The mouse instance ID in relative mode, `mouse.ID.touch?` for touch events, or `null`.
    which: ?mouse.ID = null,
    /// The amount scrolled horizontally, positive to the right and negative to the left.
    scroll_x: f32,
    /// The amount scrolled vertically, positive away from the user and negative toward the user.
    scroll_y: f32,
    /// When .flipped, the values in X and Y will be opposite. Multiply by -1 to change them back.
    direction: mouse.WheelDirection,
    /// X coordinate, relative to window.
    x: f32,
    /// Y coordinate, relative to window.
    y: f32,
};

/// Keyboard button event structure (event.key.*)
///
/// ## Remarks
/// The key is the base keycode.Keycode generated by pressing the scancode using the current keyboard
/// layout, applying any options specified in `hints.Type.keycode_options`. You can get the `keycode.Keycode`
/// corresponding to the event scancode and modifiers directly from the keyboard layout, bypassing
/// `hints.Type.keycode_options`, by calling `keyboard.getKeyFromScancode()`.
///
/// ## Version
/// This struct is available since SDL 3.2.0.
///
/// ## Code Examples
/// ```zig
///    const key = if (ev == .key_down) ev.key_down.key else break :event_handle;
///    switch (key) {
///        .a => {
///            std.debug.print("a\n", .{});
///        },
///        else => {
///            std.debug.print("other\n", .{});
///        },
///    }
/// ```
pub const Key = struct {
    /// Common event information.
    common: Common,
    /// The window with keyboard focus, if any.
    window_id: ?video.WindowID = null,
    /// The keyboard instance ID, or `null` if unknown or virtual.
    which: ?keyboard.ID,
    /// SDL physical key code.
    scancode: ?scancode.Scancode,
    /// SDL virtual key code.
    key: ?keycode.Keycode,
    /// Current key modifiers.
    mod: keycode.KeyModifier,
    /// The platform dependent scancode for this event.
    raw: u16,
    /// True if the key is pressed.
    down: bool,
    /// True if this is a key repeat.
    repeat: bool,
};

/// Window state change event data (event.window.*)
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const Window = struct {
    /// Common event information.
    common: Common,
    /// Associated window.
    window_id: video.WindowID,
    /// Event dependent data 1.
    data1: i32,
    /// Event dependent data 2.
    data2: i32,
};

/// The "quit requested" event.
pub const Quit = struct {
    /// Common event information.
    common: Common,
};

/// Needed to calculate padding.
const DummyEnum = enum(c.SDL_EventType) {
    empty,
};

/// Needed to calculate padding.
const DummyUnion = union(DummyEnum) {
    empty: void,
};

/// The structure for all events in SDL.
///
/// TODO!!!
pub const Event = union(Type) {
    /// Quit request event data.
    quit: Quit,
    /// Application being terminated by the OS.
    terminating: Common,

    /// A window resized event.
    window_resized: Window,

    /// A key pressed event.
    key_down: Key,
    /// A key released event.
    key_up: Key,

    /// A mouse moved event.
    mouse_motion: MouseMotion,
    /// A mouse button pressed event.
    mouse_button_down: MouseButton,
    /// A mouse button released event.
    mouse_button_up: MouseButton,
    /// A mouse wheel motion event.
    mouse_wheel: MouseWheel,

    /// A new audio device is available.
    audio_device_added: AudioDevice,
    /// An audio device has been removed.
    audio_device_removed: AudioDevice,
    /// An audio device's format has been changed by the system.
    audio_device_format_changed: AudioDevice,

    /// A new camera device is available.
    camera_device_added: CameraDevice,
    /// A camera device has been removed.
    camera_device_removed: CameraDevice,
    /// A camera device has been approved for use by the user.
    camera_device_approved: CameraDevice,
    /// A camera device has been denied for use by the user.
    camera_device_denied: CameraDevice,

    /// A user event.
    user: User,

    /// An unknown event.
    unknown: Unknown,
    // Padding to make union the same size of a `c.SDL_Event`.
    padding: [@sizeOf(c.SDL_Event) - @sizeOf(DummyUnion)]u8,

    // Size tests.
    comptime {
        std.debug.assert(@sizeOf(c.SDL_Event) == @sizeOf(Event));
    }

    /// Create a managed event from an SDL event.
    ///
    /// ## Function Parameters
    /// * `event`: SDL event to manage.
    ///
    /// ## Return Value
    /// A managed event union.
    ///
    /// ## Remarks
    /// This makes a copy of the event provided.
    ///
    /// ## Version
    /// This function is provided by zig-sdl3.
    pub fn fromSdl(event: c.SDL_Event) Event {
        return switch (event.type) {
            c.SDL_EVENT_QUIT => .{ .quit = .{
                .common = Common.fromSdl(&event),
            } },
            c.SDL_EVENT_TERMINATING => .{ .terminating = Common.fromSdl(&event) },
            c.SDL_EVENT_WINDOW_RESIZED => .{ .window_resized = .{
                .common = Common.fromSdl(&event),
                .window_id = event.window.windowID,
                .data1 = event.window.data1,
                .data2 = event.window.data2,
            } },
            c.SDL_EVENT_KEY_DOWN => .{ .key_down = .{
                .common = Common.fromSdl(&event),
                .window_id = if (event.key.windowID == 0) null else event.key.windowID,
                .which = .{
                    .value = event.key.which,
                },
                .scancode = @enumFromInt(event.key.scancode),
                .key = @enumFromInt(event.key.key),
                .mod = keycode.KeyModifier.fromSdl(event.key.mod),
                .raw = event.key.raw,
                .down = event.key.down,
                .repeat = event.key.repeat,
            } },
            c.SDL_EVENT_KEY_UP => .{ .key_up = .{
                .common = Common.fromSdl(&event),
                .window_id = if (event.key.windowID == 0) null else event.key.windowID,
                .which = .{
                    .value = event.key.which,
                },
                .scancode = @enumFromInt(event.key.scancode),
                .key = @enumFromInt(event.key.key),
                .mod = keycode.KeyModifier.fromSdl(event.key.mod),
                .raw = event.key.raw,
                .down = event.key.down,
                .repeat = event.key.repeat,
            } },
            c.SDL_EVENT_MOUSE_MOTION => .{ .mouse_motion = .{
                .common = Common.fromSdl(&event),
                .window_id = if (event.motion.windowID == 0) null else event.motion.windowID,
                .which = mouse.ID.fromSdl(event.button.which),
                .state = mouse.ButtonFlags.fromSdl(event.motion.state),
                .x = event.motion.x,
                .y = event.motion.y,
                .x_rel = event.motion.xrel,
                .y_rel = event.motion.yrel,
            } },
            c.SDL_EVENT_MOUSE_BUTTON_DOWN => .{ .mouse_button_down = .{
                .common = Common.fromSdl(&event),
                .window_id = if (event.button.windowID == 0) null else event.button.windowID,
                .which = mouse.ID.fromSdl(event.button.which),
                .button = @enumFromInt(event.button.button),
                .down = event.button.down,
                .clicks = event.button.clicks,
                .x = event.button.x,
                .y = event.button.y,
            } },
            c.SDL_EVENT_MOUSE_BUTTON_UP => .{ .mouse_button_up = .{
                .common = Common.fromSdl(&event),
                .window_id = if (event.button.windowID == 0) null else event.button.windowID,
                .which = mouse.ID.fromSdl(event.button.which),
                .button = @enumFromInt(event.button.button),
                .down = event.button.down,
                .clicks = event.button.clicks,
                .x = event.button.x,
                .y = event.button.y,
            } },
            c.SDL_EVENT_MOUSE_WHEEL => .{ .mouse_wheel = .{
                .common = Common.fromSdl(&event),
                .window_id = if (event.button.windowID == 0) null else event.button.windowID,
                .which = mouse.ID.fromSdl(event.button.which),
                .scroll_x = event.wheel.x,
                .scroll_y = event.wheel.y,
                .direction = @enumFromInt(event.wheel.direction),
                .x = event.wheel.mouse_x,
                .y = event.wheel.mouse_y,
            } },
            c.SDL_EVENT_AUDIO_DEVICE_ADDED => .{ .audio_device_added = .{
                .common = Common.fromSdl(&event),
                .device = .{ .value = event.adevice.which },
                .recording = event.adevice.recording,
            } },
            c.SDL_EVENT_AUDIO_DEVICE_REMOVED => .{ .audio_device_removed = .{
                .common = Common.fromSdl(&event),
                .device = .{ .value = event.adevice.which },
                .recording = event.adevice.recording,
            } },
            c.SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED => .{ .audio_device_format_changed = .{
                .common = Common.fromSdl(&event),
                .device = .{ .value = event.adevice.which },
                .recording = event.adevice.recording,
            } },
            c.SDL_EVENT_CAMERA_DEVICE_ADDED => .{ .camera_device_added = .{
                .common = Common.fromSdl(&event),
                .device = .{ .value = event.cdevice.which },
            } },
            c.SDL_EVENT_CAMERA_DEVICE_REMOVED => .{ .camera_device_removed = .{
                .common = Common.fromSdl(&event),
                .device = .{ .value = event.cdevice.which },
            } },
            c.SDL_EVENT_CAMERA_DEVICE_APPROVED => .{ .camera_device_approved = .{
                .common = Common.fromSdl(&event),
                .device = .{ .value = event.cdevice.which },
            } },
            c.SDL_EVENT_CAMERA_DEVICE_DENIED => .{ .camera_device_denied = .{
                .common = Common.fromSdl(&event),
                .device = .{ .value = event.cdevice.which },
            } },
            c.SDL_EVENT_USER...c.SDL_EVENT_LAST => .{ .user = .{
                .common = Common.fromSdl(&event),
                .event_type = event.type,
                .window_id = if (event.user.windowID == 0) null else event.user.windowID,
                .code = event.user.code,
                .data1 = event.user.data1,
                .data2 = event.user.data2,
            } },
            c.SDL_EVENT_ENUM_PADDING => .{
                .padding = @splat(0),
            },
            else => .{ .unknown = .{
                .common = Common.fromSdl(&event),
                .event_type = event.type,
            } },
        };
    }

    /// Create a managed event from an SDL event in place.
    ///
    /// ## Function Parameters
    /// * `event`: SDL event to manage. The `event` passed in will be unusable after.
    ///
    /// ## Return Value
    /// A managed event union.
    ///
    /// ## Remarks
    /// This will modify memory in-place.
    /// This means that using the `event` passed into this afterwards will result in undefined behavior.
    ///
    /// ## Version
    /// This function is provided by zig-sdl3.
    pub fn fromSdlInPlace(event: *c.SDL_Event) *Event {
        const managed: *Event = @ptrCast(event);
        managed.* = fromSdl(event.*);
        return managed;
    }

    /// Get window associated with an event.
    ///
    /// ## Function Parameters
    /// * `self`: An event containing a window.
    ///
    /// ## Return Value
    /// Returns the associated window on success or `null` if there is none.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getWindow(
        self: Event,
    ) ?video.Window {
        const event = toSdl(self);
        const ret = c.SDL_GetWindowFromEvent(&event);
        if (ret) |val| {
            return .{ .value = val };
        }
        return null;
    }

    /// Create an unmanaged event from an SDL event.
    ///
    /// ## Function Parameters
    /// * `event`: Managed event to unmanage.
    ///
    /// ## Return Value
    /// Returns an unmanaged SDL event.
    ///
    /// ## Remarks
    /// This makes a copy of the event provided.
    ///
    /// ## Version
    /// This function is provided by zig-sdl3.
    pub fn toSdl(event: Event) c.SDL_Event {
        return switch (event) {
            .quit => |val| .{ .quit = .{
                .type = c.SDL_EVENT_QUIT,
                .timestamp = val.common.timestamp,
            } },
            .terminating => |val| .{ .common = .{
                .type = c.SDL_EVENT_TERMINATING,
                .timestamp = val.timestamp,
            } },
            .window_resized => |val| .{ .window = .{
                .type = c.SDL_EVENT_WINDOW_RESIZED,
                .timestamp = val.common.timestamp,
            } },
            .key_up => |val| .{ .key = .{
                .type = c.SDL_EVENT_KEY_UP,
                .timestamp = val.common.timestamp,
                .windowID = val.window_id orelse 0,
                .which = if (val.which) |which| which.value else 0,
                .scancode = if (val.scancode) |code| code.toSdl() else c.SDL_SCANCODE_UNKNOWN,
                .key = keycode.Keycode.toSdl(val.key),
                .mod = val.mod.toSdl(),
                .raw = val.raw,
                .down = val.down,
                .repeat = val.repeat,
            } },
            .key_down => |val| .{ .key = .{
                .type = c.SDL_EVENT_KEY_DOWN,
                .timestamp = val.common.timestamp,
                .windowID = val.window_id orelse 0,
                .which = if (val.which) |which| which.value else 0,
                .scancode = if (val.scancode) |code| code.toSdl() else c.SDL_SCANCODE_UNKNOWN,
                .key = keycode.Keycode.toSdl(val.key),
                .mod = val.mod.toSdl(),
                .raw = val.raw,
                .down = val.down,
                .repeat = val.repeat,
            } },
            .mouse_motion => |val| .{ .motion = .{
                .type = c.SDL_EVENT_MOUSE_MOTION,
                .timestamp = val.common.timestamp,
                .windowID = val.window_id orelse 0,
                .which = if (val.which) |which| which.value else 0,
                .state = val.state.toSdl(),
                .x = val.x,
                .y = val.y,
                .xrel = val.x_rel,
                .yrel = val.y_rel,
            } },
            .mouse_button_up => |val| .{ .button = .{
                .type = c.SDL_EVENT_MOUSE_BUTTON_UP,
                .timestamp = val.common.timestamp,
                .windowID = val.window_id orelse 0,
                .which = mouse.ID.toSdl(val.which),
                .button = @intFromEnum(val.button),
                .down = val.down,
                .clicks = val.clicks,
                .x = val.x,
                .y = val.y,
            } },
            .mouse_button_down => |val| .{ .button = .{
                .type = c.SDL_EVENT_MOUSE_BUTTON_DOWN,
                .timestamp = val.common.timestamp,
                .windowID = val.window_id orelse 0,
                .which = mouse.ID.toSdl(val.which),
                .button = @intFromEnum(val.button),
                .down = val.down,
                .clicks = val.clicks,
                .x = val.x,
                .y = val.y,
            } },
            .mouse_wheel => |val| .{ .wheel = .{
                .type = c.SDL_EVENT_MOUSE_WHEEL,
                .timestamp = val.common.timestamp,
                .windowID = val.window_id orelse 0,
                .which = mouse.ID.toSdl(val.which),
                .x = val.scroll_x,
                .y = val.scroll_y,
                .direction = @intFromEnum(val.direction),
                .mouse_x = val.x,
                .mouse_y = val.y,
            } },
            .audio_device_added => |val| .{ .adevice = .{
                .type = c.SDL_EVENT_AUDIO_DEVICE_ADDED,
                .timestamp = val.common.timestamp,
                .which = val.device.value,
                .recording = val.recording,
            } },
            .audio_device_removed => |val| .{ .adevice = .{
                .type = c.SDL_EVENT_AUDIO_DEVICE_REMOVED,
                .timestamp = val.common.timestamp,
                .which = val.device.value,
                .recording = val.recording,
            } },
            .audio_device_format_changed => |val| .{ .adevice = .{
                .type = c.SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED,
                .timestamp = val.common.timestamp,
                .which = val.device.value,
                .recording = val.recording,
            } },
            .camera_device_added => |val| .{ .cdevice = .{
                .type = c.SDL_EVENT_CAMERA_DEVICE_ADDED,
                .timestamp = val.common.timestamp,
                .which = val.device.value,
            } },
            .camera_device_removed => |val| .{ .cdevice = .{
                .type = c.SDL_EVENT_CAMERA_DEVICE_REMOVED,
                .timestamp = val.common.timestamp,
                .which = val.device.value,
            } },
            .camera_device_approved => |val| .{ .cdevice = .{
                .type = c.SDL_EVENT_CAMERA_DEVICE_APPROVED,
                .timestamp = val.common.timestamp,
                .which = val.device.value,
            } },
            .camera_device_denied => |val| .{ .cdevice = .{
                .type = c.SDL_EVENT_CAMERA_DEVICE_DENIED,
                .timestamp = val.common.timestamp,
                .which = val.device.value,
            } },
            .user => |val| .{ .user = .{
                .type = val.event_type,
                .timestamp = val.common.timestamp,
                .windowID = val.window_id orelse 0,
                .code = val.code,
                .data1 = val.data1,
                .data2 = val.data2,
            } },
            .unknown => |val| .{ .common = .{
                .type = val.event_type,
                .timestamp = val.common.timestamp,
            } },
            .padding => .{
                .type = c.SDL_EVENT_ENUM_PADDING,
            },
        };
    }

    /// Create an unmanaged event from an SDL event in place.
    ///
    /// ## Function Parameters
    /// * `event`: Managed event to unmanage. The `event` passed in will be unusable after.
    ///
    /// ## Return Value
    /// Returns an unmanaged SDL event.
    ///
    /// ## Remarks
    /// This will modify memory in-place.
    /// This means that using the `event` passed into this afterwards will result in undefined behavior.
    ///
    /// ## Version
    /// This function is provided by zig-sdl3.
    pub fn toSdlInPlace(event: *Event) *c.SDL_Event {
        const unmanaged: *c.SDL_Event = @ptrCast(event);
        unmanaged.* = toSdl(event.*);
        return unmanaged;
    }
};

/// Add a callback to be triggered when an event is added to the event queue.
///
/// ## Function Parameters
/// * `UserData`: Type of user data.
/// * `event_filter`: An `events.Filter` function to call when an event happens.
/// * `user_data`: A pointer that is passed to `event_filter`.
///
/// ## Return Value
/// A C callback filter to use with `events.removeWatch()`.
///
/// ## Remarks
/// The `event_filter` will be called when an event happens, and its return value is ignored.
///
/// WARNING: Be very careful of what you do in the event filter function, as it may run in a different thread!
///
/// If the quit event is generated by a signal (e.g. SIGINT), it will bypass the internal queue and be delivered to the watch callback immediately,
/// and arrive at the next event poll.
///
/// Note: the callback is called for events posted by the user through `events.push()`, but not for disabled events,
/// nor for events by a filter callback set with `events.setFilter()`, nor for events posted by the user through `events.peep()`.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn addWatch(
    comptime UserData: type,
    comptime event_filter: Filter(UserData),
    user_data: ?*anyopaque,
) !FilterC {
    const Cb = struct {
        pub fn run(user_data_c: ?*anyopaque, event_c: [*c]c.SDL_Event) callconv(.c) bool {
            var event = Event.fromSdl(event_c.*);
            const ret = event_filter(@alignCast(@ptrCast(user_data_c)), &event);
            event_c.* = event.toSdl();
            return ret;
        }
    };
    try errors.wrapCallBool(c.SDL_AddEventWatch(Cb.run, user_data));
    return Cb.run;
}

/// If an event is available in the queue.
///
/// ## Return Value
/// Returns true if there is at least one event in the queue, false otherwise.
///
/// ## Remarks
/// This will not effect the events in the queue.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This is provided by zig-sdl3.
pub fn available() bool {
    return c.SDL_PollEvent(null);
}

/// Query the state of processing events by type.
///
/// ## Function Parameters
/// * `event_type`: The type of event.
///
/// ## Return Value
/// Returns true if the event is being processed, false otherwise.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn enabled(
    event_type: Type,
) bool {
    return c.SDL_EventEnabled(@intFromEnum(event_type));
}

/// Run a specific filter function on the current event queue, removing any events for which the filter returns false.
///
/// ## Function Parameters
/// * `UserData`: Type of user data.
/// * `event_filter`: An `events.Filter` function to call when an event happens.
/// * `user_data`: A pointer that is passed to `event_filter`.
///
/// ## Remarks
/// See `events.setFilter()` for more information.
/// Unlike `events.setFilter()`, this function does not change the filter permanently, it only uses the supplied filter until this function returns.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn filter(
    comptime UserData: type,
    comptime event_filter: Filter(UserData),
    user_data: ?*UserData,
) void {
    const Cb = struct {
        pub fn run(user_data_c: ?*anyopaque, event_c: [*c]c.SDL_Event) callconv(.c) bool {
            var event = Event.fromSdl(event_c.*);
            const ret = event_filter(@alignCast(@ptrCast(user_data_c)), &event);
            event_c.* = event.toSdl();
            return ret;
        }
    };
    c.SDL_FilterEvents(Cb.run, user_data);
}

/// Clear events of a specific type from the event queue.
///
/// ## Function Parameters
/// * `event_type`: The type of event to be cleared.
///
/// ## Remarks
/// This will unconditionally remove any events from the queue that match type.
/// If you need to remove a range of event types, use `events.flushGroup()` instead.
///
/// It's also normal to just ignore events you don't care about in your event loop without calling this function.
///
/// This function only affects currently queued events.
/// If you want to make sure that all pending OS events are flushed, you can call `events.pump()` on the main thread immediately before the flush call.
///
/// If you have user events with custom data that needs to be freed,
/// you should use `events.peep()` to remove and clean up those events before calling this function.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn flush(
    event_type: Type,
) void {
    c.SDL_FlushEvent(@intFromEnum(event_type));
}

/// Clear events of a range of types from the event queue.
///
/// ## Function Parameters
/// * `group`: The group of event types to flush from the event queue.
///
/// ## Remarks
/// This will unconditionally remove any events from the queue that are in the range of the category.
/// If you need to remove a single event type, use `events.flush()` instead.
///
/// It's also normal to just ignore events you don't care about in your event loop without calling this function.
///
/// This function only affects currently queued events.
/// If you want to make sure that all pending OS events are flushed, you can call `events.pump()` on the main thread immediately before the flush call.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn flushGroup(
    group: Group,
) void {
    const minmax = group.minMax();
    c.SDL_FlushEvents(minmax.min, minmax.max);
}

/// Query the current event filter.
///
/// ## Return Value
/// Returns the current event filter and user data passed to it.
/// This will return `null` if no event filter has been set.
///
/// ## Remarks
/// This function can be used to "chain" filters, by saving the existing filter before replacing it with a function that will call that saved filter.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// This function is available since SDL 3.2.0.
pub fn getFilter() ?struct { event_filter: FilterC, user_data: ?*anyopaque } {
    var event_filter: c.SDL_FunctionPointer = undefined;
    var user_data: ?*anyopaque = undefined;
    const ret = c.SDL_GetEventFilter(&event_filter, &user_data);
    if (!ret)
        return null;
    return .{ .event_filter = @ptrCast(event_filter), .user_data = user_data };
}

/// Check for the existence of a certain event type in the event queue.
///
/// ## Function Parameters
/// * `event_type`: The type of event to be queried.
///
/// ## Return Value
/// Returns true if events matching type are present, or false if events matching type are not present.
///
/// ## Remarks
/// If you need to check for a range of event types, use `events.hasGroup()` instead.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
pub fn has(
    event_type: Type,
) bool {
    return c.SDL_HasEvent(@intFromEnum(event_type));
}

/// Check for the existence of certain event types in the event queue.
///
/// ## Function Parameters
/// * `group`: The group to check for if present in the event queue.
///
/// ## Return Value
/// Returns true if events matching the group are present, or false if events matching the group are not present.
///
/// ## Remarks
/// If you need to check for a single event type, use `events.has()` instead.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn hasGroup(
    group: Group,
) bool {
    const minmax = group.minMax();
    return c.SDL_HasEvents(minmax.min, minmax.max);
}

/// Check the event queue for messages and optionally return them.
///
/// ## Function Parameters
/// * `events`: Destination slice to store events to.
/// * `action`: Action to take. Note that the `group` option does not apply to `events.Action.add`.
/// * `group`: When peeking or getting events, only consider events in the particular group.
///
/// ## Return Value
/// Returns the number of events actually stored.
///
/// ## Remarks
/// You may have to call `events.pump()` before calling this function.
/// Otherwise, the events may not be ready to be filtered when you call `events.peep()`.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn peep(
    events: []Event,
    action: Action,
    group: Group,
) !usize {
    const minmax = group.minMax();
    const raw: [*]c.SDL_Event = @ptrCast(events.ptr); // Hacky! We ensure in unit tests our enum is the same size so we can do this, then convert in-place.
    const ret = c.SDL_PeepEvents(raw, @intCast(events.len), @intFromEnum(action), minmax.min, minmax.max);
    for (0..@intCast(ret)) |ind| {
        _ = Event.fromSdlInPlace(&raw[ind]);
    }
    return @intCast(try errors.wrapCall(c_int, ret, -1));
}

/// Check the event queue for messages to see how many there are.
///
/// ## Function Parameters
/// * `num_events`: Max number of events to check for.
/// * `action`: Action to take. Note that the `group` option does not apply to `events.Action.add`.
/// * `group`: When peeking or getting events, only consider events in the particular group.
///
/// ## Return Value
/// Returns the number of events that would be peeked.
///
/// ## Remarks
/// You may have to call `events.pump()` before calling this function.
/// Otherwise, the events may not be ready to be filtered when you call `events.peep()`.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn peepSize(
    num_events: usize,
    action: Action,
    group: Group,
) !usize {
    const minmax = group.minMax();
    const ret = c.SDL_PeepEvents(null, @intCast(num_events), @intFromEnum(action), minmax.min, minmax.max);
    return @intCast(try errors.wrapCall(c_int, ret, -1));
}

/// Poll for currently pending events.
///
/// ## Return Value
/// Returns the next event in the queue or `null` if there is none available.
///
/// ## Remarks
/// The next event is removed from the queue and returned.
///
/// As this function may implicitly call `events.pump()`, you can only call this function in the thread that set the video mode.
///
/// `events.poll()` is the favored way of receiving system events since it can be done from the main loop
/// and does not suspend the main loop while waiting on an event to be posted.
///
/// The common practice is to fully process the event queue once every frame, usually as a first step before updating the game's state:
/// ```zig
/// while (game_is_still_running) {
///     while (events.poll()) |event| {  // Poll until all events are handled!
///         // Decide what to do with this event.
///     }
///
///     // Update game state, draw the current frame.
/// }
/// ```
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn poll() ?Event {
    var event: c.SDL_Event = undefined;
    const ret = c.SDL_PollEvent(&event);
    if (!ret)
        return null;
    return Event.fromSdl(event);
}

/// Pump the event loop, gathering events from the input devices.
///
/// ## Remarks
/// This function updates the event queue and internal input device state.
///
/// `events.pump()` gathers all the pending input information from devices and places it in the event queue.
/// Without calls to `events.pump()` no events would ever be placed on the queue.
/// Often the need for calls to `events.pump()` is hidden from the user since `events.poll()` and `events.wait()` implicitly call `events.pump()`.
/// However, if you are not polling or waiting for events (e.g. you are filtering them), then you must call `events.pump()` to force an event queue update.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn pump() void {
    c.SDL_PumpEvents();
}

/// Add an event to the event queue.
///
/// ## Function Parameters
/// * `event`: The event to be added to the queue.
///
/// ## Remarks
/// The event queue can actually be used as a two way communication channel.
/// Not only can events be read from the queue, but the user can also push their own events onto it.
/// The event is copied into the queue.
///
/// Note: Pushing device input events onto the queue doesn't modify the state of the device within SDL.
///
/// Note: Events pushed onto the queue with `events.push()` get passed through the event filter but events added with `events.peep()` do not.
///
/// For pushing application-specific events, please use `events.register()` to get an event type that does not conflict with other code
/// that also wants its own custom event types.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn push(
    event: Event,
) !void {
    var event_umanaged = event.toSdl();
    const ret = c.SDL_PushEvent(&event_umanaged);
    return errors.wrapCallBool(ret);
}

/// Allocate a set of user-defined events, and return the beginning event number for that set of events.
///
/// ## Function Parameters
/// * `num_events`: The number of events to be allocated.
///
/// ## Return Value
/// Returns the beginning event number, or `null` if `num_events` is invalid or if there are not enough user-defined events left.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn register(
    num_events: usize,
) ?c.SDL_EventType {
    const ret = c.SDL_RegisterEvents(@intCast(num_events));
    if (ret == 0)
        return null;
    return ret;
}

/// Remove an event watch callback added with `events.addWatch()`.
///
/// ## Function Parameters
/// * `event_filter`: Function originally passed to `events.addWatch()`.
/// * `user_data`: The user data originally passed to `events.addWatch()`.
///
/// ## Remarks
/// This function takes the same input as `events.addWatch()` to identify and delete the corresponding callback.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn removeWatch(
    event_filter: FilterC,
    user_data: ?*anyopaque,
) void {
    c.SDL_RemoveEventWatch(event_filter, user_data);
}

/// Set the state of processing events by type.
///
/// ## Function Parameters
/// * `event_type`: The type of event.
/// * `enabled`: Whether to process the event or not.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn setEnabled(
    event_type: Type,
    enable: bool,
) void {
    c.SDL_SetEventEnabled(@intFromEnum(event_type), enable);
}

/// Set up a filter to process all events before they are added to the internal event queue.
///
/// ## Function Parameters
/// * `UserData`: User data type.
/// * `event_filter`: A function to call when an event happens.
/// * `user_data`: User data passed to `event_filter`.
///
/// ## Return Value
/// Returns the C callback used.
///
/// If you just want to see events without modifying them or preventing them from being queued, you should use `events.addWatch()` instead.
///
/// If the filter function returns true when called, then the event will be added to the internal queue.
/// If it returns false, then the event will be dropped from the queue, but the internal state will still be updated.
/// This allows selective filtering of dynamically arriving events.
///
/// WARNING: Be very careful of what you do in the event filter function, as it may run in a different thread!
///
/// On platforms that support it, if the quit event is generated by an interrupt signal (e.g. pressing Ctrl-C),
/// it will be delivered to the application at the next event poll.
///
/// Note: Disabled events never make it to the event filter function; see `events.enabled()`.
///
/// Note: Events pushed onto the queue with `events.push()` get passed through the event filter, but events pushed onto the queue with `events.peep()` do not.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
///
/// ## Code Examples
/// TODO!!!
pub fn setFilter(
    comptime UserData: type,
    comptime event_filter: Filter(UserData),
    user_data: ?*UserData,
) FilterC {
    const Cb = struct {
        pub fn run(user_data_c: ?*anyopaque, event_c: [*c]c.SDL_Event) callconv(.c) bool {
            var event = Event.fromSdl(event_c.*);
            const ret = event_filter(@alignCast(@ptrCast(user_data_c)), &event);
            event_c.* = event.toSdl();
            return ret;
        }
    };
    c.SDL_SetEventFilter(Cb.run, user_data);
    return Cb.run;
}

/// Wait indefinitely for the next available event.
///
/// ## Remarks
/// As this function may implicitly call `events.pump()`, you can only call this function in the thread that initialized the video subsystem.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn wait() !void {
    return errors.wrapCallBool(c.SDL_WaitEvent(null));
}

/// Wait indefinitely for the next available event and pop it from the event queue.
///
/// ## Return Value
/// Returns the event popped.
///
/// ## Remarks
/// The next event is removed from the queue and returned.
///
/// As this function may implicitly call `events.pump()`, you can only call this function in the thread that initialized the video subsystem.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn waitAndPop() !Event {
    var event: c.SDL_Event = undefined;
    const ret = c.SDL_WaitEvent(&event);
    try errors.wrapCallBool(ret);
    return Event.fromSdl(event);
}

/// Wait until the specified timeout (in milliseconds) for the next available event.
///
/// ## Function Parameters
/// * `timeout_millseconds`: The maximum number of milliseconds to wait for the next available event.
///
/// ## Return Value
/// Returns true if an event appeared before the timeout.
///
/// ## Remarks
/// As this function may implicitly call `events.pump()`, you can only call this function in the thread that initialized the video subsystem.
///
/// The timeout is not guaranteed, the actual wait time could be longer due to system scheduling.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn waitTimeout(
    timeout_milliseconds: u31,
) bool {
    return c.SDL_WaitEventTimeout(null, @intCast(timeout_milliseconds));
}

/// Wait until the specified timeout (in milliseconds) for the next available event and pop it.
///
/// ## Function Parameters
/// * `timeout_millseconds`: The maximum number of milliseconds to wait for the next available event.
///
/// ## Return Value
/// If the call times out, then `null` is returned.
/// Returns the event popped from the event queue if event has appeared before the timeout.
///
/// ## Remarks
/// The next event is removed from the queue and returned.
///
/// As this function may implicitly call `events.pump()`, you can only call this function in the thread that initialized the video subsystem.
///
/// The timeout is not guaranteed, the actual wait time could be longer due to system scheduling.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn waitAndPopTimeout(
    timeout_milliseconds: u31,
) ?Event {
    var event: c.SDL_Event = undefined;
    const ret = c.SDL_WaitEventTimeout(&event, @intCast(timeout_milliseconds));
    if (!ret)
        return null;
    return Event.fromSdl(event);
}

fn dummyFilter(
    user_data: ?*void,
    event: *Event,
) bool {
    _ = user_data;
    _ = event;
    return true;
}

// Test SDL events.
test "Events" {
    std.testing.refAllDeclsRecursive(@This());

    defer sdl3.shutdown();
    try sdl3.init(.{ .events = true });
    defer sdl3.quit(.{ .events = true });

    setEnabled(.quit, true);
    try push(.{ .quit = .{ .common = .{ .timestamp = 27 } } });
    pump();
    try std.testing.expect(has(.quit));
    try std.testing.expect(hasGroup(.application));
    try std.testing.expect(available());
    try std.testing.expect(enabled(.quit));

    try std.testing.expect(try peepSize(1, .peek, .application) > 0);
    var buf = [_]Event{undefined};
    _ = try peep(&buf, .peek, .application);

    try std.testing.expect(poll() != null);
    // _ = try wait(false); // This is not deterministic and may hang so don't.
    _ = waitTimeout(1);

    flush(.quit);
    flushGroup(.all);

    const group = Group.application;
    try std.testing.expect(group.eventIn(.quit));
    _ = group.minMax();
    var group_iter = group.iterator();
    while (group_iter.next()) |val| {
        _ = val;
    }

    filter(void, dummyFilter, null);
    const curr_filter = setFilter(void, dummyFilter, null);
    try std.testing.expectEqual(@intFromPtr(curr_filter), @intFromPtr(getFilter().?.event_filter));

    const watch = try addWatch(void, dummyFilter, null);
    removeWatch(watch, null);

    try std.testing.expect(register(1) != null);
    _ = buf[0].getWindow();
}
