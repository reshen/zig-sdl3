const attributes = @import("attributes.zig");
const common = @import("common.zig");
const std = @import("std");

/// Get the name of this shader file (without `.zig`).
fn shader_name() []const u8 {
    return @src().file;
}

// Vertex shader variables.
const vars = common.declareVertexShaderVars(shader_name()){};

export fn main() callconv(.spirv_vertex) void {

    // Bind vertex shader variables to the current shader.
    common.bindVertexShaderVars(vars, shader_name());

    // Since we are drawing 1 primitive triangle, the indices 0, 1, and 2 are the only vetices expected.
    switch (vars.vert_in_index.*) {
        0 => {
            vars.vert_out_position.* = .{ -1, -1, 0, 1 };
            vars.vert_out_color.* = .{ 1, 0, 0, 1 };
        },
        1 => {
            vars.vert_out_position.* = .{ 1, -1, 0, 1 };
            vars.vert_out_color.* = .{ 0, 1, 0, 1 };
        },
        else => {
            vars.vert_out_position.* = .{ 0, 1, 0, 1 };
            vars.vert_out_color.* = .{ 0, 0, 1, 1 };
        },
    }
}
