const extension_options = @import("extension_options");

pub const c = @cImport({
    @cInclude("SDL3/SDL.h");
    if (extension_options.main) {
        @cInclude("SDL3/SDL_main.h");
    }
    @cInclude("SDL3/SDL_vulkan.h");
    const ext_image = extension_options.image; // Optional include.
    if (ext_image) {
        @cInclude("SDL3_image/SDL_image.h");
    }
});
