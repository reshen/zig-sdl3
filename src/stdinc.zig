const c = @import("c.zig").c;
const errors = @import("errors.zig");
const std = @import("std");

/// A callback used to implement `stdinc.calloc()`.
///
/// ## Function Parameters
/// * `num_members`: The number of elements in the array.
/// * `size`: The size of each element of the array.
///
/// ## Return Value
/// Returns a pointer to the allocated array, or `null` if allocation failed.
///
/// ## Remarks
/// SDL will always ensure that the passed `num_members` and `size` are both greater than `0`.
///
/// ## Thread Safety
/// It should be safe to call this callback from any thread.
///
/// ## Version
/// This datatype is available since SDL 3.2.0.
pub const CallocFuncC = *const fn (
    num_members: usize,
    size: usize,
) callconv(.c) ?*anyopaque;

/// A callback used to implement `stdinc.free()`.
///
/// ## Function Parameters
/// * `mem`: A pointer to allocated memory.
///
/// ## Remarks
/// SDL will ensure `mem` will never be null.
///
/// ## Thread Safety
/// It should be safe to call this callback from any thread.
///
/// ## Version
/// This datatype is available since SDL 3.2.0.
pub const FreeFuncC = *const fn (
    mem: ?*anyopaque,
) callconv(.c) void;

/// A callback used to implement `stdinc.malloc()`.
///
/// ## Function Parameters
/// * `size`: The size to allocate.
///
/// ## Return Value
/// Returns a pointer to the allocated memory, or `null` if allocation failed.
///
/// ## Remarks
/// SDL will always ensure that the passed `size` is greater than `0`.
///
/// ## Thread Safety
/// It should be safe to call this callback from any thread.
///
/// ## Version
/// This datatype is available since SDL 3.2.0.
pub const MallocFuncC = *const fn (
    size: usize,
) callconv(.c) ?*anyopaque;

/// A callback used to implement `stdinc.realloc()`.
///
/// ## Function Parameters
/// * `mem`: A pointer to allocated memory to reallocate, or `null`.
/// * `size`: The new size of the memory.
///
/// ## Return Value
/// Returns a pointer to the newly allocated memory, or `null` if allocation failed.
///
/// ## Remarks
/// SDL will always ensure that the passed `size` is greater than `0`.
///
/// ## Thread Safety
/// It should be safe to call this callback from any thread.
///
/// ## Version
/// This datatype is available since SDL 3.2.0.
pub const ReallocFuncC = *const fn (
    mem: ?*anyopaque,
    size: usize,
) callconv(.c) ?*anyopaque;

/// A thread-safe set of environment variables.
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const Environment = packed struct {
    value: *c.SDL_Environment,

    /// Destroy a set of environment variables.
    ///
    /// ## Function Parameters
    /// * `self`: The environment to destroy.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread, as long as the environment is no longer in use.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn deinit(
        self: Environment,
    ) void {
        c.SDL_DestroyEnvironment(self.value);
    }

    /// Get the value of a variable in the environment.
    ///
    /// ## Function Parameters
    /// * `self`: The environment to query.
    /// * `name`: The name of the variable to get.
    ///
    /// ## Return Value
    /// Returns the environment variable, or `null` if it can't be found.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getVariable(
        self: Environment,
        name: [:0]const u8,
    ) ?[:0]const u8 {
        const ret = c.SDL_GetEnvironmentVariable(self.value, name.ptr);
        if (ret == null)
            return null;
        return std.mem.span(ret);
    }

    /// Get all variables in the environment.
    ///
    /// ## Function Parameters
    /// * `self`: The environment to query.
    ///
    /// ## Return Value
    /// Returns a `null` terminated array of pointers to environment variables in the form "variable=value".
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getVariables(
        self: Environment,
    ) ![*:null][*c]u8 {
        return try errors.wrapNull([*:null][*c]u8, c.SDL_GetEnvironmentVariables(self.value));
    }

    /// Create a set of environment variables.
    ///
    /// ## Function Parameters
    /// * `populated`: True to initialize it from the C runtime environment, false to create an empty environment.
    ///
    /// ## Return Value
    /// Returns a new environment.
    ///
    /// ## Thread Safety
    /// If populated is false, it is safe to call this function from any thread, otherwise it is safe if no other threads are manipulating the enviroment variables.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn init(
        populated: bool,
    ) !Environment {
        return .{ .value = try errors.wrapNull(*c.SDL_Environment, c.SDL_CreateEnvironment(populated)) };
    }

    /// Set the value of a variable in the environment.
    ///
    /// ## Function Parameters
    /// * `self`: The environment to modify.
    /// * `name`: The name of the variable to set.
    /// * `value`: The value of the variable to set.
    /// * `overwrite`: True to overwrite the variable if it exists, false to return success without setting the variable if it already exists.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setVariable(
        self: Environment,
        name: [:0]const u8,
        value: [:0]const u8,
        overwrite: bool,
    ) !void {
        return errors.wrapCallBool(c.SDL_SetEnvironmentVariable(self.value, name.ptr, value.ptr, overwrite));
    }

    /// Clear a variable from the environment.
    ///
    /// ## Function Parameters
    /// * `self`: The environment to modify.
    /// * `name`: The name of the variable to unset.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn unsetVariable(
        self: Environment,
        name: [:0]const u8,
    ) !void {
        return errors.wrapCallBool(c.SDL_UnsetEnvironmentVariable(self.value, name.ptr));
    }

    // Size tests.
    comptime {
        std.debug.assert(@sizeOf(*c.SDL_Environment) == @sizeOf(Environment));
    }
};

