const c = @import("c.zig").c;
const init = @import("init.zig");
const errors = @import("errors.zig");
const std = @import("std");
const stdinc = @import("stdinc.zig");

/// Callback function that will be called when the clipboard is cleared, or new data is set.
///
/// ## Function Parameters
/// * `user_data`: A pointer to provided user data.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub const CleanupCallback = *const fn (user_data: ?*anyopaque) callconv(.c) void;

/// Callback function that will be called when data for the specified mime-type is requested by the OS.
///
/// ## Function Parameters
/// * `user_data`: A pointer to provided user data.
/// * `mime_type`: The requested mime-type.
/// * `size`: A pointer filled in with the length of the returned data.
///
/// ## Return Value
/// Returns a pointer to the data for the provided mime-type.
/// Returning `null` or setting length to `0` will cause no data to be sent to the "receiver".
/// It is up to the receiver to handle this.
/// Essentially returning no data is more or less undefined behavior and may cause breakage in receiving applications.
/// The returned data will not be freed so it needs to be retained and dealt with internally.
///
/// ## Remarks
/// The callback function is called with `null` as the mime_type when the clipboard is cleared or new data is set.
/// The clipboard is automatically cleared in `init.shutdown()`.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub const DataCallback = *const fn (user_data: ?*anyopaque, mime_type: [*c]const u8, size: [*c]usize) callconv(.c) ?*anyopaque;

/// Clear the clipboard data.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn clearData() !void {
    const ret = c.SDL_ClearClipboardData();
    return errors.wrapCallBool(ret);
}

/// Get the data from clipboard for a given mime type.
///
/// ## Function Parameters
/// * `mime_type`: MIME type to read from the clipboard.
///
/// ## Return Value
/// Returns the retrieved data buffer.
///
/// ## Remarks
/// The size of text data does not include the terminator, but the text is guaranteed to be null terminated.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getData(
    mime_type: [:0]const u8,
) ![:0]const u8 {
    var size: usize = undefined;
    const val = c.SDL_GetClipboardData(
        mime_type,
        &size,
    );
    const ret: [*]const u8 = @ptrCast(try errors.wrapNull(*anyopaque, val));
    return ret[0..size :0];
}

/// Retrieve the list of mime types available in the clipboard.
///
/// ## Return Value
/// Returns a slice strings with mime types.
/// The slice should be freed with `stdinc.free()`.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getMimeTypes() ![][*:0]u8 {
    var num_mime_types: usize = undefined;
    const val = c.SDL_GetClipboardMimeTypes(
        &num_mime_types,
    );
    const ret = try errors.wrapCallCPtr([*c]u8, val);
    return @ptrCast(ret[0..num_mime_types]);
}

/// Get UTF-8 text from the primary selection.
///
/// ## Return Value
/// Returns the primary selection text.
/// The slice should be freed with `stdinc.free()`.
///
/// ## Remarks
/// This functions returns an empty string if there was not enough memory left for a copy of the primary selection's content.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getPrimarySelectionText() ![:0]const u8 {
    const ret = c.SDL_GetPrimarySelectionText();
    const converted_ret = std.mem.span(ret);
    if (std.mem.eql(u8, converted_ret, "")) {
        if (errors.error_callback) |val|
            val(errors.get());
        return error.SdlError;
    }
    return converted_ret;
}

/// Get UTF-8 text from the clipboard.
///
/// ## Return Value
/// Returns the clipboard text.
/// The slice should be freed with `stdinc.free()`.
///
/// ## Remarks
/// This functions fails if there was not enough memory left for a copy of the clipboard's content.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getText() ![:0]u8 {
    const ret = c.SDL_GetClipboardText();
    const converted_ret: [:0]u8 = std.mem.span(ret);
    if (std.mem.eql(u8, converted_ret, "")) {
        if (errors.error_callback) |val|
            val(errors.get());
        return error.SdlError;
    }
    return converted_ret;
}

