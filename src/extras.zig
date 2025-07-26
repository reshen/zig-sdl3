const timer = @import("timer.zig");

/// Capper for keeping the framerate within a given range.
///
/// ## Remarks
/// VSync can be a good limiter for framerates, but in case VSync is not desired having unlimited FPS may be a problem.
/// This framerate capper solves this issue.
///
/// ## Version
/// This struct is provided by zig-sdl3.
pub fn FramerateCapper(
    comptime Accuracy: type,
) type {
    return struct {
        /// Mode for the capper to run at.
        mode: Mode,
        /// Current frame number, maxes out and will not go past the size of a `usize`.
        frame_num: u64 = 0,
        /// The number of elapsed nanoseconds present since last update.
        elapsed_ns: u64 = 0,
        /// Elapsed nanoseconds for the previous frame.
        prev_ns: u64 = 0,

        // Type check.
        comptime {
            if (@typeInfo(Accuracy) != .float)
                @compileError("Framerate capper accuracy only works on floating-point types.");
        }

        /// Framerate capper mode.
        ///
        /// ## Version
        /// This struct is provided by zig-sdl3.
        pub const Mode = union(enum) {
            /// Run at unlimited FPS.
            /// You may want to use this in case you have VSync in order to get dt.
            unlimited: void,
            /// Run at the given FPS.
            limited: usize,
        };

        /// Delay to achieve the target FPS.
        ///
        /// ## Function Parameters
        /// * `self`: The FPS limiter.
        ///
        /// ## Return Value
        /// Returns the delta time since the last frame in seconds.
        ///
        /// ## Version
        /// This function is provided since zig-sdl3.
        pub fn delay(
            self: *@This(),
        ) Accuracy {

            // Useful for diagnostics.
            self.frame_num +|= 1; // If this duration is exceeded, overflow or panic probably not ideal?

            const curr_ns = timer.getNanosecondsSinceInit();
            var dt: u64 = undefined;
            switch (self.mode) {
                .unlimited => {
                    dt = curr_ns -% self.elapsed_ns;
                },
                .limited => |fps| {
                    if (fps == 0) {
                        dt = curr_ns -% self.elapsed_ns;
                    } else {
                        // Nanoseconds per frame. 1 / (Frames / Seconds) = Seconds / Frame -> Nanoseconds / Frame.
                        const expected_ns = @as(u64, @intFromFloat(timer.nanoseconds_per_second / @as(Accuracy, @floatFromInt(fps))));
                        const ns_diff = curr_ns -% self.elapsed_ns;
                        if (ns_diff < expected_ns) {
                            dt = expected_ns -% ns_diff; // TODO: PROPERLY GET DT!!!
                            timer.delayNanoseconds(dt);
                        } else {
                            dt = 1;
                        }
                    }
                },
            }
            // self.prev_ns = self.elapsed_ns;
            // self.elapsed_ns = curr_ns;
            self.prev_ns = self.elapsed_ns; // IS THIS THE CORRECT MATH FOR GETTING OBSERVED FPS LATER?
            self.elapsed_ns = timer.getNanosecondsSinceInit();
            return @as(Accuracy, @floatFromInt(dt)) / @as(Accuracy, @floatFromInt(timer.nanoseconds_per_second));
        }

        /// Get the actual FPS.
        ///
        /// ## Function Parameters
        /// * `self`: The framerate capper.
        pub fn getObservedFps(
            self: @This(),
        ) Accuracy {
            // Frames / Second.
            // 1 Frame / (Nanoseconds / 1000).
            return 1 / (@as(Accuracy, @floatFromInt(@max(self.elapsed_ns -% self.prev_ns, 1))) / timer.nanoseconds_per_second);
        }
    };
}
