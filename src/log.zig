const c = @import("c.zig").c;
const errors = @import("errors.zig");
const std = @import("std");
const stdinc = @import("stdinc.zig");

/// Maximum stack size to use for a log message.
const max_log_message_stack = 1024;

/// The prototype for the log output callback function.
///
/// ## Function Parameters
/// * `user_data`: What was passed as userdata to `log.setLogOutputFunction()`.
/// * `category`: The category of the message.
/// * `priority`: The priority of the message.
/// * `message`: The message being output.
///
/// ## Thread Safety
/// This function is called by SDL when there is new text to be logged.
/// A mutex is held so that this function is never called by more than one thread at once.
///
/// ## Version
/// This datatype is available since SDL 3.2.0.
pub const LogOutputFunction = *const fn (
    user_data: ?*anyopaque,
    category: c_int,
    priority: c.SDL_LogPriority,
    message: [*c]const u8,
) callconv(.c) void;

/// The predefined log priorities.
///
/// ## Version
/// This enum is available since SDL 3.2.0.
pub const Priority = enum(c_uint) {
    trace = c.SDL_LOG_PRIORITY_TRACE,
    verbose = c.SDL_LOG_PRIORITY_VERBOSE,
    debug = c.SDL_LOG_PRIORITY_DEBUG,
    info = c.SDL_LOG_PRIORITY_INFO,
    warn = c.SDL_LOG_PRIORITY_WARN,
    err = c.SDL_LOG_PRIORITY_ERROR,
    critical = c.SDL_LOG_PRIORITY_CRITICAL,

    /// Make a priority from an SDL value.
    pub fn fromSdl(val: c_uint) ?Priority {
        if (val == c.SDL_LOG_PRIORITY_INVALID)
            return null;
        return @enumFromInt(val);
    }

    /// Set the text prepended to log messages of a given priority.
    ///
    /// ## Function Parameters
    /// * `self`: The priority to modify.
    /// * `prefix`: The prefix to use for that log priority, or `null` to use no prefix.
    ///
    /// ## Remarks
    /// By default `log.Priority.info` and below have no prefix, and `log.priority.warn` and higher have a prefix showing their priority, e.g. "WARNING: ".
    ///
    /// Note that prefixes will only effect the default log callback and not any custom ones.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setPrefix(
        self: Priority,
        prefix: ?[:0]const u8,
    ) !void {
        const ret = c.SDL_SetLogPriorityPrefix(
            @intFromEnum(self),
            if (prefix) |val| val.ptr else null,
        );
        return errors.wrapCallBool(ret);
    }
};

