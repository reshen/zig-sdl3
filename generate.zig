const std = @import("std");
const yaml = @import("yaml");

fn parseList(comptime Item: type, list: yaml.List, allocator: std.mem.Allocator) ![]Item {
    const ret = try allocator.alloc(Item, list.len);
    for (list, 0..list.len) |item, ind| {
        ret[ind] = Item.parse(try item.asMap(), allocator);
    }
    return ret;
}

fn parseStrings(list: yaml.List, allocator: std.mem.Allocator) ![][]const u8 {
    const ret = try allocator.alloc([]const u8, list.len);
    errdefer allocator.free(ret);
    for (list, 0..list.len) |item, ind| {
        ret[ind] = try item.asString();
    }
    return ret;
}

const ValueData = struct {
    zigValue: []const u8,
    sdlValue: []const u8,
    comment: ?[]const u8,

    pub fn parse(map: yaml.Map, allocator: std.mem.Allocator) !ValueData {
        _ = allocator;
        return .{
            .zigValue = try map.get("ZigValue").?.asString(),
            .sdlValue = try map.get("SdlValue").?.asString(),
            .comment = try if (map.get("Comment")) |val| val.asString() else null,
        };
    }

    pub fn free(self: *ValueData, allocator: std.mem.Allocator) void {
        _ = self;
        _ = allocator;
    }
};

const Enum = struct {
    sdlType: []const u8,
    zigType: []const u8,
    internalType: []const u8,
    comment: ?[]const u8,
    values: []const ValueData,
    functions: ?[]const Function,

    pub fn parse(map: yaml.Map, allocator: std.mem.Allocator) !Enum {
        return .{
            .sdlType = try map.get("SdlType").?.asString(),
            .zigType = try map.get("ZigType").?.asString(),
            .internalType = try map.get("InternalType").?.asString(),
            .comment = try if (map.get("Comment")) |val| val.asString() else null,
            .values = try parseList(ValueData, map.get("Values").?.asList()),
            .functions = if (map.get("Functions")) |val| try parseList(Function, val.asList(), allocator),
        };
    }

    pub fn free(self: *Enum, allocator: std.mem.Allocator) void {
        for (self.values) |value| {
            value.free(allocator);
        }
        allocator.free(self.values);
        if (self.functions) |funcs| {
            for (funcs) |func| {
                func.free(allocator);
            }
            allocator.free(funcs);
        }
    }
};

const Error = struct {
    name: []const u8,
    comment: []const u8,
    values: [][]const u8,

    pub fn parse(map: yaml.Map, allocator: std.mem.Allocator) !Error {
        return .{
            .name = try map.get("Name").?.asString(),
            .comment = try map.get("Comment").?.asString(),
            .values = try parseStrings(try map.get("Values").?.asList(), allocator),
        };
    }

    pub fn free(self: *Error, allocator: std.mem.Allocator) void {
        allocator.free(self.values);
    }
};

const Function = struct {
    sdlName: []const u8,
    zigName: []const u8,
    comment: []const u8,
    ret: struct {
        sdl: []const u8,
        zig: []const u8,
        convert: ?[]const u8,
        checks: ?[]const struct {
            method: []const u8,
            comparisonVal: []const u8,

            pub fn parse(map: yaml.Map, allocator: std.mem.Allocator) !Error {
                _ = allocator;
                return .{
                    .method = try map.get("Method").?.asString(),
                    .comparisonVal = try map.get("ComparisonVal").?.asString(),
                };
            }

            pub fn free(self: *@This(), allocator: std.mem.Allocator) void {
                _ = self;
                _ = allocator;
            }
        },

        pub fn parse(map: yaml.Map, allocator: std.mem.Allocator) !Error {
            return .{
                .sdl = try map.get("Sdl").?.asString(),
                .zig = try map.get("Zig").?.asString(),
                .convert = if (map.get("Convert")) |val| try val.asString() else null,
                .checks = if (map.get("Checks")) |val| try parseList(@TypeOf(Function.checks), try val.asList(), allocator) else null,
            };
        }

        pub fn free(self: *@This(), allocator: std.mem.Allocator) void {
            _ = self;
            _ = allocator;
        }
    },
    arguments: []const struct {
        name: []const u8,
        type: ?[]const u8,
        value: ?[]const u8,
        mode: ?[]const u8,

        pub fn parse(map: yaml.Map, allocator: std.mem.Allocator) !Error {
            _ = allocator;
            return .{
                .name = try map.get("Name").?.asString(),
                .type = if (map.get("Type")) |val| try val.asString() else null,
                .value = if (map.get("Value")) |val| try val.asString() else null,
                .mode = if (map.get("Mode")) |val| try val.asString() else null,
            };
        }

        pub fn free(self: *@This(), allocator: std.mem.Allocator) void {
            _ = self;
            _ = allocator;
        }
    },
};

const Value = struct {
    sdlName: []const u8,
    zigName: []const u8,
    type: []const u8,
    isOpaque: bool,
    comment: []const u8,
    presets: []const ValueData,
    functions: []const Function,
    customFunctions: []const struct {
        code: []const u8,
    },
};

const Flag = struct {
    name: []const u8,
    type: []const u8,
    comment: []const u8,
    values: []const struct {
        name: []const u8,
        type: []const u8,
        value: []const u8,
        comment: []const u8,
    },
    presets: []const struct {
        name: []const u8,
        comment: []const u8,
        values: []const struct {
            name: []const u8,
            value: bool,
        },
    },
    functions: []const Function,
    customFunctions: []const struct {
        code: []const u8,
    },
};

const StringMap = struct {
    sdlName: []const u8,
    zigName: []const u8,
    comment: []const u8,
    values: []const ValueData,
};

const Struct = struct {
    name: []const u8,
    type: []const u8,
    comment: []const u8,
    members: []const struct {
        zigName: []const u8,
        sdlName: []const u8,
        type: []const u8,
        value: []const u8,
        comment: []const u8,
        fromSdlCustom: []const u8,
        toSdlCustom: []const u8,
    },
    functions: []const Function,
    customFunctions: []const struct {
        code: []const u8,
    },
};

const Typedef = struct {
    sdlName: []const u8,
    zigName: []const u8,
    comment: []const u8,

    pub fn parse(map: yaml.Map, allocator: std.mem.Allocator) !Error {
        _ = allocator;
        return .{
            .sdlName = try map.get("SdlName").?.asString(),
            .zigName = try map.get("ZigName").?.asString(),
            .comment = try map.get("Comment").?.asString(),
        };
    }

    pub fn free(self: *Test, allocator: std.mem.Allocator) void {
        _ = self;
        _ = allocator;
    }
};

const Test = struct {
    name: []const u8,
    comment: []const u8,
    code: []const u8,

    pub fn parse(map: yaml.Map, allocator: std.mem.Allocator) !Error {
        _ = allocator;
        return .{
            .name = try map.get("Name").?.asString(),
            .comment = try map.get("Comment").?.asString(),
            .code = try map.get("Code").?.asString(),
        };
    }

    pub fn free(self: *Test, allocator: std.mem.Allocator) void {
        _ = self;
        _ = allocator;
    }
};

const Subsystem = struct {
    name: []const u8,
    extension: bool,
    callbacks: []const Function,
    enums: []const Enum,
    errors: []const Error,
    values: []const Value,
    flags: []const Flag,
    stringMap: []const StringMap,
    structs: []const Struct,
    functions: []const Function,
    customFunctions: []const struct {
        code: []const u8,
    },
    typedefs: []const Typedef,
    tests: []const Test,

    pub fn lessThan(ctx: void, lhs: Subsystem, rhs: Subsystem) bool {
        _ = ctx;
        return std.mem.lessThan(u8, lhs.name, rhs.name);
    }
};

const SubsystemRaw = struct {
    name: []const u8,
    extension: bool,
    callbacks: []const Function,
    enums: []const Enum,
    errors: []const Error,
    values: []const Value,
    flags: []const Flag,
    stringMap: []const StringMap,
    structs: []const Struct,
    functions: []const Function,
    customFunctions: []const struct {
        code: []const u8,
    },
    typedefs: []const Typedef,
    tests: []const Test,

    pub fn make() Subsystem {
        return .{};
    }
};

const File = struct {
    name: []const u8,
    exports: []const struct {
        sdlName: []const u8,
        zigName: []const u8,
        kind: []const u8,
        extra: []const struct {
            arg: []const u8,
        },
    },

    pub fn lessThan(ctx: void, lhs: File, rhs: File) bool {
        _ = ctx;
        return std.mem.lessThan(u8, lhs.name, rhs.name);
    }
};

