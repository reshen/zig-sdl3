const c = @import("c.zig").c;
const errors = @import("errors.zig");
const std = @import("std");

/// A callback that fires when an SDL assertion fails.
///
/// ## Function Parameters
/// * `assert_data`: A pointer to the `c.SDL_AssertData` structure corresponding to the current assertion.
/// * `user_data`: What was passed as userdata to `assert.setHandler()`.
///
/// ## Return Value
/// Returns a `c.SDL_AssertState` value indicating how to handle the failure.
///
/// ## Thread Safety
/// This callback may be called from any thread that triggers an assert at any time.
///
/// ## Version
/// This datatype is available since SDL 3.2.0.
pub const Handler = *const fn (
    assert_data: [*c]const c.SDL_AssertData,
    user_data: ?*anyopaque,
) callconv(.c) c.SDL_AssertState;

/// Possible outcomes from a triggered assertion.
///
/// ## Remarks
/// When an enabled assertion triggers, it may call the assertion handler (possibly one provided by the app via `assert.setHandler()`,
/// which will return one of these values, possibly after asking the user.
///
/// Then SDL will respond based on this outcome (loop around to retry the condition, try to break in a debugger, kill the program, or ignore the problem).
///
/// ## Version
/// This enum is available since SDL 3.2.0.
pub const State = enum(c_int) {
    /// Retry the assert immediately.
    retry = c.SDL_ASSERTION_RETRY,
    /// Make the debugger trigger a breakpoint.
    breakpoint = c.SDL_ASSERTION_BREAK,
    /// Terminate the program.
    abort = c.SDL_ASSERTION_ABORT,
    /// Ignore the assert.
    ignore = c.SDL_ASSERTION_IGNORE,
    /// Ignore the assert from now on.
    always_ignore = c.SDL_ASSERTION_ALWAYS_IGNORE,
};

/// Get the default assertion handler.
///
/// ## Return Value
/// Returns the default `assert.Handler` that is called when an assert triggers.
///
/// ## Remarks
/// This returns the function pointer that is called by default when an assertion is triggered.
/// This is an internal function provided by SDL, that is used for assertions when `assert.setHandler()` hasn't been used to provide a different function.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getDefaultHandler() Handler {
    return c.SDL_GetDefaultAssertionHandler().?;
}

/// Get the current assertion handler.
///
/// ## Return Value
/// Returns the current assertion handler and the `user_data` associated with it.
///
/// ## Remarks
/// This returns the function pointer that is called when an assertion is triggered.
/// This is either the value last passed to `assert.setHandler()`, or if no application-specified function is set,
/// is equivalent to calling `assert.getDefaultHandler()`.
///
/// The `user_data` was passed to `assert.setHandler()`.
/// This value will always be `null` for the default handler.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getHandler() struct { handler: Handler, user_data: ?*anyopaque } {
    var user_data: ?*anyopaque = undefined;
    const handler = c.SDL_GetAssertionHandler(&user_data).?;
    return .{ .handler = handler, .user_data = user_data };
}

/// Get a list of all assertion failures.
///
/// ## Return Value
/// Returns a list of all failed assertions or `null` if the list is empty.
/// This memory should not be modified or freed by the application.
/// This pointer remains valid until the next call to `init.shutdown()` or `assert.resetReport()`.
///
/// ## Remarks
/// This function gets all assertions triggered since the last call to `assert.resetReport()`, or the start of the program.
///
/// The proper way to examine this data looks something like this:
/// ```zig
/// var item = assert.getReport();
/// while (item) |val| {
///    std.debug("'{s}', {s} ({s}:{d}), triggered {d} times, always ignore: {s}.\n",
///           val.condition, val.function, val.filename,
///           val.linenum, val.trigger_count,
///           if (val.always_ignore) "yes" else "no");
///    item = item.next;
/// }
/// ```
///
/// ## Thread Safety
/// This function is not thread safe. Other threads calling S`assert.resetReport()` simultaneously, may render the returned pointer invalid.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getReport() ?*const c.SDL_AssertData {
    return c.SDL_GetAssertionReport();
}

