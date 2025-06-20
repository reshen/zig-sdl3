const attributes = @import("shaders/attributes.zig");
const constants = @import("shaders/constants.zig");
const sdl3 = @import("sdl3");
const std = @import("std");

pub const Context = struct {
    device: sdl3.gpu.Device,
    window: sdl3.video.Window,
    delta_time: f32 = 0,
    left_pressed: bool = false,
    right_pressed: bool = false,
    down_pressed: bool = false,
    up_pressed: bool = false,
};

pub fn init(example_name: [:0]const u8, window_flags: sdl3.video.WindowFlags) !Context {

    // Get our GPU device that supports SPIR-V.
    const device = try sdl3.gpu.Device.init(.{ .spirv = true }, false, null);
    errdefer device.deinit();

    // Make our demo window.
    const window = try sdl3.video.Window.init(example_name, 640, 480, window_flags);
    errdefer window.deinit();

    // Generate swapchain for window.
    try device.claimWindow(window);
    return .{
        .device = device,
        .window = window,
    };
}

pub fn quit(ctx: Context) void {
    ctx.device.releaseWindow(ctx.window);
    ctx.window.deinit();
    ctx.device.deinit();
}

pub fn loadShader(
    device: sdl3.gpu.Device,
    stage: sdl3.gpu.ShaderStage,
    code: []const u8,
    sampler_count: u32,
    uniform_buffer_count: u32,
    storage_buffer_count: u32,
    storage_texture_count: u32,
) !sdl3.gpu.Shader {
    return device.createShader(.{
        .code = code,
        .entry_point = "main",
        .format = .{ .spirv = true },
        .stage = stage,
        .num_samplers = sampler_count,
        .num_uniform_buffers = uniform_buffer_count,
        .num_storage_buffers = storage_buffer_count,
        .num_storage_textures = storage_texture_count,
        .props = null,
    });
}

/// Buffer for vertex input states.
pub const VertexInputStateBuffer = struct {
    /// Slot to use for the vertex buffer.
    slot: u32 = 0,
    /// CPU type to back the vertex data.
    /// This will be verified to match the byte size of the GPU backing.
    cpu_backing: type,
    /// GPU attributes that when combined recreate the vertex data.
    /// These combined will be verified to match the byte size of the CPU backing.
    vert_shader_name: []const u8,
    /// Input rate to use for the buffer.
    input_rate: sdl3.gpu.VertexInputRate = .vertex,
    /// Instance step rate.
    instance_step_rate: u32 = 0,
};

/// Make vertex buffer descriptions given buffers information.
pub inline fn makeVertexBufferDescriptions(
    comptime buffers: []const VertexInputStateBuffer,
) [buffers.len]sdl3.gpu.VertexBufferDescription {
    comptime {
        var descriptions: [buffers.len]sdl3.gpu.VertexBufferDescription = undefined;
        for (buffers, 0..) |buffer, i| {
            descriptions[i] = makeVertexBufferDescription(buffer);
        }
        return descriptions;
    }
}

/// Make a vertex buffer description from a vertex buffer entry.
/// This will also check to make sure that the buffer types are compatible.
inline fn makeVertexBufferDescription(
    comptime buffer_entry: VertexInputStateBuffer,
) sdl3.gpu.VertexBufferDescription {
    comptime {
        const vertex_attributes = attributes.vertex_buffer_attributes.get(buffer_entry.vert_shader_name).?;
        const cpu_type_info_struct = @typeInfo(buffer_entry.cpu_backing).@"struct";
        if (vertex_attributes.len != cpu_type_info_struct.fields.len)
            @compileError(std.fmt.comptimePrint(
                "GPU \"{s}\" and CPU \"{s}\" vertex buffer structures have differing field lengths",
                .{ buffer_entry.vert_shader_name, @typeName(buffer_entry.cpu_backing) },
            ));
        for (0..vertex_attributes.len) |i| {
            if (vertex_attributes[i].cpuType() != cpu_type_info_struct.fields[i].type)
                @compileError(std.fmt.comptimePrint(
                    "GPU \"{s}\" and CPU \"{s}\" vertex buffer structures have differing field types \"{s}\" and \"{s}\"",
                    .{ buffer_entry.vert_shader_name, @typeName(buffer_entry.cpu_backing), @typeName(vertex_attributes[i].cpuType()), @typeName(cpu_type_info_struct.fields[i].type) },
                ));
        }
        return .{
            .pitch = @sizeOf(buffer_entry.cpu_backing),
            .input_rate = buffer_entry.input_rate,
            .slot = buffer_entry.slot,
            .instance_step_rate = buffer_entry.instance_step_rate,
        };
    }
}