const FileRaw = struct {
    name: []const u8,
    exports: []const struct {
        sdlName: []const u8,
        zigName: []const u8,
        kind: []const u8,
        extra: []const struct {
            arg: []const u8,
        },
    },

    pub fn make(self: FileRaw) File {
        _ = self;
        return .{};
    }
};

const Bindings = struct {
    subsystems: std.ArrayList(Subsystem),
    files: std.ArrayList(File),
};

const WriteError = error{InvalidEnumValue};

const SdlType = enum {
    Callback,
    Enum,
    Value,
    Flag,
    StringMap,
    Struct,
    Typedef,
};

const SdlTypeData = union(SdlType) {
    Callback: struct {
        func: Function,
        name: []const u8,
    },
    Enum: Enum,
    Value: Value,
    Flag: Flag,
    StringMap: StringMap,
    Struct: Struct,
    Typedef: Typedef,
};

const SdlData = struct {
    type_data: SdlTypeData,
    subsystem: []const u8,
};

const GeneratorError = error{
    UnknownSdlToTrueSdlType,
    UnknownSdlToZigType,
    UnknownZigValueToSdlValue,
    UnknownSdlValueToZigValue,
    UnknownComparisonType,
    UnknownReturnCheck,
};

fn sdlTypeToTrueSdlType(allocator: std.mem.Allocator, sdl: []const u8, sdl_types: std.StringHashMap(SdlData), generics: std.StringHashMap(void)) ![]const u8 {

    // String.
    if (std.mem.eql(u8, sdl, "string") or std.mem.eql(u8, sdl, "stringptr") or std.mem.eql(u8, sdl, "?string") or std.mem.eql(u8, sdl, "zigstring") or std.mem.eql(u8, sdl, "?zigstring"))
        return "[*c]const u8";

    // Any opaque.
    if (std.mem.eql(u8, sdl, "*void"))
        return "?*anyopaque";

    // Void.
    if (std.mem.eql(u8, sdl, "void"))
        return "void";

    // Zig int.
    if (std.mem.eql(u8, sdl, "f32") or std.mem.eql(u8, sdl, "i64") or std.mem.eql(u8, sdl, "u5") or std.mem.eql(u8, sdl, "u6") or std.mem.eql(u8, sdl, "u8") or std.mem.eql(u8, sdl, "u31") or std.mem.eql(u8, sdl, "u32") or std.mem.eql(u8, sdl, "u64") or std.mem.eql(u8, sdl, "usize"))
        return sdl;

    // Size pointer.
    if (std.mem.eql(u8, sdl, "*usize"))
        return "*usize";

    // Generics.
    if (generics.get(sdl)) |_|
        return "?*anyopaque";
    if (generics.get(sdl[1..])) |_| // Pointer or whatever
        return "?*anyopaque";

    // SDL type.
    const gotten_sdl_type = sdl_types.get(sdl);
    if (gotten_sdl_type) |val| {
        return switch (val.type_data) {
            .StringMap => "[:0]const u8",
            .Value => |value| try std.mem.replaceOwned(u8, allocator, value.type, "$SDL", "C"),
            else => std.fmt.allocPrint(allocator, "C.{s}", .{sdl}),
        };
    }

    // Idk.
    std.debug.print("Type: {s}\n", .{sdl});
    return error.UnknownSdlToTrueSdlType;
}

fn sdlTypeToZigType(
    allocator: std.mem.Allocator,
    sdl: []const u8,
    sdl_types: std.StringHashMap(SdlData),
    generics: std.StringHashMap(void),
    generics_opaque: bool,
    imports: *std.StringHashMap(void),
    curr_subsystem: []const u8,
) ![]const u8 {

    // String type, is just simply a null-terminated zig string.
    if (std.mem.eql(u8, sdl, "string") or std.mem.eql(u8, sdl, "stringptr"))
        return "[:0]const u8";

    // Optional string type.
    if (std.mem.eql(u8, sdl, "?string") or std.mem.eql(u8, sdl, "??string"))
        return "?[:0]const u8";

    // Zig string type.
    if (std.mem.eql(u8, sdl, "zigstring"))
        return "[]const u8";

    // Optional zig string type.
    if (std.mem.eql(u8, sdl, "?zigstring"))
        return "?[]const u8";

    // Allocator.
    if (std.mem.eql(u8, sdl, "std.mem.Allocator"))
        return sdl;

    // Void.
    if (std.mem.eql(u8, sdl, "*void"))
        return "?*anyopaque";

    // Int.
    if (std.mem.eql(u8, sdl, "int"))
        return "i32";

    // Zig int.
    if (std.mem.eql(u8, sdl, "f32") or std.mem.eql(u8, sdl, "f64") or std.mem.eql(u8, sdl, "i16") or std.mem.eql(u8, sdl, "i64") or std.mem.eql(u8, sdl, "u5") or std.mem.eql(u8, sdl, "u6") or std.mem.eql(u8, sdl, "u7") or std.mem.eql(u8, sdl, "u8") or std.mem.eql(u8, sdl, "u16") or std.mem.eql(u8, sdl, "u31") or std.mem.eql(u8, sdl, "u32") or std.mem.eql(u8, sdl, "u64") or std.mem.eql(u8, sdl, "usize"))
        return sdl;

    // Bool.
    if (std.mem.eql(u8, sdl, "bool"))
        return "bool";

    // Type.
    if (std.mem.eql(u8, sdl, "type"))
        return "type";

    // Generics.
    if (generics.get(sdl) != null or generics.get(sdl[1..]) != null or generics.get(sdl[2..]) != null)
        return if (generics_opaque) "?*anyopaque" else sdl;

    // Go through SDL types.
    const found_sdl_type = sdl_types.get(sdl) orelse sdl_types.get(sdl[1..]);
    if (found_sdl_type) |sdl_type| {
        var ret = switch (sdl_type.type_data) {
            .Callback => |cb| try std.fmt.allocPrint(allocator, "*{s}Data(UserData)", .{cb.func.zigName}),
            .Enum => |en| en.zigType,
            .Value => |val| val.zigName,
            .Flag => |flag| flag.name,
            .StringMap => |map| map.zigName,
            .Struct => |st| st.name,
            .Typedef => |ty| ty.zigName,
        };
        if (!std.mem.eql(u8, sdl_type.subsystem, curr_subsystem)) {
            try imports.put(sdl_type.subsystem, {});
            ret = try std.fmt.allocPrint(allocator, "{s}.{s}", .{ sdl_type.subsystem, ret });
        }
        if (sdl[0] == '?')
            return std.fmt.allocPrint(allocator, "?{s}", .{ret});
        return ret;
    }

    // Slice.
    if (std.mem.startsWith(u8, sdl, "[]")) {
        return std.fmt.allocPrint(allocator, "[]{s}", .{try sdlTypeToZigType(allocator, sdl[2..], sdl_types, generics, generics_opaque, imports, curr_subsystem)});
    }

    // Idk.
    std.debug.print("Type: {s}\n", .{sdl});
    return error.UnknownSdlToZigType;
}

fn convertZigValueToSdl(allocator: std.mem.Allocator, val: []const u8, sdlType: []const u8, sdl_types: std.StringHashMap(SdlData)) ![]const u8 {

    // String type, just return value as it is.
    if (std.mem.eql(u8, sdlType, "string"))
        return val;

    // String type, but we want the pointer this time.
    if (std.mem.eql(u8, sdlType, "stringptr"))
        return std.fmt.allocPrint(allocator, "{s}.ptr", .{val});

    // Optional string type.
    if (std.mem.eql(u8, sdlType, "?string") or std.mem.eql(u8, sdlType, "??string"))
        return std.fmt.allocPrint(allocator, "if ({s}) |str_capture| str_capture.ptr else null", .{val});

    // Int, just cast it.
    if (std.mem.eql(u8, sdlType, "int") or std.mem.eql(u8, sdlType, "i16") or std.mem.eql(u8, sdlType, "i64") or std.mem.eql(u8, sdlType, "u5") or std.mem.eql(u8, sdlType, "u6") or std.mem.eql(u8, sdlType, "u7") or std.mem.eql(u8, sdlType, "u8") or std.mem.eql(u8, sdlType, "u16") or std.mem.eql(u8, sdlType, "u31") or std.mem.eql(u8, sdlType, "u32") or std.mem.eql(u8, sdlType, "u64") or std.mem.eql(u8, sdlType, "usize"))
        return std.fmt.allocPrint(allocator, "@intCast({s})", .{val});

    // Float, just cast it.
    if (std.mem.eql(u8, sdlType, "f32") or std.mem.eql(u8, sdlType, "f64"))
        return std.fmt.allocPrint(allocator, "@floatCast({s})", .{val});

    // Bool.
    if (std.mem.eql(u8, sdlType, "bool"))
        return val;

    // Go through SDL types.
    const found_sdl_type = sdl_types.get(sdlType) orelse sdl_types.get(sdlType[1..]);
    if (found_sdl_type) |sdl_type| {
        const val_to_use = if (sdlType[0] != '?') val else try std.fmt.allocPrint(allocator, "{s}_val", .{val});
        var ret: []const u8 = switch (sdl_type.type_data) {
            .Callback => |cb| cb.name,
            .Enum => try std.fmt.allocPrint(allocator, "@intFromEnum({s})", .{val_to_use}),
            .Value => try std.fmt.allocPrint(allocator, "{s}.value", .{val_to_use}),
            .Flag => try std.fmt.allocPrint(allocator, "{s}.toSdl()", .{val_to_use}),
            .StringMap => try std.fmt.allocPrint(allocator, "{s}.toSdl()", .{val_to_use}),
            .Struct => try std.fmt.allocPrint(allocator, "{s}.toSdl()", .{val_to_use}),
            .Typedef => val,
        };
        if (sdlType[0] == '?') {
            ret = try std.fmt.allocPrint(allocator, "if ({s}) |{s}_val| {s} else null", .{ val, val, ret });
        }
        return ret;
    }

    // Pointer I guess.
    if (std.mem.startsWith(u8, sdlType, "*") or std.mem.startsWith(u8, sdlType, "?*"))
        return val;

    // Idk.
    std.debug.print("Val: {s}, Type: {s}\n", .{ val, sdlType });
    return error.UnknownZigValueToSdlValue;
}

