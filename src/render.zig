const c = @import("c.zig").c;
const blend_mode = @import("blend_mode.zig");
const errors = @import("errors.zig");
const events = @import("events.zig");
const pixels = @import("pixels.zig");
const properties = @import("properties.zig");
const rect = @import("rect.zig");
const std = @import("std");
const surface = @import("surface.zig");
const video = @import("video.zig");

/// The size, in pixels, of a single `render.Renderer.renderDebugText()` character.
///
/// ## Remarks
/// The font is monospaced and square, so this applies to all characters.
///
/// ## Version
/// This macro is available since SDL 3.2.0.
pub const debug_text_font_character_size: usize = @intCast(c.SDL_DEBUG_TEXT_FONT_CHARACTER_SIZE);

/// The name of the software renderer.
///
/// ## Version
/// This macro is available since SDL 3.2.0.
pub const software_renderer_name = c.SDL_SOFTWARE_RENDERER;

// GPU render state added in 3.4.0.

// GPU render state description added in 3.4.0.

/// A structure representing rendering state
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const Renderer = struct {
    value: *c.SDL_Renderer,

    /// Add a set of synchronization semaphores for the current frame.
    ///
    /// ## Function Parameters
    /// * `self`: The rendering context.
    /// * `wait_stage_mask`: The `VkPipelineStageFlags` for the wait.
    /// * `wait_semaphore`: A `VkSempahore` to wait on before rendering the current frame, or `null` if not needed.
    /// * `signal_semaphore`: A `VkSempahore` that SDL will signal when rendering for the current frame is complete, or `null` if not needed.
    ///
    /// ## Remarks
    /// The Vulkan renderer will wait for `wait_semaphore` before submitting rendering commands and signal `signal_semaphore` after rendering commands
    /// are complete for this frame.
    ///
    /// This should be called each frame that you want semaphore synchronization.
    /// The Vulkan renderer may have multiple frames in flight on the GPU, so you should have multiple semaphores that are used for synchronization.
    /// Querying `render.Renderer.getProperties().vulkan_swapchain_image_count` will give you the maximum number of semaphores you'll need.
    ///
    /// Thread Safety
    /// It is NOT safe to call this function from two threads at once.
    ///
    /// Version
    /// This function is available since SDL 3.2.0.
    pub fn addVulkanSemaphores(
        self: Renderer,
        wait_stage_mask: u32,
        wait_semaphore: ?i64,
        signal_semaphore: ?i64,
    ) !void {
        const ret = c.SDL_AddVulkanRenderSemaphores(
            self.value,
            wait_stage_mask,
            if (wait_semaphore) |val| val else 0,
            if (signal_semaphore) |val| val else 0,
        );
        return errors.wrapCallBool(ret);
    }

    /// Clear the current rendering target with the drawing color.
    ///
    /// ## Function Parameters
    /// * `self`: The rendering context.
    ///
    /// ## Remarks
    /// This function clears the entire rendering target, ignoring the viewport and the clip rectangle.
    /// Note, that clearing will also set/fill all pixels of the rendering target to current renderer draw color,
    /// so make sure to invoke `render.Renderer.setDrawColor()` when needed.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn clear(
        self: Renderer,
    ) !void {
        const ret = c.SDL_RenderClear(
            self.value,
        );
        return errors.wrapCallBool(ret);
    }

    /// Convert the coordinates in an event to render coordinates.
    ///
    /// ## Function Parameters
    /// * `self`: The rendering context.
    /// * `event`: The event to modify.
    ///
    /// ## Remarks
    /// This takes into account several states:
    /// * The window dimensions.
    /// * The logical presentation settings (`render.Renderer.setLogicalPresentation()`).
    /// * The scale (`render.Renderer.setScale()`).
    /// * The viewport (`render.Renderer.setViewport()`).
    ///
    /// Various event types are converted with this function: mouse, touch, pen, etc.
    ///
    /// Touch coordinates are converted from normalized coordinates in the window to non-normalized rendering coordinates.
    ///
    /// Relative mouse coordinates (`x_rel` and `y_rel` event fields) are also converted.
    /// Applications that do not want these fields converted should use `render.Renderer.coordinatesFromWindow()` on the specific event fields instead of
    /// converting the entire event structure.
    ///
    /// Once converted, coordinates may be outside the rendering area.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn convertEventToRenderCoordinates(
        self: Renderer,
        event: *events.Event,
    ) !void {
        var event_sdl = event.toSdl();
        try errors.wrapCallBool(c.SDL_ConvertEventToRenderCoordinates(self.value, &event_sdl));
        event.* = events.Event.fromSdl(event_sdl);
    }

    // CreateGPURenderer added in 3.4.0.

    // CreateGPURenderState added in 3.4.0.

    /// Create a texture from an existing surface.
    ///
    /// ## Function Parameters
    /// * `self`: The rendering context.
    /// * `surface_to_copy`: Surface containing pixel data used to fill the texture.
    ///
    /// ## Return Value
    /// Returns the created texture.
    ///
    /// ## Remarks
    /// The surface is not modified or freed by this function.
    ///
    /// The `render.TextureAccess` hint for the created texture is `render.TextureAccess.static`.
    ///
    /// The pixel format of the created texture may be different from the pixel format of the surface,
    /// and can be queried using the `render.Texture.getProperties().format` property.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    ///
    /// ## Code Examples
    /// TODO!!!
    pub fn createTextureFromSurface(
        self: Renderer,
        surface_to_copy: surface.Surface,
    ) !Texture {
        const ret = c.SDL_CreateTextureFromSurface(
            self.value,
            surface_to_copy.value,
        );
        return Texture{ .value = try errors.wrapNull(*c.SDL_Texture, ret) };
    }

    // SetGPURenderStateFragmentUniforms for render state is added in 3.4.0.
    // SDL_DestroyGPURenderState is added in 3.4.0.

    /// Destroy the rendering context for a window and free all associated textures.
    ///
    /// ## Function Parameters
    /// * `self`: The rendering context.
    ///
    /// ## Remarks
    /// This should be called before destroying the associated window.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn deinit(
        self: Renderer,
    ) void {
        c.SDL_DestroyRenderer(
            self.value,
        );
    }

    /// Force the rendering context to flush any pending commands and state.
    ///
    /// ## Function Parameters
    /// * `self`: The rendering context.
    ///
    /// ## Remarks
    /// You do not need to (and in fact, shouldn't) call this function unless you are planning to call into OpenGL/Direct3D/Metal/whatever directly,
    /// in addition to using a renderer.
    ///
    /// This is for a very-specific case: if you are using SDL's render API, and you plan to make OpenGL/D3D/whatever calls in addition to SDL render API calls.
    /// If this applies, you should call this function between calls to SDL's render API and the low-level API you're using in cooperation.
    ///
    /// In all other cases, you can ignore this function.
    ///
    /// This call makes SDL flush any pending rendering work it was queueing up to do later in a single batch, and marks any internal cached state as invalid,
    /// so it'll prepare all its state again later, from scratch.
    ///
    /// This means you do not need to save state in your rendering code to protect the SDL renderer.
    /// However, there lots of arbitrary pieces of Direct3D and OpenGL state that can confuse things;
    /// you should use your best judgment and be prepared to make changes if specific state needs to be protected.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn flush(
        self: Renderer,
    ) !void {
        const ret = c.SDL_FlushRenderer(
            self.value,
        );
        return errors.wrapCallBool(ret);
    }

    /// Create a 2D rendering context for a window.
    ///
    /// ## Function Parameters
    /// * `window`: The window where rendering is displayed.
    /// * `renderer_name`: The name of the rendering driver to initialize, or `null` to let SDL choose one.
    ///
    /// ## Return Value
    /// Returns a valid rendering context.
    ///
    /// ## Remarks
    /// If you want a specific renderer, you can specify its name here.
    /// A list of available renderers can be obtained by calling `render.getDriverName()` multiple times, with indices from `0` to `render.getNumDrivers()`.
    /// If you don't need a specific renderer, specify `null` and SDL will attempt to choose the best option for you, based on what is available on the user's system.
    ///
    /// If name is a comma-separated list, SDL will try each name, in the order listed, until one succeeds or all of them fail.
    ///
    /// By default the rendering size matches the window size in pixels,
    /// but you can call `render.Renderer.setLogicalPresentation()` to change the content size and scaling options.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    ///
    /// ## Code Examples
    /// TODO!!!
    pub fn init(
        window: video.Window,
        renderer_name: ?[:0]const u8,
    ) !Renderer {
        const ret = c.SDL_CreateRenderer(
            window.value,
            if (renderer_name) |str_capture| str_capture.ptr else null,
        );
        return Renderer{ .value = try errors.wrapNull(*c.SDL_Renderer, ret) };
    }

    /// Create a 2D software rendering context for a surface.
    ///
    /// ## Function Parameters
    /// * `target_surface`: The surface structure representing the surface where rendering is done.
    ///
    /// ## Return Value
    /// Returns a valid rendering context.
    ///
    /// ## Remarks
    /// Two other API which can be used to create SDL_Renderer: `render.Renderer.init()` and `render.Renderer.initWithWindow()`.
    /// These can also create a software renderer, but they are intended to be used with a `video.Window` as the final destination and not a `surface.Surface`.
    ///
    /// Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// Version
    /// This function is available since SDL 3.2.0.
    ///
    /// ## Code Examples
    /// TODO!!!
    pub fn initSoftwareRenderer(
        target_surface: surface.Surface,
    ) !Renderer {
        const ret = c.SDL_CreateSoftwareRenderer(
            target_surface.value,
        );
        return Renderer{ .value = try errors.wrapNull(*c.SDL_Renderer, ret) };
    }

    /// Create a window and default renderer.
    ///
    /// ## Function Parameters
    /// * `title`: The title of the window, in UTF-8 encoding.
    /// * `width`: The width of the window.
    /// * `height`: The height of the window.
    /// * `window_flags`: The flags used to create the window.
    ///
    /// ## Return Value
    /// Returns the created window and renderer.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    ///
    /// ## Code Examples
    /// TODO!!!
    pub fn initWithWindow(
        title: [:0]const u8,
        width: usize,
        height: usize,
        window_flags: video.WindowFlags,
    ) !struct { window: video.Window, renderer: Renderer } {
        var window: ?*c.SDL_Window = undefined;
        var renderer: ?*c.SDL_Renderer = undefined;
        const ret = c.SDL_CreateWindowAndRenderer(
            title,
            @intCast(width),
            @intCast(height),
            window_flags.toSdl(),
            &window,
            &renderer,
        );
        try errors.wrapCallBool(ret);
        return .{ .window = .{ .value = window.? }, .renderer = .{ .value = renderer.? } };
    }

    /// Update the screen with any rendering performed since the previous call.
    ///
    /// ## Function Parameters
    /// * `self`: The rendering context.
    ///
    /// ## Remarks
    /// SDL's rendering functions operate on a backbuffer; that is
    /// calling a rendering function such as `render.Renderer.renderLine()` does not directly put a line on the screen, but rather updates the backbuffer.
    /// As such, you compose your entire scene and present the composed backbuffer to the screen as a complete picture.
    ///
    /// Therefore, when using SDL's rendering API, one does all drawing intended for the frame,
    /// and then calls this function once per frame to present the final drawing to the user.
    ///
    /// The backbuffer should be considered invalidated after each present; do not assume that previous contents will exist between frames.
    /// You are strongly encouraged to call `render.Renderer.clear()` to initialize the backbuffer before starting each new frame's drawing,
    /// even if you plan to overwrite every pixel.
    ///
    /// Please note, that in case of rendering to a texture - there is no need to call this after drawing needed objects to a texture,
    /// and should not be done; you are only required to change back the rendering target to default via `renderer.Renderer.setTarget(null)` afterwards,
    /// as textures by themselves do not have a concept of backbuffers.
    /// Calling `render.Renderer.present()` while rendering to a texture will fail.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn present(
        self: Renderer,
    ) !void {
        const ret = c.SDL_RenderPresent(
            self.value,
        );
        return errors.wrapCallBool(ret);
    }

    /// Copy a portion of the texture to the current rendering target at subpixel precision.
    ///
    /// ## Function Parameters
    /// * `self`: The renderer which should copy parts of a texture.
    /// * `texture`: The source texture.
    /// * `src_rect`: The source rectangle, or `null` for the entire texture.
    /// * `dst_rect`: The destination rectangle, or `null` for the entire target.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn renderTexture(
        self: Renderer,
        texture: Texture,
        src_rect: ?rect.FRect,
        dst_rect: ?rect.FRect,
    ) !void {
        const src_rect_sdl: c.SDL_FRect = if (src_rect) |val| val.toSdl() else undefined;
        const dst_rect_sdl: c.SDL_FRect = if (dst_rect) |val| val.toSdl() else undefined;
        const ret = c.SDL_RenderTexture(
            self.value,
            texture.value,
            if (src_rect != null) &src_rect_sdl else null,
            if (dst_rect != null) &dst_rect_sdl else null,
        );
        return errors.wrapCallBool(ret);
    }

    /// Set the clip rectangle for rendering on the specified target.
    ///
    /// ## Function Parameters
    /// * `self`: The rendering context.
    /// * `clipping`: A rect structure representing the clip area, relative to the viewport, or `null` to disable clipping.
    ///
    /// ## Remarks
    /// Each render target has its own clip rectangle.
    /// This function sets the cliprect for the current render target.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setClipRect(
        self: Renderer,
        clipping: ?rect.IRect,
    ) !void {
        const clipping_sdl: c.SDL_Rect = if (clipping) |val| val.toSdl() else undefined;
        const ret = c.SDL_SetRenderClipRect(
            self.value,
            if (clipping != null) &clipping_sdl else null,
        );
        return errors.wrapCallBool(ret);
    }

    /// Set the color scale used for render operations.
    ///
    /// ## Function Parameters
    /// * `self`: The rendering context.
    /// * `scale`: The color scale value.
    ///
    /// ## Remarks
    /// The color scale is an additional scale multiplied into the pixel color value while rendering.
    /// This can be used to adjust the brightness of colors during HDR rendering, or changing HDR video brightness when playing on an SDR display.
    ///
    /// The color scale does not affect the alpha channel, only the color brightness.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setColorScale(
        self: Renderer,
        scale: f32,
    ) !void {
        const ret = c.SDL_SetRenderColorScale(
            self.value,
            @floatCast(scale),
        );
        return errors.wrapCallBool(ret);
    }

    // This is added in SDL 3.4.0.
    // /// Set default scale mode for new textures for given renderer.
    // ///
    // /// ## Function Parameters
    // /// * `self`: The renderer to update.
    // /// * `scale_mode`: The scale mode to change to for new textures.
    // ///
    // /// ## Remarks
    // /// When a renderer is created, `scale_mode` defaults to `surface.ScaleMode.linear`.
    // ///
    // /// ## Thread Safety
    // /// This function should only be called on the main thread.
    // ///
    // /// ## Version
    // /// This function is available since SDL 3.4.0.
    // pub fn setDefaultTextureScaleMode(
    //     self: Renderer,
    //     scale_mode: surface.ScaleMode,
    // ) !void {
    //     return errors.wrapCallBool(C.setscalemode)
    // }

    /// Set the blend mode used for drawing operations (Fill and Line).
    ///
    /// ## Function Parameters
    /// * `self`: The rendering context.
    /// * `mode`: The mode to use for blending.
    ///
    /// ## Remarks
    /// If the blend mode is not supported, the closest supported mode is chosen.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setDrawBlendMode(
        self: Renderer,
        mode: ?blend_mode.Mode,
    ) !void {
        const ret = c.SDL_SetRenderDrawBlendMode(
            self.value,
            if (mode) |mode_val| mode_val.value else c.SDL_BLENDMODE_NONE,
        );
        return errors.wrapCallBool(ret);
    }

    /// Set the color used for drawing operations (Rect, Line and Clear).
    ///
    /// ## Function Parameters
    /// * `self`: The rendering context.
    /// * `color`: Color used to draw on the rendering target.
    ///
    /// ## Remarks
    /// Set the color for drawing or filling rectangles, lines, and points, and for `render.Renderer.clear()`.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setDrawColor(
        self: Renderer,
        color: pixels.Color,
    ) !void {
        const ret = c.SDL_SetRenderDrawColor(
            self.value,
            color.r,
            color.g,
            color.b,
            color.a,
        );
        return errors.wrapCallBool(ret);
    }

    /// Set the color used for drawing operations (Rect, Line and Clear).
    ///
    /// ## Function Parameters
    /// * `self`: The rendering context.
    /// * `color`: Color used to draw on the rendering target.
    ///
    /// ## Remarks
    /// Set the color for drawing or filling rectangles, lines, and points, and for `render.Renderer.clear()`.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setDrawColorFloat(
        self: Renderer,
        color: pixels.FColor,
    ) !void {
        const ret = c.SDL_SetRenderDrawColorFloat(
            self.value,
            color.r,
            color.g,
            color.b,
            color.a,
        );
        return errors.wrapCallBool(ret);
    }

    /// Set a device independent resolution and presentation mode for rendering.
    ///
    /// ## Function Parameters
    /// * `self`: The rendering context.
    /// * `width`: The width of the logical resolution.
    /// * `height`: The height of the logical resolution.
    /// * `presentation_mode`: The presentation mode used.
    ///
    /// ## Remarks
    /// This function sets the width and height of the logical rendering output.
    /// The renderer will act as if the current render target is always the requested dimensions, scaling to the actual resolution as necessary.
    ///
    /// This can be useful for games that expect a fixed size, but would like to scale the output to whatever is available, regardless of how a user resizes a window,
    /// or if the display is high DPI.
    ///
    /// Logical presentation can be used with both render target textures and the renderer's window; the state is unique to each render target,
    /// and this function sets the state for the current render target.
    /// It might be useful to draw to a texture that matches the window dimensions with logical presentation enabled,
    /// and then draw that texture across the entire window with logical presentation disabled.
    /// Be careful not to render both with logical presentation enabled, however, as this could produce double-letterboxing, etc.
    ///
    /// You can disable logical coordinates by setting the mode to `null`, and in that case you get the full pixel resolution of the render target;
    /// it is safe to toggle logical presentation during the rendering of a frame: perhaps most of the rendering is done to specific dimensions but to make fonts look sharp,
    /// the app turns off logical presentation while drawing text, for example.
    ///
    /// For the renderer's window, letterboxing is drawn into the framebuffer if logical presentation is enabled during `render.Renderer.present()`;
    /// be sure to reenable it before presenting if you were toggling it,
    /// otherwise the letterbox areas might have artifacts from previous frames (or artifacts from external overlays, etc).
    /// Letterboxing is never drawn into texture render targets; be sure to call `render.Renderer.clear()` before drawing into the texture so the letterboxing areas are cleared,
    /// if appropriate.
    ///
    /// You can convert coordinates in an event into rendering coordinates using `render.Renderer.convertEventToRenderCoordinates()`.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setLogicalPresentation(
        self: Renderer,
        width: usize,
        height: usize,
        presentation_mode: ?LogicalPresentation,
    ) !void {
        const ret = c.SDL_SetRenderLogicalPresentation(
            self.value,
            @intCast(width),
            @intCast(height),
            if (presentation_mode) |val| @intFromEnum(val) else c.SDL_LOGICAL_PRESENTATION_DISABLED,
        );
        return errors.wrapCallBool(ret);
    }

    /// Set the drawing scale for rendering on the current target.
    ///
    /// ## Function Parameters
    /// * `self`: The rendering context.
    /// * `x`: The horizontal scaling factor.
    /// * `y`: The vertical scaling factor.
    ///
    /// ## Remarks
    /// The drawing coordinates are scaled by the x/y scaling factors before they are used by the renderer.
    /// This allows resolution independent drawing with a single coordinate system.
    ///
    /// If this results in scaling or subpixel drawing by the rendering backend, it will be handled using the appropriate quality hints.
    /// For best results use integer scaling factors.
    ///
    /// Each render target has its own scale.
    /// This function sets the scale for the current render target.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setScale(
        self: Renderer,
        x: f32,
        y: f32,
    ) !void {
        const ret = c.SDL_SetRenderScale(
            self.value,
            x,
            y,
        );
        return errors.wrapCallBool(ret);
    }

    /// Set a texture as the current rendering target.
    ///
    /// ## Function Parameters
    /// * `self`: The rendering context.
    /// * `target`: The targeted texture, which must be created with the `render.TextureAccess.target` flag, or `null` to render to the window instead of a texture.
    ///
    /// ## Remarks
    /// The default render target is the window for which the renderer was created.
    /// To stop rendering to a texture and render to the window again, call this function with a `null` texture.
    ///
    /// Viewport, cliprect, scale, and logical presentation are unique to each render target.
    /// Get and set functions for these states apply to the current render target set by this function,
    /// and those states persist on each target when the current render target changes.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setTarget(
        self: Renderer,
        target: ?Texture,
    ) !void {
        const ret = c.SDL_SetRenderTarget(
            self.value,
            if (target) |target_val| target_val.value else null,
        );
        return errors.wrapCallBool(ret);
    }

    // SetRenderTextureAddressMode added in SDL 3.4.0.

    /// Set the drawing area for rendering on the current target.
    ///
    /// ## Function Parameters
    /// * `self`: The rendering context.
    /// * `viewport`: The structure representing the drawing area, or `null` to set the viewport to the entire target.
    ///
    /// ## Remarks
    /// Drawing will clip to this area (separately from any clipping done with `render.Renderer.setClipRect()`),
    /// and the top left of the area will become coordinate `(0, 0)` for future drawing commands.
    ///
    /// The area's width and height must be `>= 0`.
    ///
    /// Each render target has its own viewport. This function sets the viewport for the current render target.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setViewport(
        self: Renderer,
        viewport: ?rect.IRect,
    ) !void {
        const viewport_sdl: c.SDL_Rect = if (viewport) |val| val.toSdl() else undefined;
        const ret = c.SDL_SetRenderViewport(
            self.value,
            if (viewport != null) &viewport_sdl else null,
        );
        return errors.wrapCallBool(ret);
    }

    /// Toggle VSync of the given renderer.
    ///
    /// ## Function Parameters
    /// * `self`: The renderer to toggle.
    /// * `vsync`: The vertical refresh sync interval.
    ///
    /// ## Remarks
    /// When a renderer is created, vsync defaults to `render.Vsync.disabled`.
    ///
    /// Not every value is supported by every driver, so you should check for errors to see whether the requested setting is supported.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setVSync(
        self: Renderer,
        vsync: ?video.VSync,
    ) !void {
        const ret = c.SDL_SetRenderVSync(self.value, video.VSync.toSdl(vsync));
        return errors.wrapCallBool(ret);
    }

    // SetRenderGPUState is added in SDL 3.4.0.

    /// Get the number of 2D rendering drivers available for the current display.
    pub fn numDrivers() usize {
        const ret = c.SDL_GetNumRenderDrivers();
        return @intCast(ret);
    }

    /// Use this function to get the name of a built in 2D rendering driver.
    pub fn getDriverName(
        index: usize,
    ) ?[:0]const u8 {
        const ret = c.SDL_GetRenderDriver(
            @intCast(index),
        );
        if (ret == null)
            return null;
        return std.mem.span(ret);
    }

    /// Create a 2D rendering context for a window, with the specified properties.
    pub fn initWithProperties(
        props: properties.Group,
    ) !Renderer {
        const ret = c.SDL_CreateRendererWithProperties(
            props.value,
        );
        if (ret == null)
            return error.SdlError;
        return Renderer{ .value = ret.? };
    }

    /// Get the renderer associated with a window.
    pub fn getRenderer(
        window: video.Window,
    ) !Renderer {
        const ret = c.SDL_GetRenderer(
            window.value,
        );
        if (ret == null)
            return error.SdlError;
        return Renderer{ .value = ret.? };
    }

    /// Get the window associated with a renderer.
    pub fn getWindow(
        self: Renderer,
    ) !video.Window {
        const ret = c.SDL_GetRenderWindow(
            self.value,
        );
        if (ret == null)
            return error.SdlError;
        return video.Window{ .value = ret.? };
    }

    /// Get the name of a renderer.
    pub fn getName(
        self: Renderer,
    ) ![:0]const u8 {
        const ret = c.SDL_GetRendererName(
            self.value,
        );
        if (ret == null)
            return error.SdlError;
        return std.mem.span(ret);
    }

    /// Get the properties associated with a renderer.
    pub fn getProperties(
        self: Renderer,
    ) !properties.Group {
        const ret = c.SDL_GetRendererProperties(
            self.value,
        );
        if (ret == 0)
            return error.SdlError;
        return properties.Group{ .value = ret };
    }

    /// Get the output size in pixels of a rendering context.
    pub fn getOutputSize(
        self: Renderer,
    ) !struct { width: usize, height: usize } {
        var w: c_int = undefined;
        var h: c_int = undefined;
        const ret = c.SDL_GetRenderOutputSize(
            self.value,
            &w,
            &h,
        );
        if (!ret)
            return error.SdlError;
        return .{ .width = @intCast(w), .height = @intCast(h) };
    }

    /// Get the current output size in pixels of a rendering context.
    pub fn getCurrentOutputSize(
        self: Renderer,
    ) !struct { width: usize, height: usize } {
        var w: c_int = undefined;
        var h: c_int = undefined;
        const ret = c.SDL_GetCurrentRenderOutputSize(
            self.value,
            &w,
            &h,
        );
        if (!ret)
            return error.SdlError;
        return .{ .width = @intCast(w), .height = @intCast(h) };
    }

    /// Create a texture for a rendering context.
    pub fn createTexture(
        self: Renderer,
        format: pixels.Format,
        texture_access: TextureAccess,
        width: usize,
        height: usize,
    ) !Texture {
        const ret = c.SDL_CreateTexture(
            self.value,
            format.value,
            @intFromEnum(texture_access),
            @intCast(width),
            @intCast(height),
        );
        if (ret == null)
            return error.SdlError;
        return Texture{ .value = ret };
    }

    /// Create a texture for a rendering context with the specified properties.
    pub fn createTextureWithProperties(
        self: Renderer,
        props: properties.Group,
    ) !Texture {
        const ret = c.SDL_CreateTextureWithProperties(
            self.value,
            props.value,
        );
        if (ret == null)
            return error.SdlError;
        return Texture{ .value = ret };
    }

    /// Get the current render target.
    pub fn getTarget(
        self: Renderer,
    ) ?Texture {
        const ret = c.SDL_GetRenderTarget(
            self.value,
        );
        if (ret == null)
            return null;
        return Texture{ .value = ret };
    }

    /// Get device independent resolution and presentation mode for rendering.
    pub fn getLogicalPresentation(
        self: Renderer,
    ) !struct { width: usize, height: usize, presentation_mode: ?LogicalPresentation } {
        var w: c_int = undefined;
        var h: c_int = undefined;
        var presentation_mode: c.SDL_RendererLogicalPresentation = undefined;
        const ret = c.SDL_GetRenderLogicalPresentation(
            self.value,
            &w,
            &h,
            &presentation_mode,
        );
        if (!ret)
            return error.SdlError;
        return .{ .width = @intCast(w), .height = @intCast(h), .presentation_mode = if (presentation_mode == c.SDL_LOGICAL_PRESENTATION_DISABLED) null else @enumFromInt(presentation_mode) };
    }

    /// Get the final presentation rectangle for rendering.
    pub fn getLogicalPresentationRect(
        self: Renderer,
    ) !rect.FRect {
        var presentation_rect: c.SDL_FRect = undefined;
        const ret = c.SDL_GetRenderLogicalPresentationRect(
            self.value,
            &presentation_rect,
        );
        if (!ret)
            return error.SdlError;
        return rect.FRect.fromSdl(presentation_rect);
    }

    /// Get a point in render coordinates when given a point in window coordinates.
    pub fn renderCoordinatesFromWindowCoordinates(
        self: Renderer,
        x: f32,
        y: f32,
    ) !struct { x: f32, y: f32 } {
        var render_x: f32 = undefined;
        var render_y: f32 = undefined;
        const ret = c.SDL_RenderCoordinatesFromWindow(
            self.value,
            @floatCast(x),
            @floatCast(y),
            &render_x,
            &render_y,
        );
        if (!ret)
            return error.SdlError;
        return .{ .x = render_x, .y = render_y };
    }

    /// Get a point in window coordinates when given a point in render coordinates.
    pub fn renderCoordinatesToWindowCoordinates(
        self: Renderer,
        x: f32,
        y: f32,
    ) !struct { x: f32, y: f32 } {
        var window_x: f32 = undefined;
        var window_y: f32 = undefined;
        const ret = c.SDL_RenderCoordinatesToWindow(
            self.value,
            @floatCast(x),
            @floatCast(y),
            &window_x,
            &window_y,
        );
        if (!ret)
            return error.SdlError;
        return .{ .x = window_x, .y = window_y };
    }

    /// Get the drawing area for the current target.
    pub fn getViewport(
        self: Renderer,
    ) !rect.IRect {
        var viewport: c.SDL_Rect = undefined;
        const ret = c.SDL_GetRenderViewport(
            self.value,
            &viewport,
        );
        if (!ret)
            return error.SdlError;
        return rect.IRect.fromSdl(viewport);
    }

    /// Return whether an explicit rectangle was set as the viewport.
    pub fn viewportSet(
        self: Renderer,
    ) bool {
        const ret = c.SDL_RenderViewportSet(
            self.value,
        );
        return ret;
    }

    /// Get the safe area for rendering within the current viewport.
    pub fn getSafeArea(
        self: Renderer,
    ) !rect.IRect {
        var area: c.SDL_Rect = undefined;
        const ret = c.SDL_GetRenderSafeArea(
            self.value,
            &area,
        );
        if (!ret)
            return error.SdlError;
        return rect.IRect.fromSdl(area);
    }

    // /// Get the clip rectangle for the current target.
    // pub fn getClipRect(
    //     self: Renderer,
    // ) !?rect.IRect {
    //     var clipping: c.SDL_Rect = undefined;
    //     const ret = c.SDL_GetRenderClipRect(
    //         self.value,
    //         &clipping,
    //     );
    //     if (!ret)
    //         return error.SdlError;
    //     if (clipping.empty())
    //         return null;
    //     return rect.IRect.fromSdl(clipping);
    // }

    /// Get whether clipping is enabled on the given renderer.
    pub fn clipEnabled(
        self: Renderer,
    ) bool {
        const ret = c.SDL_RenderClipEnabled(
            self.value,
        );
        return ret;
    }

    /// Get the drawing scale for the current target.
    pub fn getScale(
        self: Renderer,
    ) !struct { x: f32, y: f32 } {
        var x: f32 = undefined;
        var y: f32 = undefined;
        const ret = c.SDL_GetRenderScale(
            self.value,
            &x,
            &y,
        );
        if (!ret)
            return error.SdlError;
        return .{ .x = x, .y = y };
    }

    /// Get the color used for drawing operations (Rect, Line and Clear).
    pub fn getDrawColor(
        self: Renderer,
    ) !pixels.Color {
        var r: u8 = undefined;
        var g: u8 = undefined;
        var b: u8 = undefined;
        var a: u8 = undefined;
        const ret = c.SDL_GetRenderDrawColor(
            self.value,
            &r,
            &g,
            &b,
            &a,
        );
        if (!ret)
            return error.SdlError;
        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    /// Get the color used for drawing operations (Rect, Line and Clear).
    pub fn getDrawColorFloat(
        self: Renderer,
    ) !pixels.FColor {
        var r: f32 = undefined;
        var g: f32 = undefined;
        var b: f32 = undefined;
        var a: f32 = undefined;
        const ret = c.SDL_GetRenderDrawColorFloat(
            self.value,
            &r,
            &g,
            &b,
            &a,
        );
        if (!ret)
            return error.SdlError;
        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    /// Get the color scale used for render operations.
    pub fn getColorScale(
        self: Renderer,
    ) !f32 {
        var scale: f32 = undefined;
        const ret = c.SDL_GetRenderColorScale(
            self.value,
            &scale,
        );
        if (!ret)
            return error.SdlError;
        return scale;
    }

    /// Get the blend mode used for drawing operations.
    pub fn getDrawBlendMode(
        self: Renderer,
    ) !?blend_mode.Mode {
        var mode: c.SDL_BlendMode = undefined;
        const ret = c.SDL_GetRenderDrawBlendMode(
            self.value,
            &mode,
        );
        if (!ret)
            return error.SdlError;
        if (mode == c.SDL_BLENDMODE_NONE)
            return null;
        return .{ .value = mode };
    }

    /// Draw a point on the current rendering target at subpixel precision.
    pub fn renderPoint(
        self: Renderer,
        p1: rect.FPoint,
    ) !void {
        const ret = c.SDL_RenderPoint(
            self.value,
            p1.x,
            p1.y,
        );
        if (!ret)
            return error.SdlError;
    }

    /// Draw multiple points on the current rendering target at subpixel precision.
    pub fn renderPoints(
        self: Renderer,
        points: []const rect.FPoint,
    ) !void {
        const ret = c.SDL_RenderPoints(
            self.value,
            @ptrCast(points.ptr),
            @intCast(points.len),
        );
        if (!ret)
            return error.SdlError;
    }

    /// Draw a line on the current rendering target at subpixel precision.
    pub fn renderLine(
        self: Renderer,
        p1: rect.FPoint,
        p2: rect.FPoint,
    ) !void {
        const ret = c.SDL_RenderLine(
            self.value,
            p1.x,
            p1.y,
            p2.x,
            p2.y,
        );
        if (!ret)
            return error.SdlError;
    }

    /// Draw a series of connected lines on the current rendering target at subpixel precision.
    pub fn renderLines(
        self: Renderer,
        points: []const rect.FPoint,
    ) !void {
        const ret = c.SDL_RenderLines(
            self.value,
            @ptrCast(points.ptr),
            @intCast(points.len),
        );
        if (!ret)
            return error.SdlError;
    }

    /// Draw a rectangle on the current rendering target at subpixel precision.
    pub fn renderRect(
        self: Renderer,
        dst: ?rect.FRect,
    ) !void {
        const dst_sdl: ?c.SDL_FRect = if (dst == null) null else dst.?.toSdl();
        const ret = c.SDL_RenderRect(
            self.value,
            if (dst_sdl == null) null else &(dst_sdl.?),
        );
        if (!ret)
            return error.SdlError;
    }

    /// Draw some number of rectangles on the current rendering target at subpixel precision.
    pub fn renderRects(
        self: Renderer,
        rects: []const rect.FRect,
    ) !void {
        const ret = c.SDL_RenderRects(
            self.value,
            @ptrCast(rects.ptr),
            @intCast(rects.len),
        );
        if (!ret)
            return error.SdlError;
    }

    /// Fill a rectangle on the current rendering target with the drawing color at subpixel precision.
    pub fn renderFillRect(
        self: Renderer,
        dst: ?rect.FRect,
    ) !void {
        const dst_sdl: ?c.SDL_FRect = if (dst == null) null else dst.?.toSdl();
        const ret = c.SDL_RenderFillRect(
            self.value,
            if (dst_sdl == null) null else &(dst_sdl.?),
        );
        if (!ret)
            return error.SdlError;
    }

    /// Fill some number of rectangles on the current rendering target with the drawing color at subpixel precision.
    pub fn renderFillRects(
        self: Renderer,
        rects: []const rect.FRect,
    ) !void {
        const ret = c.SDL_RenderFillRects(
            self.value,
            @ptrCast(rects.ptr),
            @intCast(rects.len),
        );
        if (!ret)
            return error.SdlError;
    }

    /// Copy a portion of the source texture to the current rendering target, with rotation and flipping, at subpixel precision.
    pub fn renderTextureRotated(
        self: Renderer,
        texture: Texture,
        src_rect: ?rect.FRect,
        dst_rect: ?rect.FRect,
        angle: f64,
        center: ?rect.FPoint,
        flip_mode: ?surface.FlipMode,
    ) !void {
        const src_rect_sdl: ?c.SDL_FRect = if (src_rect == null) null else src_rect.?.toSdl();
        const dst_rect_sdl: ?c.SDL_FRect = if (dst_rect == null) null else dst_rect.?.toSdl();
        const center_sdl: ?c.SDL_FPoint = if (center == null) null else center.?.toSdl();
        const ret = c.SDL_RenderTextureRotated(
            self.value,
            texture.value,
            if (src_rect_sdl == null) null else &(src_rect_sdl.?),
            if (dst_rect_sdl == null) null else &(dst_rect_sdl.?),
            @floatCast(angle),
            if (center_sdl == null) null else &(center_sdl.?),
            if (flip_mode) |val| @intFromEnum(val) else c.SDL_FLIP_NONE,
        );
        if (!ret)
            return error.SdlError;
    }

    /// Tile a portion of the texture to the current rendering target at subpixel precision.
    pub fn renderTextureTiled(
        self: Renderer,
        texture: Texture,
        src_rect: ?rect.FRect,
        scale: f32,
        dst_rect: ?rect.FRect,
    ) !void {
        const src_rect_sdl: ?c.SDL_FRect = if (src_rect == null) null else src_rect.?.toSdl();
        const dst_rect_sdl: ?c.SDL_FRect = if (dst_rect == null) null else dst_rect.?.toSdl();
        const ret = c.SDL_RenderTextureTiled(
            self.value,
            texture.value,
            if (src_rect_sdl == null) null else &(src_rect_sdl.?),
            @floatCast(scale),
            if (dst_rect_sdl == null) null else &(dst_rect_sdl.?),
        );
        if (!ret)
            return error.SdlError;
    }

    /// Perform a scaled copy using the 9-grid algorithm to the current rendering target at subpixel precision.
    pub fn renderTexture9Grid(
        self: Renderer,
        texture: Texture,
        src_rect: ?rect.FRect,
        left_width: f32,
        right_width: f32,
        top_height: f32,
        bottom_height: f32,
        scale: f32,
        dst_rect: ?rect.FRect,
    ) !void {
        const src_rect_sdl: ?c.SDL_FRect = if (src_rect == null) null else src_rect.?.toSdl();
        const dst_rect_sdl: ?c.SDL_FRect = if (dst_rect == null) null else dst_rect.?.toSdl();
        const ret = c.SDL_RenderTexture9Grid(
            self.value,
            texture.value,
            if (src_rect_sdl == null) null else &(src_rect_sdl.?),
            @floatCast(left_width),
            @floatCast(right_width),
            @floatCast(top_height),
            @floatCast(bottom_height),
            @floatCast(scale),
            if (dst_rect_sdl == null) null else &(dst_rect_sdl.?),
        );
        if (!ret)
            return error.SdlError;
    }

    // /// Render a list of triangles, optionally using a texture and indices into the vertex arrays Color and alpha modulation is done per vertex.
    // pub fn renderGeometry(
    //     self: Renderer,
    //     texture: ?Texture,
    //     vertices: [*]const Vertex,
    //     num_vertices: usize,
    //     indices: ?[*]const c_int,
    //     num_indices: usize,
    // ) !void {
    //     const ret = c.SDL_RenderGeometry(
    //         self.value,
    //         if (texture) |texture_val| texture_val.value else null,
    //         vertices,
    //         @intCast(num_vertices),
    //         if (indices) |val| val else null,
    //         @intCast(num_indices),
    //     );
    //     if (!ret)
    //         return error.SdlError;
    // }

    /// Render a list of triangles, optionally using a texture and indices into the vertex arrays Color and alpha modulation is done per vertex.
    pub fn renderGeometryRaw(
        self: Renderer,
        texture: ?Texture,
        xy_positions: [*]const f32,
        xy_positions_stride: usize,
        colors: [*]const pixels.FColor,
        colors_stride: usize,
        uv_coords: [*]const f32,
        uv_coords_stride: usize,
        num_vertices: usize,
        indices: ?*const anyopaque,
        num_indices: usize,
        bytes_per_index: usize,
    ) !void {
        const ret = c.SDL_RenderGeometryRaw(
            self.value,
            if (texture) |texture_val| texture_val.value else null,
            xy_positions,
            @intCast(xy_positions_stride),
            colors,
            @intCast(colors_stride),
            uv_coords,
            @intCast(uv_coords_stride),
            @intCast(num_vertices),
            indices,
            @intCast(num_indices),
            @intCast(bytes_per_index),
        );
        if (!ret)
            return error.SdlError;
    }

    /// Read pixels from the current rendering target.
    pub fn readPixels(
        self: Renderer,
        capture_area: ?rect.IRect,
    ) !surface.Surface {
        const capture_area_sdl: ?c.SDL_Rect = if (capture_area == null) null else capture_area.?.toSdl();
        const ret = c.SDL_RenderReadPixels(
            self.value,
            if (capture_area_sdl == null) null else &(capture_area_sdl.?),
        );
        if (ret == null)
            return error.SdlError;
        return surface.Surface{ .value = ret };
    }

    /// Get the CAMetalLayer associated with the given Metal renderer.
    pub fn getMetalLayer(
        self: Renderer,
    ) ?*anyopaque {
        const ret = c.SDL_GetRenderMetalLayer(
            self.value,
        );
        return ret;
    }

    /// Get the Metal command encoder for the current frame.
    pub fn getMetalCommandEncoder(
        self: Renderer,
    ) ?*anyopaque {
        const ret = c.SDL_GetRenderMetalCommandEncoder(
            self.value,
        );
        return ret;
    }

    // /// Get VSync of the given renderer.
    // pub fn getVSync(
    //     self: Renderer,
    // ) !?VSync {
    //     var vsync: c_int = undefined;
    //     const ret = c.SDL_GetRenderVSync(self.value, &vsync);
    //     if (!ret)
    //         return error.SdlError;
    //     return VSync.fromSdl(vsync);
    // }

};

/// How the logical size is mapped to the output.
///
/// ## Version
/// This enum is available since SDL 3.2.0.
pub const LogicalPresentation = enum(c_uint) {
    /// The rendered content is stretched to the output resolution.
    stretch = c.SDL_LOGICAL_PRESENTATION_STRETCH,
    /// The rendered content is fit to the largest dimension and the other dimension is letterboxed with black bars.
    letter_box = c.SDL_LOGICAL_PRESENTATION_LETTERBOX,
    /// The rendered content is fit to the smallest dimension and the other dimension extends beyond the output bounds.
    overscan = c.SDL_LOGICAL_PRESENTATION_OVERSCAN,
    /// The rendered content is scaled up by integer multiples to fit the output resolution.
    integer_scale = c.SDL_LOGICAL_PRESENTATION_INTEGER_SCALE,

    /// Convert from an SDL.
    pub fn fromSdl(value: c.SDL_RendererLogicalPresentation) ?LogicalPresentation {
        if (value == c.SDL_LOGICAL_PRESENTATION_DISABLED)
            return null;
        return @enumFromInt(value);
    }

    /// Convert to an SDL value.
    pub fn toSdl(self: ?LogicalPresentation) c.SDL_RendererLogicalPresentation {
        if (self) |val|
            return @intFromEnum(val);
        return c.SDL_LOGICAL_PRESENTATION_DISABLED;
    }
};

/// An efficient driver-specific representation of pixel data.
///
/// ## Remarks
/// Note that the reference count will be `1` when initialized, and decremented on each call to `render.Texture.deinit()`.
/// An application is free to increment the reference count when an additional uses is added, just be sure it has a corresponding deinit call.
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const Texture = struct {
    value: *c.SDL_Texture,

    /// Destroy the specified texture.
    ///
    /// ## Function Parameters
    /// * `self`: The texture to destroy.
    ///
    /// ## Remarks
    /// Passing an otherwise invalid texture will set the SDL error message to "Invalid texture".
    ///
    /// This will decrement the reference count of the texture, and only destroy it if the reference count is at 1.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn deinit(
        self: Texture,
    ) void {
        c.SDL_DestroyTexture(self.value);
    }

    /// Get the format of the texture.
    ///
    /// ## Function Parameters
    /// * `self`: The texture.
    ///
    /// ## Return Value
    /// The format of the texture.
    ///
    /// ## Version
    /// This function is provided by zig-sdl3.
    pub fn getFormat(
        self: Texture,
    ) ?pixels.Format {
        return pixels.Format.fromSdl(self.value.format);
    }

    /// Get the height of the texture.
    ///
    /// ## Function Parameters
    /// * `self`: The texture.
    ///
    /// ## Return Value
    /// The height of the texture.
    ///
    /// ## Version
    /// This function is provided by zig-sdl3.
    pub fn getHeight(
        self: Texture,
    ) usize {
        return @intCast(self.value.h);
    }

    /// Get the reference count of the texture.
    ///
    /// ## Function Parameters
    /// * `self`: The texture.
    ///
    /// ## Return Value
    /// The reference count of the texture.
    ///
    /// ## Version
    /// This function is provided by zig-sdl3.
    pub fn getRefCount(
        self: Texture,
    ) usize {
        return @intCast(self.value.refcount);
    }

    /// Get the width of the texture.
    ///
    /// ## Function Parameters
    /// * `self`: The texture.
    ///
    /// ## Return Value
    /// The width of the texture.
    ///
    /// ## Version
    /// This function is provided by zig-sdl3.
    pub fn getWidth(
        self: Texture,
    ) usize {
        return @intCast(self.value.w);
    }

    /// Increment the ref count of the texture.
    ///
    /// ## Function Parameters
    /// * `self`: The texture.
    ///
    /// ## Remarks
    /// All calls to this function must be matched with `render.Texture.deinit()`.
    ///
    /// ## Thread Safety
    /// This function is not thread safe.
    ///
    /// ## Version
    /// This function is provided by zig-sdl3.
    pub fn incrementRefCount(
        self: Texture,
    ) void {
        self.value.refcount += 1;
    }

    /// Create a texture for a rendering context.
    ///
    /// ## Function Parameters
    /// * `renderer`: The rendering context.
    /// * `format`: Pixel format of the texture.
    /// * `access`: Access method for the texture.
    /// * `width`: The width of the texture in pixels.
    /// * `height`: The height of the texture in pixels.
    ///
    /// ## Return Value
    /// Returns the created texture.
    ///
    /// ## Remarks
    /// The contents of a texture when first created are not defined.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    ///
    /// ## Code Examples
    /// TODO!!!
    pub fn init(
        renderer: Renderer,
        format: pixels.Format,
        access: TextureAccess,
        width: usize,
        height: usize,
    ) !Texture {
        return .{ .value = try errors.wrapNull(*c.SDL_Texture, c.SDL_CreateTexture(
            renderer.value,
            pixels.Format.toSdl(format),
            @intFromEnum(access),
            @intCast(width),
            @intCast(height),
        )) };
    }

    /// Lock a portion of the texture for write-only pixel access.
    ///
    /// ## Function Parameters
    /// * `self`: The texture to update.
    /// * `update_area`: The rectangle representing the area to lock for access, or `null` to lock the entire texture.
    ///
    /// ## Return Value
    /// Returns a pointer to the raw pixel data along with the pitch.
    /// The pitch is the length of one row in bytes.
    ///
    /// ## Remarks
    /// The texture must be created to allow streaming access in its `render.AccessMode`.
    /// As an optimization, the pixels made available for editing don't necessarily contain the old texture data.
    /// This is a write-only operation, and if you need to keep a copy of the texture data you should do that at the application level.
    ///
    /// You must use `render.Texture.unlock()` to unlock the pixels and apply any changes.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn lock(
        self: Texture,
        update_area: ?rect.IRect,
    ) !struct { pixels: [*]u8, pitch: usize } {
        const update_area_sdl: c.SDL_Rect = if (update_area) |val| val.toSdl() else undefined;
        var data: ?*anyopaque = undefined;
        var pitch: c_int = undefined;
        const ret = c.SDL_LockTexture(
            self.value,
            if (update_area != null) &update_area_sdl else null,
            &data,
            &pitch,
        );
        try errors.wrapCallBool(ret);
        return .{ .pixels = @ptrCast(@alignCast(data)), .pitch = @intCast(pitch) };
    }

    /// Lock a portion of the texture for write-only pixel access, and expose it as a SDL surface.
    ///
    /// ## Function Parameters
    /// * `self`: The texture to update.
    /// * `update_area`: The rectangle representing the area to lock for access, or `null` to lock the entire texture.
    ///
    /// ## Return Value
    /// Returns an SDL surface of size `update_area`.
    /// Don't assume any specific pixel content.
    ///
    /// ## Remarks
    /// Besides providing a surface instead of raw pixel data, this function operates like `render.Texture.lock()`.
    ///
    /// As an optimization, the pixels made available for editing don't necessarily contain the old texture data.
    /// This is a write-only operation, and if you need to keep a copy of the texture data you should do that at the application level.
    ///
    /// You must use `render.Texture.unlock()` to unlock the pixels and apply any changes.
    ///
    /// The returned surface is freed internally after calling `render.Texture.unlock()` or `render.Texture.deinit()`.
    /// The caller should not free it.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn lockToSurface(
        self: Texture,
        update_area: ?rect.IRect,
    ) !surface.Surface {
        const update_area_sdl: c.SDL_Rect = if (update_area) |val| val.toSdl() else undefined;
        var data: [*c]c.SDL_Surface = undefined;
        const ret = c.SDL_LockTextureToSurface(
            self.value,
            if (update_area != null) &update_area_sdl else null,
            &data,
        );
        try errors.wrapCallBool(ret);
        return .{ .value = data };
    }

    /// Set an additional alpha value multiplied into render copy operations.
    ///
    /// ## Function Parameters
    /// * `self`: The texture to update.
    /// * `alpha`: The source alpha value multiplied into copy operations.
    ///
    /// ## Remarks
    /// When this texture is rendered, during the copy operation the source alpha value is modulated by this alpha value according to the following formula:
    /// `srcC = srcA * (alpha / 255)`
    ///
    /// Alpha modulation is not always supported by the renderer; it will error if alpha modulation is not supported.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setAlphaMod(
        self: Texture,
        alpha: u8,
    ) !void {
        const ret = c.SDL_SetTextureAlphaMod(
            self.value,
            alpha,
        );
        return errors.wrapCallBool(ret);
    }

    /// Set an additional alpha value multiplied into render copy operations.
    ///
    /// ## Function Parameters
    /// * `self`: The texture to update.
    /// * `alpha`: The source alpha value multiplied into copy operations.
    ///
    /// ## Remarks
    /// When this texture is rendered, during the copy operation the source alpha value is modulated by this alpha value according to the following formula:
    /// `srcC = srcA * alpha`
    ///
    /// Alpha modulation is not always supported by the renderer; it will error if alpha modulation is not supported.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setAlphaModFloat(
        self: Texture,
        alpha: f32,
    ) !void {
        const ret = c.SDL_SetTextureAlphaModFloat(
            self.value,
            alpha,
        );
        return errors.wrapCallBool(ret);
    }

    /// Set the blend mode for a texture, used by `renderer.renderTexture`.
    ///
    /// ## Function Parameters
    /// * `self`: The texture to update.
    /// * `blend_mode`: The blend mode to use for texture blending.
    ///
    /// ## Remarks
    /// If the blend mode is not supported, the closest supported mode is chosen and this function returns an error.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setBlendMode(
        self: Texture,
        mode: blend_mode.Mode,
    ) !void {
        const ret = c.SDL_SetTextureBlendMode(
            self.value,
            mode.value,
        );
        return errors.wrapCallBool(ret);
    }

    /// Set an additional color value multiplied into render copy operations.
    ///
    /// ## Function Parameters
    /// * `self`: The texture to update.
    /// * `r`: The red color value multiplied into copy operations.
    /// * `g`: The green color value multiplied into copy operations.
    /// * `b`: The blue color value multiplied into copy operations.
    ///
    /// ## Remarks
    /// When this texture is rendered, during the copy operation each source color channel is modulated by the appropriate color value according to the following formula:
    /// `srcC = srcC * (color / 255)`
    ///
    /// Color modulation is not always supported by the renderer; it will error if color modulation is not supported.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setColorMod(
        self: Texture,
        r: u8,
        g: u8,
        b: u8,
    ) !void {
        const ret = c.SDL_SetTextureColorMod(
            self.value,
            r,
            g,
            b,
        );
        return errors.wrapCallBool(ret);
    }

    /// Set an additional color value multiplied into render copy operations.
    ///
    /// ## Function Parameters
    /// * `self`: The texture to update.
    /// * `r`: The red color value multiplied into copy operations.
    /// * `g`: The green color value multiplied into copy operations.
    /// * `b`: The blue color value multiplied into copy operations.
    ///
    /// ## Remarks
    /// When this texture is rendered, during the copy operation each source color channel is modulated by the appropriate color value according to the following formula:
    /// `srcC = srcC * color`
    ///
    /// Color modulation is not always supported by the renderer; it will error if color modulation is not supported.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setColorModFloat(
        self: Texture,
        r: f32,
        g: f32,
        b: f32,
    ) !void {
        const ret = c.SDL_SetTextureColorModFloat(
            self.value,
            r,
            g,
            b,
        );
        return errors.wrapCallBool(ret);
    }

    /// Set the scale mode used for texture scale operations.
    ///
    /// ## Function Parameters
    /// * `self`: The texture to update.
    /// * `mode`: The mode to use for texture scaling.
    ///
    /// ## Remarks
    /// The default texture scale mode is `surface.ScaleMode.linear`.
    ///
    /// If the scale mode is not supported, the closest supported mode is chosen.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setScaleMode(
        self: Texture,
        mode: surface.ScaleMode,
    ) !void {
        const ret = c.SDL_SetTextureScaleMode(
            self.value,
            @intCast(@intFromEnum(mode)),
        );
        return errors.wrapCallBool(ret);
    }

    /// Unlock a texture, uploading the changes to video memory, if needed.
    ///
    /// ## Function Parameters
    /// * `self`: The locked texture.
    ///
    /// ## Remarks
    /// Warning: Please note that `render.Texture.lock()` is intended to be write-only; it will not guarantee the previous contents of the texture will be provided.
    /// You must fully initialize any area of a texture that you lock before unlocking it, as the pixels might otherwise be uninitialized memory.
    ///
    /// Which is to say: locking and immediately unlocking a texture can result in corrupted textures, depending on the renderer in use.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn unlock(
        self: Texture,
    ) void {
        c.SDL_UnlockTexture(
            self.value,
        );
    }

    /// Update the given texture rectangle with new pixel data.
    ///
    /// ## Function Parameters
    /// * `self`: The texture to update.
    /// * `update_area`: The rectangle of pixels to update, or `null` to update the entire texture.
    /// * `data`: The raw pixel data in the format of the texture.
    /// * `pitch`: The number of bytes in a row of pixel data, including padding between lines.
    ///
    /// ## Remarks
    /// The pixel data must be in the pixel format of the texture, which can be queried using the `format` property.
    ///
    /// This is a fairly slow function, intended for use with static textures that do not change often.
    ///
    /// If the texture is intended to be updated often, it is preferred to create the texture as streaming and use the locking functions referenced below.
    /// While this function will work with streaming textures, for optimization reasons you may not get the pixels back if you lock the texture afterward.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn update(
        self: Texture,
        update_area: ?rect.IRect,
        data: [*]const u8,
        pitch: usize,
    ) !void {
        const update_area_sdl: c.SDL_Rect = if (update_area) |val| val.toSdl() else undefined;
        const ret = c.SDL_UpdateTexture(
            self.value,
            if (update_area != null) &update_area_sdl else null,
            data,
            @intCast(pitch),
        );
        return errors.wrapCallBool(ret);
    }

    /// Update a rectangle within a planar NV12 or NV21 texture with new pixels.
    ///
    /// ## Function Parameters
    /// * `self`: The texture to update.
    /// * `update_area`: The rectangle of pixels to update, or `null` to update the entire texture.
    /// * `y_data`: The raw pixel data for the Y plane.
    /// * `y_pitch`: The number of bytes between rows of pixel data for the Y plane.
    /// * `uv_data`: The raw pixel data for the UV plane.
    /// * `uv_pitch`: The number of bytes between rows of pixel data for the UV plane.
    ///
    /// ## Remarks
    /// You can use `render.Texture.update()` as long as your pixel data is a contiguous block of NV12/21 planes in the proper order,
    /// but this function is available if your pixel data is not contiguous.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn updateNV(
        self: Texture,
        update_area: ?rect.IRect,
        y_data: [*]const u8,
        y_pitch: usize,
        uv_data: [*]const u8,
        uv_pitch: usize,
    ) !void {
        const update_area_sdl: c.SDL_Rect = if (update_area) |val| val.toSdl() else undefined;
        const ret = c.SDL_UpdateNVTexture(
            self.value,
            if (update_area != null) &update_area_sdl else null,
            y_data,
            @intCast(y_pitch),
            uv_data,
            @intCast(uv_pitch),
        );
        return errors.wrapCallBool(ret);
    }

    /// Update a rectangle within a planar YV12 or IYUV texture with new pixel data.
    ///
    /// ## Function Parameters
    /// * `self`: The texture to update.
    /// * `update_area`: The rectangle of pixels to update, or `null` to update the entire texture.
    /// * `y_data`: The raw pixel data for the Y plane.
    /// * `y_pitch`: The number of bytes between rows of pixel data for the Y plane.
    /// * `u_data`: The raw pixel data for the U plane.
    /// * `u_pitch`: The number of bytes between rows of pixel data for the U plane.
    /// * `v_data`: The raw pixel data for the V plane.
    /// * `v_pitch`: The number of bytes between rows of pixel data for the V plane.
    ///
    /// ## Remarks
    /// You can use `render.Texture.update()` as long as your pixel data is a contiguous block of Y and U/V planes in the proper order,
    /// but this function is available if your pixel data is not contiguous.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn updateYUV(
        self: Texture,
        update_area: ?rect.IRect,
        y_data: [*]const u8,
        y_pitch: usize,
        u_data: [*]const u8,
        u_pitch: usize,
        v_data: [*]const u8,
        v_pitch: usize,
    ) !void {
        const update_area_sdl: c.SDL_Rect = if (update_area) |val| val.toSdl() else undefined;
        const ret = c.SDL_UpdateYUVTexture(
            self.value,
            if (update_area != null) &update_area_sdl else null,
            y_data,
            @intCast(y_pitch),
            u_data,
            @intCast(u_pitch),
            v_data,
            @intCast(v_pitch),
        );
        return errors.wrapCallBool(ret);
    }

    /// Get the properties associated with a texture.
    pub fn getProperties(
        self: Texture,
    ) !properties.Group {
        const ret = c.SDL_GetTextureProperties(
            self.value,
        );
        if (ret == 0)
            return error.SdlError;
        return properties.Group{ .value = ret };
    }

    /// Get the renderer that created an SDL_Texture.
    pub fn getRenderer(
        self: Texture,
    ) !Renderer {
        const ret = c.SDL_GetRendererFromTexture(
            self.value,
        );
        if (ret == null)
            return error.SdlError;
        return Renderer{ .value = ret.? };
    }

    /// Get the size of a texture, as floating point values.
    pub fn getSize(
        self: Texture,
    ) !struct { width: f32, height: f32 } {
        var w: f32 = undefined;
        var h: f32 = undefined;
        const ret = c.SDL_GetTextureSize(
            self.value,
            &w,
            &h,
        );
        if (!ret)
            return error.SdlError;
        return .{ .width = @floatCast(w), .height = @floatCast(h) };
    }

    /// Get the additional color value multiplied into render copy operations.
    pub fn getColorMod(
        self: Texture,
    ) !struct { r: u8, g: u8, b: u8 } {
        var r: u8 = undefined;
        var g: u8 = undefined;
        var b: u8 = undefined;
        const ret = c.SDL_GetTextureColorMod(
            self.value,
            &r,
            &g,
            &b,
        );
        if (!ret)
            return error.SdlError;
        return .{ .r = r, .g = g, .b = b };
    }

    /// Get the additional color value multiplied into render copy operations.
    pub fn getColorModFloat(
        self: Texture,
    ) !struct { r: f32, g: f32, b: f32 } {
        var r: f32 = undefined;
        var g: f32 = undefined;
        var b: f32 = undefined;
        const ret = c.SDL_GetTextureColorModFloat(
            self.value,
            &r,
            &g,
            &b,
        );
        if (!ret)
            return error.SdlError;
        return .{ .r = r, .g = g, .b = b };
    }

    /// Get the additional alpha value multiplied into render copy operations.
    pub fn getAlphaMod(
        self: Texture,
    ) !u8 {
        var alpha: u8 = undefined;
        const ret = c.SDL_GetTextureAlphaMod(
            self.value,
            &alpha,
        );
        if (!ret)
            return error.SdlError;
        return alpha;
    }

    /// Get the additional alpha value multiplied into render copy operations.
    pub fn getAlphaModFloat(
        self: Texture,
    ) !f32 {
        var alpha: f32 = undefined;
        const ret = c.SDL_GetTextureAlphaModFloat(
            self.value,
            &alpha,
        );
        if (!ret)
            return error.SdlError;
        return alpha;
    }

    /// Get the blend mode used for texture copy operations.
    pub fn getBlendMode(
        self: Texture,
    ) !?blend_mode.Mode {
        var mode: c.SDL_BlendMode = undefined;
        const ret = c.SDL_GetTextureBlendMode(
            self.value,
            &mode,
        );
        if (!ret)
            return error.SdlError;
        if (mode == c.SDL_BLENDMODE_INVALID)
            return null;
        return .{ .value = mode };
    }

    /// Get the scale mode used for texture scale operations.
    pub fn getScaleMode(
        self: Texture,
    ) !surface.ScaleMode {
        var mode: c.SDL_ScaleMode = undefined;
        const ret = c.SDL_GetTextureScaleMode(
            self.value,
            &mode,
        );
        if (!ret)
            return error.SdlError;
        return @enumFromInt(mode);
    }
};

/// The access pattern allowed for a texture.
///
/// ## Version
/// This enum is available since SDL 3.2.0.
pub const TextureAccess = enum(c_uint) {
    /// Changes rarely, not lockable.
    static = c.SDL_TEXTUREACCESS_STATIC,
    /// Changes frequently, lockable.
    streaming = c.SDL_TEXTUREACCESS_STREAMING,
    /// Texture can be used as a render target.
    target = c.SDL_TEXTUREACCESS_TARGET,
};

// Texture address mode in SDL 3.4.0.

/// Vertex structure.
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const Vertex = extern struct {
    /// Position in SDL renderer coordinates.
    position: rect.FPoint,
    /// Vertex color.
    color: pixels.FColor,
    /// Normalized texture coordinates, if needed.
    tex_coord: rect.FPoint,

    // Size tests.
    comptime {
        errors.assertStructsEqual(c.SDL_Vertex, Vertex);
    }
};

// Render tests.
test "Render" {
    std.testing.refAllDeclsRecursive(@This());
}
