const c = @import("c.zig").c;
const errors = @import("errors.zig");
const properties = @import("properties.zig");
const std = @import("std");

/// Status, set by a read or write operation.
///
/// ## Version
/// This error is available since SDL 3.2.0.
pub const Error = error{
    /// Read or write I/O error.
    Err,
    /// Non blocking I/O, not ready.
    NotReady,
    /// Tried to write a read-only buffer
    ReadOnly,
    /// Tried to read a write-only buffer.
    WriteOnly,
};

/// Mode for `io_steam.Stream.initFromFile()`.
///
/// ## Version
/// This enum is provided by zig-sdl3.
pub const FileMode = enum {
    /// Open a text file for reading.
    /// The file must exist.
    read_text,
    /// Create an empty text file for writing.
    /// If a file with the same name already exists its content is erased and the file is treated as a new empty file.
    write_text,
    /// Append to a text file.
    /// Writing operations append data at the end of the file.
    /// The file is created if it does not exist.
    append_text,
    /// Open a text file for update both reading and writing.
    /// The file must exist.
    read_write_update_text,
    /// Create an empty text file for both reading and writing.
    /// If a file with the same name already exists its content is erased and the file is treated as a new empty file.
    read_write_replace_text,
    /// Open a text file for reading and appending.
    /// All writing operations are performed at the end of the file, protecting the previous content to be overwritten.
    /// You can reposition the internal pointer to anywhere in the file for reading, but writing operations will move it back to the end of file.
    /// The file is created if it does not exist.
    read_append_text,
    /// Open a binary file for reading.
    /// The file must exist.
    read_binary,
    /// Create an empty binary file for writing.
    /// If a file with the same name already exists its content is erased and the file is treated as a new empty file.
    write_binary,
    /// Append to a binary file.
    /// Writing operations append data at the end of the file.
    /// The file is created if it does not exist.
    append_binary,
    /// Open a binary file for update both reading and writing.
    /// The file must exist.
    read_write_update_binary,
    /// Create an empty binary file for both reading and writing.
    /// If a file with the same name already exists its content is erased and the file is treated as a new empty file.
    read_write_replace_binary,
    /// Open a binary file for reading and appending.
    /// All writing operations are performed at the end of the file, protecting the previous content to be overwritten.
    /// You can reposition the internal pointer to anywhere in the file for reading, but writing operations will move it back to the end of file.
    /// The file is created if it does not exist.
    read_append_binary,
};

/// The function pointers that drive an `io_stream.Stream`.
///
/// ## Remarks
/// Applications can provide this struct to `io_stream.Stream.init()` to create their own implementation of a stream.
/// This is not necessarily required, as SDL already offers several common types of I/O streams,
/// via functions like `io_stream.Stream.initFromFile()` and `io_stream.Stream.initFromMem()`.
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const Interface = struct {
    /// Returns the number of bytes in the stream.
    ///
    /// ## Function Parameters
    /// * `user_data`: User context.
    ///
    /// ## Return Value
    /// The total size of the data stream, or `-1` on error.
    size: *const fn (user_data: ?*anyopaque) callconv(.c) i64,
    /// Seek to `offset` relative to `whence`.
    ///
    /// ## Function Parameters
    /// * `user_data`: User context.
    /// * `offset`: Offset to seek from.
    /// * `whence`: Where to seek relative to.
    ///
    /// ## Return Value
    /// The final offset in the data stream, or `-1` on error.
    seek: *const fn (user_data: ?*anyopaque, offset: i64, whence: c.SDL_IOWhence) callconv(.c) i64,
    /// Read up to `size` bytes from the data stream to the area pointed at by `ptr`.
    ///
    /// ## Function Parameters
    /// * `user_data`: User context.
    /// * `ptr`: Pointer to read into.
    /// * `size`: Maximum amount of data to read.
    /// * `status`: Output status.
    ///
    /// ## Remarks
    /// Set `status` on incomplete read.
    ///
    /// ## Return Value
    /// The number of bytes read.
    read: *const fn (user_data: ?*anyopaque, ptr: ?*anyopaque, size: usize, status: [*c]c.SDL_IOStatus) callconv(.c) usize,
    /// Write up to `size` bytes to the data stream from the area pointed at by `ptr`.
    ///
    /// ## Function Parameters
    /// * `user_data`: User context.
    /// * `ptr`: Pointer to read into.
    /// * `size`: Maximum amount of data to write.
    /// * `status`: Output status.
    ///
    /// ## Remarks
    /// Set `status` on incomplete write.
    ///
    /// ## Return Value
    /// The number of bytes written.
    write: *const fn (user_data: ?*anyopaque, ptr: ?*const anyopaque, size: usize, status: [*c]c.SDL_IOStatus) callconv(.c) usize,
    /// If the stream is buffering, make sure the data is written out.
    ///
    /// ## Function Parameters
    /// * `user_data`: User context.
    ///
    /// ## Remarks
    /// Set `status` on failure.
    ///
    /// ## Return Value
    /// True if successful.
    flush: *const fn (user_data: ?*anyopaque, status: [*c]c.SDL_IOStatus) callconv(.c) bool,
    /// Close and free any allocated resources.
    ///
    /// ## Function Parameters
    /// * `user_data`: User context.
    ///
    /// ## Remarks
    /// This does not guarantee file writes will sync to physical media; they can be in the system's file cache, waiting to go to disk.
    /// The stream is still destroyed even if this fails, so clean up anything even if flushing buffers, etc, returns an error.
    ///
    /// ## Return Value
    /// True if successful.
    close: *const fn (user_data: ?*anyopaque) callconv(.c) bool,

    /// Convert from an SDL value.
    pub fn fromSdl(value: c.SDL_IOStreamInterface) Interface {
        return .{
            .size = value.size.?,
            .seek = value.seek.?,
            .read = value.read.?,
            .write = value.write.?,
            .flush = value.flush.?,
            .close = value.close.?,
        };
    }

    /// Convert to an SDL value.
    pub fn toSdl(self: Interface) c.SDL_IOStreamInterface {
        return .{
            .version = @sizeOf(c.SDL_IOStreamInterface),
            .size = self.size,
            .seek = self.seek,
            .read = self.read,
            .write = self.write,
            .flush = self.flush,
            .close = self.close,
        };
    }
};