fn convertSdlValueToZig(
    allocator: std.mem.Allocator,
    val: []const u8,
    sdlType: []const u8,
    sdl_types: std.StringHashMap(SdlData),
    convert: []const u8,
    imports: *std.StringHashMap(void),
    curr_subsystem: []const u8,
) ![]const u8 {

    // Custom convert mode.
    if (!std.mem.eql(u8, convert, "null"))
        return convert;

    // If converting from a string, just take a span.
    if (std.mem.eql(u8, sdlType, "string") or std.mem.eql(u8, sdlType, "?string") or std.mem.eql(u8, sdlType, "zigstring"))
        return std.fmt.allocPrint(allocator, "std.mem.span({s})", .{val});

    // Optional zig string, it may be null.
    if (std.mem.eql(u8, sdlType, "??string") or std.mem.eql(u8, sdlType, "?zigstring"))
        return std.fmt.allocPrint(allocator, "if ({s} == null) null else std.mem.span({s})", .{ val, val });

    // Bool, simple enough.
    if (std.mem.eql(u8, sdlType, "bool"))
        return val;

    // Int, just cast it.
    if (std.mem.eql(u8, sdlType, "int") or std.mem.eql(u8, sdlType, "i16") or std.mem.eql(u8, sdlType, "u1") or std.mem.eql(u8, sdlType, "u5") or std.mem.eql(u8, sdlType, "u6") or std.mem.eql(u8, sdlType, "u8") or std.mem.eql(u8, sdlType, "u16") or std.mem.eql(u8, sdlType, "u31") or std.mem.eql(u8, sdlType, "u32") or std.mem.eql(u8, sdlType, "u64") or std.mem.eql(u8, sdlType, "usize"))
        return std.fmt.allocPrint(allocator, "@intCast({s})", .{val});

    // Float, just cast it.
    if (std.mem.eql(u8, sdlType, "f32") or std.mem.eql(u8, sdlType, "f64"))
        return std.fmt.allocPrint(allocator, "@floatCast({s})", .{val});

    // Void pointer idk.
    if (std.mem.eql(u8, sdlType, "*void"))
        return val;

    // Go through SDL types.
    const found_sdl_type = sdl_types.get(sdlType) orelse sdl_types.get(sdlType[1..]);
    if (found_sdl_type) |sdl_type| {
        if (!std.mem.eql(u8, sdl_type.subsystem, curr_subsystem)) {
            try imports.put(sdl_type.subsystem, {});
            return switch (sdl_type.type_data) {
                .Callback => val,
                .Enum => std.fmt.allocPrint(allocator, "@enumFromInt({s})", .{val}),
                .Value => |v| if (v.isOpaque) std.fmt.allocPrint(allocator, "{s}.{s}{{ .value = {s}.? }}", .{ sdl_type.subsystem, v.zigName, val }) else std.fmt.allocPrint(allocator, "{s}.{s}{{ .value = {s} }}", .{ sdl_type.subsystem, v.zigName, val }),
                .Flag => |flag| std.fmt.allocPrint(allocator, "{s}.{s}.fromSdl({s})", .{ sdl_type.subsystem, flag.name, val }),
                .StringMap => |map| std.fmt.allocPrint(allocator, "{s}.{s}.fromSdl({s})", .{ sdl_type.subsystem, map.zigName, val }),
                .Struct => |st| return std.fmt.allocPrint(allocator, "{s}.{s}.fromSdl({s})", .{ sdl_type.subsystem, st.name, val }),
                .Typedef => val,
            };
        }
        return switch (sdl_type.type_data) {
            .Callback => val,
            .Enum => std.fmt.allocPrint(allocator, "@enumFromInt({s})", .{val}),
            .Value => |v| if (v.isOpaque) std.fmt.allocPrint(allocator, "{s}{{ .value = {s}.? }}", .{ v.zigName, val }) else std.fmt.allocPrint(allocator, "{s}{{ .value = {s} }}", .{ v.zigName, val }),
            .Flag => |flag| std.fmt.allocPrint(allocator, "{s}.fromSdl({s})", .{ flag.name, val }),
            .StringMap => |map| std.fmt.allocPrint(allocator, "{s}.fromSdl({s})", .{ map.zigName, val }),
            .Struct => |st| return std.fmt.allocPrint(allocator, "{s}.fromSdl({s})", .{ st.name, val }),
            .Typedef => val,
        };
    }

    // Idk.
    std.debug.print("Val: {s}, Type: {s}\n", .{ val, sdlType });
    return error.UnknownSdlValueToZigValue;
}

fn writeReturnConversions(allocator: std.mem.Allocator, writer: std.io.AnyWriter, func: Function, indent: usize, ret_used: *bool) !bool {
    var converted_ret = false;
    for (func.ret.checks) |check| {

        // Custom method.
        if (std.mem.eql(u8, check.method, "Custom")) {
            try nextLine(writer, indent + 1);
            try writer.writeAll(check.comparisonVal);
            ret_used.* = true;
        }

        // Returns null if SDL value matches comparison value.
        else if (std.mem.eql(u8, check.method, "ReturnNullIfEqStr")) {

            // const converted_ret = std.mem.span(ret);
            // if (std.mem.eql(u8, converted_ret, <comparisonVal>))
            //  return null;
            try nextLine(writer, indent + 1);
            try writer.writeAll("const converted_ret = std.mem.span(ret);");
            try nextLine(writer, indent + 1);
            try writer.print("if (std.mem.eql(u8, converted_ret, {s}))", .{check.comparisonVal});
            try nextLine(writer, indent + 2);
            try writer.writeAll("return null;");
            converted_ret = true;
        }

        // Raw comparison value.
        else if (std.mem.eql(u8, check.method, "ReturnNullIfEq")) {

            // if (ret == <comparisonVal>)
            //  return null;
            try nextLine(writer, indent + 1);
            try writer.print(
                "if (ret == {s})",
                .{try std.mem.replaceOwned(u8, allocator, check.comparisonVal, "$SDL", "C")},
            );
            try nextLine(writer, indent + 2);
            try writer.writeAll("return null;");
            ret_used.* = true;
        }

        // Returns null if SDL value matches comparison value.
        else if (std.mem.eql(u8, check.method, "ReturnErrIfEqStr")) {

            // const converted_ret = std.mem.span(ret);
            // if (std.mem.eql(u8, converted_ret, <comparisonVal>))
            //  return null;
            try nextLine(writer, indent + 1);
            try writer.writeAll("const converted_ret = std.mem.span(ret);");
            try nextLine(writer, indent + 1);
            try writer.print("if (std.mem.eql(u8, converted_ret, {s}))", .{check.comparisonVal});
            try nextLine(writer, indent + 2);
            try writer.writeAll("return error.SdlError;");
            converted_ret = true;
        }

        // Returns error if SDL value matches comparison value.
        else if (std.mem.eql(u8, check.method, "ReturnErrIfEq")) {

            // Comparison type is bool. Self explanatory.
            if (std.mem.eql(u8, func.ret.sdl, "bool")) {

                // if (ret)
                //  return error.SdlError;
                try nextLine(writer, indent + 1);
                if (std.mem.eql(u8, check.comparisonVal, "true")) {
                    try writer.writeAll("if (ret)");
                } else try writer.writeAll("if (!ret)");
                try nextLine(writer, indent + 2);
                try writer.writeAll("return error.SdlError;");
                ret_used.* = true;
            }

            // Just compare raw value.
            else {

                // if (ret == <comparisonVal>)
                //  return error.SdlError;
                try nextLine(writer, indent + 1);
                try writer.print(
                    "if (ret == {s})",
                    .{try std.mem.replaceOwned(u8, allocator, check.comparisonVal, "$SDL", "C")},
                );
                try nextLine(writer, indent + 2);
                try writer.writeAll("return error.SdlError;");
                ret_used.* = true;
            }
        }

        // Not handled.
        else {
            return error.UnknownReturnCheck;
        }
    }
    return converted_ret;
}

