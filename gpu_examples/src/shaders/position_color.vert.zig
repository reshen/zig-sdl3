const constants = @import("constants.zig");
const std = @import("std");

/// Get the name of this shader file (without `.zig`).
fn shader_name() []const u8 {
    const file_name = @src().file;
    return file_name[0 .. file_name.len - 4];
}

// Vertex shader variables.
const vars = constants.declareVertexShaderVars(shader_name()){};

// Data to output.
extern var vert_out_color: constants.vert_out_frag_in_color.typ addrspace(.output);

export fn main() callconv(.spirv_vertex) void {

    // Setup vertex buffer inputs.
    std.gpu.location(vars.vert_in_position, constants.vert_in_position.loc);
    std.gpu.location(vars.vert_in_color, constants.vert_in_color.loc);

    // Vertex position is built-in.
    std.gpu.position(vars.vert_out_position);

    // Export the color to a pre-selected slot.
    std.gpu.location(&vert_out_color, constants.vert_out_frag_in_color.loc);

    // Just forward the position and color.
    vars.vert_out_position.* = constants.vert_out_position_type{ vars.vert_in_position.*[0], vars.vert_in_position.*[1], vars.vert_in_position.*[2], 1 };
    vert_out_color = vars.vert_in_color.*;
}
