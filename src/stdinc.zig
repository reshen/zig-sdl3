const c = @import("c.zig").c;
const errors = @import("errors.zig");
const std = @import("std");

/// A thread-safe set of environment variables.
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const Environment = packed struct {
    value: *c.SDL_Environment,

    // Size tests.
    comptime {
        std.debug.assert(@sizeOf(*c.SDL_Environment) == @sizeOf(Environment));
    }
};

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
pub const CallocFunc = *const fn (num_members: usize, size: usize) callconv(.c) ?*anyopaque;

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
pub const FreeFunc = *const fn (mem: ?*anyopaque) callconv(.c) void;

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
pub const MallocFunc = *const fn (size: usize) callconv(.c) ?*anyopaque;

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
pub const ReallocFunc = *const fn (mem: ?*anyopaque, size: usize) callconv(.c) ?*anyopaque;

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
pub fn getOriginalMemoryFunctions() struct { malloc: MallocFunc, calloc: CallocFunc, realloc: ReallocFunc, free: FreeFunc } {
    var malloc_fn: ?MallocFunc = undefined;
    var calloc_fn: ?CallocFunc = undefined;
    var realloc_fn: ?ReallocFunc = undefined;
    var free_fn: ?FreeFunc = undefined;
    c.SDL_GetOriginalMemoryFunctions(
        &malloc_fn,
        &calloc_fn,
        &realloc_fn,
        &free_fn,
    );
    return .{ .malloc = malloc_fn.?, .calloc = calloc_fn.?, .realloc = realloc_fn.?, .free = free_fn.? };
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
    malloc_fn: MallocFunc,
    calloc_fn: CallocFunc,
    realloc_fn: ReallocFunc,
    free_fn: FreeFunc,
) !void {
    const ret = c.SDL_SetMemoryFunctions(
        malloc_fn,
        calloc_fn,
        realloc_fn,
        free_fn,
    );
    return errors.wrapCallBool(ret);
}

/// Custom allocator to use for `stdinc.setMemoryFunctionsByAllocator()`.
pub var custom_allocator: ?std.mem.Allocator = null;

const Allocation = struct {
    size: usize,
    buf: void,
};

fn allocCalloc(num_members: usize, size: usize) callconv(.c) ?*anyopaque {
    const custom_allocator_val = custom_allocator orelse return null;
    const total_buf = custom_allocator_val.alloc(u8, size * num_members + @sizeOf(Allocation)) catch return null;
    const allocation: *Allocation = @ptrCast(@alignCast(total_buf.ptr));
    allocation.size = total_buf.len;
    return &allocation.buf;
}

fn allocFree(mem: ?*anyopaque) callconv(.c) void {
    const raw_ptr = mem orelse return;
    const custom_allocator_val = custom_allocator orelse return;
    const allocation: *Allocation = @alignCast(@fieldParentPtr("buf", @as(*void, @ptrCast(raw_ptr))));
    custom_allocator_val.free(@as([*]u8, @ptrCast(raw_ptr))[0..allocation.size]);
}

fn allocMalloc(size: usize) callconv(.c) ?*anyopaque {
    const custom_allocator_val = custom_allocator orelse return null;
    const total_buf = custom_allocator_val.alloc(u8, size + @sizeOf(Allocation)) catch return null;
    const allocation: *Allocation = @ptrCast(@alignCast(total_buf.ptr));
    allocation.size = total_buf.len;
    return &allocation.buf;
}

fn allocRealloc(mem: ?*anyopaque, size: usize) callconv(.c) ?*anyopaque {
    const raw_ptr = mem orelse return null;
    const custom_allocator_val = custom_allocator orelse return null;
    var allocation: *Allocation = @alignCast(@fieldParentPtr("buf", @as(*void, @ptrCast(raw_ptr))));
    const total_buf = custom_allocator_val.realloc(@as([*]u8, @ptrCast(raw_ptr))[0..allocation.size], size + @sizeOf(Allocation)) catch return null;
    allocation = @ptrCast(@alignCast(total_buf.ptr));
    allocation.size = total_buf.len;
    return &allocation.buf;
}

/// Replace SDL's memory allocation functions to use the allocator specified by `stdinc.custom_allocator`.
/// This can be restored with `stdinc.restoreMemoryFunctions()`.
///
/// ## Version
/// This is provided by zig-sdl3.
pub fn setMemoryFunctionsByAllocator() !void {
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
    {
        custom_allocator = std.testing.allocator;
        defer custom_allocator = null;

        var ptr = allocMalloc(5).?;
        allocFree(ptr);
        ptr = allocCalloc(3, 5).?;
        ptr = allocRealloc(ptr, 303).?;
        allocFree(ptr);
    }

    // getOriginalMemoryFunctions
    // restoreMemoryFunctions
    // setMemoryFunctions
    // setMemoryFunctionsByAllocator
}