fn nextLine(writer: std.io.AnyWriter, indent: usize) !void {
    try writer.writeAll("\n");
    for (0..indent) |_| {
        try writer.writeAll("\t");
    }
}

fn writeEnum(
    allocator: std.mem.Allocator,
    writer: std.io.AnyWriter,
    en: Enum,
    indent: usize,
    sdl_types: std.StringHashMap(SdlData),
    imports: *std.StringHashMap(void),
    curr_subsystem: []const u8,
) !void {

    //
    // /// <comment>
    // pub const <zigType> = enum(<internalType>) {
    try nextLine(writer, 0);
    try nextLine(writer, indent);
    try writer.print("/// {s}", .{en.comment});
    try nextLine(writer, indent);
    try writer.print("pub const {s} = enum({s}) {{", .{ en.zigType, en.internalType });

    // /// <comment>
    // <zigValue> = C.<sdlValue>,
    for (en.values) |val| {

        // Comment only if present.
        if (!std.mem.eql(u8, val.comment, "null")) {
            try nextLine(writer, indent + 1);
            try writer.print("/// {s}", .{val.comment});
        }

        // Write value.
        try nextLine(writer, indent + 1);
        try writer.print("{s} = {s},", .{ val.zigValue, try std.mem.replaceOwned(u8, allocator, val.sdlValue, "$SDL", "C") });
    }

    // <function>
    for (en.functions) |func| {
        try writeFunction(allocator, writer, func, indent + 1, sdl_types, imports, curr_subsystem);
    }

    // };
    try nextLine(writer, indent);
    try writer.writeAll("};");
}

fn writeError(writer: std.io.AnyWriter, err: Error, indent: usize) !void {

    //
    // /// <comment>
    // pub const <name> = error{
    try nextLine(writer, 0);
    try nextLine(writer, indent);
    try writer.print("/// {s}", .{err.comment});
    try nextLine(writer, indent);
    try writer.print("pub const {s} = error{{", .{err.name});

    // <val>,
    for (err.values) |val| {
        try nextLine(writer, indent + 1);
        try writer.print("{s},", .{val});
    }

    // };
    try nextLine(writer, indent);
    try writer.writeAll("};");
}

fn writeValue(
    allocator: std.mem.Allocator,
    writer: std.io.AnyWriter,
    val: Value,
    indent: usize,
    sdl_types: std.StringHashMap(SdlData),
    imports: *std.StringHashMap(void),
    curr_subsystem: []const u8,
) !void {

    //
    // /// <comment>
    // pub const <name> = struct {
    try nextLine(writer, 0);
    try nextLine(writer, indent);
    try writer.print("/// {s}", .{val.comment});
    try nextLine(writer, indent);
    try writer.print("pub const {s} = struct {{", .{val.zigName});

    // value: C.<type>,
    try nextLine(writer, indent + 1);
    if (val.isOpaque) {
        try writer.print("value: *{s},", .{try std.mem.replaceOwned(u8, allocator, val.type, "$SDL", "C")});
    } else try writer.print("value: {s},", .{try std.mem.replaceOwned(u8, allocator, val.type, "$SDL", "C")});

    // /// <comment>
    // pub const <zigValue> = <name> { .value = <sdlValue> };
    for (val.presets) |preset| {
        if (!std.mem.eql(u8, preset.comment, "null")) {
            try nextLine(writer, indent + 1);
            try writer.print("/// {s}", .{preset.comment});
        }
        try nextLine(writer, indent + 1);
        try writer.writeAll(try std.mem.replaceOwned(
            u8,
            allocator,
            try std.fmt.allocPrint(allocator, "pub const {s} = {s}{{ .value = {s} }};", .{ preset.zigValue, val.zigName, preset.sdlValue }),
            "$SDL",
            "C",
        ));
    }

    // <function>
    for (val.functions) |func| {
        try writeFunction(allocator, writer, func, indent + 1, sdl_types, imports, curr_subsystem);
    }
    for (val.customFunctions) |func| {
        try nextLine(writer, 0);
        try nextLine(writer, indent + 1);
        try writer.writeAll(func.code);
    }

    // };
    try nextLine(writer, indent);
    try writer.writeAll("};");
}

fn writeFlag(
    allocator: std.mem.Allocator,
    writer: std.io.AnyWriter,
    flag: Flag,
    indent: usize,
    sdl_types: std.StringHashMap(SdlData),
    imports: *std.StringHashMap(void),
    curr_subsystem: []const u8,
) !void {

    //
    // /// <comment>
    // pub const <name> = struct {
    try nextLine(writer, 0);
    try nextLine(writer, indent);
    try writer.print("/// {s}", .{flag.comment});
    try nextLine(writer, indent);
    try writer.print("pub const {s} = struct {{", .{flag.name});

    // /// <comment>
    // <name>: bool = <value>,
    for (flag.values) |val| {
        if (!std.mem.eql(u8, val.comment, "null")) {
            try nextLine(writer, indent + 1);
            try writer.print("/// {s}", .{val.comment});
        }
        try nextLine(writer, indent + 1);
        try writer.print("{s}: bool", .{val.name});
        if (!std.mem.eql(u8, val.value, "null"))
            try writer.print(" = {s}", .{val.value});
        try writer.writeAll(",");
    }

    // /// <comment>
    // pub const <name> = <type>{
    //  .<name> = <value>,
    // };
    for (flag.presets) |preset| {
        if (!std.mem.eql(u8, preset.comment, "null")) {
            try nextLine(writer, indent + 1);
            try writer.print("/// {s}", .{preset.comment});
        }
        try nextLine(writer, indent + 1);
        try writer.print("pub const {s} = {s}{{", .{ preset.name, flag.name });
        for (preset.values) |val| {
            try nextLine(writer, indent + 2);
            try writer.print(".{s} = {s},", .{ val.name, if (val.value) "true" else "false" });
        }
        try nextLine(writer, indent + 1);
        try writer.writeAll("};");
    }

    // pub fn fromSdl(flags: C.<type>) <name> {
    //  return .{
    //      .<name> = (flags & C.<type>) != 0,
    //  };
    // }
    try nextLine(writer, 0);
    try nextLine(writer, indent + 1);
    try writer.writeAll("/// Convert from an SDL value.");
    try nextLine(writer, indent + 1);
    try writer.print("pub fn fromSdl(flags: C.{s}) {s} {{", .{ flag.type, flag.name });
    try nextLine(writer, indent + 2);
    try writer.writeAll("return .{");
    for (flag.values) |val| {
        try nextLine(writer, indent + 3);
        try writer.print(".{s} = (flags & C.{s}) != 0,", .{ val.name, val.type });
    }
    try nextLine(writer, indent + 2);
    try writer.writeAll("};");
    try nextLine(writer, indent + 1);
    try writer.writeAll("}");

    // pub fn toSdl(self: <name>) <type> {
    //  return
    //      (if (self.<name>) @as(C.<type>, C.<type>) else 0) |
    //      0;
    // }
    try nextLine(writer, 0);
    try nextLine(writer, indent + 1);
    try writer.writeAll("/// Convert to an SDL value.");
    try nextLine(writer, indent + 1);
    try writer.print("pub fn toSdl(self: {s}) C.{s} {{", .{ flag.name, flag.type });
    try nextLine(writer, indent + 2);
    try writer.writeAll("return ");
    for (flag.values, 0..) |val, ind| {
        if (ind != 0)
            try nextLine(writer, indent + 3);
        try writer.print("(if (self.{s}) @as(C.{s}, C.{s}) else 0) |", .{ val.name, flag.type, val.type });
    }
    try nextLine(writer, indent + 3);
    try writer.writeAll("0;");
    try nextLine(writer, indent + 1);
    try writer.writeAll("}");

    // <function>
    for (flag.functions) |func| {
        try writeFunction(allocator, writer, func, indent + 1, sdl_types, imports, curr_subsystem);
    }
    for (flag.customFunctions) |func| {
        try nextLine(writer, 0);
        try nextLine(writer, indent + 1);
        try writer.writeAll(func.code);
    }

    // };
    try nextLine(writer, indent);
    try writer.writeAll("};");
}