/// Free allocated memory.
///
/// ## Function Parameters
/// * `mem`: A pointer to allocated memory, or `null`.
///
/// ## Remarks
/// The pointer is no longer valid after this call and cannot be dereferenced anymore.
///
/// If mem is `null`, this function does nothing.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn free(mem: anytype) void {
    switch (@typeInfo(@TypeOf(mem))) {
        .pointer => |pt| {
            if (pt.size == .slice) {
                c.SDL_free(@ptrCast(mem.ptr));
            } else {
                c.SDL_free(@ptrCast(mem));
            }
        },
        else => @compileError("Invalid argument to SDL free"),
    }
}

/// Get the process environment.
///
/// ## Return Value
/// Returns a pointer to the environment for the process.
///
/// ## Remarks
/// Use functions in the returned environment to manipulate it, use zig's environment functions to persist outside it.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getEnvironment() !Environment {
    return .{ .value = try errors.wrapNull(*c.SDL_Environment, c.SDL_GetEnvironment()) };
}

/// Get the current set of SDL memory functions.
///
/// ## Return Value
/// Returns the current memory functions.
///
/// ## Remarks
/// This is what `stdinc.malloc()` and friends will use by default, if there has been no call to `stdinc.setMemoryFunctions()`.
/// This is not necessarily using the C runtime's malloc functions behind the scenes!
/// Different platforms and build configurations might do any number of unexpected things.
///
/// ## Thread Safety
/// This does not hold a lock, so do not call this in the unlikely event of a background thread calling `stdinc.setMemoryFunctions()` simultaneously.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getMemoryFunctions() struct { malloc: MallocFuncC, calloc: CallocFuncC, realloc: ReallocFuncC, free: FreeFuncC } {
    var malloc_fn: ?MallocFuncC = undefined;
    var calloc_fn: ?CallocFuncC = undefined;
    var realloc_fn: ?ReallocFuncC = undefined;
    var free_fn: ?FreeFuncC = undefined;
    c.SDL_GetMemoryFunctions(
        &malloc_fn,
        &calloc_fn,
        &realloc_fn,
        &free_fn,
    );
    return .{ .malloc = malloc_fn.?, .calloc = calloc_fn.?, .realloc = realloc_fn.?, .free = free_fn.? };
}

/// Get the number of outstanding (unfreed) allocations.
///
/// ## Return Value
/// Returns the number of allocations or `null` if allocation counting is disabled.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getNumAllocations() ?usize {
    const ret = c.SDL_GetNumAllocations();
    if (ret == -1)
        return null;
    return @intCast(ret);
}

/// Get the original set of SDL memory functions.
///
/// ## Return Value
/// Returns the original memory functions.
///
/// ## Remarks
/// This is what `stdinc.malloc()` and friends will use by default, if there has been no call to `stdinc.setMemoryFunctions()`.
/// This is not necessarily using the C runtime's malloc functions behind the scenes!
/// Different platforms and build configurations might do any number of unexpected things.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getOriginalMemoryFunctions() struct { malloc: MallocFuncC, calloc: CallocFuncC, realloc: ReallocFuncC, free: FreeFuncC } {
    var malloc_fn: ?MallocFuncC = undefined;
    var calloc_fn: ?CallocFuncC = undefined;
    var realloc_fn: ?ReallocFuncC = undefined;
    var free_fn: ?FreeFuncC = undefined;
    c.SDL_GetOriginalMemoryFunctions(
        &malloc_fn,
        &calloc_fn,
        &realloc_fn,
        &free_fn,
    );
    return .{ .malloc = malloc_fn.?, .calloc = calloc_fn.?, .realloc = realloc_fn.?, .free = free_fn.? };
}