/// The read/write operation structure.
///
/// ## Remarks
/// This operates as an opaque handle.
/// There are several APIs to create various types of I/O streams,
/// or an app can supply an `io_stream.Interface` to `io_stream.Stream.initInterface()` to provide their own stream implementation behind this struct's abstract interface.
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const Stream = struct {
    value: *c.SDL_IOStream,

    /// Properties that can be obtained from a stream.
    ///
    /// ## Version
    /// This struct is provided by zig-sdl3.
    pub const Properties = struct {
        /// Memory slice if `io_stream.Stream.initFromMem()` or `io_stream.Stream.initFromConstMem()` was called.
        memory: ?[]u8,
        /// Data that can be get/set for `io_stream.Stream.initFromDynamicMem()`.
        dynamic_memory: ?struct {
            /// A pointer to the internal memory of the stream.
            /// This can be set to `null` to transfer ownership of the memory to the application, which should free the memory with `stdinc.free()`.
            /// If this is done, the next operation on the stream must be `io_stream.Stream.deinit()`.
            ptr: ?*anyopaque,
            /// Memory will be allocated in multiples of this size, defaulting to `1024`.
            chunk_size: ?usize = null,
        },
        /// Data that may set by `io_stream.Stream.initFromFile()`.
        /// A pointer, that can be cast to a win32 `HANDLE`, that this stream is using to access the filesystem.
        /// If the program isn't running on Windows, or SDL used some other method to access the filesystem, this property will not be set.
        window_handle: ?*anyopaque,
        /// Data that may set by `io_stream.Stream.initFromFile()`.
        /// A pointer, that can be cast to a stdio `FILE *`, that this stream is using to access the filesystem.
        /// If SDL used some other method to access the filesystem, this property will not be set.
        /// PLEASE NOTE that if SDL is using a different C runtime than your app, trying to use this pointer will almost certainly result in a crash!
        /// This is mostly a problem on Windows; make sure you build SDL and your app with the same compiler and settings to avoid it.
        stdio_file: ?*anyopaque,
        /// Data that may set by `io_stream.Stream.initFromFile()`.
        /// A file descriptor that this stream is using to access the filesystem.
        file_descriptor: ?i64,
        /// Data that may set by `io_stream.Stream.initFromFile()`.
        /// A pointer, that can be cast to an Android NDK `AAsset *`, that this stream is using to access the filesystem.
        /// If SDL used some other method to access the filesystem, this property will not be set.
        android_aasset: ?*anyopaque,

        /// Convert from SDL properties.
        pub fn fromProperties(props: properties.Group) Properties {
            return .{
                .memory = if (props.get(c.SDL_PROP_IOSTREAM_MEMORY_POINTER)) |val|
                    @as([*]u8, @alignCast(@ptrCast(val.pointer.?)))[0..@intCast(props.get(c.SDL_PROP_IOSTREAM_MEMORY_SIZE_NUMBER).?.number)]
                else
                    null,
                .dynamic_memory = if (props.get(c.SDL_PROP_IOSTREAM_DYNAMIC_MEMORY_POINTER)) |val| .{
                    .ptr = val.pointer,
                    .chunk_size = if (props.get(c.SDL_PROP_IOSTREAM_DYNAMIC_CHUNKSIZE_NUMBER)) |chunk_size| @intCast(chunk_size.number) else null,
                } else null,
                .window_handle = if (props.get(c.SDL_PROP_IOSTREAM_WINDOWS_HANDLE_POINTER)) |val| val.pointer.? else null,
                .stdio_file = if (props.get(c.SDL_PROP_IOSTREAM_STDIO_FILE_POINTER)) |val| val.pointer.? else null,
                .file_descriptor = if (props.get(c.SDL_PROP_IOSTREAM_FILE_DESCRIPTOR_NUMBER)) |val| val.number else null,
                .android_aasset = if (props.get(c.SDL_PROP_IOSTREAM_ANDROID_AASSET_POINTER)) |val| val.pointer.? else null,
            };
        }

        /// Set properties.
        pub fn setProperties(self: Properties, props: properties.Group) !void {
            if (self.memory) |val| {
                try props.set(c.SDL_PROP_IOSTREAM_MEMORY_POINTER, .{ .pointer = val.ptr });
                try props.set(c.SDL_PROP_IOSTREAM_MEMORY_SIZE_NUMBER, .{ .number = @intCast(val.len) });
            } else {
                try props.clear(c.SDL_PROP_IOSTREAM_MEMORY_POINTER);
                try props.clear(c.SDL_PROP_IOSTREAM_MEMORY_SIZE_NUMBER);
            }
            if (self.dynamic_memory) |val| {
                try props.set(c.SDL_PROP_IOSTREAM_DYNAMIC_MEMORY_POINTER, .{ .pointer = val.ptr });
                if (val.chunk_size) |chunk_size| {
                    try props.set(c.SDL_PROP_IOSTREAM_DYNAMIC_CHUNKSIZE_NUMBER, .{ .number = @intCast(chunk_size) });
                }
            } else {
                try props.clear(c.SDL_PROP_IOSTREAM_DYNAMIC_MEMORY_POINTER);
                try props.clear(c.SDL_PROP_IOSTREAM_DYNAMIC_CHUNKSIZE_NUMBER);
            }
            if (self.window_handle) |val| {
                try props.set(c.SDL_PROP_IOSTREAM_WINDOWS_HANDLE_POINTER, .{ .pointer = val });
            } else try props.clear(c.SDL_PROP_IOSTREAM_WINDOWS_HANDLE_POINTER);
            if (self.stdio_file) |val| {
                try props.set(c.SDL_PROP_IOSTREAM_STDIO_FILE_POINTER, .{ .pointer = val });
            } else try props.clear(c.SDL_PROP_IOSTREAM_STDIO_FILE_POINTER);
            if (self.file_descriptor) |val| {
                try props.set(c.SDL_PROP_IOSTREAM_FILE_DESCRIPTOR_NUMBER, .{ .number = val });
            } else try props.clear(c.SDL_PROP_IOSTREAM_FILE_DESCRIPTOR_NUMBER);
            if (self.android_aasset) |val| {
                try props.set(c.SDL_PROP_IOSTREAM_ANDROID_AASSET_POINTER, .{ .pointer = val });
            } else try props.clear(c.SDL_PROP_IOSTREAM_ANDROID_AASSET_POINTER);
        }
    };

    /// Close and free an allocated stream structure.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to close.
    ///
    /// ## Remarks
    /// `io_stream.Stream.deinit()` closes and cleans up the stream.
    /// It releases any resources used by the stream and frees the `io_stream.Stream` itself.
    /// This returns an error if the stream failed to flush to its output (e.g. to disk).
    ///
    /// Note that if this fails to flush the stream for any reason, this function reports an error, but the `io_stream.Stream` is still invalid once this function returns.
    ///
    /// This call flushes any buffered writes to the operating system, but there are no guarantees that those writes have gone to physical media;
    /// they might be in the OS's file cache, waiting to go to disk later.
    /// If it's absolutely crucial that writes go to disk immediately, so they are definitely stored even if the power fails before the file cache would have caught up,
    /// one should call `io_stream.Stream.flush()` before closing.
    /// Note that flushing takes time and makes the system and your app operate less efficiently, so do so sparingly.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn deinit(
        self: Stream,
    ) !void {
        return errors.wrapCallBool(c.SDL_CloseIO(
            self.value,
        ));
    }

    /// Flush any buffered data in the stream.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to flush.
    ///
    /// ## Remarks
    /// This function makes sure that any buffered data is written to the stream.
    /// Normally this isn't necessary but if the stream is a pipe or socket it guarantees that any pending data is sent.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn flush(
        self: Stream,
    ) !void {
        return errors.wrapCallBool(c.SDL_FlushIO(
            self.value,
        ));
    }

    /// Get the properties associated with a stream.
    ///
    /// ## Function Parameters
    /// * `self`: Stream structure.
    ///
    /// ## Return Value
    /// Returns the stream's properties.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getProperties(
        self: Stream,
    ) !Properties {
        return Properties.fromProperties(.{
            .value = try errors.wrapCall(c.SDL_PropertiesID, c.SDL_GetIOProperties(
                self.value,
            ), 0),
        });
    }

    /// Use this function to get the size of the data stream in a stream.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to get the size from.
    ///
    /// ## Return Value
    /// Returns the size of the data stream.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getSize(
        self: Stream,
    ) !usize {
        const ret = c.SDL_GetIOSize(self.value);
        if (ret < 0) {
            errors.callErrorCallback();
            return error.SdlError;
        }
        return @intCast(ret);
    }

    /// Create a custom stream.
    ///
    /// ## Function Parameters
    /// * `interface`: The interface that implements this stream.
    /// * `user_data`: User data that will be passed to the interface functions.
    ///
    /// ## Return Value
    /// Returns the created stream.
    ///
    /// ## Remarks
    /// Applications do not need to use this function unless they are providing their own `io_stream.Stream` implementation.
    /// If you just need a stream to read/write a common data source, you should use the built-in implementations in SDL,
    /// like `io_stream.Stream.initFromFile()` or `io_stream.Stream.initFromMem()`, etc.
    ///
    /// This function makes a copy of iface and the caller does not need to keep it around after this call.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn init(
        interface: Interface,
        user_data: ?*anyopaque,
    ) !Stream {
        const interface_sdl = interface.toSdl();
        return .{
            .value = try errors.wrapNull(*c.SDL_IOStream, c.SDL_OpenIO(
                &interface_sdl,
                user_data,
            )),
        };
    }

    /// Use this function to prepare a read-only memory buffer for use with a stream.
    ///
    /// ## Function Parameters
    /// * `data`: Read only buffer to make into a stream.
    ///
    /// ## Return Value
    /// Returns a stream.
    ///
    /// ## Remarks
    /// This function sets up a stream struct based on a memory area of a certain size.
    /// It assumes the memory area is not writable.
    ///
    /// Attempting to write to this stream will report an error without writing to the memory buffer.
    ///
    /// This memory buffer is not copied by the stream; the pointer you provide must remain valid until you close the stream.
    /// Closing the stream will not free the original buffer.
    ///
    /// If you need to write to a memory buffer, you should use `io_stream.Stream.initFromMem()` with a writable buffer of memory instead.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn initFromConstMem(
        data: []const u8,
    ) !Stream {
        return .{
            .value = try errors.wrapNull(*c.SDL_IOStream, c.SDL_IOFromConstMem(
                data.ptr,
                data.len,
            )),
        };
    }

    /// Use this function to create a stream that is backed by dynamically allocated memory.
    ///
    /// ## Return Value
    /// Returns a stream.
    ///
    /// ## Remarks
    /// You may adjust the stream's properties to access the memory and allocations.
    ///
    /// ## Thread Safety
    /// It is safe to call this function from any thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn initFromDynamicMem() !Stream {
        return .{
            .value = try errors.wrapNull(*c.SDL_IOStream, c.SDL_IOFromDynamicMem()),
        };
    }

    /// Use this function to create a new stream structure for reading from and/or writing to a named file.
    ///
    /// ## Function Parameters
    /// * `path`: A UTF-8 string representing the filename to open.
    /// * `mode`: An ASCII string representing the mode to be used for opening the file.
    ///
    /// ## Return Value
    /// Returns a stream.
    ///
    /// ## Remarks
    /// This function supports Unicode filenames, but they must be encoded in UTF-8 format, regardless of the underlying operating system.
    ///
    /// In Android, `io_stream.Stream.initFromFile()` can be used to open `content://` URIs.
    /// As a fallback, `io_stream.Stream.initFromFile()` will transparently open a matching filename in the app's assets.
    ///
    /// Closing the stream will close SDL's internal file handle.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn initFromFile(
        path: [:0]const u8,
        mode: FileMode,
    ) !Stream {
        return .{
            .value = try errors.wrapNull(*c.SDL_IOStream, c.SDL_IOFromFile(path.ptr, switch (mode) {
                .append_binary => "ab",
                .append_text => "a",
                .read_append_binary => "a+b",
                .read_append_text => "a+",
                .read_binary => "rb",
                .read_text => "r",
                .read_write_replace_binary => "w+b",
                .read_write_replace_text => "w+",
                .read_write_update_binary => "r+b",
                .read_write_update_text => "r+",
                .write_binary => "wb",
                .write_text => "w",
            })),
        };
    }

    /// Use this function to prepare a read-write memory buffer for use with a stream.
    ///
    /// ## Function Parameters
    /// * `data`: Buffer to make into a stream.
    ///
    /// ## Return Value
    /// Returns a stream.
    ///
    /// ## Remarks
    /// This function sets up a stream struct based on a memory area of a certain size, for both read and write access.
    ///
    /// This memory buffer is not copied by the stream; the pointer you provide must remain valid until you close the stream.
    /// Closing the stream will not free the original buffer.
    ///
    /// If you need to make sure the stream never writes to the memory buffer, you should use `io_stream.Stream.initFromConstMem()` with a read-only buffer of memory instead.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn initFromMem(
        data: []u8,
    ) !Stream {
        return .{
            .value = try errors.wrapNull(*c.SDL_IOStream, c.SDL_IOFromMem(
                data.ptr,
                data.len,
            )),
        };
    }

    /// Initialize a stream for compatibility with SDL.
    ///
    /// ## Remarks
    /// Note the source must exist for the lifetime of this stream.
    /// Read and write to the stream using the source you provide.
    ///
    /// ## Function Parameters
    /// * `source`: The stream source to initialize from.
    ///
    /// ## Return Value
    /// Returns a stream.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn initFromStreamSource(
        source: *std.io.StreamSource,
    ) !Stream {
        const ret = c.SDL_OpenIO(&stream_source_interface, source);
        if (ret) |val| {
            return .{ .value = val };
        }
        return error.SDLError;
    }

    /// Load all the data from an SDL data stream.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to read all available data from.
    /// * `close_when_done`: If true, close the stream before returning, even on error.
    ///
    /// ## Return Value
    /// Returns the data.
    /// This should be freed with `stdinc.free()`.
    ///
    /// ## Remarks
    /// The data is null-terminated for convenience.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn loadFile(
        self: Stream,
        close_when_done: bool,
    ) ![:0]u8 {
        var len: usize = undefined;
        return @as([*:0]u8, @alignCast(@ptrCast(try errors.wrapNull(*anyopaque, c.SDL_LoadFile_IO(
            self.value,
            &len,
            close_when_done,
        )))))[0..len :0];
    }

    /// Read from a data source.
    ///
    /// ## Function Parameters
    /// * `self`: Stream structure.
    /// * `buf`: Buffer to read into.
    ///
    /// ## Return Value
    /// Returns the slice of bytes read, this re-uses the same pointer for `buf`.
    /// If `null` is returned, then the end of file has been reached.
    ///
    /// ## Remarks
    /// This function may read less bytes than requested.
    ///
    /// This function will return `null` when the data stream is completely read, and will not return an error.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn read(
        self: Stream,
        buf: []u8,
    ) !?[]u8 {
        const ret = c.SDL_ReadIO(self.value, buf.ptr, buf.len);
        if (ret == 0) {
            const status = c.SDL_GetIOStatus(self.value);
            switch (status) {
                c.SDL_IO_STATUS_ERROR => {
                    errors.callErrorCallback();
                    return error.Err;
                },
                c.SDL_IO_STATUS_NOT_READY => {
                    errors.callErrorCallback();
                    return error.NotReady;
                },
                c.SDL_IO_STATUS_READONLY => {
                    errors.callErrorCallback();
                    return error.ReadOnly;
                },
                c.SDL_IO_STATUS_WRITEONLY => {
                    errors.callErrorCallback();
                    return error.WriteOnly;
                },
                else => return null,
            }
        }
        return buf.ptr[0..ret];
    }

    /// Use this function to read a signed byte from a stream.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to read from.
    ///
    /// ## Return Value
    /// Returns a value if successful, `null` if the end of file is reached, or an error if an error was encountered.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn readS8(
        self: Stream,
    ) !?i8 {
        var ret: i8 = undefined;
        if (!c.SDL_ReadS8(self.value, &ret)) {
            switch (c.SDL_GetIOStatus(self.value)) {
                c.SDL_IO_STATUS_ERROR => {
                    errors.callErrorCallback();
                    return error.Err;
                },
                c.SDL_IO_STATUS_NOT_READY => {
                    errors.callErrorCallback();
                    return error.NotReady;
                },
                c.SDL_IO_STATUS_READONLY => {
                    errors.callErrorCallback();
                    return error.ReadOnly;
                },
                c.SDL_IO_STATUS_WRITEONLY => {
                    errors.callErrorCallback();
                    return error.WriteOnly;
                },
                else => {
                    return null;
                },
            }
        }
        return ret;
    }

    /// Use this function to read 16 bits of big-endian data from a stream and return in native format.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to read from.
    ///
    /// ## Return Value
    /// Returns a value if successful, `null` if the end of file is reached, or an error if an error was encountered.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the data returned will be in the native byte order.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn readS16Be(
        self: Stream,
    ) !?i16 {
        var ret: i16 = undefined;
        if (!c.SDL_ReadS16BE(self.value, &ret)) {
            switch (c.SDL_GetIOStatus(self.value)) {
                c.SDL_IO_STATUS_ERROR => {
                    errors.callErrorCallback();
                    return error.Err;
                },
                c.SDL_IO_STATUS_NOT_READY => {
                    errors.callErrorCallback();
                    return error.NotReady;
                },
                c.SDL_IO_STATUS_READONLY => {
                    errors.callErrorCallback();
                    return error.ReadOnly;
                },
                c.SDL_IO_STATUS_WRITEONLY => {
                    errors.callErrorCallback();
                    return error.WriteOnly;
                },
                else => {
                    return null;
                },
            }
        }
        return ret;
    }

    /// Use this function to read 16 bits of little-endian data from a stream and return in native format.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to read from.
    ///
    /// ## Return Value
    /// Returns a value if successful, `null` if the end of file is reached, or an error if an error was encountered.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the data returned will be in the native byte order.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn readS16Le(
        self: Stream,
    ) !?i16 {
        var ret: i16 = undefined;
        if (!c.SDL_ReadS16LE(self.value, &ret)) {
            switch (c.SDL_GetIOStatus(self.value)) {
                c.SDL_IO_STATUS_ERROR => {
                    errors.callErrorCallback();
                    return error.Err;
                },
                c.SDL_IO_STATUS_NOT_READY => {
                    errors.callErrorCallback();
                    return error.NotReady;
                },
                c.SDL_IO_STATUS_READONLY => {
                    errors.callErrorCallback();
                    return error.ReadOnly;
                },
                c.SDL_IO_STATUS_WRITEONLY => {
                    errors.callErrorCallback();
                    return error.WriteOnly;
                },
                else => {
                    return null;
                },
            }
        }
        return ret;
    }

    /// Use this function to read 32 bits of big-endian data from a stream and return in native format.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to read from.
    ///
    /// ## Return Value
    /// Returns a value if successful, `null` if the end of file is reached, or an error if an error was encountered.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the data returned will be in the native byte order.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn readS32Be(
        self: Stream,
    ) !?i32 {
        var ret: i32 = undefined;
        if (!c.SDL_ReadS32BE(self.value, &ret)) {
            switch (c.SDL_GetIOStatus(self.value)) {
                c.SDL_IO_STATUS_ERROR => {
                    errors.callErrorCallback();
                    return error.Err;
                },
                c.SDL_IO_STATUS_NOT_READY => {
                    errors.callErrorCallback();
                    return error.NotReady;
                },
                c.SDL_IO_STATUS_READONLY => {
                    errors.callErrorCallback();
                    return error.ReadOnly;
                },
                c.SDL_IO_STATUS_WRITEONLY => {
                    errors.callErrorCallback();
                    return error.WriteOnly;
                },
                else => {
                    return null;
                },
            }
        }
        return ret;
    }

    /// Use this function to read 32 bits of little-endian data from a stream and return in native format.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to read from.
    ///
    /// ## Return Value
    /// Returns a value if successful, `null` if the end of file is reached, or an error if an error was encountered.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the data returned will be in the native byte order.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn readS32Le(
        self: Stream,
    ) !?i32 {
        var ret: i32 = undefined;
        if (!c.SDL_ReadS32LE(self.value, &ret)) {
            switch (c.SDL_GetIOStatus(self.value)) {
                c.SDL_IO_STATUS_ERROR => {
                    errors.callErrorCallback();
                    return error.Err;
                },
                c.SDL_IO_STATUS_NOT_READY => {
                    errors.callErrorCallback();
                    return error.NotReady;
                },
                c.SDL_IO_STATUS_READONLY => {
                    errors.callErrorCallback();
                    return error.ReadOnly;
                },
                c.SDL_IO_STATUS_WRITEONLY => {
                    errors.callErrorCallback();
                    return error.WriteOnly;
                },
                else => {
                    return null;
                },
            }
        }
        return ret;
    }

    /// Use this function to read 64 bits of big-endian data from a stream and return in native format.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to read from.
    ///
    /// ## Return Value
    /// Returns a value if successful, `null` if the end of file is reached, or an error if an error was encountered.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the data returned will be in the native byte order.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn readS64Be(
        self: Stream,
    ) !?i64 {
        var ret: i64 = undefined;
        if (!c.SDL_ReadS64BE(self.value, &ret)) {
            switch (c.SDL_GetIOStatus(self.value)) {
                c.SDL_IO_STATUS_ERROR => {
                    errors.callErrorCallback();
                    return error.Err;
                },
                c.SDL_IO_STATUS_NOT_READY => {
                    errors.callErrorCallback();
                    return error.NotReady;
                },
                c.SDL_IO_STATUS_READONLY => {
                    errors.callErrorCallback();
                    return error.ReadOnly;
                },
                c.SDL_IO_STATUS_WRITEONLY => {
                    errors.callErrorCallback();
                    return error.WriteOnly;
                },
                else => {
                    return null;
                },
            }
        }
        return ret;
    }

    /// Use this function to read 64 bits of little-endian data from a stream and return in native format.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to read from.
    ///
    /// ## Return Value
    /// Returns a value if successful, `null` if the end of file is reached, or an error if an error was encountered.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the data returned will be in the native byte order.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn readS64Le(
        self: Stream,
    ) !?i64 {
        var ret: i64 = undefined;
        if (!c.SDL_ReadS64LE(self.value, &ret)) {
            switch (c.SDL_GetIOStatus(self.value)) {
                c.SDL_IO_STATUS_ERROR => {
                    errors.callErrorCallback();
                    return error.Err;
                },
                c.SDL_IO_STATUS_NOT_READY => {
                    errors.callErrorCallback();
                    return error.NotReady;
                },
                c.SDL_IO_STATUS_READONLY => {
                    errors.callErrorCallback();
                    return error.ReadOnly;
                },
                c.SDL_IO_STATUS_WRITEONLY => {
                    errors.callErrorCallback();
                    return error.WriteOnly;
                },
                else => {
                    return null;
                },
            }
        }
        return ret;
    }

    /// Use this function to read a byte from a stream.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to read from.
    ///
    /// ## Return Value
    /// Returns a value if successful, `null` if the end of file is reached, or an error if an error was encountered.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn readU8(
        self: Stream,
    ) !?u8 {
        var ret: u8 = undefined;
        if (!c.SDL_ReadU8(self.value, &ret)) {
            switch (c.SDL_GetIOStatus(self.value)) {
                c.SDL_IO_STATUS_ERROR => {
                    errors.callErrorCallback();
                    return error.Err;
                },
                c.SDL_IO_STATUS_NOT_READY => {
                    errors.callErrorCallback();
                    return error.NotReady;
                },
                c.SDL_IO_STATUS_READONLY => {
                    errors.callErrorCallback();
                    return error.ReadOnly;
                },
                c.SDL_IO_STATUS_WRITEONLY => {
                    errors.callErrorCallback();
                    return error.WriteOnly;
                },
                else => {
                    return null;
                },
            }
        }
        return ret;
    }

    /// Use this function to read 16 bits of big-endian data from a stream and return in native format.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to read from.
    ///
    /// ## Return Value
    /// Returns a value if successful, `null` if the end of file is reached, or an error if an error was encountered.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the data returned will be in the native byte order.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn readU16Be(
        self: Stream,
    ) !?u16 {
        var ret: u16 = undefined;
        if (!c.SDL_ReadU16BE(self.value, &ret)) {
            switch (c.SDL_GetIOStatus(self.value)) {
                c.SDL_IO_STATUS_ERROR => {
                    errors.callErrorCallback();
                    return error.Err;
                },
                c.SDL_IO_STATUS_NOT_READY => {
                    errors.callErrorCallback();
                    return error.NotReady;
                },
                c.SDL_IO_STATUS_READONLY => {
                    errors.callErrorCallback();
                    return error.ReadOnly;
                },
                c.SDL_IO_STATUS_WRITEONLY => {
                    errors.callErrorCallback();
                    return error.WriteOnly;
                },
                else => {
                    return null;
                },
            }
        }
        return ret;
    }

    /// Use this function to read 16 bits of little-endian data from a stream and return in native format.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to read from.
    ///
    /// ## Return Value
    /// Returns a value if successful, `null` if the end of file is reached, or an error if an error was encountered.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the data returned will be in the native byte order.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn readU16Le(
        self: Stream,
    ) !?u16 {
        var ret: u16 = undefined;
        if (!c.SDL_ReadU16LE(self.value, &ret)) {
            switch (c.SDL_GetIOStatus(self.value)) {
                c.SDL_IO_STATUS_ERROR => {
                    errors.callErrorCallback();
                    return error.Err;
                },
                c.SDL_IO_STATUS_NOT_READY => {
                    errors.callErrorCallback();
                    return error.NotReady;
                },
                c.SDL_IO_STATUS_READONLY => {
                    errors.callErrorCallback();
                    return error.ReadOnly;
                },
                c.SDL_IO_STATUS_WRITEONLY => {
                    errors.callErrorCallback();
                    return error.WriteOnly;
                },
                else => {
                    return null;
                },
            }
        }
        return ret;
    }

    /// Use this function to read 32 bits of big-endian data from a stream and return in native format.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to read from.
    ///
    /// ## Return Value
    /// Returns a value if successful, `null` if the end of file is reached, or an error if an error was encountered.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the data returned will be in the native byte order.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn readU32Be(
        self: Stream,
    ) !?u32 {
        var ret: u32 = undefined;
        if (!c.SDL_ReadU32BE(self.value, &ret)) {
            switch (c.SDL_GetIOStatus(self.value)) {
                c.SDL_IO_STATUS_ERROR => {
                    errors.callErrorCallback();
                    return error.Err;
                },
                c.SDL_IO_STATUS_NOT_READY => {
                    errors.callErrorCallback();
                    return error.NotReady;
                },
                c.SDL_IO_STATUS_READONLY => {
                    errors.callErrorCallback();
                    return error.ReadOnly;
                },
                c.SDL_IO_STATUS_WRITEONLY => {
                    errors.callErrorCallback();
                    return error.WriteOnly;
                },
                else => {
                    return null;
                },
            }
        }
        return ret;
    }

    /// Use this function to read 32 bits of little-endian data from a stream and return in native format.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to read from.
    ///
    /// ## Return Value
    /// Returns a value if successful, `null` if the end of file is reached, or an error if an error was encountered.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the data returned will be in the native byte order.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn readU32Le(
        self: Stream,
    ) !?u32 {
        var ret: u32 = undefined;
        if (!c.SDL_ReadU32LE(self.value, &ret)) {
            switch (c.SDL_GetIOStatus(self.value)) {
                c.SDL_IO_STATUS_ERROR => {
                    errors.callErrorCallback();
                    return error.Err;
                },
                c.SDL_IO_STATUS_NOT_READY => {
                    errors.callErrorCallback();
                    return error.NotReady;
                },
                c.SDL_IO_STATUS_READONLY => {
                    errors.callErrorCallback();
                    return error.ReadOnly;
                },
                c.SDL_IO_STATUS_WRITEONLY => {
                    errors.callErrorCallback();
                    return error.WriteOnly;
                },
                else => {
                    return null;
                },
            }
        }
        return ret;
    }

    /// Use this function to read 64 bits of big-endian data from a stream and return in native format.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to read from.
    ///
    /// ## Return Value
    /// Returns a value if successful, `null` if the end of file is reached, or an error if an error was encountered.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the data returned will be in the native byte order.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn readU64Be(
        self: Stream,
    ) !?u64 {
        var ret: u64 = undefined;
        if (!c.SDL_ReadU64BE(self.value, &ret)) {
            switch (c.SDL_GetIOStatus(self.value)) {
                c.SDL_IO_STATUS_ERROR => {
                    errors.callErrorCallback();
                    return error.Err;
                },
                c.SDL_IO_STATUS_NOT_READY => {
                    errors.callErrorCallback();
                    return error.NotReady;
                },
                c.SDL_IO_STATUS_READONLY => {
                    errors.callErrorCallback();
                    return error.ReadOnly;
                },
                c.SDL_IO_STATUS_WRITEONLY => {
                    errors.callErrorCallback();
                    return error.WriteOnly;
                },
                else => {
                    return null;
                },
            }
        }
        return ret;
    }

    /// Use this function to read 64 bits of little-endian data from a stream and return in native format.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to read from.
    ///
    /// ## Return Value
    /// Returns a value if successful, `null` if the end of file is reached, or an error if an error was encountered.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the data returned will be in the native byte order.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn readU64Le(
        self: Stream,
    ) !?u64 {
        var ret: u64 = undefined;
        if (!c.SDL_ReadU64LE(self.value, &ret)) {
            switch (c.SDL_GetIOStatus(self.value)) {
                c.SDL_IO_STATUS_ERROR => {
                    errors.callErrorCallback();
                    return error.Err;
                },
                c.SDL_IO_STATUS_NOT_READY => {
                    errors.callErrorCallback();
                    return error.NotReady;
                },
                c.SDL_IO_STATUS_READONLY => {
                    errors.callErrorCallback();
                    return error.ReadOnly;
                },
                c.SDL_IO_STATUS_WRITEONLY => {
                    errors.callErrorCallback();
                    return error.WriteOnly;
                },
                else => {
                    return null;
                },
            }
        }
        return ret;
    }

    fn readerRead(
        self: Stream,
        buffer: []u8,
    ) Error!usize {
        const ret = try self.read(buffer);
        if (ret) |val|
            return val.len;
        return 0;
    }

    /// Stream reader type.
    ///
    /// ## Version
    /// This type is provided by zig-sdl3.
    pub const Reader = std.io.Reader(Stream, Error, readerRead);

    /// Get a reader to the stream.
    ///
    /// ## Function Parameters
    /// * `self`: Stream to get the reader to.
    ///
    /// ## Return Value
    /// Returns a reader.
    ///
    /// ## Version
    /// This function is provided by zig-sdl3.
    pub fn reader(
        self: Stream,
    ) Reader {
        return .{ .context = self };
    }

    /// Save all the data into an SDL data stream.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to write all data to.
    /// * `data`: The data to be written.
    /// * `close_when_done`: Close the stream before returning, even if an error occurs.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn saveFile(
        self: Stream,
        data: []const u8,
        close_when_done: bool,
    ) !void {
        return errors.wrapCallBool(c.SDL_SaveFile_IO(
            self.value,
            data.ptr,
            data.len,
            close_when_done,
        ));
    }

    /// Seek within a data stream.
    ///
    /// ## Function Parameters
    /// * `self`: The stream structure.
    /// * `offset`: An offset in bytes, relative to whence location; can be negative.
    /// * `whence`: Where to seek from.
    ///
    /// ## Return Value
    /// Returns the final offset in the data stream after the seek.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn seek(
        self: Stream,
        offset: isize,
        whence: Whence,
    ) !usize {
        return @intCast(try errors.wrapCall(i64, c.SDL_SeekIO(
            self.value,
            @intCast(offset),
            @intFromEnum(whence),
        ), -1));
    }

    pub fn setProperties(
        self: Stream,
        props: Properties,
    ) !void {
        const val = try errors.wrapCall(c.SDL_PropertiesID, c.SDL_GetIOProperties(self.value), 0);
        const group = properties.Group{ .value = val };
        try props.setProperties(group);
    }

    /// Determine the current read/write offset in a data stream.
    ///
    /// ## Function Parameters
    /// * `self`: A data stream object from which to get the current offset.
    ///
    /// ## Return Value
    /// Returns the current offset in the stream.
    ///
    /// ## Remarks
    /// This is actually a wrapper function that calls the `io_stream.Stream.seek()` method, with an offset of `0` bytes from `io_stream.Whence.cur`,
    /// to simplify application development.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn tell(
        self: Stream,
    ) !usize {
        const ret = c.SDL_TellIO(
            self.value,
        );
        return @intCast(try errors.wrapCall(i64, ret, -1));
    }

    /// Write to a data stream.
    ///
    /// ## Function Parameters
    /// * `self`: Stream structure.
    /// * `data`: Data to write.
    /// * `size_written`: Size written, only populated when this function returns an error. It will be less than the `data.len`.
    ///
    /// ## Remarks
    /// This function writes exactly the data to the stream.
    /// If this fails for any reason, it'll return less than size to demonstrate how far the write progressed.
    ///
    /// On error, this function still attempts to write as much as possible, so it will fill `size_written` positive value less than the requested write size if there is an error.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn write(
        self: Stream,
        data: []const u8,
        size_written: ?*usize,
    ) !void {
        const ret = c.SDL_WriteIO(self.value, data.ptr, data.len);
        if (ret != data.len) {
            const status = c.SDL_GetIOStatus(self.value);
            const err_val: ?Error = switch (status) {
                c.SDL_IO_STATUS_ERROR => error.Err,
                c.SDL_IO_STATUS_NOT_READY => error.NotReady,
                c.SDL_IO_STATUS_READONLY => error.ReadOnly,
                c.SDL_IO_STATUS_WRITEONLY => error.WriteOnly,
                else => null,
            };
            if (err_val) |err| {
                errors.callErrorCallback();
                if (size_written) |val|
                    val.* = ret;
                return err;
            }
        }
    }

    /// Use this function to write a signed byte to a stream.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to write to.
    /// * `value`: The byte value to write.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn writeS8(
        self: Stream,
        value: i8,
    ) !void {
        return errors.wrapCallBool(c.SDL_WriteS8(
            self.value,
            value,
        ));
    }

    /// Use this function to write 16 bits in native format to a stream as big-endian data.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to write to.
    /// * `value`: The data to be written, in native format.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the application always specifies native format, and the data written will be in big-endian format.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn writeS16Be(
        self: Stream,
        value: i16,
    ) !void {
        return errors.wrapCallBool(c.SDL_WriteS16BE(
            self.value,
            value,
        ));
    }

    /// Use this function to write 16 bits in native format to a stream as little-endian data.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to write to.
    /// * `value`: The data to be written, in native format.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the application always specifies native format, and the data written will be in little-endian format.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn writeS16Le(
        self: Stream,
        value: i16,
    ) !void {
        return errors.wrapCallBool(c.SDL_WriteS16LE(
            self.value,
            value,
        ));
    }

    /// Use this function to write 32 bits in native format to a stream as big-endian data.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to write to.
    /// * `value`: The data to be written, in native format.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the application always specifies native format, and the data written will be in big-endian format.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn writeS32Be(
        self: Stream,
        value: i32,
    ) !void {
        return errors.wrapCallBool(c.SDL_WriteS32BE(
            self.value,
            value,
        ));
    }

    /// Use this function to write 32 bits in native format to a stream as little-endian data.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to write to.
    /// * `value`: The data to be written, in native format.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the application always specifies native format, and the data written will be in little-endian format.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn writeS32Le(
        self: Stream,
        value: i32,
    ) !void {
        return errors.wrapCallBool(c.SDL_WriteS32LE(
            self.value,
            value,
        ));
    }

    /// Use this function to write 64 bits in native format to a stream as big-endian data.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to write to.
    /// * `value`: The data to be written, in native format.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the application always specifies native format, and the data written will be in big-endian format.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn writeS64Be(
        self: Stream,
        value: i64,
    ) !void {
        return errors.wrapCallBool(c.SDL_WriteS64BE(
            self.value,
            value,
        ));
    }

    /// Use this function to write 64 bits in native format to a stream as little-endian data.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to write to.
    /// * `value`: The data to be written, in native format.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the application always specifies native format, and the data written will be in little-endian format.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn writeS64Le(
        self: Stream,
        value: i64,
    ) !void {
        return errors.wrapCallBool(c.SDL_WriteS64LE(
            self.value,
            value,
        ));
    }

    /// Use this function to write a byte to a stream.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to write to.
    /// * `value`: The byte value to write.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn writeU8(
        self: Stream,
        value: u8,
    ) !void {
        return errors.wrapCallBool(c.SDL_WriteU8(
            self.value,
            value,
        ));
    }

    /// Use this function to write 16 bits in native format to a stream as big-endian data.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to write to.
    /// * `value`: The data to be written, in native format.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the application always specifies native format, and the data written will be in big-endian format.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn writeU16Be(
        self: Stream,
        value: u16,
    ) !void {
        return errors.wrapCallBool(c.SDL_WriteU16BE(
            self.value,
            value,
        ));
    }

    /// Use this function to write 16 bits in native format to a stream as little-endian data.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to write to.
    /// * `value`: The data to be written, in native format.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the application always specifies native format, and the data written will be in little-endian format.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn writeU16Le(
        self: Stream,
        value: u16,
    ) !void {
        return errors.wrapCallBool(c.SDL_WriteU16LE(
            self.value,
            value,
        ));
    }

    /// Use this function to write 32 bits in native format to a stream as big-endian data.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to write to.
    /// * `value`: The data to be written, in native format.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the application always specifies native format, and the data written will be in big-endian format.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn writeU32Be(
        self: Stream,
        value: u32,
    ) !void {
        return errors.wrapCallBool(c.SDL_WriteU32BE(
            self.value,
            value,
        ));
    }

    /// Use this function to write 32 bits in native format to a stream as little-endian data.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to write to.
    /// * `value`: The data to be written, in native format.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the application always specifies native format, and the data written will be in little-endian format.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn writeU32Le(
        self: Stream,
        value: u32,
    ) !void {
        return errors.wrapCallBool(c.SDL_WriteU32LE(
            self.value,
            value,
        ));
    }

    /// Use this function to write 64 bits in native format to a stream as big-endian data.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to write to.
    /// * `value`: The data to be written, in native format.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the application always specifies native format, and the data written will be in big-endian format.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn writeU64Be(
        self: Stream,
        value: u64,
    ) !void {
        return errors.wrapCallBool(c.SDL_WriteU64BE(
            self.value,
            value,
        ));
    }

    /// Use this function to write 64 bits in native format to a stream as little-endian data.
    ///
    /// ## Function Parameters
    /// * `self`: The stream to write to.
    /// * `value`: The data to be written, in native format.
    ///
    /// ## Remarks
    /// SDL byteswaps the data only if necessary, so the application always specifies native format, and the data written will be in little-endian format.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn writeU64Le(
        self: Stream,
        value: u64,
    ) !void {
        return errors.wrapCallBool(c.SDL_WriteU64LE(
            self.value,
            value,
        ));
    }

    fn writerWrite(
        self: Stream,
        data: []const u8,
    ) Error!usize {
        try self.write(data, null);
        return data.len;
    }

    /// Stream writer type.
    ///
    /// ## Version
    /// This type is provided by zig-sdl3.
    pub const Writer = std.io.Writer(Stream, Error, writerWrite);

    /// Get a writer to the stream.
    ///
    /// ## Function Parameters
    /// * `self`: Stream to get the writer to.
    ///
    /// ## Return Value
    /// Returns a writer.
    ///
    /// ## Version
    /// This function is provided by zig-sdl3.
    pub fn writer(
        self: Stream,
    ) Writer {
        return .{ .context = self };
    }
};

