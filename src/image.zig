// This file was generated using `zig build bindings`. Do not manually edit!

const c = @import("c.zig").c;
const std = @import("std");

/// SDL image version information.
pub const Version = struct {
    value: c_int,
    /// SDL version compiled against.
    pub const compiled_against = Version{ .value = c.SDL_IMAGE_VERSION };

    /// Create an SDL image version number.
    pub fn make(
        major: u32,
        minor: u32,
        micro: u32,
    ) Version {
        const ret = c.SDL_VERSIONNUM(
            @intCast(major),
            @intCast(minor),
            @intCast(micro),
        );
        return Version{ .value = ret };
    }

    /// Major version number.
    pub fn getMajor(
        self: version.Version,
    ) u32 {
        const ret = c.SDL_VERSIONNUM_MAJOR(
            self.value,
        );
        return @intCast(ret);
    }

    /// Minor version number.
    pub fn getMinor(
        self: version.Version,
    ) u32 {
        const ret = c.SDL_VERSIONNUM_MINOR(
            self.value,
        );
        return @intCast(ret);
    }

    /// Micro version number.
    pub fn getMicro(
        self: version.Version,
    ) u32 {
        const ret = c.SDL_VERSIONNUM_MICRO(
            self.value,
        );
        return @intCast(ret);
    }

    /// Check if the SDL image version is at least greater than the given one.
    pub fn atLeast(
        major: u32,
        minor: u32,
        micro: u32,
    ) bool {
        const ret = c.SDL_IMAGE_VERSION_ATLEAST(
            @intCast(major),
            @intCast(minor),
            @intCast(micro),
        );
        return ret;
    }

    /// Get the version of SDL image that is linked against your program. Possibly different than the compiled against version.
    pub fn get() Version {
        const ret = c.IMG_Version();
        return Version{ .value = ret };
    }
};

/// Animated image support.
pub const Animation = struct {
    value: c.IMG_Animation,

    /// Load an animation from a file.
    pub fn init(
        file: [:0]const u8,
    ) !Animation {
        const ret = c.IMG_LoadAnimation(
            file,
        );
        if (ret == null)
            return error.SdlError;
        return Animation{ .value = ret };
    }

    /// Load an animation from an SDL_IOStream.
    pub fn initFromIo(
        source: io_stream.Stream,
        close_when_done: bool,
    ) !Animation {
        const ret = c.IMG_LoadAnimation_IO(
            source.value,
            close_when_done,
        );
        if (ret == null)
            return error.SdlError;
        return Animation{ .value = ret };
    }

    /// Load an animation from an SDL datasource.
    pub fn initFromTypedIo(
        source: io_stream.Stream,
        close_when_done: bool,
        file_type: [:0]const u8,
    ) !Animation {
        const ret = c.IMG_LoadAnimationTyped_IO(
            source.value,
            close_when_done,
            file_type,
        );
        if (ret == null)
            return error.SdlError;
        return Animation{ .value = ret };
    }

    /// Dispose of an IMG_Animation and free its resources.
    pub fn deinit(
        self: Animation,
    ) void {
        const ret = c.IMG_FreeAnimation(
            self.value,
        );
        _ = ret;
    }

    /// Load a GIF animation directly.
    pub fn initFromGifIo(
        source: io_stream.Stream,
    ) !Animation {
        const ret = c.IMG_LoadGIFAnimation_IO(
            source.value,
        );
        if (ret == null)
            return error.SdlError;
        return Animation{ .value = ret };
    }

    /// Load a WEBP animation directly.
    pub fn initFromWebpIo(
        source: io_stream.Stream,
    ) !Animation {
        const ret = c.IMG_LoadWEBPAnimation_IO(
            source.value,
        );
        if (ret == null)
            return error.SdlError;
        return Animation{ .value = ret };
    }

    /// Get the width of an animation.
    pub fn getWidth(self: Animation) usize {
        return @intCast(self.value.w);
    }

    /// Get the height of an animation.
    pub fn getHeight(self: Animation) usize {
        return @intCast(self.value.h);
    }

    /// Get number of frames of an animation.
    pub fn getNumFrames(self: Animation) usize {
        return @intCast(self.value.count);
    }

    /// Get a frame of animation. Returns null if out of bounds.
    pub fn getFrame(self: Animation, index: usize) ?struct { frame: surface.Surface, delay: usize } {
        if (index >= self.getNumFrames())
            return null;
        return .{
            .frame = .{ .value = self.value.frames[index] },
            .delay = @intCast(self.value.delays[index]),
        };
    }
};

