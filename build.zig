const std = @import("std");
const zig = @import("builtin");

const ExampleOptions = struct {
    ext_image: bool,
    ext_net: bool,
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const cfg = std.Build.TestOptions{
        .name = "zig-sdl3",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/sdl3.zig"),
        .version = .{
            .major = 0,
            .minor = 1,
            .patch = 0,
        },
    };

    // C SDL options.
    const c_sdl_preferred_linkage = b.option(
        std.builtin.LinkMode,
        "c_sdl_preferred_linkage",
        "Prefer building statically or dynamically linked libraries (default: static)",
    ) orelse .static;
    const c_sdl_strip = b.option(
        bool,
        "c_sdl_strip",
        "Strip debug symbols (default: varies)",
    ) orelse (optimize == .ReleaseSmall);
    const c_sdl_sanitize_c = b.option(
        enum { off, trap, full }, // TODO: Change to std.zig.SanitizeC after 0.15
        "c_sdl_sanitize_c",
        "Detect C undefined behavior (default: trap)",
    ) orelse .trap;
    const c_sdl_lto = b.option(
        enum { none, full, thin }, // TODO: Change to std.zig.LtoMode after 0.15
        "c_sdl_lto",
        "Perform link time optimization (default: false)",
    ) orelse .none;
    const c_sdl_emscripten_pthreads = b.option(
        bool,
        "c_sdl_emscripten_pthreads",
        "Build with pthreads support when targeting Emscripten (default: false)",
    ) orelse false;
    const c_sdl_install_build_config_h = b.option(
        bool,
        "c_sdl_install_build_config_h",
        "Additionally install 'SDL_build_config.h' when installing SDL (default: false)",
    ) orelse false;

    const sdl_dep = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
        .preferred_linkage = c_sdl_preferred_linkage,
        .strip = c_sdl_strip,
        .sanitize_c = c_sdl_sanitize_c,
        .lto = c_sdl_lto,
        .emscripten_pthreads = c_sdl_emscripten_pthreads,
        .install_build_config_h = c_sdl_install_build_config_h,
    });

    const sdl_dep_lib = sdl_dep.artifact("SDL3");

    const sdl3 = b.addModule("sdl3", .{
        .root_source_file = cfg.root_source_file,
        .target = target,
        .optimize = optimize,
    });

    // SDL options.
    const extension_options = b.addOptions();
    const main_callbacks = b.option(bool, "callbacks", "Enable SDL callbacks rather than use a main function") orelse false;
    extension_options.addOption(bool, "callbacks", main_callbacks);
    const sdl3_main = b.option(bool, "main", "Enable SDL main") orelse false;
    extension_options.addOption(bool, "main", sdl3_main);
    const ext_image = b.option(bool, "ext_image", "Enable SDL_image extension") orelse false;
    extension_options.addOption(bool, "image", ext_image);
    const ext_net = b.option(bool, "ext_net", "Enable SDL_net extension") orelse false;
    extension_options.addOption(bool, "net", ext_net);

    // Linking zig-sdl to sdl3, makes the library much easier to use.
    sdl3.addOptions("extension_options", extension_options);
    sdl3.linkLibrary(sdl_dep_lib);
    if (ext_image) {
        setupSdlImage(b, sdl3, sdl_dep_lib, c_sdl_preferred_linkage, cfg);
    }
    if (ext_net) {
        setupSdlNet(b, sdl3, sdl_dep_lib, c_sdl_preferred_linkage, cfg);
    }

    _ = setupDocs(b, sdl3);
    _ = setupTest(b, cfg, extension_options);
    const example_options = ExampleOptions{
        .ext_image = ext_image,
        .ext_net = ext_net,
    };
    _ = try setupExamples(b, sdl3, cfg, example_options);
    _ = try runExample(b, sdl3, cfg, example_options);
}

