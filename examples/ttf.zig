const sdl3 = @import("sdl3");
const std = @import("std");

const screen_width: c_int = 800;
const screen_height: c_int = 600;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    try sdl3.init(.{ .video = true, .events = true });
    defer sdl3.quit(.{ .video = true, .events = true });

    try sdl3.ttf.init();
    defer sdl3.ttf.quit();

    std.log.info("Using SDL_ttf {d}.{d}.{d}", .{ sdl3.ttf.major_version, sdl3.ttf.minor_version, sdl3.ttf.micro_version });
    std.log.info("Linked against SDL_ttf version: {}", .{sdl3.ttf.getVersion()});
    std.debug.assert(sdl3.ttf.versionAtLeast(3, 0, 0));
    const ft_version = sdl3.ttf.getFreeTypeVersion();
    std.log.info("Using FreeType {d}.{d}.{d}", .{ ft_version.major, ft_version.minor, ft_version.patch });
    const hb_version = sdl3.ttf.getHarfBuzzVersion();
    std.log.info("Using HarfBuzz {d}.{d}.{d}", .{ hb_version.major, hb_version.minor, hb_version.patch });
    std.debug.assert(sdl3.ttf.wasInit() > 0);

    const tag = sdl3.ttf.stringToTag("test");
    const tag_str = sdl3.ttf.tagToString(tag);
    std.log.info("Tag 'test' -> {any} -> {s}", .{ tag, &tag_str });

    const window: sdl3.video.Window = try .init("SDL_ttf Example", screen_width, screen_height, .{ .resizable = true });
    defer window.deinit();

    const renderer: sdl3.render.Renderer = try .init(window, null);
    defer renderer.deinit();

    const font_path = "data/font.ttf";
    var font = try sdl3.ttf.Font.init(font_path, 24);
    defer font.deinit();

    std.log.info("Font Family: {s}", .{font.getFamilyName()});
    std.log.info("Font Style: {s}", .{font.getStyleName()});
    std.log.info("Font is fixed width: {}", .{font.isFixedWidth()});
    std.log.info("Font is scalable: {}", .{font.isScalable()});
    std.log.info("Font height: {d}", .{font.getHeight()});
    std.log.info("Font ascent: {d}", .{font.getAscent()});
    std.log.info("Font descent: {d}", .{font.getDescent()});
    std.log.info("Font lineskip: {d}", .{font.getLineSkip()});
    std.log.info("Font faces: {d}", .{font.getNumFaces()});
    std.log.info("Font kerning enabled: {}", .{font.getKerning()});
    std.log.info("Font has glyph 'A': {}", .{font.hasGlyph('A')});
    if (font.getGlyphMetrics('A')) |metrics| {
        std.log.info("Glyph 'A' metrics: minx={d}, maxx={d}, miny={d}, maxy={d}, advance={d}", .{
            metrics.minx, metrics.maxx, metrics.miny, metrics.maxy, metrics.advance,
        });
    } else |err| {
        std.log.warn("Could not get glyph metrics for 'A': {s}", .{@errorName(err)});
    }
    if (font.getGlyphKerning('V', 'A')) |kerning| {
        std.log.info("Kerning for 'VA': {d}", .{kerning});
    } else |err| {
        std.log.warn("Could not get glyph kerning for 'VA': {s}", .{@errorName(err)});
    }

    const white: sdl3.ttf.Color = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
    const yellow: sdl3.ttf.Color = .{ .r = 255, .g = 255, .b = 0, .a = 255 };
    const cyan: sdl3.ttf.Color = .{ .r = 0, .g = 255, .b = 255, .a = 255 };
    const magenta: sdl3.ttf.Color = .{ .r = 255, .g = 0, .b = 255, .a = 255 };

    const solid_texture = try textureFromSurface(renderer, try font.renderTextSolid("Solid Text", white));
    defer solid_texture.deinit();

    const shaded_texture = try textureFromSurface(renderer, try font.renderTextShaded("Shaded Text", yellow, .{ .r = 50, .g = 50, .b = 50, .a = 255 }));
    defer shaded_texture.deinit();

    const blended_texture = try textureFromSurface(renderer, try font.renderTextBlended("Blended Text", cyan));
    defer blended_texture.deinit();

    const wrapped_text = "This is a looooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong text that will be wrapped.";
    const wrapped_texture = try textureFromSurface(renderer, try font.renderTextBlendedWrapped(wrapped_text, magenta, 400));
    defer wrapped_texture.deinit();

    font.setStyle(.{ .bold = true, .italic = true });
    const styled_texture = try textureFromSurface(renderer, try font.renderTextBlended("Bold and Italic", white));
    defer styled_texture.deinit();
    font.setStyle(.{}); // Reset.

    try font.setOutline(2);
    const outlined_texture = try textureFromSurface(renderer, try font.renderTextBlended("Outlined Text", yellow));
    defer outlined_texture.deinit();
    try font.setOutline(0); // Reset.

    const long_text = "This is a very long string that we want to fit into a small space.";
    const max_width = 200;
    const measured = try font.measureString(long_text, max_width);
    const truncated_text = try std.fmt.allocPrint(allocator, "{s}...", .{long_text[0..measured.measured_length]});
    defer allocator.free(truncated_text);
    const truncated_texture = try textureFromSurface(renderer, try font.renderTextBlended(truncated_text, white));
    defer truncated_texture.deinit();

    const text_engine: sdl3.ttf.RendererTextEngine = try .init(renderer);
    defer text_engine.deinit();

    const text_obj: sdl3.ttf.Text = try .init(.{ .value = text_engine.value }, font, "Editable Text Object");
    defer text_obj.deinit();
    try text_obj.setColor(255, 165, 0, 255);
    try text_obj.setPosition(10, 450);

    var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .limited = 60 } };
    var quit_app = false;
    var frame_count: u64 = 0;
    while (!quit_app) {
        const dt = fps_capper.delay();
        _ = dt;

        while (sdl3.events.poll()) |event| {
            switch (event) {
                .quit, .terminating => quit_app = true,
                .key_down => |key| {
                    if (key.scancode == .escape) {
                        quit_app = true;
                    }
                },
                else => {},
            }
        }

        if (frame_count > 0 and frame_count % 60 == 0) {
            if (text_obj.getText().len > 50) {
                try text_obj.setString("Editable Text Object");
            } else {
                try text_obj.appendString(" .");
            }
        }

        // --- Rendering ---
        try renderer.setDrawColor(.{ .r = 20, .g = 20, .b = 40, .a = 255 });
        try renderer.clear();

        var y_pos: f32 = 10;
        const textures_to_render = [_]*const sdl3.render.Texture{
            &solid_texture,
            &shaded_texture,
            &blended_texture,
            &styled_texture,
            &outlined_texture,
            &truncated_texture,
            &wrapped_texture,
        };

        for (textures_to_render) |tex_ptr| {
            const tex = tex_ptr.*;
            const size = try tex.getSize();
            const dst = sdl3.rect.FRect{ .x = 10, .y = y_pos, .w = size.width, .h = size.height };
            try renderer.renderTexture(tex, null, dst);
            y_pos += size.height + 5;
        }

        const text_pos = try text_obj.getPosition();
        try sdl3.ttf.drawRendererText(text_obj, @as(f32, @floatFromInt(text_pos.x)), @as(f32, @floatFromInt(text_pos.y)));

        try renderer.present();

        frame_count += 1;
    }
}

fn textureFromSurface(renderer: sdl3.render.Renderer, surface: sdl3.surface.Surface) !sdl3.render.Texture {
    defer surface.deinit();
    return try renderer.createTextureFromSurface(surface);
}