/// Possible `whence` values for `io_stream.Stream` seeking.
///
/// ## Remarks
/// These map to the same "whence" concept that `fseek` or `lseek` use in the standard C runtime.
///
/// ## Version
/// This enum is available since SDL 3.2.0.
pub const Whence = enum(c_uint) {
    /// Seek from the beginning of data.
    set = c.SDL_IO_SEEK_SET,
    /// Seek relative to current read point.
    cur = c.SDL_IO_SEEK_CUR,
    /// Seek relative to the end of data.
    end = c.SDL_IO_SEEK_END,
};

const stream_source_interface = c.SDL_IOStreamInterface{
    .version = @sizeOf(c.SDL_IOStreamInterface),
    .size = streamSize,
    .seek = streamSeek,
    .read = streamRead,
    .write = streamWrite,
    .flush = streamFlush,
    .close = streamClose,
};

fn streamSize(data: ?*anyopaque) callconv(.c) i64 {
    var stream: *std.io.StreamSource = @ptrCast(@alignCast(data.?));
    const end_pos = stream.getEndPos() catch return -1;
    return @intCast(end_pos);
}

fn streamSeek(data: ?*anyopaque, offset: i64, whence: c_uint) callconv(.c) i64 {
    var stream: *std.io.StreamSource = @ptrCast(@alignCast(data.?));
    switch (whence) {
        c.SDL_IO_SEEK_CUR => stream.seekBy(offset) catch return -1,
        c.SDL_IO_SEEK_SET => stream.seekTo(@intCast(offset)) catch return -1,
        c.SDL_IO_SEEK_END => {
            const end_pos = stream.getEndPos() catch return -1;
            if (offset > end_pos)
                return -1;
            stream.seekTo(@intCast(end_pos - @as(u64, @intCast(offset)))) catch return -1;
        },
        else => return -1,
    }
    const pos = stream.getPos() catch return -1;
    return @as(i64, @intCast(pos));
}

