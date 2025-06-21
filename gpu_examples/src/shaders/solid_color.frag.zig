const attributes = @import("attributes.zig");
const common = @import("common.zig");
const std = @import("std");

extern var frag_in_color: attributes.vert_out_frag_in_color.type addrspace(.input);
extern var frag_out_color: attributes.frag_out_color.type addrspace(.output);

comptime {
    std.debug.assert(@TypeOf(frag_in_color) == @TypeOf(frag_out_color));
}

export fn main() callconv(.spirv_fragment) void {

    // Out color still needs to have a location be specified, but should be 0.
    std.gpu.fragmentOrigin(main, .upper_left);
    std.gpu.location(&frag_out_color, attributes.frag_out_color.loc);

    // Import the input color as the pre-selected location (must match with vertex shader).
    std.gpu.location(&frag_in_color, attributes.vert_out_frag_in_color.loc);

    // Simple out = in.
    frag_out_color = frag_in_color;
}
