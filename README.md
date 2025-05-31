zig-sdl3
========

A lightweight wrapper to zig-ify SDL3.

> [!WARNING]
> This is not production ready and currently in development!
>
> I'm hoping to be done soon, great progress has been made so far!
>
> See the [checklist](checklist.md) for more details on progress.

# Documentation
[https://gota7.github.io/zig-sdl3/](https://gota7.github.io/zig-sdl3/)

# About

This library aims to unite the power of SDL3 with general zigisms to feel right at home alongside the zig standard library.
SDL3 is compatible with many different platforms, making it the perfect library to pair with zig.
Some advantages of SDL3 include windowing, audio, gamepad, keyboard, mouse, rendering, and GPU abstractions across all supported platforms.

# Building and using

Download and add zig-sdl3 as a dependency by running the following command in your project root:

```sh
zig fetch --save git+https://github.com/Gota7/zig-sdl3#master
```

Then add zig-sdl3 as a dependency and import its modules and artifact in your `build.zig`:

```zig
const sdl3 = b.dependency("sdl3", .{
    .target = target,
    .optimize = optimize,
    .callbacks = false,
    .ext_image = true,
});
```
Now add the modules and artifact to your target as you would normally:

```zig
lib.root_module.addImport("sdl3", sdl3.module("sdl3"));
```

# Example

```zig
const std = @import("std");
const sdl3 = @import("sdl3");

const SCREEN_WIDTH = 640;
const SCREEN_HEIGHT = 480;

pub fn main() !void {
    defer sdl3.init.shutdown();

    const init_flags = sdl3.init.Flags{ .video = true };
    try sdl3.init.init(init_flags);
    defer sdl3.init.quit(init_flags);

    const window = try sdl3.video.Window.init("Hello SDL3", SCREEN_WIDTH, SCREEN_HEIGHT, .{});
    defer window.deinit();

    const surface = try window.getSurface();
    try surface.fillRect(null, surface.mapRgb(128, 30, 255));
    try window.updateSurface();

    while (true) {
        switch ((try sdl3.events.wait(true)).?) {
            .quit => break,
            .terminating => break,
            else => {}
        }
    }
}
```

# Structure

## Source
The `src` folder was originally generated via a binding generator, but manually perfecting and testing the subsystems was found to be more productive.
Each source file must also call each function at least once in testing if possible to ensure compilation is successful.

## Examples

The `examples` directory has some example programs utilizing SDL3.
All examples may be built with `zig build examples`, or a single example can be ran with `zig build run -Dexample=<example name>`.

## Template

The `template` directory contains a sample hello world to get started using SDL3.
Simply copy this folder to use as your project, and have fun!

## Tests
Tests for the library can be ran by running `zig build test`.

# Features

* SDL subsystems are divided into convenient namespaces.
* Functions that can fail have the return wrapped with an error type and can even call a custom error callback.
* C namespace exporting raw SDL functions in case it is ever needed.
* Standard `init` and `deinit` functions for creating and destroying resources.
* Skirts around C compat weirdness when possible (C pointers, anyopaque, C types).
* Naming and conventions are more consistent with zig.
* Functions return values rather than write to pointers.
* Types that are intended to be nullable are now clearly annotated as such with optionals.
* Easy conversion to/from SDL types from the wrapped types.
* The `self.function()` notation is used where applicable.