fn writeMap(writer: std.io.AnyWriter, map: StringMap, indent: usize) !void {

    //
    // /// <comment>
    // pub const <zigType> = enum {
    try nextLine(writer, 0);
    try nextLine(writer, indent);
    try writer.print("/// {s}", .{map.comment});
    try nextLine(writer, indent);
    try writer.print("pub const {s} = enum {{", .{map.zigName});

    // /// <comment>
    // <zigValue> = C.<sdlValue>,
    for (map.values) |val| {

        // Comment only if present.
        if (!std.mem.eql(u8, val.comment, "null")) {
            try nextLine(writer, indent + 1);
            try writer.print("/// {s}", .{val.comment});
        }

        // Write value.
        try nextLine(writer, indent + 1);
        try writer.print("{s},", .{val.zigValue});
    }

    //
    // /// Convert from an SDL string.
    // pub fn fromSdl(val: [:0]const u8) <name> {
    try nextLine(writer, 0);
    try nextLine(writer, indent + 1);
    try writer.writeAll("/// Convert from an SDL string.");
    try nextLine(writer, indent + 1);
    try writer.print("pub fn fromSdl(val: [:0]const u8) {s} {{", .{map.zigName});

    // if (std.mem.eql(u8, C.<sdl>, val))
    //  return .<name>;
    for (map.values) |val| {
        try nextLine(writer, indent + 2);
        try writer.print("if (std.mem.eql(u8, C.{s}, val))", .{val.sdlValue});
        try nextLine(writer, indent + 3);
        try writer.print("return .{s};", .{val.zigValue});
    }

    // Idk, return first time.
    try nextLine(writer, indent + 2);
    try writer.print("return .{s};", .{map.values[0].zigValue});

    // }
    try nextLine(writer, indent + 1);
    try writer.writeAll("}");

    //
    // /// Convert to an SDL string.
    // pub fn toSdl(self: <zigValue>) [:0]const u8 {
    try nextLine(writer, 0);
    try nextLine(writer, indent + 1);
    try writer.writeAll("/// Convert to an SDL string.");
    try nextLine(writer, indent + 1);
    try writer.print("pub fn toSdl(self: {s}) [:0]const u8 {{", .{map.zigName});

    //  return switch (self) {
    //	    .<zigName> => C.<sdlName>,
    //	};
    try nextLine(writer, indent + 2);
    try writer.writeAll("return switch (self) {");
    for (map.values) |val| {
        try nextLine(writer, indent + 3);
        try writer.print(".{s} => C.{s},", .{ val.zigValue, val.sdlValue });
    }
    try nextLine(writer, indent + 2);
    try writer.writeAll("};");

    // }
    try nextLine(writer, indent + 1);
    try writer.writeAll("}");

    // };
    try nextLine(writer, indent);
    try writer.writeAll("};");
}

fn writeStruct(
    allocator: std.mem.Allocator,
    writer: std.io.AnyWriter,
    st: Struct,
    indent: usize,
    sdl_types: std.StringHashMap(SdlData),
    imports: *std.StringHashMap(void),
    curr_subsystem: []const u8,
) !void {

    //
    // /// <comment>
    // pub const <name> = struct {
    try nextLine(writer, 0);
    try nextLine(writer, indent);
    try writer.print("/// {s}", .{st.comment});
    try nextLine(writer, indent);
    try writer.print("pub const {s} = struct {{", .{st.name});

    // /// <comment>
    // <name>: <type> = <value>,
    const generics = std.StringHashMap(void).init(allocator);
    for (st.members) |member| {

        // Comment only if present.
        if (!std.mem.eql(u8, member.comment, "null")) {
            try nextLine(writer, indent + 1);
            try writer.print("/// {s}", .{member.comment});
        }

        // Write member.
        try nextLine(writer, indent + 1);
        if (!std.mem.eql(u8, member.value, "null")) {
            try writer.print("{s}: {s} = {s},", .{ member.zigName, try sdlTypeToZigType(allocator, member.type, sdl_types, generics, true, imports, curr_subsystem), member.value });
        } else try writer.print("{s}: {s},", .{ member.zigName, try sdlTypeToZigType(allocator, member.type, sdl_types, generics, true, imports, curr_subsystem) });
    }

    // pub fn fromSdl(data: C.<type>) <name> {
    //  return .{
    //      .<name> = <convert data.<name>>,
    //  };
    // }
    try nextLine(writer, 0);
    try nextLine(writer, indent + 1);
    try writer.writeAll("/// Convert from an SDL value.");
    try nextLine(writer, indent + 1);
    try writer.print("pub fn fromSdl(data: C.{s}) {s} {{", .{ st.type, st.name });
    try nextLine(writer, indent + 2);
    try writer.writeAll("return .{");
    for (st.members) |member| {
        try nextLine(writer, indent + 3);
        try writer.print(".{s} = {s},", .{ member.zigName, if (std.mem.eql(u8, member.fromSdlCustom, "null")) try convertSdlValueToZig(
            allocator,
            try std.fmt.allocPrint(allocator, "data.{s}", .{member.sdlName}),
            member.type,
            sdl_types,
            "null",
            imports,
            curr_subsystem,
        ) else member.fromSdlCustom });
    }
    try nextLine(writer, indent + 2);
    try writer.writeAll("};");
    try nextLine(writer, indent + 1);
    try writer.writeAll("}");

    // pub fn toSdl(self: <name>) C.<type> {
    //  return .{
    //      .<name> = <convert self.<name>>,
    //  };
    // }
    try nextLine(writer, 0);
    try nextLine(writer, indent + 1);
    try writer.writeAll("/// Convert to an SDL value.");
    try nextLine(writer, indent + 1);
    try writer.print("pub fn toSdl(self: {s}) C.{s} {{", .{ st.name, st.type });
    try nextLine(writer, indent + 2);
    try writer.writeAll("return .{");
    for (st.members) |member| {
        try nextLine(writer, indent + 3);
        try writer.print(".{s} = {s},", .{ member.sdlName, if (std.mem.eql(u8, member.toSdlCustom, "null")) try convertZigValueToSdl(
            allocator,
            try std.fmt.allocPrint(allocator, "self.{s}", .{member.zigName}),
            member.type,
            sdl_types,
        ) else member.toSdlCustom });
    }
    try nextLine(writer, indent + 2);
    try writer.writeAll("};");
    try nextLine(writer, indent + 1);
    try writer.writeAll("}");

    // Write functions.
    for (st.functions) |func| {
        try writeFunction(allocator, writer, func, indent + 1, sdl_types, imports, curr_subsystem);
    }
    for (st.customFunctions) |func| {
        try nextLine(writer, 0);
        try nextLine(writer, indent + 1);
        try writer.writeAll(func.code);
    }

    // };
    try nextLine(writer, indent);
    try writer.writeAll("};");
}