pub fn setupSdlNet(b: *std.Build, sdl3: *std.Build.Module, sdl_dep_lib: *std.Build.Step.Compile, linkage: std.builtin.LinkMode, cfg: std.Build.TestOptions) void {
    const target = cfg.target orelse b.standardTargetOptions(.{});
    const optimize = cfg.optimize;

    const upstream = b.lazyDependency("sdl_net", .{}) orelse return;
    const native_os = target.result.os.tag;

    const lib_name = "SDL3_net";
    const version = std.SemanticVersion.parse("3.0.0") catch unreachable;
    // Options.
    const shared = b.option(bool, "shared", "Build a shared library") orelse false;
    const werror = b.option(bool, "werror", "Treat warnings as errors") orelse false;
    // Library.
    const lib = b.addLibrary(.{
        .name = lib_name,
        .version = version,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .linkage = linkage,
    });

    var lib_c_flags: std.ArrayList([]const u8) = .init(b.allocator);
    defer lib_c_flags.deinit();
    lib_c_flags.appendSlice(&.{"-std=c99"}) catch @panic("OOM");
    if (werror) {
        lib_c_flags.append("-Werror") catch @panic("OOM");
    }

    lib.root_module.addCSourceFile(.{
        .file = upstream.path("src/SDL_net.c"),
        .flags = lib_c_flags.items,
    });
    // Headers.
    lib.root_module.addIncludePath(upstream.path("include"));
    // Defines.
    lib.root_module.addCMacro("BUILD_SDL", "1");
    lib.root_module.addCMacro("SDL_BUILD_MAJOR_VERSION", b.fmt("{d}", .{version.major}));
    lib.root_module.addCMacro("SDL_BUILD_MINOR_VERSION", b.fmt("{d}", .{version.minor}));
    lib.root_module.addCMacro("SDL_BUILD_MICRO_VERSION", b.fmt("{d}", .{version.patch}));
    if (shared and native_os == .windows) {
        lib.root_module.addCMacro("DLL_EXPORT", "");
    }
    if (native_os != .windows and native_os != .haiku) {
        lib.root_module.addCMacro("_DEFAULT_SOURCE", "");
    }
    lib.root_module.linkLibrary(sdl_dep_lib);
    // Linking.
    if (native_os == .windows) {
        lib.root_module.linkSystemLibrary("iphlpapi", .{});
        lib.root_module.linkSystemLibrary("ws2_32", .{});
        if (shared) {
            lib.root_module.addWin32ResourceFile(.{ .file = upstream.path("src/version.rc") });
        }
    } else if (native_os == .haiku) {
        lib.root_module.linkSystemLibrary("network", .{});
    }
    // Linker version.
    if (target.result.ofmt == .elf or target.result.ofmt == .macho) {
        lib.setVersionScript(upstream.path("src/SDL_net.sym"));
    }
    if (shared) {
        lib.linker_allow_shlib_undefined = false;
    }

    b.installArtifact(lib);
    // Installation.
    const install_header = b.addInstallHeaderFile(upstream.path("include/SDL3_net/SDL_net.h"), "SDL3_net/SDL_net.h");
    b.getInstallStep().dependOn(&install_header.step);
    const install_license = b.addInstallFile(upstream.path("LICENSE.txt"), "share/licenses/SDL3_net/LICENSE.txt");
    b.getInstallStep().dependOn(&install_license.step);

    sdl3.linkLibrary(lib);
    sdl3.addIncludePath(upstream.path("include"));
}

// Most of this is copied from https://github.com/allyourcodebase/SDL_image/blob/main/build.zig.
pub fn setupSdlImage(b: *std.Build, sdl3: *std.Build.Module, sdl_dep_lib: *std.Build.Step.Compile, linkage: std.builtin.LinkMode, cfg: std.Build.TestOptions) void {
    const upstream = b.lazyDependency("sdl_image", .{}) orelse return;

    const target = cfg.target orelse b.standardTargetOptions(.{});
    const lib = b.addLibrary(.{
        .name = "SDL3_image",
        .version = .{ .major = 3, .minor = 2, .patch = 4 },
        .linkage = linkage,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = cfg.optimize,
            .link_libc = true,
        }),
    });
    lib.linkLibrary(sdl_dep_lib);

    // Use stb_image for loading JPEG and PNG files. Native alternatives such as
    // Windows Imaging Component and Apple's Image I/O framework are not yet
    // supported by this build script.
    lib.root_module.addCMacro("USE_STBIMAGE", "");

    // The following are options for supported file formats. AVIF, JXL, TIFF,
    // and WebP are not yet supported by this build script, as they require
    // additional dependencies.
    if (b.option(bool, "image_enable_bmp", "Support loading BMP images") orelse true)
        lib.root_module.addCMacro("LOAD_BMP", "");
    if (b.option(bool, "image_enable_gif", "Support loading GIF images") orelse true)
        lib.root_module.addCMacro("LOAD_GIF", "");
    if (b.option(bool, "image_enable_jpg", "Support loading JPEG images") orelse true)
        lib.root_module.addCMacro("LOAD_JPG", "");
    if (b.option(bool, "image_enable_lbm", "Support loading LBM images") orelse true)
        lib.root_module.addCMacro("LOAD_LBM", "");
    if (b.option(bool, "image_enable_pcx", "Support loading PCX images") orelse true)
        lib.root_module.addCMacro("LOAD_PCX", "");
    if (b.option(bool, "image_enable_png", "Support loading PNG images") orelse true)
        lib.root_module.addCMacro("LOAD_PNG", "");
    if (b.option(bool, "image_enable_pnm", "Support loading PNM images") orelse true)
        lib.root_module.addCMacro("LOAD_PNM", "");
    if (b.option(bool, "image_enable_qoi", "Support loading QOI images") orelse true)
        lib.root_module.addCMacro("LOAD_QOI", "");
    if (b.option(bool, "image_enable_svg", "Support loading SVG images") orelse true)
        lib.root_module.addCMacro("LOAD_SVG", "");
    if (b.option(bool, "image_enable_tga", "Support loading TGA images") orelse true)
        lib.root_module.addCMacro("LOAD_TGA", "");
    if (b.option(bool, "image_enable_xcf", "Support loading XCF images") orelse true)
        lib.root_module.addCMacro("LOAD_XCF", "");
    if (b.option(bool, "image_enable_xpm", "Support loading XPM images") orelse true)
        lib.root_module.addCMacro("LOAD_XPM", "");
    if (b.option(bool, "image_enable_xv", "Support loading XV images") orelse true)
        lib.root_module.addCMacro("LOAD_XV", "");

    lib.addIncludePath(upstream.path("include"));
    lib.addIncludePath(upstream.path("src"));

    lib.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &.{
            "IMG.c",
            "IMG_WIC.c",
            "IMG_avif.c",
            "IMG_bmp.c",
            "IMG_gif.c",
            "IMG_jpg.c",
            "IMG_jxl.c",
            "IMG_lbm.c",
            "IMG_pcx.c",
            "IMG_png.c",
            "IMG_pnm.c",
            "IMG_qoi.c",
            "IMG_stb.c",
            "IMG_svg.c",
            "IMG_tga.c",
            "IMG_tif.c",
            "IMG_webp.c",
            "IMG_xcf.c",
            "IMG_xpm.c",
            "IMG_xv.c",
        },
    });

    if (target.result.os.tag == .macos) {
        lib.addCSourceFile(.{
            .file = upstream.path("src/IMG_ImageIO.m"),
        });
        lib.linkFramework("Foundation");
        lib.linkFramework("ApplicationServices");
    }

    lib.installHeadersDirectory(upstream.path("include"), "", .{});

    sdl3.linkLibrary(lib);
    sdl3.addIncludePath(upstream.path("include"));
}