/// The predefined log categories.
///
/// ## Remarks
/// By default the application and gpu categories are enabled at the INFO level,
/// the assert category is enabled at the WARN level,
/// test is enabled at the VERBOSE level,
/// and all other categories are enabled at the ERROR level.
///
/// ## Version
/// This is available since SDL 3.2.0.
pub const Category = packed struct {
    value: c_int,
    pub const application = Category{ .value = c.SDL_LOG_CATEGORY_APPLICATION };
    pub const errors = Category{ .value = c.SDL_LOG_CATEGORY_ERROR };
    pub const assert = Category{ .value = c.SDL_LOG_CATEGORY_ASSERT };
    pub const system = Category{ .value = c.SDL_LOG_CATEGORY_SYSTEM };
    pub const audio = Category{ .value = c.SDL_LOG_CATEGORY_AUDIO };
    pub const video = Category{ .value = c.SDL_LOG_CATEGORY_VIDEO };
    pub const render = Category{ .value = c.SDL_LOG_CATEGORY_RENDER };
    pub const input = Category{ .value = c.SDL_LOG_CATEGORY_INPUT };
    pub const testing = Category{ .value = c.SDL_LOG_CATEGORY_TEST };
    pub const gpu = Category{ .value = c.SDL_LOG_CATEGORY_GPU };
    /// First value to use for custom log categories.
    pub const custom = Category{ .value = c.SDL_LOG_CATEGORY_CUSTOM };

    /// Get zig representation of a category.
    pub fn fromSdl(val: c_int) ?Category {
        if (val == c.SDL_LOG_CATEGORY_ERROR)
            return null;
        return .{ .value = val };
    }

    /// Get the priority of a particular log category.
    ///
    /// ## Function Parameters
    /// * `self`: The category to query.
    ///
    /// ## Return Value
    /// Returns the `log.Priority` for the requested query.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getPriority(
        self: Category,
    ) Priority {
        return @enumFromInt(c.SDL_GetLogPriority(self.value));
    }

    /// Log a message with the specified category and priority.
    ///
    /// ## Function Parameters
    /// * `self`: The category of the message.
    /// * `priority`: The priority of the message.
    /// * `fmt`: Print format to log the message.
    /// * `args`: Arguments to the print format.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn log(
        self: Category,
        priority: Priority,
        comptime fmt: []const u8,
        args: anytype,
    ) !void {
        var fallback = std.heap.stackFallback(max_log_message_stack, stdinc.allocator);
        const allocator = fallback.get();
        const msg = try std.fmt.allocPrintZ(allocator, fmt, args);
        defer allocator.free(msg);
        c.SDL_LogMessage(
            self.value,
            @intFromEnum(priority),
            "%s",
            msg.ptr,
        );
    }

    /// Log a message with `log.Priority.Critical`.
    ///
    /// ## Function Parameters
    /// * `self`: Category of the message.
    /// * `fmt`: Print format to log the message.
    /// * `args`: Arguments to the print format.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn logCritical(
        self: Category,
        comptime fmt: []const u8,
        args: anytype,
    ) !void {
        var fallback = std.heap.stackFallback(max_log_message_stack, stdinc.allocator);
        const allocator = fallback.get();
        const msg = try std.fmt.allocPrintZ(allocator, fmt, args);
        defer allocator.free(msg);
        c.SDL_LogCritical(
            self.value,
            "%s",
            msg.ptr,
        );
    }

    /// Log a message with `log.Priority.debug`.
    ///
    /// ## Function Parameters
    /// * `self`: Category of the message.
    /// * `fmt`: Print format to log the message.
    /// * `args`: Arguments to the print format.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn logDebug(
        self: Category,
        comptime fmt: []const u8,
        args: anytype,
    ) !void {
        var fallback = std.heap.stackFallback(max_log_message_stack, stdinc.allocator);
        const allocator = fallback.get();
        const msg = try std.fmt.allocPrintZ(allocator, fmt, args);
        defer allocator.free(msg);
        c.SDL_LogDebug(
            self.value,
            "%s",
            msg.ptr,
        );
    }

    /// Log a message with `log.Priority.err`.
    ///
    /// ## Function Parameters
    /// * `self`: Category of the message.
    /// * `fmt`: Print format to log the message.
    /// * `args`: Arguments to the print format.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn logError(
        self: Category,
        comptime fmt: []const u8,
        args: anytype,
    ) !void {
        var fallback = std.heap.stackFallback(max_log_message_stack, stdinc.allocator);
        const allocator = fallback.get();
        const msg = try std.fmt.allocPrintZ(allocator, fmt, args);
        defer allocator.free(msg);
        c.SDL_LogError(
            self.value,
            "%s",
            msg.ptr,
        );
    }

    /// Log a message with `log.Priority.info`.
    ///
    /// ## Function Parameters
    /// * `self`: Category of the message.
    /// * `fmt`: Print format to log the message.
    /// * `args`: Arguments to the print format.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn logInfo(
        self: Category,
        comptime fmt: []const u8,
        args: anytype,
    ) !void {
        var fallback = std.heap.stackFallback(max_log_message_stack, stdinc.allocator);
        const allocator = fallback.get();
        const msg = try std.fmt.allocPrintZ(allocator, fmt, args);
        defer allocator.free(msg);
        c.SDL_LogInfo(
            self.value,
            "%s",
            msg.ptr,
        );
    }

    /// Log a message with `log.Priority.trace`.
    ///
    /// ## Function Parameters
    /// * `self`: Category of the message.
    /// * `fmt`: Print format to log the message.
    /// * `args`: Arguments to the print format.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn logTrace(
        self: Category,
        comptime fmt: []const u8,
        args: anytype,
    ) !void {
        var fallback = std.heap.stackFallback(max_log_message_stack, stdinc.allocator);
        const allocator = fallback.get();
        const msg = try std.fmt.allocPrintZ(allocator, fmt, args);
        defer allocator.free(msg);
        c.SDL_LogTrace(
            self.value,
            "%s",
            msg.ptr,
        );
    }

    /// Log a message with `log.Priority.verbose`.
    ///
    /// ## Function Parameters
    /// * `self`: Category of the message.
    /// * `fmt`: Print format to log the message.
    /// * `args`: Arguments to the print format.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn logVerbose(
        self: Category,
        comptime fmt: []const u8,
        args: anytype,
    ) !void {
        var fallback = std.heap.stackFallback(max_log_message_stack, stdinc.allocator);
        const allocator = fallback.get();
        const msg = try std.fmt.allocPrintZ(allocator, fmt, args);
        defer allocator.free(msg);
        c.SDL_LogVerbose(
            self.value,
            "%s",
            msg.ptr,
        );
    }

    /// Log a message with `log.Priority.warn`.
    ///
    /// ## Function Parameters
    /// * `self`: Category of the message.
    /// * `fmt`: Print format to log the message.
    /// * `args`: Arguments to the print format.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn logWarn(
        self: Category,
        comptime fmt: []const u8,
        args: anytype,
    ) !void {
        var fallback = std.heap.stackFallback(max_log_message_stack, stdinc.allocator);
        const allocator = fallback.get();
        const msg = try std.fmt.allocPrintZ(allocator, fmt, args);
        defer allocator.free(msg);
        c.SDL_LogWarn(
            self.value,
            "%s",
            msg.ptr,
        );
    }

    /// Set the priority of a particular log category.
    ///
    /// ## Function Parameters
    /// * `self`: The category to assign the priority to.
    /// * `priority`: The log priority to assign.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setPriority(
        self: Category,
        priority: Priority,
    ) void {
        const ret = c.SDL_SetLogPriority(
            self.value,
            @intFromEnum(priority),
        );
        _ = ret;
    }
};