/// Convert a single Unicode codepoint to UTF-8.
///
/// ## Function Parameters
/// * `codepoint`: A Unicode codepoint to convert to UTF-8.
/// * `dst`: The location to write the encoded UTF-8. Must point to at least 4 bytes!
///
/// ## Return Value
/// Returns the address of the first byte past the newly-written UTF-8 sequence.
///
/// ## Remarks
/// If codepoint is an invalid value (outside the Unicode range, or a UTF-16 surrogate value, etc), this will use `U+FFFD (REPLACEMENT CHARACTER)`
/// for the codepoint instead, and not set an error.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn ucs4ToUtf8(codepoint: u32, dst: *[4]u8) [*]u8 {
    return c.SDL_UCS4ToUTF8(codepoint, dst);
}

/// Allocator that uses SDL's `stdinc.malloc()` and `stdinc.free()` functions.
pub const allocator = std.mem.Allocator{
    .ptr = undefined,
    .vtable = &.{
        .alloc = sdlAlloc,
        .resize = sdlResize,
        .remap = sdlRemap,
        .free = sdlFree,
    },
};

fn sdlAlloc(ptr: *anyopaque, len: usize, alignment: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
    _ = ptr;
    _ = alignment;
    _ = ret_addr;
    const ret = c.SDL_malloc(len);
    if (ret) |val| {
        return @as([*]u8, @alignCast(@ptrCast(val)));
    }
    return null;
}

fn sdlResize(ptr: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
    _ = ptr;
    _ = memory;
    _ = alignment;
    _ = new_len;
    _ = ret_addr;
    return false;
}

fn sdlRemap(ptr: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    _ = ptr;
    _ = alignment;
    _ = ret_addr;
    const ret = c.SDL_realloc(memory.ptr, new_len);
    if (ret) |val| {
        return @as([*]u8, @alignCast(@ptrCast(val)));
    }
    return null;
}

fn sdlFree(ptr: *anyopaque, memory: []u8, alignment: std.mem.Alignment, ret_addr: usize) void {
    _ = ptr;
    _ = alignment;
    _ = ret_addr;
    c.SDL_free(memory.ptr);
}

/// Replace SDL's memory allocation functions with the original ones.
///
/// ## Version
/// This is provided by zig-sdl3.
pub fn restoreMemoryFunctions() !void {
    const originals = getOriginalMemoryFunctions();
    return setMemoryFunctions(
        originals.malloc,
        originals.calloc,
        originals.realloc,
        originals.free,
    );
}

/// Replace SDL's memory allocation functions with a custom set.
///
/// ## Function Parameters
/// * `malloc`: Custom `malloc` function.
/// * `calloc`: Custom `calloc` function.
/// * `realloc`: Custom `realloc` function.
/// * `free`: Custom `free` function.
///
/// ## Remarks
/// It is not safe to call this function once any allocations have been made, as future calls to `stdinc.free()` will use the new allocator,
/// even if they came from an `stdinc.malloc()` made with the old one!
///
/// If used, usually this needs to be the first call made into the SDL library, if not the very first thing done at program startup time.
///
/// ## Thread Safety
/// It is safe to call this function from any thread, but one should not replace the memory functions once any allocations are made!
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn setMemoryFunctions(
    malloc_fn: MallocFuncC,
    calloc_fn: CallocFuncC,
    realloc_fn: ReallocFuncC,
    free_fn: FreeFuncC,
) !void {
    const ret = c.SDL_SetMemoryFunctions(
        malloc_fn,
        calloc_fn,
        realloc_fn,
        free_fn,
    );
    return errors.wrapCallBool(ret);
}

/// Iterate over a UTF8 string in reverse.
///
/// ## Version
/// This struct is provided by zig-sdl3.
pub const Utf8ReverseIterator = struct {
    str: [*c]const u8,
    start: [*c]const u8,

    /// Get the previous UTF-8 codepoint.
    ///
    /// ## Function Parameters
    /// * `self`: The UTF-8 iterator.
    ///
    /// ## Return Value
    /// Returns the previous unicode codepoint, or `null` if done.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn prev(
        self: *Utf8ReverseIterator,
    ) ?u32 {
        const ret = c.SDL_StepBackUTF8(self.start, &self.str);
        if (ret == 0)
            return null;
        return ret;
    }
};