/// Query whether there is data in the clipboard for the provided mime type.
///
/// ## Function Parameters
/// * `mime_type`: The mime type to check for data for.
///
/// ## Return Value
/// Returns true if there exists data in clipboard for the provided mime type, false if it does not.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn hasData(
    mime_type: [:0]const u8,
) bool {
    const ret = c.SDL_HasClipboardData(
        mime_type.ptr,
    );
    return ret;
}

/// Query whether the primary selection exists and contains a non-empty text string.
///
/// ## Return Value
/// Returns true if the primary selection has text, or false if it does not.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn hasPrimarySelectionText() bool {
    const ret = c.SDL_HasPrimarySelectionText();
    return ret;
}

/// Query whether the clipboard exists and contains a non-empty text string.
///
/// ## Return Value
/// Returns true if the clipboard has text, or false if it does not.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn hasText() bool {
    const ret = c.SDL_HasClipboardText();
    return ret;
}

/// Offer clipboard data to the OS.
///
/// ## Function Parameters
/// * `callback`: A function pointer to the function that provides the clipboard data.
/// * `cleanup`: A function pointer to the function that cleans up the clipboard data.
/// * `user_data`: An opaque pointer that will be forwarded to the callbacks.
/// * `mime_types`: A slice of mime-types that are being offered.
///
/// ## Remarks
/// Tell the operating system that the application is offering clipboard data for each of the provided mime-types.
/// Once another application requests the data the callback function will be called, allowing it to generate and respond with the data for the requested mime-type.
///
/// The size of text data does not include any terminator, and the text does not need to be null terminated (e.g. you can directly copy a portion of a document).
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn setData(
    callback: DataCallback,
    cleanup: CleanupCallback,
    user_data: ?*anyopaque,
    mime_types: [][*:0]const u8,
) !void {
    const ret = c.SDL_SetClipboardData(
        callback,
        cleanup,
        user_data,
        @ptrCast(mime_types.ptr),
        @intCast(mime_types.len),
    );
    return errors.wrapCallBool(ret);
}

/// Put UTF-8 text into the primary selection.
///
/// ## Function Parameters
/// * `text`: The text to store in the primary selection.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn setPrimarySelectionText(
    text: [:0]const u8,
) !void {
    const ret = c.SDL_SetPrimarySelectionText(
        text,
    );
    return errors.wrapCallBool(ret);
}

/// Put UTF-8 text into the clipboard.
///
/// ## Function Parameters
/// * `text`: The text to store in the clipboard.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn setText(
    text: [:0]const u8,
) !void {
    const ret = c.SDL_SetClipboardText(
        text.ptr,
    );
    return errors.wrapCallBool(ret);
}

fn cleanup_cb(
    user_data: ?*anyopaque,
) callconv(.c) void {
    _ = user_data;
}

fn data_cb(
    user_data: ?*anyopaque,
    mime_type: [*c]const u8,
    size: [*c]usize,
) callconv(.c) ?*anyopaque {
    _ = user_data;
    _ = mime_type;
    size.* = 1;
    return @constCast(@ptrCast(&data_cb));
}

// Test the clipboard. Yes it needs video.
test "Clipboard" {
    std.testing.refAllDeclsRecursive(@This());

    defer init.shutdown();
    const flags = init.Flags{ .video = true };
    try init.init(flags);
    defer init.quit(flags);

    const text_raw: ?[:0]u8 = getText() catch null;

    try setText("Hello World!");
    const gotten_text = try getText();
    defer stdinc.free(gotten_text);
    try std.testing.expectEqualStrings("Hello World!", gotten_text);
    try std.testing.expect(hasText());

    const mimes = try getMimeTypes();
    defer stdinc.free(mimes);

    if (hasPrimarySelectionText()) {
        const primary = try getPrimarySelectionText();
        try setPrimarySelectionText(primary);
    }

    var mime_types = [_][*:0]const u8{"GOTA"};
    try setData(data_cb, cleanup_cb, null, &mime_types);
    try std.testing.expect(hasData("GOTA"));
    _ = try getData("GOTA");

    clearData() catch {};
    try std.testing.expect(!hasText());
    try std.testing.expect(!hasData("GOTA"));

    if (text_raw) |val| {
        setText(val) catch {};
        stdinc.free(val.ptr);
    }
}
