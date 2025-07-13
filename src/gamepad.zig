const c = @import("c.zig").c;
const errors = @import("errors.zig");
const joystick = @import("joystick.zig");
const std = @import("std");

/// The list of axes available on a gamepad.
///
/// ## Remarks
/// Thumbstick axis values range from `joystick.axis_min` to `joystick.axis_max`, and are centered within `~8000` of zero,
/// though advanced UI will allow users to set or autodetect the dead zone, which varies between gamepads.
///
/// Trigger axis values range from `0` (released) to `joystick.axis_max` (fully pressed) when reported by `gamepad.Gamepad.getAxis()`.
/// Note that this is not the same range that will be reported by the lower-level `joystick.Joystick.getAxis()`.
///
/// ## Version
/// This enum is available since SDL 3.2.0.
pub const Axis = enum(c_int) {
    left_x = c.SDL_GAMEPAD_AXIS_LEFTX,
    left_y = c.SDL_GAMEPAD_AXIS_LEFTY,
    right_x = c.SDL_GAMEPAD_AXIS_RIGHTX,
    right_y = c.SDL_GAMEPAD_AXIS_RIGHTY,
    left_trigger = c.SDL_GAMEPAD_AXIS_LEFT_TRIGGER,
    right_trigger = c.SDL_GAMEPAD_AXIS_RIGHT_TRIGGER,

    /// Convert from SDL.
    pub fn fromSdl(value: c_int) ?Axis {
        if (value == c.SDL_GAMEPAD_AXIS_INVALID)
            return null;
        return @enumFromInt(value);
    }

    /// Convert to SDL.
    pub fn toSdl(self: ?Axis) c_int {
        if (self) |val|
            return @intFromEnum(val);
        return c.SDL_GAMEPAD_AXIS_INVALID;
    }
};

/// A mapping between one joystick input to a gamepad control.
///
/// ## Remarks
/// A gamepad has a collection of several bindings, to say, for example, when joystick button number `5` is pressed, that should be treated like the gamepad's "start" button.
///
/// SDL has these bindings built-in for many popular controllers, and can add more with a simple text string.
/// Those strings are parsed into a collection of these structs to make it easier to operate on the data.
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const Binding = struct {
    /// Joystick information to bind from.
    input: union(BindingType) {
        /// Joystick button index.
        button: u32,
        /// Joystick axis index and min/max.
        axis: packed struct {
            index: u32,
            min: i16,
            max: i16,
        },
        /// Joystick hat index and type.
        hat: packed struct {
            index: u32,
            type: joystick.Hat,
        },
    },
    /// Output gamepad button or axis to use.
    output: union(BindingType) {
        /// Maps to a gamepad button.
        button: Button,
        /// Maps to a gamepad axis.
        axis: packed struct {
            index: Axis,
            min: i16,
            max: i16,
        },
        /// Do not use this!
        hat: Button,
    },

    // Size check.
    comptime {
        std.debug.assert(@sizeOf(Binding) <= @sizeOf(c.SDL_GamepadBinding));
    }

    /// Convert from SDL in place.
    pub fn fromSdlInPlace(ptr: *c.SDL_GamepadBinding) void {
        const ret = Binding{
            .input = switch (ptr.input_type) {
                c.SDL_GAMEPAD_BINDTYPE_AXIS => .{ .axis = .{
                    .index = @intCast(ptr.input.axis.axis),
                    .min = @intCast(ptr.input.axis.axis_min),
                    .max = @intCast(ptr.input.axis.axis_max),
                } },
                c.SDL_GAMEPAD_BINDTYPE_HAT => .{ .hat = .{
                    .index = @intCast(ptr.input.hat.hat),
                    .type = @enumFromInt(ptr.input.hat.hat_mask),
                } },
                else => .{
                    .button = @intCast(ptr.input.button),
                },
            },
            .output = switch (ptr.output_type) {
                c.SDL_GAMEPAD_BINDTYPE_AXIS => .{ .axis = .{
                    .index = @enumFromInt(ptr.output.axis.axis),
                    .min = @intCast(ptr.output.axis.axis_min),
                    .max = @intCast(ptr.output.axis.axis_max),
                } },
                else => .{
                    .button = @enumFromInt(ptr.output.button),
                },
            },
        };
        @as(*Binding, @alignCast(@ptrCast(ptr))).* = ret;
    }
};

