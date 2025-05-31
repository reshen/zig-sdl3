const sdl3 = @import("sdl3");
const std = @import("std");

const State = struct {
    allocator: std.mem.Allocator,
    window: sdl3.video.Window,
    quit: bool = false,
    last_file: ?[:0]const u8 = null,
    last_file_filter: ?usize = null,
    last_folder: ?[:0]const u8 = null,
    is_file: bool = true,
};

// Called whenever a native dialog is shown.
fn fileCallback(user_data: ?*anyopaque, file_list: [*c]const [*c]const u8, filter: c_int) callconv(.c) void {
    const data = sdl3.dialog.sanatizeFileCallback(State, user_data, file_list, filter) catch {
        if (user_data) |val| {
            const user: *State = @alignCast(@ptrCast(val));
            if (user.is_file) {
                user.last_file = "[dialog error]";
                user.last_file_filter = null;
            } else {
                user.last_folder = "[dialog error]";
            }
        }
        showMenu(@alignCast(@ptrCast(user_data))) catch {};
        return;
    };
    if (data.user_data) |user| {
        if (user.is_file) {
            user.last_file = std.fmt.allocPrintZ(user.allocator, "{s}", .{if (data.file_list) |val| val[0] else "[null]"}) catch "[allocation error]";
            user.last_file_filter = data.filter;
        } else {
            user.last_folder = std.fmt.allocPrintZ(user.allocator, "{s}", .{if (data.file_list) |val| val[0] else "[null]"}) catch "[allocation error]";
        }
    }
    showMenu(@alignCast(@ptrCast(user_data))) catch {};
}

// Logic for showing the main menu popup.
fn showMenu(state: *State) !void {
    const selected = try sdl3.message_box.show(.{
        .buttons = &.{
            .{
                .text = "Select File",
                .value = 0,
            },
            .{
                .text = "Select Folder",
                .value = 1,
            },
            .{
                .text = "Save File",
                .value = 2,
            },
            .{
                .text = "Save File 2",
                .value = 3,
            },
            .{
                .text = "Quit",
                .value = -1,
            },
        },
        .color_scheme = null,
        .flags = .{},
        .parent_window = state.window,
        .title = "Dialog Example",
        .message = try std.fmt.allocPrintZ(
            state.allocator,
            "Last file: {s}\nLast file filter: {s}\nLast folder: {s}",
            .{
                if (state.last_file) |val| val else "[null]",
                if (state.last_file_filter) |val| std.fmt.allocPrintZ(state.allocator, "{d}", .{val}) catch "[allocation error]" else "[null]",
                if (state.last_folder) |val| val else "[null]",
            },
        ),
    });
    switch (selected) {
        -1 => state.quit = true,
        0 => {
            state.is_file = true;
            sdl3.dialog.showOpenFile(fileCallback, state, state.window, &.{
                .{
                    .name = "PNG Images",
                    .pattern = "png",
                },
                .{
                    .name = "Any File",
                    .pattern = "*",
                },
            }, state.last_file, false);
        },
        1 => {
            state.is_file = false;
            sdl3.dialog.showOpenFolder(fileCallback, state, state.window, state.last_folder, false);
        },
        2 => {
            state.is_file = true;
            sdl3.dialog.showSaveFile(fileCallback, state, state.window, &.{
                .{
                    .name = "PNG Images",
                    .pattern = "png",
                },
                .{
                    .name = "Any File",
                    .pattern = "*",
                },
            }, state.last_file);
        },
        3 => {
            state.is_file = true;
            const props = try sdl3.dialog.showWithProperties(.save_file, fileCallback, state, .{});
            defer props.deinit();
        },
        else => {},
    }
}

pub fn main() !void {

    // Memory is used pretty terribly in this app with constant leaks but it's just an example.
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    defer sdl3.init.shutdown();

    try sdl3.init.init(.{ .video = true });
    defer sdl3.init.quit(.{ .video = false });

    const window = try sdl3.video.Window.init("Dialog Example Backing", 500, 300, .{
        .transparent = true,
    });
    defer window.deinit();

    var state = State{
        .allocator = allocator,
        .window = window,
    };
    try showMenu(&state);

    while (!state.quit) {
        switch ((try sdl3.events.wait(true)).?) {
            .terminating => break,
            .quit => break,
            else => {},
        }
    }
}