fn writeCallback(
    allocator: std.mem.Allocator,
    writer: std.io.AnyWriter,
    func: Function,
    indent: usize,
    sdl_types: std.StringHashMap(SdlData),
    imports: *std.StringHashMap(void),
    curr_subsystem: []const u8,
) !void {

    //
    // <comment>
    // pub fn <zigName>(
    try nextLine(writer, 0);
    try nextLine(writer, indent);
    try writer.print("/// {s}", .{func.comment});
    try nextLine(writer, indent);
    try writer.print("pub fn {s}(", .{func.zigName});

    // comptime <name>: type
    var type_cnt: usize = 0;
    var generics = std.StringHashMap(void).init(allocator);
    for (func.arguments) |arg| {
        if (std.mem.eql(u8, arg.type, "type")) {
            try nextLine(writer, indent + 1);
            try writer.print("comptime {s}: type,", .{arg.name});
            try generics.put(arg.name, {});
            type_cnt += 1;
        }
    }
    if (type_cnt > 0)
        try nextLine(writer, indent);

    // ) type {
    try writer.writeAll(") type {");

    //  return *const fn(
    try nextLine(writer, indent + 1);
    try writer.writeAll("return *const fn (");

    // <name>: <type>,
    type_cnt = 0;
    for (func.arguments) |arg| {
        if (!std.mem.eql(u8, arg.type, "type") and std.mem.eql(u8, arg.value, "null")) {
            try nextLine(writer, indent + 2);
            try writer.print("{s}: {s},", .{ arg.name, try sdlTypeToZigType(allocator, arg.type, sdl_types, generics, false, imports, curr_subsystem) });
            type_cnt += 1;
        }
    }
    if (type_cnt > 0)
        try nextLine(writer, indent + 1);

    //  ) <return>;
    // }
    try writer.print(") {s};", .{func.ret.zig});
    try nextLine(writer, indent);
    try writer.writeAll("}");

    //
    // /// <comment>
    // pub fn {s}Data(comptime UserData: type) type {
    //  return struct {
    //      cb: *const fn (
    try nextLine(writer, 0);
    try nextLine(writer, indent);
    try writer.print("/// {s}", .{func.comment});
    try nextLine(writer, indent);
    try writer.print("pub fn {s}Data(comptime UserData: type) type {{", .{func.zigName});
    try nextLine(writer, indent + 1);
    try writer.writeAll("return struct {");
    try nextLine(writer, indent + 2);
    try writer.writeAll("cb: *const fn (");

    // <name: <type>,
    type_cnt = 0;
    for (func.arguments) |arg| {
        if (!std.mem.eql(u8, arg.type, "type") and std.mem.eql(u8, arg.value, "null")) {
            try nextLine(writer, indent + 3);
            try writer.print("{s}: {s},", .{ arg.name, try sdlTypeToZigType(allocator, arg.type, sdl_types, generics, false, imports, curr_subsystem) });
            type_cnt += 1;
        }
    }
    if (type_cnt > 0)
        try nextLine(writer, indent + 2);

    //      ) <ret>,
    //      data: *UserData,
    //  };
    // }
    try writer.print(") {s},", .{func.ret.zig});
    try nextLine(writer, indent + 2);
    try writer.writeAll("data: *UserData,");
    try nextLine(writer, indent + 1);
    try writer.writeAll("};");
    try nextLine(writer, indent);
    try writer.writeAll("}");

    //
    // /// <comment>
    // pub fn <zigName>(
    try nextLine(writer, 0);
    try nextLine(writer, indent);
    try writer.print("/// {s}", .{func.comment});
    try nextLine(writer, indent);
    var c_name = try allocator.alloc(u8, func.zigName.len);
    @memcpy(c_name, func.zigName);
    c_name[0] = std.ascii.toLower(c_name[0]);
    try writer.print("pub fn {s}(", .{c_name});

    // <name>: <type>
    for (func.arguments) |arg| {
        if (!std.mem.eql(u8, arg.type, "type")) {
            try nextLine(writer, indent + 1);
            try writer.print("{s}: {s},", .{ arg.name, try sdlTypeToTrueSdlType(allocator, arg.type, sdl_types, generics) });
        }
    }
    if (func.arguments.len > 0)
        try nextLine(writer, indent);

    // ) callconv(.C) <return> {
    try writer.print(") callconv(.C) {s} {{", .{try sdlTypeToTrueSdlType(allocator, func.ret.sdl, sdl_types, generics)});

    // const cb_data: *<zigName>Data(anyopaque) = @ptrCast(@alignCast(<firstGeneric>));
    var first_generic_type: ?[]const u8 = null;
    var first_generic_type_ptr: []const u8 = undefined;
    var first_generic_name: []const u8 = undefined;
    for (func.arguments) |arg| {
        if (first_generic_type == null and std.mem.eql(u8, arg.type, "type")) {
            first_generic_type = arg.type;
            first_generic_type_ptr = try std.fmt.allocPrint(allocator, "*{s}", .{arg.name});
        } else if (first_generic_type != null and std.mem.eql(u8, arg.type, first_generic_type_ptr)) {
            first_generic_name = arg.name;
            break;
        }
    }
    try nextLine(writer, indent + 1);
    try writer.print("const cb_data: *{s}Data(anyopaque) = @ptrCast(@alignCast({s}));", .{ func.zigName, first_generic_name });

    // const ret = cb_data.cb(
    try nextLine(writer, indent + 1);
    try writer.writeAll("const ret = cb_data.cb(");

    // <argValue>,
    for (func.arguments) |arg| {
        if (!std.mem.eql(u8, arg.type, "type")) {

            // Generic test.
            if (generics.get(arg.type) != null or generics.get(arg.type[1..]) != null) {

                // Is the first generic type.
                if (std.mem.eql(u8, arg.type, first_generic_type_ptr)) {
                    try nextLine(writer, indent + 2);
                    try writer.writeAll("cb_data.data,");
                } else {
                    return error.UnknownSdlValueToZigValue;
                }
            } else {
                if (std.mem.eql(u8, arg.value, "null")) {
                    try nextLine(writer, indent + 2);
                    try writer.print("{s},", .{try convertSdlValueToZig(allocator, arg.name, arg.type, sdl_types, "null", imports, curr_subsystem)});
                }
            }
        }
    }
    if (func.arguments.len > 0)
        try nextLine(writer, indent + 1);

    // );
    try writer.writeAll(");");

    // Write each conversion, depends on type.
    var ret_used = false;
    const converted_ret = try writeReturnConversions(allocator, writer, func, indent, &ret_used);

    // Return if not a void type.
    if (!std.mem.eql(u8, func.ret.zig, "void") and !std.mem.eql(u8, func.ret.zig, "!void")) {

        // return <convert ret>;
        try nextLine(writer, indent + 1);
        if (converted_ret) {
            try writer.writeAll("return converted_ret;");
        } else try writer.print("return {s};", .{
            try convertSdlValueToZig(allocator, "ret", func.ret.sdl, sdl_types, func.ret.convert, imports, curr_subsystem),
        });
        ret_used = true;
    }

    // Discard original value entirely.
    if (!ret_used) {

        // _ = ret;
        try nextLine(writer, indent + 1);
        try writer.writeAll("_ = ret;");
    }

    // }
    try nextLine(writer, indent);
    try writer.writeAll("}");
}