/// Types of gamepad control bindings.
///
/// ## Remarks
/// A gamepad is a collection of bindings that map arbitrary joystick buttons, axes and hat switches to specific positions on a generic console-style gamepad.
/// This enum is used as part of `gamepad.Binding` to specify those mappings.
///
/// ## Version
/// This enum is available since SDL 3.2.0.
pub const BindingType = enum(c_uint) {
    button = c.SDL_GAMEPAD_BINDTYPE_BUTTON,
    axis = c.SDL_GAMEPAD_BINDTYPE_AXIS,
    hat = c.SDL_GAMEPAD_BINDTYPE_HAT,

    /// Convert from SDL.
    pub fn fromSdl(value: c.SDL_GamepadBindingType) ?BindingType {
        if (value == c.SDL_GAMEPAD_BINDTYPE_NONE)
            return null;
        return @enumFromInt(value);
    }

    /// Convert to SDL.
    pub fn toSdl(self: ?BindingType) c.SDL_GamepadBindingType {
        if (self) |val|
            return @intFromEnum(val);
        return c.SDL_GAMEPAD_BINDTYPE_NONE;
    }
};

/// The list of buttons available on a gamepad.
///
/// ## Remarks
/// For controllers that use a diamond pattern for the face buttons, the south/east/west/north buttons below correspond to the locations in the diamond pattern.
/// For Xbox controllers, this would be A/B/X/Y, for Nintendo Switch controllers,
/// this would be B/A/Y/X, for GameCube controllers this would be A/X/B/Y, for PlayStation controllers this would be Cross/Circle/Square/Triangle.
///
/// For controllers that don't use a diamond pattern for the face buttons,
/// the south/east/west/north buttons indicate the buttons labeled A, B, C, D, or 1, 2, 3, 4, or for controllers that aren't labeled, they are the primary, secondary, etc. buttons.
///
/// The activate action is often the south button and the cancel action is often the east button,
/// but in some regions this is reversed, so your game should allow remapping actions based on user preferences.
///
/// You can query the labels for the face buttons using `gamepad.Button.getLabel()`.
///
/// ## Version
/// This enum is available since SDL 3.2.0.
pub const Button = enum(c_int) {
    /// Bottom face button (e.g. Xbox A button).
    south = c.SDL_GAMEPAD_BUTTON_SOUTH,
    /// Right face button (e.g. Xbox B button).
    east = c.SDL_GAMEPAD_BUTTON_EAST,
    /// Left face button (e.g. Xbox X button).
    west = c.SDL_GAMEPAD_BUTTON_WEST,
    /// Top face button (e.g. Xbox Y button).
    north = c.SDL_GAMEPAD_BUTTON_NORTH,
    back = c.SDL_GAMEPAD_BUTTON_BACK,
    guide = c.SDL_GAMEPAD_BUTTON_GUIDE,
    start = c.SDL_GAMEPAD_BUTTON_START,
    left_stick = c.SDL_GAMEPAD_BUTTON_LEFT_STICK,
    right_stick = c.SDL_GAMEPAD_BUTTON_RIGHT_STICK,
    left_shoulder = c.SDL_GAMEPAD_BUTTON_LEFT_SHOULDER,
    right_shoulder = c.SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER,
    dpad_up = c.SDL_GAMEPAD_BUTTON_DPAD_UP,
    dpad_down = c.SDL_GAMEPAD_BUTTON_DPAD_DOWN,
    dpad_left = c.SDL_GAMEPAD_BUTTON_DPAD_LEFT,
    dpad_right = c.SDL_GAMEPAD_BUTTON_DPAD_RIGHT,
    /// Additional button (e.g. Xbox Series X share button, PS5 microphone button, Nintendo Switch Pro capture button, Amazon Luna microphone button, Google Stadia capture button).
    misc1 = c.SDL_GAMEPAD_BUTTON_MISC1,
    /// Upper or primary paddle, under your right hand (e.g. Xbox Elite paddle P1)
    right_paddle1 = c.SDL_GAMEPAD_BUTTON_RIGHT_PADDLE1,
    /// Upper or primary paddle, under your left hand (e.g. Xbox Elite paddle P3).
    left_paddle1 = c.SDL_GAMEPAD_BUTTON_LEFT_PADDLE1,
    /// Lower or secondary paddle, under your right hand (e.g. Xbox Elite paddle P2).
    right_paddle2 = c.SDL_GAMEPAD_BUTTON_RIGHT_PADDLE2,
    /// Lower or secondary paddle, under your left hand (e.g. Xbox Elite paddle P4).
    left_paddle2 = c.SDL_GAMEPAD_BUTTON_LEFT_PADDLE2,
    /// PS4/PS5 touchpad button.
    touchpad = c.SDL_GAMEPAD_BUTTON_TOUCHPAD,
    /// Additional button.
    misc2 = c.SDL_GAMEPAD_BUTTON_MISC2,
    /// Additional button.
    misc3 = c.SDL_GAMEPAD_BUTTON_MISC3,
    /// Additional button.
    misc4 = c.SDL_GAMEPAD_BUTTON_MISC4,
    /// Additional button.
    misc5 = c.SDL_GAMEPAD_BUTTON_MISC5,
    /// Additional button.
    misc6 = c.SDL_GAMEPAD_BUTTON_MISC6,

    /// Convert from SDL.
    pub fn fromSdl(value: c.SDL_GamepadButton) ?Button {
        if (value == c.SDL_GAMEPAD_BUTTON_INVALID)
            return null;
        return @enumFromInt(value);
    }

    /// Convert to SDL.
    pub fn toSdl(self: ?Button) c.SDL_GamepadButton {
        if (self) |val|
            return @intFromEnum(val);
        return c.SDL_GAMEPAD_BUTTON_INVALID;
    }
};