/// Get the default log output function.
///
/// ## Return Value
/// Returns the default log output callback.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getDefaultLogOutputFunction() LogOutputFunction {
    return c.SDL_GetDefaultLogOutputFunction().?;
}

/// Get the current log output function.
///
/// ## Return Value
/// * `callback`: A `log.LogOutputFunction` filled in with the current log `callback`.
/// * `user_data`: A pointer filled in with the pointer that is passed to `callback`.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getLogOutputFunction() struct { callback: LogOutputFunction, user_data: ?*anyopaque } {
    var callback: c.SDL_LogOutputFunction = undefined;
    var user_data: ?*anyopaque = undefined;
    c.SDL_GetLogOutputFunction(
        &callback,
        &user_data,
    );
    return .{ .callback = callback.?, .user_data = user_data };
}

/// Log a message with `log.Category.application` and `log.Priority.info`.
///
/// ## Function Parameters
/// * `fmt`: Print format to log the message.
/// * `args`: Arguments to the print format.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn log(
    comptime fmt: []const u8,
    args: anytype,
) !void {
    var fallback = std.heap.stackFallback(max_log_message_stack, stdinc.allocator);
    const allocator = fallback.get();
    const msg = try std.fmt.allocPrintZ(allocator, fmt, args);
    defer allocator.free(msg);
    c.SDL_Log(
        "%s",
        msg.ptr,
    );
}

/// Reset all priorities to default.
///
/// ## Remarks
/// This is called by `init.shutdown()`.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn resetAllPriorities() void {
    c.SDL_ResetLogPriorities();
}

/// Set the priority of all log categories.
///
/// ## Function Parameters
/// * `priority`: The priority to assign to all categories.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn setAllPriorities(
    priority: Priority,
) void {
    c.SDL_SetLogPriorities(
        @intFromEnum(priority),
    );
}

/// Replace the default log output function with one of your own.
///
/// ## Function Parameters
/// * `callback`: A `log.LogOutputFunction` to call instead of the default.
/// * `user_data`: A pointer that is passed to `callback`.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn setLogOutputFunction(
    callback: LogOutputFunction,
    user_data: ?*anyopaque,
) void {
    c.SDL_SetLogOutputFunction(
        callback,
        user_data,
    );
}