fn writeFunction(
    allocator: std.mem.Allocator,
    writer: std.io.AnyWriter,
    func: Function,
    indent: usize,
    sdl_types: std.StringHashMap(SdlData),
    imports: *std.StringHashMap(void),
    curr_subsystem: []const u8,
) !void {

    //
    // /// <comment>
    // pub fn <zigName>(
    try nextLine(writer, 0);
    try nextLine(writer, indent);
    try writer.print("/// {s}", .{func.comment});
    try nextLine(writer, indent);
    try writer.print("pub fn {s}(", .{func.zigName});

    // <argName>: <argType>,
    var generics = std.StringHashMap(void).init(allocator);
    var num_args: usize = 0;
    for (func.arguments) |arg| {
        if (!std.mem.eql(u8, arg.type, "null") and !std.mem.eql(u8, arg.mode, "out") and !std.mem.eql(u8, arg.mode, "convertSdlConstNullable")) {
            try nextLine(writer, indent + 1);
            if (std.mem.eql(u8, arg.mode, "verbatim")) {
                try writer.print("{s}: {s},", .{ arg.name, arg.type });
            } else try writer.print("{s}: {s},", .{ arg.name, try sdlTypeToZigType(allocator, arg.type, sdl_types, generics, false, imports, curr_subsystem) });
            num_args += 1;
        }
        if (std.mem.eql(u8, arg.type, "type")) {
            try generics.put(arg.name, {});
            num_args += 1;
        } else if (std.mem.eql(u8, arg.mode, "convertSdlConstNullable")) {
            try nextLine(writer, indent + 1);
            try writer.print("{s}: ?{s},", .{ arg.name, try sdlTypeToZigType(allocator, arg.type, sdl_types, generics, false, imports, curr_subsystem) });
        }
    }
    if (num_args > 0)
        try nextLine(writer, indent);

    // ) <retZig> {
    try writer.print(") {s} {{", .{func.ret.zig});

    // var <argName>: <argType> = undefined;
    // const <argName>_sdl: <argType> = <convert(<argName>)>;
    // const <argName>_buf = try <argName>.<argValue>;
    for (func.arguments) |arg| {

        // Pointer is written to.
        if (std.mem.eql(u8, arg.mode, "out")) {
            try nextLine(writer, indent + 1);
            try writer.print("var {s}: {s} = undefined;", .{
                arg.name,
                if (sdl_types.get(arg.type) != null) try std.fmt.allocPrint(allocator, "C.{s}", .{arg.type}) else arg.type,
            });
        }

        // Allocate a buffer.
        else if (std.mem.eql(u8, arg.mode, "allocator")) {
            try nextLine(writer, indent + 1);
            try writer.print("const {s}_buf = try {s}.{s};", .{ arg.name, arg.name, arg.value });
        }

        // Constant pointer.
        if (std.mem.eql(u8, arg.mode, "convertSdlConst")) {
            try nextLine(writer, indent + 1);
            try writer.print("const {s}: {s} = {s};", .{
                try std.fmt.allocPrint(allocator, "{s}_sdl", .{arg.name}),
                if (sdl_types.get(arg.type) != null) try std.fmt.allocPrint(allocator, "C.{s}", .{arg.type}) else arg.type,
                try convertZigValueToSdl(allocator, arg.name, arg.type, sdl_types),
            });
        } else if (std.mem.eql(u8, arg.mode, "convertSdlConstNullable")) {
            try nextLine(writer, indent + 1);
            try writer.print("const {s}: ?{s} = if ({s} == null) null else {s};", .{
                try std.fmt.allocPrint(allocator, "{s}_sdl", .{arg.name}),
                if (sdl_types.get(arg.type) != null) try std.fmt.allocPrint(allocator, "C.{s}", .{arg.type}) else arg.type,
                arg.name,
                try convertZigValueToSdl(allocator, try std.fmt.allocPrint(allocator, "{s}.?", .{arg.name}), arg.type, sdl_types),
            });
        }
    }

    // Return type import.
    if (sdl_types.get(func.ret.sdl)) |val| {
        if (!std.mem.eql(u8, val.subsystem, curr_subsystem))
            try imports.put(val.subsystem, {});
    }

    // const ret = C.<sdlName>(
    try nextLine(writer, indent + 1);
    try writer.print("const ret = C.{s}(", .{func.sdlName});
    var ret_used = false;

    // <argValue>,
    num_args = 0;
    for (func.arguments) |arg| {

        // Skip generic.
        if (std.mem.eql(u8, arg.mode, "generic"))
            continue;

        try nextLine(writer, indent + 2);
        var val = arg.value;

        // Convert constant.
        if (std.mem.eql(u8, arg.mode, "convertSdlConst") and std.mem.eql(u8, arg.value, "null")) {
            val = try std.fmt.allocPrint(allocator, "&{s}_sdl", .{arg.name});
        }

        // Convert constant nullable.
        else if (std.mem.eql(u8, arg.mode, "convertSdlConstNullable") and std.mem.eql(u8, arg.value, "null")) {
            val = try std.fmt.allocPrint(allocator, "if ({s}_sdl == null) null else &({s}_sdl.?)", .{ arg.name, arg.name });
        }

        // Allocator mode.
        else if (std.mem.eql(u8, arg.mode, "allocator")) {
            val = try std.fmt.allocPrint(allocator, "{s}_buf.ptr", .{arg.name});
        }

        // Convert name.
        else if (std.mem.eql(u8, arg.value, "null")) {
            val = try convertZigValueToSdl(allocator, arg.name, arg.type, sdl_types);
        }

        try writer.print("{s},", .{val});
        num_args += 1;

        // Callback mode, pass data.
        if (std.mem.eql(u8, arg.mode, "callback")) {
            try nextLine(writer, indent + 2);
            try writer.print("{s},", .{arg.name});
        }
    }

    // );
    if (num_args > 0)
        try nextLine(writer, indent + 1);
    try writer.writeAll(");");

    // Write each conversion, depends on type.
    const converted_ret = try writeReturnConversions(allocator, writer, func, indent, &ret_used);

    // Return if not a void type.
    if (!std.mem.eql(u8, func.ret.zig, "void") and !std.mem.eql(u8, func.ret.zig, "!void")) {

        // Special case: SDL is void type.
        if (std.mem.eql(u8, func.ret.sdl, "void")) {
            try nextLine(writer, indent + 1);
            try writer.writeAll("_ = ret;");
        }

        // return <convert ret>;
        try nextLine(writer, indent + 1);
        if (converted_ret) {
            try writer.writeAll("return converted_ret;");
        } else try writer.print("return {s};", .{
            try convertSdlValueToZig(allocator, "ret", func.ret.sdl, sdl_types, func.ret.convert, imports, curr_subsystem),
        });
        ret_used = true;
    }

    // Discard original value entirely.
    if (!ret_used) {

        // _ = ret;
        try nextLine(writer, indent + 1);
        try writer.writeAll("_ = ret;");
    }

    // }
    try nextLine(writer, indent);
    try writer.writeAll("}");
}

fn writeTypedef(writer: std.io.AnyWriter, ty: Typedef, indent: usize) !void {

    //
    // /// <comment>
    // pub const <zigName> = <sdlName>;
    try nextLine(writer, 0);
    if (!std.mem.eql(u8, ty.comment, "null")) {
        try nextLine(writer, indent);
        try writer.print("/// {s}", .{ty.comment});
    }
    try nextLine(writer, indent);
    try writer.print("pub const {s} = C.{s};", .{ ty.zigName, ty.sdlName });
}

fn writeTest(allocator: std.mem.Allocator, writer: std.io.AnyWriter, t: Test) !void {
    try nextLine(writer, 0);
    try writer.print(
        \\
        \\// {s}
        \\test "{s}" {{
        \\
    ++ "\t", .{ t.comment, t.name });
    try writer.writeAll(try std.mem.replaceOwned(u8, allocator, t.code[0 .. t.code.len - 1], "\n", "\n\t"));
    try writer.print(
        \\
        \\}}
    , .{});
}