/// Decode a UTF-8 string in reverse, one Unicode codepoint at a time.
///
/// ## Function Parameters
/// * `str`: The UTF-8 string to decode.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn stepBackUtf8(
    str: []const u8,
) Utf8ReverseIterator {
    return .{
        .str = @ptrFromInt(@intFromPtr(str.ptr) + str.len),
        .start = str.ptr,
    };
}

/// Iterate over a UTF8 string.
///
/// ## Version
/// This struct is provided by zig-sdl3.
pub const Utf8Iterator = struct {
    str: [*c]const u8,
    len: usize,

    /// Get the next UTF-8 codepoint.
    ///
    /// ## Function Parameters
    /// * `self`: The UTF-8 iterator.
    ///
    /// ## Return Value
    /// Returns the next unicode codepoint, or `null` if done.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn next(
        self: *Utf8Iterator,
    ) ?u32 {
        const ret = c.SDL_StepUTF8(&self.str, &self.len);
        if (ret == 0)
            return null;
        return ret;
    }
};

/// Decode a UTF-8 string, one Unicode codepoint at a time.
///
/// ## Function Parameters
/// * `str`: The UTF-8 string to decode.
///
/// ## Thread Safety
/// It is safe to call this function from any thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn stepUtf8(
    str: []const u8,
) Utf8Iterator {
    return .{
        .str = str.ptr,
        .len = str.len,
    };
}

/// Custom allocator to use for `stdinc.setMemoryFunctionsByAllocator()`.
var custom_allocator: std.mem.Allocator = undefined;

const Allocation = struct {
    size: usize,
    buf: void,
};

fn allocCalloc(num_members: usize, size: usize) callconv(.c) ?*anyopaque {
    const total_buf = custom_allocator.alloc(u8, size * num_members + @sizeOf(Allocation)) catch return null;
    const allocation: *Allocation = @ptrCast(@alignCast(total_buf.ptr));
    allocation.size = total_buf.len;
    return &allocation.buf;
}

fn allocFree(mem: ?*anyopaque) callconv(.c) void {
    const raw_ptr = mem orelse return;
    const allocation: *Allocation = @alignCast(@fieldParentPtr("buf", @as(*void, @ptrCast(raw_ptr))));
    custom_allocator.free(@as([*]u8, @ptrCast(raw_ptr))[0..allocation.size]);
}

fn allocMalloc(size: usize) callconv(.c) ?*anyopaque {
    const total_buf = custom_allocator.alloc(u8, size + @sizeOf(Allocation)) catch return null;
    const allocation: *Allocation = @ptrCast(@alignCast(total_buf.ptr));
    allocation.size = total_buf.len;
    return &allocation.buf;
}

fn allocRealloc(mem: ?*anyopaque, size: usize) callconv(.c) ?*anyopaque {
    const raw_ptr = mem orelse return null;
    var allocation: *Allocation = @alignCast(@fieldParentPtr("buf", @as(*void, @ptrCast(raw_ptr))));
    const total_buf = custom_allocator.realloc(@as([*]u8, @ptrCast(raw_ptr))[0..allocation.size], size + @sizeOf(Allocation)) catch return null;
    allocation = @ptrCast(@alignCast(total_buf.ptr));
    allocation.size = total_buf.len;
    return &allocation.buf;
}

/// Replace SDL's memory allocation functions to use with an allocator.
/// This can be restored with `stdinc.restoreMemoryFunctions()`.
///
/// ## Function Parameters
/// * `new_allocator`: The new allocator to use for allocations.
///
/// ## Version
/// This is provided by zig-sdl3.
pub fn setMemoryFunctionsByAllocator(
    new_allocator: std.mem.Allocator,
) !void {
    custom_allocator = new_allocator;
    return setMemoryFunctions(
        allocMalloc,
        allocCalloc,
        allocRealloc,
        allocFree,
    );
}

// Test C-library function wrappers.
test "Stdinc" {
    std.testing.refAllDeclsRecursive(@This());
    custom_allocator = std.testing.allocator;
    var ptr = allocMalloc(5).?;
    allocFree(ptr);
    ptr = allocCalloc(3, 5).?;
    ptr = allocRealloc(ptr, 303).?;
    allocFree(ptr);
}