/// Make vertex attributes given buffers information.
pub inline fn makeVertexAttributes(
    comptime buffers: []const VertexInputStateBuffer,
) [countNumAttributes(buffers)]sdl3.gpu.VertexAttribute {
    comptime {
        var ret: [countNumAttributes(buffers)]sdl3.gpu.VertexAttribute = undefined;
        var curr_ind: usize = 0;
        for (buffers) |buffer| {
            const vertex_attributes = attributes.vertex_buffer_attributes.get(buffer.vert_shader_name).?;
            for (vertex_attributes, 0..) |_, ind| {
                ret[curr_ind] = makeVertexAttribute(buffer, ind);
                curr_ind += 1;
            }
        }
        return ret;
    }
}

/// Count the number of attributes for a group of buffers.
inline fn countNumAttributes(
    comptime buffers: []const VertexInputStateBuffer,
) usize {
    comptime {
        var ret: usize = 0;
        for (buffers) |buffer| {
            const vertex_attributes = attributes.vertex_buffer_attributes.get(buffer.vert_shader_name).?;
            for (vertex_attributes) |_| {
                ret += 1;
            }
        }
        return ret;
    }
}

/// Make a vertex attribute from a buffer given the attribute/attribute index. TODO: SUPPORT ATTRIBUTES ACROSS MULTIPLE BUFFERS!!!
inline fn makeVertexAttribute(
    comptime buffer_entry: VertexInputStateBuffer,
    comptime index: usize,
) sdl3.gpu.VertexAttribute {
    comptime {
        const vertex_attributes = attributes.vertex_buffer_attributes.get(buffer_entry.vert_shader_name).?;
        const cpu_type_info_struct = @typeInfo(buffer_entry.cpu_backing).@"struct";
        if (vertex_attributes.len != cpu_type_info_struct.fields.len)
            @compileError(std.fmt.comptimePrint(
                "GPU \"{s}\" and CPU \"{s}\" vertex buffer structures have differing field lengths",
                .{ buffer_entry.vert_shader_name, @typeName(buffer_entry.cpu_backing) },
            ));
        return .{
            .location = vertex_attributes[index].loc,
            .format = getAttributeFormat(vertex_attributes[index]),
            .buffer_slot = buffer_entry.slot,
            .offset = @offsetOf(buffer_entry.cpu_backing, cpu_type_info_struct.fields[index].name),
        };
    }
}

/// Get the SDL attribute format for a GPU attribute type.
inline fn getAttributeFormat(
    comptime attribute: constants.Attribute,
) sdl3.gpu.VertexElementFormat {
    comptime {
        if (attribute.byte_normalize) {
            return switch (attribute.typ) {
                @Vector(4, f32) => .u8x4_normalized,
                else => @compileError(std.fmt.comptimePrint("Unable to get normalized attribute format for {s}", .{@typeName(attribute.typ)})),
            };
        } else {
            return switch (attribute.typ) {
                @Vector(2, f32) => .f32x2,
                @Vector(3, f32) => .f32x3,
                @Vector(4, f32) => .f32x4,
                else => @compileError(std.fmt.comptimePrint("Unable to get attribute format for {s}", .{@typeName(attribute.typ)})),
            };
        }
    }
}