fn streamRead(data: ?*anyopaque, ptr: ?*anyopaque, size: usize, status: [*c]c_uint) callconv(.c) usize {
    var stream: *std.io.StreamSource = @ptrCast(@alignCast(data.?));
    var dest: [*]u8 = @ptrCast(ptr.?);
    return stream.read(dest[0..size]) catch blk: {
        status.* = c.SDL_IO_STATUS_ERROR;
        break :blk 0;
    };
}

fn streamWrite(data: ?*anyopaque, ptr: ?*const anyopaque, size: usize, status: [*c]c_uint) callconv(.c) usize {
    var stream: *std.io.StreamSource = @ptrCast(@alignCast(data.?));
    var src: [*]const u8 = @ptrCast(ptr.?);
    return stream.write(src[0..size]) catch blk: {
        status.* = c.SDL_IO_STATUS_ERROR;
        break :blk 0;
    };
}

fn streamFlush(data: ?*anyopaque, status: [*c]c_uint) callconv(.c) bool {
    _ = data;
    _ = status;
    return true; // No flushing needed, idk.
}

fn streamClose(data: ?*anyopaque) callconv(.c) bool {
    _ = data;
    return true;
}

/// Load all the data from a file path.
///
/// ## Function Parameters
/// * `path`: The path to read all available data from.
///
/// ## Return Value
/// Returns the data.
/// This should be freed with `stdinc.free()`.
///
/// ## Remarks
/// The data is null-terminated for convenience.
///
/// ## Thread Safety
/// This function is not thread safe.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn loadFile(
    path: [:0]const u8,
) ![:0]u8 {
    var len: usize = undefined;
    return @as([*:0]u8, @alignCast(@ptrCast(try errors.wrapNull(*anyopaque, c.SDL_LoadFile(
        path.ptr,
        &len,
    )))))[0..len :0];
}