/// Load an image from an SDL data source into a software surface.
pub fn loadTypedIo(
    source: io_stream.Stream,
    close_when_done: bool,
    file_type: [:0]const u8,
) !surface.Surface {
    const ret = c.IMG_LoadTyped_IO(
        source.value,
        close_when_done,
        file_type,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load an image from a filesystem path into a software surface.
pub fn loadFile(
    path: [:0]const u8,
) !surface.Surface {
    const ret = c.IMG_Load(
        path,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load an image from an SDL data source into a software surface.
pub fn loadIo(
    source: io_stream.Stream,
    close_when_done: bool,
) !surface.Surface {
    const ret = c.IMG_Load_IO(
        source.value,
        close_when_done,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load an image from a filesystem path into a GPU texture.
pub fn loadTexture(
    renderer: render.Renderer,
    path: [:0]const u8,
) !render.Texture {
    const ret = c.IMG_LoadTexture(
        renderer.value,
        path,
    );
    if (ret == null)
        return error.SdlError;
    return render.Texture{ .value = ret };
}

/// Load an image from an SDL data source into a GPU texture.
pub fn loadTextureIo(
    renderer: render.Renderer,
    source: io_stream.Stream,
    close_when_done: bool,
) !render.Texture {
    const ret = c.IMG_LoadTexture_IO(
        renderer.value,
        source.value,
        close_when_done,
    );
    if (ret == null)
        return error.SdlError;
    return render.Texture{ .value = ret };
}

/// Load an image from an SDL data source into a GPU texture.
pub fn loadTextureTypedIo(
    renderer: render.Renderer,
    source: io_stream.Stream,
    close_when_done: bool,
    file_type: [:0]const u8,
) !render.Texture {
    const ret = c.IMG_LoadTextureTyped_IO(
        renderer.value,
        source.value,
        close_when_done,
        file_type,
    );
    if (ret == null)
        return error.SdlError;
    return render.Texture{ .value = ret };
}

/// Detect AVIF image data on a readable/seekable SDL_IOStream.
pub fn isAvif(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isAVIF(
        source.value,
    );
    return ret;
}

/// Detect ICO image data on a readable/seekable SDL_IOStream.
pub fn isIco(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isICO(
        source.value,
    );
    return ret;
}

/// Detect CUR image data on a readable/seekable SDL_IOStream.
pub fn isCur(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isCUR(
        source.value,
    );
    return ret;
}

/// Detect BMP image data on a readable/seekable SDL_IOStream.
pub fn isBmp(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isBMP(
        source.value,
    );
    return ret;
}

/// Detect GIF image data on a readable/seekable SDL_IOStream.
pub fn isGif(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isGIF(
        source.value,
    );
    return ret;
}

/// Detect JPG image data on a readable/seekable SDL_IOStream.
pub fn isJpg(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isJPG(
        source.value,
    );
    return ret;
}

/// Detect JXL image data on a readable/seekable SDL_IOStream.
pub fn isJxl(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isJXL(
        source.value,
    );
    return ret;
}

/// Detect LBM image data on a readable/seekable SDL_IOStream.
pub fn isLbm(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isLBM(
        source.value,
    );
    return ret;
}

/// Detect PCX image data on a readable/seekable SDL_IOStream.
pub fn isPcx(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isPCX(
        source.value,
    );
    return ret;
}

/// Detect PNG image data on a readable/seekable SDL_IOStream.
pub fn isPng(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isPNG(
        source.value,
    );
    return ret;
}

/// Detect PNM image data on a readable/seekable SDL_IOStream.
pub fn isPnm(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isPNM(
        source.value,
    );
    return ret;
}

/// Detect SVG image data on a readable/seekable SDL_IOStream.
pub fn isSvg(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isSVG(
        source.value,
    );
    return ret;
}

/// Detect QOI image data on a readable/seekable SDL_IOStream.
pub fn isQoi(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isQOI(
        source.value,
    );
    return ret;
}

/// Detect TIF image data on a readable/seekable SDL_IOStream.
pub fn isTif(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isTIF(
        source.value,
    );
    return ret;
}

/// Detect XCF image data on a readable/seekable SDL_IOStream.
pub fn isXcf(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isXCF(
        source.value,
    );
    return ret;
}

/// Detect XPM image data on a readable/seekable SDL_IOStream.
pub fn isXpm(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isXPM(
        source.value,
    );
    return ret;
}

/// Detect XV image data on a readable/seekable SDL_IOStream.
pub fn isXv(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isXV(
        source.value,
    );
    return ret;
}

/// Detect WEBP image data on a readable/seekable SDL_IOStream.
pub fn isWebp(
    source: io_stream.Stream,
) bool {
    const ret = c.IMG_isWEBP(
        source.value,
    );
    return ret;
}

/// Load a AVIF image directly.
pub fn loadAvifIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadAVIF_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a ICO image directly.
pub fn loadIcoIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadICO_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a CUR image directly.
pub fn loadCurIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadCUR_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a BMP image directly.
pub fn loadBmpIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadBMP_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a GIF image directly.
pub fn loadGifIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadGIF_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a JPG image directly.
pub fn loadJpgIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadJPG_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a JXL image directly.
pub fn loadJxlIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadJXL_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a LBM image directly.
pub fn loadLbmIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadLBM_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a PCX image directly.
pub fn loadPcxIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadPCX_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a PNG image directly.
pub fn loadPngIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadPNG_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a PNM image directly.
pub fn loadPnmIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadPNM_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a SVG image directly.
pub fn loadSvgIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadSVG_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a QOI image directly.
pub fn loadQoiIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadQOI_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a TGA image directly.
pub fn loadTgaIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadTGA_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a TIF image directly.
pub fn loadTifIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadTIF_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a XCF image directly.
pub fn loadXcfIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadXCF_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a XPM image directly.
pub fn loadXpmIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadXPM_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a XV image directly.
pub fn loadXvIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadXV_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load a Webp image directly.
pub fn loadWebpIo(
    source: io_stream.Stream,
) !surface.Surface {
    const ret = c.IMG_LoadWebp_IO(
        source.value,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load an SVG image, scaled to a specific size.
pub fn loadSizedSvgIo(
    source: io_stream.Stream,
    width: usize,
    height: usize,
) !surface.Surface {
    const ret = c.IMG_LoadSizedSVG_IO(
        source.value,
        @intCast(width),
        @intCast(height),
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load an XPM image from a memory array.
pub fn readXpmFromArray(
    xpm: [:0][:0]const u8,
) !surface.Surface {
    const ret = c.IMG_ReadXPMFromArray(
        xpm.ptr,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Load an XPM image from a memory array.
pub fn readXpmFromArrayToRgb8888(
    xpm: [:0][:0]const u8,
) !surface.Surface {
    const ret = c.IMG_ReadXPMFromArrayToRGB888(
        xpm.ptr,
    );
    if (ret == null)
        return error.SdlError;
    return surface.Surface{ .value = ret };
}

/// Save an SDL_Surface into a AVIF image file.
pub fn saveAvif(
    source: surface.Surface,
    file: [:0]const u8,
    quality: u7,
) !void {
    const ret = c.IMG_SaveAVIF(
        source.value,
        file,
        @intCast(quality),
    );
    if (!ret)
        return error.SdlError;
}

/// Save an SDL_Surface into AVIF image data, via an SDL_IOStream.
pub fn saveAvifIo(
    source: surface.Surface,
    dst: io_stream.Stream,
    close_when_done: bool,
    quality: u7,
) !void {
    const ret = c.IMG_SaveAVIF_IO(
        source.value,
        dst.value,
        close_when_done,
        @intCast(quality),
    );
    if (!ret)
        return error.SdlError;
}

/// Save an SDL_Surface into a PNG image file.
pub fn savePng(
    source: surface.Surface,
    file: [:0]const u8,
) !void {
    const ret = c.IMG_SavePNG(
        source.value,
        file,
    );
    if (!ret)
        return error.SdlError;
}

/// Save an SDL_Surface into PNG image data, via an SDL_IOStream.
pub fn savePngIo(
    source: surface.Surface,
    dst: io_stream.Stream,
    close_when_done: bool,
) !void {
    const ret = c.IMG_SavePNG_IO(
        source.value,
        dst.value,
        close_when_done,
    );
    if (!ret)
        return error.SdlError;
}

/// Save an SDL_Surface into a JPG image file.
pub fn saveJpg(
    source: surface.Surface,
    file: [:0]const u8,
    quality: u7,
) !void {
    const ret = c.IMG_SaveJPG(
        source.value,
        file,
        @intCast(quality),
    );
    if (!ret)
        return error.SdlError;
}

/// Save an SDL_Surface into JPG image data, via an SDL_IOStream.
pub fn saveJpgIo(
    source: surface.Surface,
    dst: io_stream.Stream,
    close_when_done: bool,
    quality: u7,
) !void {
    const ret = c.IMG_SaveJPG_IO(
        source.value,
        dst.value,
        close_when_done,
        @intCast(quality),
    );
    if (!ret)
        return error.SdlError;
}

const io_stream = @import("io_stream.zig");
const render = @import("render.zig");
const version = @import("version.zig");
const surface = @import("surface.zig");