/// The set of gamepad button labels.
///
/// ## Remarks
/// This isn't a complete set, just the face buttons to make it easy to show button prompts.
///
/// For a complete set, you should look at the button and gamepad type and have a set of symbols that work well with your art style.
///
/// ## Version
/// This enum is available since SDL 3.2.0.
pub const ButtonLabel = enum(c_uint) {
    a = c.SDL_GAMEPAD_BUTTON_LABEL_A,
    b = c.SDL_GAMEPAD_BUTTON_LABEL_B,
    x = c.SDL_GAMEPAD_BUTTON_LABEL_X,
    y = c.SDL_GAMEPAD_BUTTON_LABEL_Y,
    cross = c.SDL_GAMEPAD_BUTTON_LABEL_CROSS,
    circle = c.SDL_GAMEPAD_BUTTON_LABEL_CIRCLE,
    square = c.SDL_GAMEPAD_BUTTON_LABEL_SQUARE,
    triangle = c.SDL_GAMEPAD_BUTTON_LABEL_TRIANGLE,

    /// Convert from SDL.
    pub fn fromSdl(value: c.SDL_GamepadButtonLabel) ?ButtonLabel {
        if (value == c.SDL_GAMEPAD_BUTTON_LABEL_UNKNOWN)
            return null;
        return @enumFromInt(value);
    }

    /// Convert to SDL.
    pub fn toSdl(self: ?ButtonLabel) c.SDL_GamepadButtonLabel {
        if (self) |val|
            return @intFromEnum(val);
        return c.SDL_GAMEPAD_BUTTON_LABEL_UNKNOWN;
    }
};

/// The structure used to identify an SDL gamepad.
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const Gamepad = struct {
    value: *c.SDL_Gamepad,
};

/// Standard gamepad types.
///
/// ## Remarks
/// This type does not necessarily map to first-party controllers from Microsoft/Sony/Nintendo; in many cases, third-party controllers can report as these,
/// either because they were designed for a specific console, or they simply most closely match that console's controllers (does it have A/B/X/Y buttons or X/O/Square/Triangle?
/// Does it have a touchpad? etc).
///
/// ## Version
/// This enum is available since SDL 3.2.0.
pub const Type = enum(c_uint) {
    standard = c.SDL_GAMEPAD_TYPE_STANDARD,
    xbox360 = c.SDL_GAMEPAD_TYPE_XBOX360,
    xbox_one = c.SDL_GAMEPAD_TYPE_XBOXONE,
    ps3 = c.SDL_GAMEPAD_TYPE_PS3,
    ps4 = c.SDL_GAMEPAD_TYPE_PS4,
    ps5 = c.SDL_GAMEPAD_TYPE_PS5,
    switch_pro = c.SDL_GAMEPAD_TYPE_NINTENDO_SWITCH_PRO,
    switch_joycon_left = c.SDL_GAMEPAD_TYPE_NINTENDO_SWITCH_JOYCON_LEFT,
    switch_joycon_right = c.SDL_GAMEPAD_TYPE_NINTENDO_SWITCH_JOYCON_RIGHT,
    switch_joycon_pair = c.SDL_GAMEPAD_TYPE_NINTENDO_SWITCH_JOYCON_PAIR,
    // gamecube = c.SDL_GAMEPAD_TYPE_GAMECUBE,

    /// Convert from SDL.
    pub fn fromSdl(value: c.SDL_GamepadType) ?Type {
        if (value == c.SDL_GAMEPAD_TYPE_UNKNOWN)
            return null;
        return @enumFromInt(value);
    }

    /// Convert to SDL.
    pub fn toSdl(self: ?Type) c.SDL_GamepadType {
        if (self) |val|
            return @intFromEnum(val);
        return c.SDL_GAMEPAD_TYPE_UNKNOWN;
    }
};

// Gamepad tests.
test "Gamepad" {
    std.testing.refAllDeclsRecursive(@This());
}