/// Save all the data into a file path.
///
/// ## Function Parameters
/// * `path`: The path to write all available data into.
/// * `data`: The data to write to the file.
///
/// ## Thread Safety
/// This function is not thread safe.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn saveFile(
    path: [:0]const u8,
    data: []const u8,
) !void {
    return errors.wrapCallBool(c.SDL_SaveFile(
        path.ptr,
        data.ptr,
        data.len,
    ));
}

// Stream tests.
test "Stream" {
    std.testing.refAllDeclsRecursive(@This());

    // Test stream source.
    var buffer: [64]u8 = undefined;
    var source: std.io.StreamSource = .{ .buffer = .{ .buffer = &buffer, .pos = 0 } };
    const stream = try Stream.initFromStreamSource(&source);
    defer stream.deinit() catch {};
    try stream.writeU8(7);
    try std.testing.expect(buffer[0] == 7);
    buffer[1] = 3;
    try std.testing.expectEqual(3, try stream.readU8());
    try std.testing.expectEqual(64, try stream.getSize());
    try std.testing.expectEqual(50, stream.seek(50, .set));
    try std.testing.expectEqual(41, stream.seek(23, .end));
    try std.testing.expectEqual(43, stream.seek(2, .cur));

    // Test writer/reader.
    _ = try stream.seek(0, .set);
    try stream.writer().print("Hello {s}!", .{"World"});
    _ = try stream.seek(0, .set);
    const hello_world = "Hello World!";
    var hello_world_buf: [hello_world.len]u8 = undefined;
    try std.testing.expectEqual(hello_world.len, try stream.reader().readAll(&hello_world_buf));
    try std.testing.expectEqualStrings(hello_world, &hello_world_buf);
}