const TestLogCallbackData = struct {
    buf: *std.ArrayList(u8),
    last_str: usize = 0,
    last_category: ?Category = null,
    last_priority: ?Priority = null,
};

fn testLogCallback(user_data: ?*anyopaque, category: c_int, priority: c.SDL_LogPriority, message: [*c]const u8) callconv(.c) void {
    var data: *TestLogCallbackData = @ptrCast(@alignCast(user_data));
    data.last_str = data.buf.items.len;
    data.last_category = Category.fromSdl(category);
    data.last_priority = Priority.fromSdl(priority);
    data.buf.appendSlice(std.mem.span(message)) catch {};
}

fn testGetLastMessage(data: TestLogCallbackData) []const u8 {
    return data.buf.items[data.last_str..];
}

// Test logging functionality.
test "Log" {
    std.testing.refAllDeclsRecursive(@This());

    const backup = getLogOutputFunction();
    try std.testing.expectEqual(getDefaultLogOutputFunction(), backup.callback);

    var log_arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer log_arena.deinit();
    const allocator = log_arena.allocator();

    var log_out = std.ArrayList(u8).init(allocator);
    var data = TestLogCallbackData{
        .buf = &log_out,
    };

    setLogOutputFunction(testLogCallback, &data);
    try log("Hello World {d}!", .{0});
    try std.testing.expectEqualStrings("Hello World 0!", testGetLastMessage(data));
    try std.testing.expectEqual(Category.application, data.last_category);
    try std.testing.expectEqual(.info, data.last_priority);

    const category = Category.render;
    category.setPriority(.critical);
    try std.testing.expectEqual(.critical, category.getPriority());
    category.setPriority(.err);
    try std.testing.expectEqual(.err, category.getPriority());

    setAllPriorities(.trace);
    try std.testing.expectEqual(.trace, Category.application.getPriority());

    try category.log(.verbose, "a{d}", .{1});
    try std.testing.expectEqualStrings("a1", testGetLastMessage(data));
    try std.testing.expectEqual(category, data.last_category);
    try std.testing.expectEqual(.verbose, data.last_priority);

    try category.logCritical("b{d}", .{2});
    try std.testing.expectEqualStrings("b2", testGetLastMessage(data));
    try std.testing.expectEqual(category, data.last_category);
    try std.testing.expectEqual(.critical, data.last_priority);

    try category.logDebug("c{d}", .{3});
    try std.testing.expectEqualStrings("c3", testGetLastMessage(data));
    try std.testing.expectEqual(category, data.last_category);
    try std.testing.expectEqual(.debug, data.last_priority);

    try category.logError("d{d}", .{4});
    try std.testing.expectEqualStrings("d4", testGetLastMessage(data));
    try std.testing.expectEqual(category, data.last_category);
    try std.testing.expectEqual(.err, data.last_priority);

    try category.logInfo("e{d}", .{5});
    try std.testing.expectEqualStrings("e5", testGetLastMessage(data));
    try std.testing.expectEqual(category, data.last_category);
    try std.testing.expectEqual(.info, data.last_priority);

    try category.logTrace("f{d}", .{6});
    try std.testing.expectEqualStrings("f6", testGetLastMessage(data));
    try std.testing.expectEqual(category, data.last_category);
    try std.testing.expectEqual(.trace, data.last_priority);

    try category.logVerbose("g{d}", .{7});
    try std.testing.expectEqualStrings("g7", testGetLastMessage(data));
    try std.testing.expectEqual(category, data.last_category);
    try std.testing.expectEqual(.verbose, data.last_priority);

    try category.logWarn("h{d}", .{8});
    try std.testing.expectEqualStrings("h8", testGetLastMessage(data));
    try std.testing.expectEqual(category, data.last_category);
    try std.testing.expectEqual(.warn, data.last_priority);

    // Prefix only takes effect with default function for some reason? So we can not really test this.
    const pri = Priority.info;
    try pri.setPrefix("[INFO]: ");
    try pri.setPrefix(null);

    resetAllPriorities();
    try std.testing.expectEqual(.info, Category.application.getPriority());
    setLogOutputFunction(backup.callback, backup.user_data);
}