pub fn setupDocs(b: *std.Build, sdl3: *std.Build.Module) *std.Build.Step {
    const sdl3_lib = b.addStaticLibrary(.{
        .root_module = sdl3,
        .name = "sdl3",
    });
    const docs = b.addInstallDirectory(.{
        .source_dir = sdl3_lib.getEmittedDocs(),
        .install_dir = .{ .prefix = {} },
        .install_subdir = "docs",
    });
    const docs_step = b.step("docs", "Generate library documentation");
    docs_step.dependOn(&docs.step);
    return docs_step;
}

pub fn setupExample(b: *std.Build, sdl3: *std.Build.Module, cfg: std.Build.TestOptions, name: []const u8) !*std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = name,
        .target = cfg.target orelse b.standardTargetOptions(.{}),
        .optimize = cfg.optimize,
        .root_source_file = b.path(try std.fmt.allocPrint(b.allocator, "examples/{s}.zig", .{name})),
        .version = cfg.version,
    });
    exe.root_module.addImport("sdl3", sdl3);
    b.installArtifact(exe);
    return exe;
}

pub fn runExample(b: *std.Build, sdl3: *std.Build.Module, cfg: std.Build.TestOptions, options: ExampleOptions) !void {
    const run_example: ?[]const u8 = b.option([]const u8, "example", "The example name for running an example") orelse null;
    const run = b.step("run", "Run an example with -Dexample=<example_name> option");
    if (run_example) |example| {
        var can_run = true;
        // TODO unhardcode if we will need more extension-specific examples
        if (std.mem.eql(u8, example, "net")) {
            can_run = options.ext_net;
        }

        if (can_run) {
            const run_art = b.addRunArtifact(try setupExample(b, sdl3, cfg, example));
            run_art.step.dependOn(b.getInstallStep());
            run.dependOn(&run_art.step);
        }
    }
}

pub fn setupExamples(b: *std.Build, sdl3: *std.Build.Module, cfg: std.Build.TestOptions, options: ExampleOptions) !*std.Build.Step {
    const exp = b.step("examples", "Build all examples");
    const examples_dir = b.path("examples");
    var dir = (try std.fs.openDirAbsolute(examples_dir.getPath(b), .{ .iterate = true }));
    defer dir.close();
    var dir_iterator = try dir.walk(b.allocator);
    defer dir_iterator.deinit();
    while (try dir_iterator.next()) |file| {
        if (file.kind == .file and std.mem.endsWith(u8, file.basename, ".zig")) {
            const name = file.basename[0 .. file.basename.len - 4];
            var build_example = true;
            // TODO unhardcode if we will need more extension-specific examples
            if (std.mem.eql(u8, name, "net")) {
                build_example = options.ext_net;
            }

            if (build_example) {
                _ = try setupExample(b, sdl3, cfg, name);
            }
        }
    }
    exp.dependOn(b.getInstallStep());
    return exp;
}

pub fn setupTest(b: *std.Build, cfg: std.Build.TestOptions, extension_options: *std.Build.Step.Options) *std.Build.Step.Compile {
    const tst = b.addTest(cfg);
    tst.root_module.addOptions("extension_options", extension_options);
    const sdl_dep = b.dependency("sdl", .{
        .target = cfg.target orelse b.standardTargetOptions(.{}),
        .optimize = cfg.optimize,
    });
    const sdl_dep_lib = sdl_dep.artifact("SDL3");
    tst.linkLibrary(sdl_dep_lib);
    const tst_run = b.addRunArtifact(tst);
    const tst_step = b.step("test", "Run all tests");
    tst_step.dependOn(&tst_run.step);
    return tst;
}
