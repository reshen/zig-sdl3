const sdl3 = @import("sdl3");
const std = @import("std");

fn printPropertyType(typ: ?sdl3.properties.Type) []const u8 {
    if (typ) |val|
        return switch (val) {
            .pointer => "pointer",
            .string => "string",
            .number => "number",
            .float => "float",
            .boolean => "boolean",
        };
    return "[does not exist]";
}

fn arrayCleanupCallback(user_data: ?*anyopaque, val: ?*anyopaque) callconv(.c) void {
    _ = user_data;
    const data: *std.ArrayList(u32) = @alignCast(@ptrCast(val));
    data.deinit();
}

fn printItems(user_data: ?*anyopaque, props: sdl3.c.SDL_PropertiesID, name: [*c]const u8) callconv(.c) void {
    const index: *u32 = @alignCast(@ptrCast(user_data));
    const group = sdl3.properties.Group{ .value = props };
    std.io.getStdOut().writer().print("Index: {d}, Name: \"{s}\", Type: {s}\n", .{
        index.*,
        name,
        printPropertyType(group.getType(std.mem.span(name))),
    }) catch std.io.getStdErr().writer().print("Standard writer error\n", .{}) catch {};
    index.* += 1;
}

pub fn main() !void {
    const properties = try sdl3.properties.Group.init();
    defer properties.deinit();
    var num: u32 = 3;
    try properties.set("myBool", .{ .boolean = true });
    try properties.set("myNum", .{ .number = 7 });
    try properties.set("myNumPtr", .{ .pointer = &num });
    try properties.set("myStr", .{ .string = "Hello World!" });

    const allocator = std.heap.c_allocator;
    var arr = std.ArrayList(u32).init(allocator);
    try properties.setPointerPropertyWithCleanup("myArr", &arr, arrayCleanupCallback, null);

    const writer = std.io.getStdOut().writer();
    try writer.print("Type of \"myStr\" is {s}\n", .{printPropertyType(properties.getType("myStr"))});
    try writer.print("Type of \"isNotThere\" is {s}\n\n", .{printPropertyType(properties.getType("isNotThere"))});

    var index: usize = 0;
    try properties.enumerateProperties(printItems, &index);

    try writer.print("\nNotice that since \"myArr\" has a custom deleter that it is not present!\n", .{});
    const global_properties = try sdl3.properties.getGlobal();
    try properties.copyTo(global_properties);
    var set = try global_properties.getAll(allocator);
    defer set.deinit();
    var iterator = set.iterator();
    index = 0;
    while (iterator.next()) |item| {
        try writer.print("Index: {d}, Name: \"{s}\", Type: {s}\n", .{ index, item.key_ptr.*, printPropertyType(global_properties.getType(@ptrCast(item.key_ptr.*))) });
        index += 1;
    }

    try writer.print("\nYou can clear items\n", .{});
    index = 0;
    try properties.clear("myNumPtr");
    try properties.clear("myStr");
    try properties.enumerateProperties(printItems, &index);

    if (properties.get("myBool")) |val| {
        try writer.print("\nValue of \"myBool\" is {s}\n", .{if (val.boolean) "true" else "false"});
    }
    if (properties.get("myStr")) |val| {
        try writer.print("\nValue of \"myStr\" is {s}\n", .{val.string}); // Will not print.
    }
}