pub fn main() !void {

    // We are using an arena so no freeing is necessary other than freeing the arena itself.
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Load the bindings YAML files.
    var result = Bindings{
        .subsystems = std.ArrayList(Subsystem).init(allocator),
        .files = std.ArrayList(File).init(allocator),
    };
    const subsystems_dir = try std.fs.cwd().openDir("bindings/subsystems", .{ .iterate = true });
    var subsystems_iter = subsystems_dir.iterate();
    while (try subsystems_iter.next()) |subsystem| {
        if (subsystem.kind != .file or !std.mem.endsWith(u8, subsystem.name, ".yaml"))
            continue;
        var untyped = try yaml.Yaml.load(allocator, try subsystems_dir.realpathAlloc(allocator, subsystem.name));
        var parsed = try untyped.parse(SubsystemRaw);
        try result.subsystems.append(parsed.make());
    }
    const files_dir = try std.fs.cwd().openDir("bindings/files", .{ .iterate = true });
    var files_iter = files_dir.iterate();
    while (try files_iter.next()) |file| {
        if (file.kind != .file or !std.mem.endsWith(u8, file.name, ".yaml"))
            continue;
        var untyped = try yaml.Yaml.load(allocator, try subsystems_dir.realpathAlloc(allocator, file.name));
        try result.files.append((try untyped.parse(FileRaw)).make());
    }

    // Sort items.
    std.mem.sort(Subsystem, result.subsystems.items, {}, Subsystem.lessThan);
    std.mem.sort(File, result.files.items, {}, File.lessThan);

    // Fetch SDL types.
    var sdl_types = std.StringHashMap(SdlData).init(allocator);
    for (result.subsystems.items) |subsystem| {
        for (subsystem.callbacks) |cb| {
            var name = try allocator.alloc(u8, cb.zigName.len);
            @memcpy(name, cb.zigName);
            name[0] = std.ascii.toLower(name[0]);
            try sdl_types.put(cb.sdlName, SdlData{ .subsystem = subsystem.name, .type_data = SdlTypeData{ .Callback = .{
                .func = cb,
                .name = name,
            } } });
        }
        for (subsystem.enums) |en| {
            try sdl_types.put(en.sdlType, SdlData{ .subsystem = subsystem.name, .type_data = SdlTypeData{ .Enum = en } });
        }
        for (subsystem.values) |val| {
            try sdl_types.put(val.sdlName, SdlData{ .subsystem = subsystem.name, .type_data = SdlTypeData{ .Value = val } });
        }
        for (subsystem.flags) |flag| {
            try sdl_types.put(flag.type, SdlData{ .subsystem = subsystem.name, .type_data = SdlTypeData{ .Flag = flag } });
        }
        for (subsystem.stringMap) |map| {
            try sdl_types.put(map.sdlName, SdlData{ .subsystem = subsystem.name, .type_data = SdlTypeData{ .StringMap = map } });
        }
        for (subsystem.structs) |st| {
            try sdl_types.put(st.type, SdlData{ .subsystem = subsystem.name, .type_data = SdlTypeData{ .Struct = st } });
        }
        for (subsystem.typedefs) |ty| {
            try sdl_types.put(ty.sdlName, SdlData{ .subsystem = subsystem.name, .type_data = SdlTypeData{ .Typedef = ty } });
        }
    }
    for (result.files.items) |file| {
        for (file.exports) |exp| {
            if (std.mem.eql(u8, exp.kind, "callback")) {
                try sdl_types.put(exp.sdlName, SdlData{ .subsystem = file.name, .type_data = SdlTypeData{ .Callback = .{
                    .func = .{
                        .arguments = &.{},
                        .comment = "null",
                        .ret = .{
                            .sdl = "void",
                            .zig = "void",
                            .checks = &.{},
                            .convert = "null",
                        },
                        .sdlName = exp.sdlName,
                        .zigName = exp.zigName,
                    },
                    .name = exp.zigName,
                } } });
            } else if (std.mem.eql(u8, exp.kind, "enum")) {
                try sdl_types.put(exp.sdlName, SdlData{ .subsystem = file.name, .type_data = SdlTypeData{ .Enum = .{
                    .comment = "null",
                    .functions = &.{},
                    .internalType = exp.extra[0].arg,
                    .sdlType = exp.sdlName,
                    .values = &.{},
                    .zigType = exp.zigName,
                } } });
            } else if (std.mem.eql(u8, exp.kind, "value")) {
                try sdl_types.put(exp.sdlName, SdlData{ .subsystem = file.name, .type_data = SdlTypeData{ .Value = .{
                    .comment = "null",
                    .customFunctions = &.{},
                    .functions = &.{},
                    .isOpaque = std.mem.eql(u8, exp.extra[0].arg, "true"),
                    .presets = &.{},
                    .sdlName = exp.sdlName,
                    .type = "void",
                    .zigName = exp.zigName,
                } } });
            } else if (std.mem.eql(u8, exp.kind, "flag")) {
                try sdl_types.put(exp.sdlName, SdlData{ .subsystem = file.name, .type_data = SdlTypeData{ .Flag = .{
                    .comment = "null",
                    .customFunctions = &.{},
                    .functions = &.{},
                    .name = exp.zigName,
                    .presets = &.{},
                    .type = exp.sdlName,
                    .values = &.{},
                } } });
            } else if (std.mem.eql(u8, exp.kind, "stringMap")) {
                try sdl_types.put(exp.sdlName, SdlData{ .subsystem = file.name, .type_data = SdlTypeData{ .StringMap = .{
                    .comment = "null",
                    .sdlName = exp.sdlName,
                    .values = &.{},
                    .zigName = exp.zigName,
                } } });
            } else if (std.mem.eql(u8, exp.kind, "struct")) {
                try sdl_types.put(exp.sdlName, SdlData{ .subsystem = file.name, .type_data = SdlTypeData{ .Struct = .{
                    .comment = "null",
                    .customFunctions = &.{},
                    .functions = &.{},
                    .members = &.{},
                    .name = exp.zigName,
                    .type = exp.sdlName,
                } } });
            } else if (std.mem.eql(u8, exp.kind, "typedef")) {
                try sdl_types.put(exp.sdlName, SdlData{ .subsystem = file.name, .type_data = SdlTypeData{ .Typedef = .{
                    .sdlName = exp.sdlName,
                    .zigName = exp.zigName,
                    .comment = "null",
                } } });
            }
        }
    }

    // Recreate generated folder.
    std.fs.cwd().deleteTree("src") catch {};
    try std.fs.cwd().makeDir("src");
    const dir = try std.fs.cwd().openDir("src", .{});

    // Open main library file and generate subsystems.
    const sdl_file = try dir.createFile("sdl3.zig", .{ .truncate = true });
    for (result.subsystems.items) |subsystem| {
        const file = try dir.createFile(try std.fmt.allocPrint(
            allocator,
            "{s}.zig",
            .{subsystem.name},
        ), .{ .truncate = true });
        defer file.close();

        // Single name count. Special case to just import the subsystem directly.
        var item_cnt: usize = 0;
        var single_name: []const u8 = undefined;

        // Imports to use.
        var imports = std.StringHashMap(void).init(allocator);

        // Write base data.
        const writer = file.writer().any();
        try writer.writeAll(
            \\// This file was generated using `zig build bindings`. Do not manually edit!
            \\
            \\const C = @import("c.zig").C;
            \\const std = @import("std");
        );
        for (subsystem.callbacks) |cb| {
            try writeCallback(allocator, writer, cb, 0, sdl_types, &imports, subsystem.name);
        }
        for (subsystem.enums) |en| {
            try writeEnum(allocator, writer, en, 0, sdl_types, &imports, subsystem.name);
            if (item_cnt == 0) {
                single_name = en.zigType;
            }
            item_cnt += 1;
        }
        for (subsystem.errors) |err| {
            try writeError(writer, err, 0);
            if (item_cnt == 0) {
                single_name = err.name;
            }
            item_cnt += 1;
        }
        for (subsystem.values) |val| {
            try writeValue(allocator, writer, val, 0, sdl_types, &imports, subsystem.name);
            if (item_cnt == 0) {
                single_name = val.zigName;
            }
            item_cnt += 1;
        }
        for (subsystem.flags) |flag| {
            try writeFlag(allocator, writer, flag, 0, sdl_types, &imports, subsystem.name);
            if (item_cnt == 0) {
                single_name = flag.name;
            }
            item_cnt += 1;
        }
        for (subsystem.stringMap) |map| {
            try writeMap(writer, map, 0);
            if (item_cnt == 0) {
                single_name = map.zigName;
            }
            item_cnt += 1;
        }
        for (subsystem.structs) |st| {
            try writeStruct(allocator, writer, st, 0, sdl_types, &imports, subsystem.name);
            if (item_cnt == 0) {
                single_name = st.name;
            }
            item_cnt += 1;
        }
        for (subsystem.functions) |func| {
            try writeFunction(allocator, writer, func, 0, sdl_types, &imports, subsystem.name);
            if (item_cnt == 0) {
                single_name = func.zigName;
            }
            item_cnt += 1;
        }
        for (subsystem.customFunctions) |func| {
            try nextLine(writer, 0);
            try nextLine(writer, 0);
            try writer.writeAll(func.code);
            item_cnt += 2;
        }
        for (subsystem.typedefs) |typedef| {
            try writeTypedef(writer, typedef, 0);
            if (item_cnt == 0) {
                single_name = typedef.zigName;
            }
            item_cnt += 1;
        }
        for (subsystem.tests) |t| {
            try writeTest(allocator, writer, t);
        }
        try nextLine(writer, 0);

        // Write imports.
        if (imports.count() > 0) {
            var iter = imports.keyIterator();
            while (iter.next()) |import| {
                try nextLine(writer, 0);
                try writer.print("const {s} = @import(\"{s}.zig\");", .{ import.*, import.* });
            }
            try nextLine(writer, 0);
        }

        // Add import to main file.
        if (subsystem.extension) {
            if (item_cnt != 1) {
                try sdl_file.writer().print("pub const {s} = if (extension_options.{s}) @import(\"{s}.zig\") else void;\n", .{ subsystem.name, subsystem.name, subsystem.name });
            } else try sdl_file.writer().print("pub const {s} = if (extension_options.{s}) @import(\"{s}.zig\").{s} else void;\n", .{ single_name, subsystem.name, subsystem.name, single_name });
        } else {
            if (item_cnt != 1) {
                try sdl_file.writer().print("pub const {s} = @import(\"{s}.zig\");\n", .{ subsystem.name, subsystem.name });
            } else try sdl_file.writer().print("pub const {s} = @import(\"{s}.zig\").{s};\n", .{ single_name, subsystem.name, single_name });
        }
    }
    if (result.files.items.len > 0)
        try nextLine(sdl_file.writer().any(), 0);
    for (result.files.items) |file| {
        try (try std.fs.cwd().openDir("bindings/files", .{})).copyFile(
            try std.fmt.allocPrint(allocator, "{s}.zig", .{file.name}),
            try std.fs.cwd().openDir("src", .{}),
            try std.fmt.allocPrint(allocator, "{s}.zig", .{file.name}),
            .{},
        );
        if (file.exports.len != 1) {
            try sdl_file.writer().print("pub const {s} = @import(\"{s}.zig\");\n", .{ file.name, file.name });
        } else try sdl_file.writer().print("pub const {s} = @import(\"{s}.zig\").{s};\n", .{ file.exports[0].zigName, file.name, file.exports[0].zigName });
    }

    // C bindings.
    const c_file = try dir.createFile("c.zig", .{ .truncate = true });
    try c_file.writer().writeAll(
        \\pub const C = @cImport({
        \\    @cInclude("SDL3/SDL.h");
        \\    @cInclude("SDL3_image/SDL_image.h");
        \\});
    );

    // Rest of main file.
    try sdl_file.writer().writeAll(
        \\
        \\pub const C = @import("c.zig").C;
        \\
        \\const extension_options = @import("extension_options");
        \\const std = @import("std");
        \\
        \\/// Whether or not to continue the application or exit with success/failure.
        \\pub const AppResult = enum(c_uint) {
        \\    Continue = C.SDL_APP_CONTINUE,
        \\    Success = C.SDL_APP_SUCCESS,
        \\    Failure = C.SDL_APP_FAILURE,
        \\};
        \\
        \\/// Free memory allocated with SDL. For slices, pass in the pointer.
        \\pub fn free(mem: ?*anyopaque) void {
        \\    C.SDL_free(mem);
        \\}
        \\
        \\test {
        \\    std.testing.refAllDecls(@This());
        \\}
        \\
    );
}