/// Report an assertion.
///
/// ## Function Parameters
/// * `data`: Assert data structure. Should be unique for this call.
/// * `location`: Source location from `@src()`.
///
/// ## Return Value
/// Returns assert state.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn report(
    data: *c.SDL_AssertData,
    location: std.builtin.SourceLocation,
) State {
    return @enumFromInt(c.SDL_ReportAssertion(
        data,
        location.fn_name,
        location.file,
        @intCast(location.line),
    ));
}

/// Clear the list of all assertion failures.
///
/// ## Remarks
/// This function will clear the list of all assertions triggered up to that point.
/// Immediately following this call, `assert.getReport()` will return no items.
/// In addition, any previously-triggered assertions will be reset to a `trigger_count` of zero, and their `always_ignore` state will be `false`.
///
/// ## Thread Safety
/// This function is not thread safe.
/// Other threads triggering an assertion, or simultaneously calling this function may cause memory leaks or crashes.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn resetReport() void {
    c.SDL_ResetAssertionReport();
}

/// Set an application-defined assertion handler.
///
/// ## Function Parameters
/// * `handler`: The `assert.Handler` function to call when an assertion fails or `null` for the default handler.
/// * `user_data`: A pointer that is passed to handler.
///
/// ## Remarks
/// This function allows an application to show its own assertion UI and/or force the response to an assertion failure.
/// If the application doesn't provide this, SDL will try to do the right thing, popping up a system-specific GUI dialog, and probably minimizing any fullscreen windows.
///
/// This callback may fire from any thread, but it runs wrapped in a mutex, so it will only fire from one thread at a time.
///
/// This callback is NOT reset to SDL's internal handler upon `init.shutdown()`!
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn setHandler(
    handler: ?Handler,
    user_data: ?*anyopaque,
) void {
    c.SDL_SetAssertionHandler(handler, user_data);
}

const TestHandlerCallbackData = struct {
    last_data: ?*const c.SDL_AssertData = null,
};

fn testAssertCallback(assert_data: [*c]const c.SDL_AssertData, user_data: ?*anyopaque) callconv(.c) c.SDL_AssertState {
    var data: *TestHandlerCallbackData = @ptrCast(@alignCast(user_data));
    data.last_data = assert_data;
    return @intFromEnum(State.ignore);
}

// Test asserting functionality.
test "Assert" {
    std.testing.refAllDeclsRecursive(@This());

    const handler = getHandler();
    try std.testing.expectEqual(getDefaultHandler(), handler.handler);
    try std.testing.expectEqual(null, handler.user_data);

    var data = TestHandlerCallbackData{};
    setHandler(testAssertCallback, &data);

    try std.testing.expectEqual(null, getReport());

    var assert_data1 = c.SDL_AssertData{};
    var assert_data2 = c.SDL_AssertData{};
    _ = report(&assert_data1, @src());
    _ = report(&assert_data2, @src());

    const report2: *const c.SDL_AssertData = getReport().?;
    const report1: *const c.SDL_AssertData = report2.next.?;
    try std.testing.expectEqual(null, report1.next);
    try std.testing.expectEqual(214, report1.linenum);
    try std.testing.expectEqualStrings("test.Assert", std.mem.span(report1.function));
    try std.testing.expectEqualStrings("assert.zig", std.mem.span(report1.filename));
    try std.testing.expectEqual(215, report2.linenum);
    try std.testing.expectEqualStrings("test.Assert", std.mem.span(report2.function));
    try std.testing.expectEqualStrings("assert.zig", std.mem.span(report2.filename));

    resetReport();
    try std.testing.expectEqual(null, getReport());

    setHandler(null, null);
    try std.testing.expectEqual(getDefaultHandler(), getHandler().handler);
}
