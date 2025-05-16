/// Not recommended for usage unless absolutely needed.
///
/// SDL's macros are not compatible with zig, use zig when appropriate.
///
/// However, setting callbacks should work fine.
pub const assert = @import("assert.zig");

/// SDL offers a way to perform I/O asynchronously.
/// This allows an app to read or write files without waiting for data to actually transfer; the functions that request I/O never block while the request is fulfilled.
///
/// Instead, the data moves in the background and the app can check for results at their leisure.
///
/// This is more complicated than just reading and writing files in a synchronous way, but it can allow for more efficiency,
/// and never having framerate drops as the hard drive catches up, etc.
///
/// The general usage pattern for async I/O is:
/// * Create one or more `async_io.Queue` objects.
/// * Open files with `async_io.File.init()`.
/// * Start I/O tasks to the files with `async_io.Queue.readFile()` or `async_io.Queue.writeFile()`, putting those tasks into one of the queues.
/// * Later on, use `async_io.Queue.getResult()` on a queue to see if any task is finished without blocking. Tasks might finish in any order with success or failure.
/// * When all your tasks are done, close the file with `async_io.Queue.CloseFile()`. This also generates a task, since it might flush data to disk!
///
/// This all works, without blocking, in a single thread, but one can also wait on a queue in a background thread, sleeping until new results have arrived:
/// * Call `async_io.Queue.waitResult()` from one or more threads to efficiently block until new tasks complete.
/// * When shutting down, call `async_io.Queue.signal()` to unblock any sleeping threads despite there being no new tasks completed.
///
/// And, of course, to match the synchronous `io_stream.loadFile()`, we offer `async_io.Queue.loadFile()` as a convenience function.
/// This will handle allocating a buffer, slurping in the file data, and null-terminating it; you still check for results later.
///
/// Behind the scenes, SDL will use newer, efficient APIs on platforms that support them: Linux's `io_uring` and Windows 11's `IoRing`, for example.
/// If those technologies aren't available, SDL will offload the work to a thread pool that will manage otherwise-synchronous loads without blocking the app.
///
/// ## Best Practices
/// Simple non-blocking I/O--for an app that just wants to pick up data whenever it's ready without losing framerate waiting on disks to spin--can use whatever pattern
/// works well for the program.
/// In this case, simply call `async_io.Queue.readFile()`, or maybe `async_io.Queue.loadFile()`, as needed.
/// Once a frame, call SDL_GetAsyncIOResult to check for any completed tasks and deal with the data as it arrives.
///
/// If two separate pieces of the same program need their own I/O, it is legal for each to create their own queue.
/// This will prevent either piece from accidentally consuming the other's completed tasks. Each queue does require some amount of resources, but it is not an overwhelming cost.
/// Do not make a queue for each task, however.
/// It is better to put many tasks into a single queue.
/// They will be reported in order of completion, not in the order they were submitted, so it doesn't generally matter what order tasks are started.
///
/// One async I/O queue can be shared by multiple threads, or one thread can have more than one queue, but the most efficient way--if ruthless efficiency is the goal--is to
/// have one queue per thread, with multiple threads working in parallel,
/// and attempt to keep each queue loaded with tasks that are both started by and consumed by the same thread.
/// On modern platforms that can use newer interfaces, this can keep data flowing as efficiently as possible all the way from storage hardware to the app,
/// with no contention between threads for access to the same queue.
///
/// Written data is not guaranteed to make it to physical media by the time a closing task is completed, unless `async_io.closeFile()` is called with its `flush` parameter set to true,
/// which is to say that a successful result here can still result in lost data during an unfortunately-timed power outage if not flushed.
/// However, flushing will take longer and may be unnecessary, depending on the app's needs.
pub const async_io = @import("async_io.zig");

/// Audio functionality for the SDL library.
///
/// All audio in SDL3 revolves around `audio.Stream`.
/// Whether you want to play or record audio, convert it, stream it, buffer it, or mix it, you're going to be passing it through an audio stream.
///
/// Audio streams are quite flexible; they can accept any amount of data at a time, in any supported format, and output it as needed in any other format,
/// even if the data format changes on either side halfway through.
///
/// An app opens an audio device and binds any number of audio streams to it, feeding more data to the streams as available.
/// When the device needs more data, it will pull it from all bound streams and mix them together for playback.
///
/// Audio streams can also use an app-provided callback to supply data on-demand, which maps pretty closely to the SDL2 audio model.
///
/// SDL also provides a simple .WAV loader in `audio.loadWav()` (and `audio.loadWavIo()` if you aren't reading from a file) as a basic means to load sound data into your program.
///
/// ## Logical audio devices
/// In SDL3, opening a physical device (like a SoundBlaster 16 Pro) gives you a logical device ID that you can bind audio streams to.
/// In almost all cases, logical devices can be used anywhere in the API that a physical device is normally used.
/// However, since each device opening generates a new logical device, different parts of the program (say, a VoIP library, or text-to-speech framework,
/// or maybe some other sort of mixer on top of SDL) can have their own device opens that do not interfere with each other;
/// each logical device will mix its separate audio down to a single buffer, fed to the physical device, behind the scenes.
/// As many logical devices as you like can come and go; SDL will only have to open the physical device at the OS level once,
/// and will manage all the logical devices on top of it internally.
///
/// One other benefit of logical devices: if you don't open a specific physical device, instead opting for the default,
/// SDL can automatically migrate those logical devices to different hardware as circumstances change: a user plugged in headphones?
/// The system default changed?
/// SDL can transparently migrate the logical devices to the correct physical device seamlessly and keep playing;
/// the app doesn't even have to know it happened if it doesn't want to.
///
/// ## Simplified Audio
/// As a simplified model for when a single source of audio is all that's needed, an app can use `audio.Device.openStream()`, which is a single function to open an audio device,
/// create an audio stream, bind that stream to the newly-opened device, and (optionally) provide a callback for obtaining audio data.
/// When using this function, the primary interface is the `audio.Stream` and the device handle is mostly hidden away;
/// destroying a stream created through this function will also close the device, stream bindings cannot be changed, etc.
/// One other quirk of this is that the device is started in a paused state and must be explicitly resumed;
/// this is partially to offer a clean migration for SDL2 apps and partially because the app might have to do more setup before playback begins;
/// in the non-simplified form, nothing will play until a stream is bound to a device, so they start unpaused.
///
/// ## Channel Layouts
/// Audio data passing through SDL is uncompressed PCM data, interleaved. One can provide their own decompression through an MP3, etc, decoder,
/// but SDL does not provide this directly.
/// Each interleaved channel of data is meant to be in a specific order.
///
/// Abbreviations:
/// * FRONT = Single mono speaker.
/// * FL = Front left speaker.
/// * FR = Front right speaker.
/// * FC = Front center speaker.
/// * BL = Back left speaker.
/// * BR = Back right speaker.
/// * SR = Surround right speaker.
/// * SL = Surround left speaker.
/// * BC = Back center speaker.
/// * LFE = Low-frequency speaker.
///
/// These are listed in the order they are laid out in memory, so "FL, FR" means "the front left speaker is laid out in memory first, then the front right,
/// then it repeats for the next audio frame":
/// * 1 channel (mono) layout: FRONT
/// * 2 channels (stereo) layout: FL, FR
/// * 3 channels (2.1) layout: FL, FR, LFE
/// * 4 channels (quad) layout: FL, FR, BL, BR
/// * 5 channels (4.1) layout: FL, FR, LFE, BL, BR
/// * 6 channels (5.1) layout: FL, FR, FC, LFE, BL, BR (last two can also be SL, SR)
/// * 7 channels (6.1) layout: FL, FR, FC, LFE, BC, SL, SR
/// * 8 channels (7.1) layout: FL, FR, FC, LFE, BL, BR, SL, SR
///
/// This is the same order as DirectSound expects, but applied to all platforms; SDL will swizzle the channels as necessary if a platform expects something different.
///
/// `audio.Stream` can also be provided channel maps to change this ordering to whatever is necessary, in other audio processing scenarios.
pub const audio = @import("audio.zig");

/// Functions for fiddling with bits and bitmasks.
pub const bits = @import("bits.zig");

/// Blend modes decide how two colors will mix together.
/// There are both standard modes for basic needs and a means to create custom modes, dictating what sort of math to do on what color components.
pub const blend_mode = @import("blend_mode.zig");

/// Provide raw access to SDL3's C API.
///
/// Under most circumstances, you will never need to use this.
/// This should only really be used for functions not yet implemented in zig-sdl3.
pub const c = @import("c.zig").C;

/// CPU feature detection for SDL.
///
/// These functions are largely concerned with reporting if the system has access to various SIMD instruction sets,
/// but also has other important info to share, such as system RAM size and number of logical CPU cores.
///
/// CPU instruction set checks, like `cpu_info.hasSse()` and `cpu_info.hasNeon()`, are available on all platforms,
/// even if they don't make sense (an ARM processor will never have SSE and an x86 processor will never have NEON,
/// for example, but these functions still exist and will simply return false in these cases).
pub const cpu_info = @import("cpu_info.zig");

/// Video capture for the SDL library.
///
/// This API lets apps read input from video sources, like webcams.
/// Camera devices can be enumerated, queried, and opened.
/// Once opened, it will provide `surface.Surface` objects as new frames of video come in.
/// These surfaces can be uploaded to an `render.Texture` or processed as pixels in memory.
///
/// Several platforms will alert the user if an app tries to access a camera,
/// and some will present a UI asking the user if your application should be allowed to obtain images at all, which they can deny.
/// A successfully opened camera will not provide images until permission is granted.
/// Applications, after opening a camera device, can see if they were granted access by either polling with the `camera.Camera.getPermissionState()` function,
/// or waiting for an `event.Type.camera_device_approved` or `event.Type.camera_device_denied` event.
/// Platforms that don't have any user approval process will report approval immediately.
///
/// Note that SDL cameras only provide video as individual frames; they will not provide full-motion video encoded in a movie file format,
/// although an app is free to encode the acquired frames into any format it likes.
/// It also does not provide audio from the camera hardware through this API; not only do many webcams not have microphones at all,
/// many people--from streamers to people on Zoom calls--will want to use a separate microphone regardless of the camera.
/// In any case, recorded audio will be available through SDL's audio API no matter what hardware provides the microphone.
///
/// ## Camera Gotchas
/// Consumer-level camera hardware tends to take a little while to warm up, once the device has been opened.
/// Generally most camera apps have some sort of UI to take a picture (a button to snap a pic while a preview is showing,
/// some sort of multi-second countdown for the user to pose, like a photo booth), which puts control in the users' hands,
/// or they are intended to stay on for long times (Pokemon Go, etc).
///
/// It's not uncommon that a newly-opened camera will provide a couple of completely black frames, maybe followed by some under-exposed images.
/// If taking a single frame automatically, or recording video from a camera's input without the user initiating it from a preview,
/// it could be wise to drop the first several frames (if not the first several seconds worth of frames!) before using images from a camera.
pub const camera = @import("camera.zig");

/// SDL provides access to the system clipboard, both for reading information from other processes and publishing information of its own.
///
/// This is not just text! SDL apps can access and publish data by mimetype.
///
/// ## Basic Use (Text)
/// Obtaining and publishing simple text to the system clipboard is as easy as calling `clipboard.getText()` and `clipboard.setText()`, respectively.
/// These deal with C strings in UTF-8 encoding. Data transmission and encoding conversion is completely managed by SDL.
///
/// ## Clipboard Callbacks (Non-Text)
/// Things get more complicated when the clipboard contains something other than text.
/// Not only can the system clipboard contain data of any type, in some cases it can contain the same data in different formats!
/// For example, an image painting app might let the user copy a graphic to the clipboard, and offers it in .BMP, .JPG, or .PNG format for other apps to consume.
///
/// Obtaining clipboard data ("pasting") like this is a matter of calling `clipboard.getData()` and telling it the mimetype of the data you want.
/// But how does one know if that format is available?
/// `hasData()` can report if a specific mimetype is offered, and `clipboard.getMimeTypes()` can provide the entire list of mimetypes available,
/// so the app can decide what to do with the data and what formats it can support.
///
/// Setting the clipboard ("copying") to arbitrary data is done with `clipboard.setData()`.
/// The app does not provide the data in this call, but rather the mimetypes it is willing to provide and a callback function.
/// During the callback, the app will generate the data.
/// This allows massive data sets to be provided to the clipboard, without any data being copied before it is explicitly requested.
/// More specifically, it allows an app to offer data in multiple formats without providing a copy of all of them upfront.
/// If the app has an image that it could provide in PNG or JPG format, it doesn't have to encode it to either of those unless and until something tries to paste it.
///
/// ## Primary Selection
/// The X11 and Wayland video targets have a concept of the "primary selection" in addition to the usual clipboard.
/// This is generally highlighted (but not explicitly copied) text from various apps.
/// SDL offers APIs for this through `clipboard.getPrimarySelectionText()` and `clipboard.setPrimarySelectionText()`.
/// SDL offers these APIs on platforms without this concept, too, but only so far that it will keep a copy of a string that the app sets for later retrieval;
/// the operating system will not ever attempt to change the string externally if it doesn't support a primary selection.
pub const clipboard = @import("clipboard.zig");

/// File dialog support.
///
/// SDL offers file dialogs, to let users select files with native GUI interfaces.
/// There are "open" dialogs, "save" dialogs, and folder selection dialogs.
/// The app can control some details, such as filtering to specific files,
/// or whether multiple files can be selected by the user.
///
/// Note that launching a file dialog is a non-blocking operation; control returns to the app immediately,
/// and a callback is called later (possibly in another thread) when the user makes a choice.
pub const dialog = @import("dialog.zig");

/// Functions converting endian-specific values to different byte orders.
///
/// These functions either unconditionally swap byte order (`endian.swap16()`, `endian.swap32()`, `endian.swap64()`, `endian.swapFloat()`),
/// or they swap to/from the system's native byte order
/// (`endian.swap16Le()`, `endian.swap16Be()`, `endian.swap32Le()`, `endian.swap32Be()`, `endian.swapFloatLe()`, `endian.swapfloatBe()`).
/// In the latter case, the functionality is provided by macros that become no-ops if a swap isn't necessary: on an x86 (littleendian) processor,
/// `endian.swap32Le()` does nothing, but `endian.swap32Be()` reverses the bytes of the data.
/// On a PowerPC processor (bigendian), the macros behavior is reversed.
///
/// The swap routines are inline functions, and attempt to use compiler intrinsics,
/// inline assembly, and other magic to make byteswapping efficient.
pub const endian = @import("endian.zig");

/// Simple error message routines for SDL.
///
/// Most apps will interface with these APIs in exactly one function:
/// when almost any SDL function call reports failure, you can get a human-readable string of the problem from `errors.get()`.
///
/// These strings are maintained per-thread, and apps are welcome to set their own errors, which is popular when building libraries on top of SDL for other apps to consume.
/// These strings are set by calling `errors.set()`.
pub const errors = @import("errors.zig");

pub const events = @import("events.zig");

/// SDL offers an API for examining and manipulating the system's filesystem.
/// This covers most things one would need to do with directories, except for actual file I/O (which is covered by `io_stream` and `async_io` instead).
///
/// There are functions to answer necessary path questions:
/// * Where is my app's data? `filesystem.getBasePath()`.
/// * Where can I safely write files? `filesystem.getPrefPath()`.
/// * Where are paths like Downloads, Desktop, Music? `filesystem.getUserFolder()`.
/// * What is this thing at this location? `filesystem.getPathInfo()`.
/// * What items live in this folder? `filesystem.enumerateDirectory()`.
/// * What items live in this folder by wildcard? `filesystem.globDirectory()`.
/// * What is my current working directory? `filesystem.getCurrentDirectory()`.
///
/// SDL also offers functions to manipulate the directory tree: renaming, removing, copying files.
pub const filesystem = @import("filesystem.zig");

/// The GPU API offers a cross-platform way for apps to talk to modern graphics hardware.
/// It offers both 3D graphics and compute support, in the style of Metal, Vulkan, and Direct3D 12.
///
/// This is a very complex category, and so it is recommended to read over https://wiki.libsdl.org/SDL3/CategoryGPU.
pub const gpu = @import("gpu.zig");

/// A GUID is a 128-bit value that represents something that is uniquely identifiable by this value: "globally unique."
///
/// SDL provides functions to convert a GUID to/from a stri
pub const GUID = @import("guid.zig").GUID;

/// File for SDL HID API functions.
///
/// This is an adaptation of the original HIDAPI interface by Alan Ott, and includes source code licensed under the following license:
/// ```
/// HIDAPI - Multi-Platform library for
/// communication with HID devices.
///
/// Copyright 2009, Alan Ott, Signal 11 Software.
/// All Rights Reserved.
///
/// This software may be used by anyone for any reason so
/// long as the copyright notice in the source files
/// remains intact.
/// ```
/// (Note that this license is the same as item three of SDL's zlib license, so it adds no new requirements on the user.)
///
/// If you would like a version of SDL without this code, you can build SDL with `SDL_HIDAPI_DISABLED` defined to `1`.
/// You might want to do this for example on iOS or tvOS to avoid a dependency on the CoreBluetooth framework.
pub const hid_api = @import("hid_api.zig");

/// This file contains functions to set and get configuration hints, as well as listing each of them alphabetically.
///
/// The convention for naming hints is "xy_z", where "XY_Z" is the environment variable that can be used to override the default.
///
/// In general these hints are just that - they may or may not be supported or applicable on any given platform,
/// but they provide a way for an application or user to give the library a hint as to how they would like the library to work.
pub const hints = @import("hints.zig");
pub const image = if (extension_options.image) @import("image.zig") else void;

/// All SDL programs need to initialize the library before starting to work with it.
///
/// Almost everything can simply call `init.init()` near startup, with a handful of flags to specify subsystems to touch.
/// These are here to make sure SDL does not even attempt to touch low-level pieces of the operating system that you don't intend to use.
/// For example, you might be using SDL for video and input but chose an external library for audio,
/// and in this case you would just need to leave off the `audio` flag to make sure that external library has complete control.
///
/// Most apps, when terminating, should call `init.shutdown()`.
/// This will clean up (nearly) everything that SDL might have allocated, and crucially,
/// it'll make sure that the display's resolution is back to what the user expects if you had previously changed it for your game.
///
/// SDL3 apps are strongly encouraged to call `init.setAppMetadata()` at startup to fill in details about the program.
/// This is completely optional, but it helps in small ways (we can provide an About dialog box for the macOS menu, we can name the app in the system's audio mixer, etc).
/// Those that want to provide a lot of information should look at the more-detailed `init.setAppMetadataProperty()`.
pub const init = @import("init.zig");

/// SDL does some preprocessor gymnastics to determine if any CPU-specific compiler intrinsics are available,
/// as this is not necessarily an easy thing to calculate, and sometimes depends on quirks of a system, versions of build tools, and other external forces.
///
/// Apps including SDL's headers will be able to check consistent preprocessor definitions to decide if it's safe to use compiler intrinsics for a specific CPU architecture.
/// This check only tells you that the compiler is capable of using those intrinsics; at runtime,
/// you should still check if they are available on the current system with the CPU info functions, such as `cpu_info.hasSse()` or `cpu_info.hasNeon()`.
/// Otherwise, the process might crash for using an unsupported CPU instruction.
///
/// SDL only sets preprocessor defines for CPU intrinsics if they are supported, so apps should check the constants.
///
/// SDL will also include the appropriate instruction-set-specific support headers, so if SDL decides to set `intrin.sse2` to true,
/// it will also `#include <emmintrin.h>` as well.
pub const intrin = @import("intrin.zig");

/// SDL provides an abstract interface for reading and writing data streams.
/// It offers implementations for files, memory, etc, and the app can provide their own implementations, too.
///
/// `io_stream.Stream` is not related to the standard C++ iostream class, other than both are abstract interfaces to read/write data.
pub const io_stream = @import("io_stream.zig");

/// SDL joystick support.
///
/// This is the lower-level joystick handling.
/// If you want the simpler option, where what each button does is well-defined, you should use the `gamepad` API instead.
///
/// The term "instance_id" is the current instantiation of a joystick device in the system, if the joystick is removed and then re-inserted then it will get a new `instance_id`,
/// `instance_id`'s are monotonically increasing identifiers of a joystick plugged in.
///
/// The term "player_index" is the number assigned to a player on a specific controller.
/// For XInput controllers this returns the XInput user index.
/// Many joysticks will not be able to supply this information.
///
/// The `GUID` is used as a stable 128-bit identifier for a joystick device that does not change over time.
/// It identifies class of the device (a X360 wired controller for example).
/// This identifier is platform dependent.
///
/// In order to use these functions, `init.init()` must have been called with the `init.Flags.joystick` flag.
/// This causes SDL to scan the system for joysticks, and load appropriate drivers.
///
/// If you would like to receive joystick updates while the application is in the background,
/// you should set the following hint before calling `init.init()`: `hints.Type.joystick_allow_background_events`.
pub const joystick = @import("joystick.zig");

/// SDL keyboard management.
///
/// Please refer to the Best Keyboard Practices document for details on how best to accept keyboard input in various types of programs:
/// https://wiki.libsdl.org/SDL3/BestKeyboardPractices
pub const keyboard = @import("keyboard.zig");

/// Defines constants which identify keyboard keys and modifiers.
///
/// Please refer to the Best Keyboard Practices document for details on what this information means and how best to use it.
///
/// https://wiki.libsdl.org/SDL3/BestKeyboardPractices
pub const keycode = @import("keycode.zig");

/// System-dependent library loading routines.
///
/// Shared objects are code that is programmatically loadable at runtime.
/// Windows calls these "DLLs", Linux calls them "shared libraries", etc.
///
/// To use them, build such a library, then call `SharedObject.load()` on it.
/// Once loaded, you can use `SharedObject.loadFunction()` on that object to find the address of its exported symbols.
/// When done with the object, call `SharedObject.unload()` to dispose of it.
///
/// Some things to keep in mind:
///
/// These functions only work on C function names.
/// Other languages may have name mangling and intrinsic language support that varies from compiler to compiler.
/// Make sure you declare your function pointers with the same calling convention as the actual library function.
/// Your code will crash mysteriously if you do not do this.
/// Avoid namespace collisions. If you load a symbol from the library, it is not defined whether or not it goes into the global symbol namespace for the application.
/// If it does and it conflicts with symbols in your code or other shared libraries, you will not get the results you expect. :)
/// Once a library is unloaded, all pointers into it obtained through `SharedObject.loadFunction()` become invalid, even if the library is later reloaded.
/// Don't unload a library if you plan to use these pointers in the future.
/// Notably: beware of giving one of these pointers to `atexit()`, since it may call that pointer after the library unloads.
pub const SharedObject = @import("loadso.zig").SharedObject;

/// SDL locale services.
///
/// This provides a way to get a list of preferred locales (language plus country) for the user.
/// There is exactly one function: `Locale.getPreferred()`, which handles all the heavy lifting,
/// and offers documentation on all the strange ways humans might have configured their language settings.
pub const Locale = @import("locale.zig").Locale;

/// Simple log messages with priorities and categories.
/// A message's `log.Priority` signifies how important the message is.
/// A message's `log.Category` signifies from what domain it belongs to.
/// Every category has a minimum priority specified: when a message belongs to that category, it will only be sent out if it has that minimum priority or higher.
///
/// SDL's own logs are sent below the default priority threshold, so they are quiet by default.
///
/// You can change the log verbosity programmatically using `log.Category.setPriority()` or with `hints.set(.Logging, ...)`, or with the "SDL_LOGGING" environment variable.
/// This variable is a comma separated set of category=level tokens that define the default logging levels for SDL applications.
///
/// The category can be a numeric category, one of "app", "error", "assert", "system", "audio", "video", "render", "input", "test", or * for any unspecified category.
///
/// The level can be a numeric level, one of "verbose", "debug", "info", "warn", "error", "critical", or "quiet" to disable that category.
///
/// You can omit the category if you want to set the logging level for all categories.
///
/// If this hint isn't set, the default log levels are equivalent to:
///
/// app=info,assert=warn,test=verbose,*=error
///
/// Here's where the messages go on different platforms:
///
/// * Windows: debug output stream
/// * Android: log output
/// * Others: standard error output (stderr)
///
/// You don't need to have a newline (\n) on the end of messages, the functions will do that for you.
/// For consistent behavior cross-platform, you shouldn't have any newlines in messages,
/// such as to log multiple lines in one call; unusual platform-specific behavior can be observed in such usage.
/// Do one log call per line instead, with no newlines in messages.
///
/// Each log call is atomic, so you won't see log messages cut off one another when logging from multiple threads.
pub const log = @import("log.zig");

/// Ability to call other main functions.
///
/// SDL will take care of platform specific details on how it gets called.
///
/// You most likely don't want to touch this and instead deal with the `.callbacks` setting to enable main callbacks in `build.zig`.
/// See the template project for an example on how to set this up.
///
/// For more information, see:
/// [https://wiki.libsdl.org/SDL3/README/main-functions](https://wiki.libsdl.org/SDL3/README/main-functions).
pub const main_funcs = if (extension_options.main) @import("main.zig") else void;

/// SDL offers a simple message box API, which is useful for simple alerts,
/// such as informing the user when something fatal happens at startup without the need to build a UI for it (or informing the user before your UI is ready).
///
/// These message boxes are native system dialogs where possible.
///
/// There is both a customizable function (`message_box.show()`) that offers lots of options for what to display and reports on what choice the user made,
/// and also a much-simplified version (`message_box.showSimple()`), merely takes a text message and title,
/// and waits until the user presses a single "OK" UI button.
/// Often, this is all that is necessary.
pub const message_box = @import("message_box.zig");

/// Functions to creating Metal layers and views on SDL windows.
///
/// This provides some platform-specific glue for Apple platforms.
/// Most macOS and iOS apps can use SDL without these functions, but this API they can be useful for specific OS-level integration tasks.
pub const MetalView = @import("metal.zig").View;

/// Any GUI application has to deal with the mouse, and SDL provides functions to manage mouse input and the displayed cursor.
///
/// Most interactions with the mouse will come through the event subsystem.
/// Moving a mouse generates an `event.Type.mouse_motion` event, pushing a button generates `event.Type.mouse_button_down`, etc,
/// but one can also query the current state of the mouse at any time with `mouse.getState()`.
///
/// For certain games, it's useful to disassociate the mouse cursor from mouse input.
/// An FPS, for example, would not want the player's motion to stop as the mouse hits the edge of the window.
/// For these scenarios, use `mouse.setWindowRelativeMode()`, which hides the cursor, grabs mouse input to the window, and reads mouse input no matter how far it moves.
///
/// Games that want the system to track the mouse but want to draw their own cursor can use `moues.hide()` and `mouse.show()`.
/// It might be more efficient to let the system manage the cursor, if possible, using `mouse.set()` with a custom image made through `mouse.Cursor.initColor()`,
/// or perhaps just a specific system cursor from `mouse.Cursor.initSystem()`.
///
/// SDL can, on many platforms, differentiate between multiple connected mice, allowing for interesting input scenarios and multiplayer games.
/// They can be enumerated with `mouse.getMice()`, and SDL will send `event.Type.mouse_added` and `event.Type.mouse_removed` events as they are connected and unplugged.
///
/// Since many apps only care about basic mouse input, SDL offers a virtual mouse device for touch and pen input,
/// which often can make a desktop application work on a touchscreen phone without any code changes.
/// Apps that care about touch/pen separately from mouse input should filter out events with a which field of `mouse.ID.touch` and `mouse.ID.pen`.
pub const mouse = @import("mouse.zig");

/// SDL API functions that don't fit elsewhere.
pub const openURL = @import("misc.zig").openURL;

/// SDL pen event handling.
///
/// SDL provides an API for pressure-sensitive pen (stylus and/or eraser) handling, e.g., for input and drawing tablets or suitably equipped mobile / tablet devices.
///
/// To get started with pens, simply handle pen events.
/// When a pen starts providing input, SDL will assign it a unique `pen.ID`, which will remain for the life of the process, as long as the pen stays connected.
///
/// Pens may provide more than simple touch input; they might have other axes, such as pressure, tilt, rotation, etc.
pub const pen = @import("pen.zig");

/// SDL offers facilities for pixel management.
///
/// Largely these facilities deal with pixel format: what does this set of bits represent?
///
/// If you mostly want to think of a pixel as some combination of red, green, blue, and maybe alpha intensities, this is all pretty straightforward,
/// and in many cases, is enough information to build a perfectly fine game.
///
/// However, the actual definition of a pixel is more complex than that:
///
/// Pixels are a representation of a color in a particular color space.
///
/// The first characteristic of a color space is the color type.
/// SDL understands two different color types, RGB and YCbCr, or in SDL also referred to as YUV.
///
/// RGB colors consist of red, green, and blue channels of color that are added together to represent the colors we see on the screen.
///
/// https://en.wikipedia.org/wiki/RGB_color_model
///
/// YCbCr colors represent colors as a Y luma brightness component and red and blue chroma color offsets.
/// This color representation takes advantage of the fact that the human eye is more sensitive to brightness than the color in an image.
/// The Cb and Cr components are often compressed and have lower resolution than the luma component.
///
/// https://en.wikipedia.org/wiki/YCbCr
///
/// When the color information in YCbCr is compressed, the Y pixels are left at full resolution and each Cr and Cb pixel represents an average of the
/// color information in a block of Y pixels.
/// The chroma location determines where in that block of pixels the color information is coming from.
///
/// The color range defines how much of the pixel to use when converting a pixel into a color on the display.
/// When the full color range is used, the entire numeric range of the pixel bits is significant.
/// When narrow color range is used, for historical reasons, the pixel uses only a portion of the numeric range to represent colors.
///
/// The color primaries and white point are a definition of the colors in the color space relative to the standard XYZ color space.
///
/// https://en.wikipedia.org/wiki/CIE_1931_color_space
///
/// The transfer characteristic, or opto-electrical transfer function (OETF), is the way a color is converted from mathematically linear space into a non-linear output signals.
///
/// https://en.wikipedia.org/wiki/Rec._709#Transfer_characteristics
///
/// The matrix coefficients are used to convert between YCbCr and RGB colors.
pub const pixels = @import("pixels.zig");

/// SDL provides a means to identify the app's platform, both at compile time and runtime.
pub const platform = @import("platform.zig");

/// SDL power management routines.
///
/// There is a single function in this category: `PowerState.get()`.
///
/// This function is useful for games on the go.
/// This allows an app to know if it's running on a draining battery, which can be useful if the app wants to reduce processing, or perhaps framerate,
/// to extend the duration of the battery's charge.
/// Perhaps the app just wants to show a battery meter when fullscreen, or alert the user when the power is getting extremely low, so they can save their game.
pub const PowerState = @import("power.zig").PowerState;

/// Process control support.
///
/// These functions provide a cross-platform way to spawn and manage OS-level processes.
///
/// You can create a new subprocess with `Process.init()` and optionally read and write to it using `Process.read()` or `Process.getInput()` and `Process.getOutput()`.
/// If more advanced functionality like chaining input between processes is necessary, you can use `Process.initWithProperties()`.
///
/// You can get the status of a created process with `Process.wait()`, or terminate the process with `Process.kill()`.
///
/// Don't forget to call `Process.deinit()` to clean up, whether the process process was killed, terminated on its own, or is still running!
pub const Process = @import("process.zig").Process;

/// A property is a variable that can be created and retrieved by name at runtime.
///
/// All properties are part of a property group `properties.Group`.
/// A property group can be created with the `properties.Group.init()` function and destroyed with the `properties.Group.deinit()` function.
///
/// Properties can be added to and retrieved from a property group through `properties.Group.set()` and `properties.Group.get()`.
///
/// Properties can be removed from a group by using `properties.Group.clear()`.
pub const properties = @import("properties.zig");

/// Some helper functions for managing rectangles and 2D points, in both integer and floating point versions.
pub const rect = @import("rect.zig");

/// Header file for SDL 2D rendering functions.
///
/// This API supports the following features:
/// * Single pixel points.
/// * Single pixel lines.
/// * Filled rectangles.
/// * Texture images.
/// * 2D polygons.
///
/// The primitives may be drawn in opaque, blended, or additive modes.
///
/// The texture images may be drawn in opaque, blended, or additive modes.
/// They can have an additional color tint or alpha modulation applied to them, and may also be stretched with linear interpolation.
///
/// This API is designed to accelerate simple 2D operations.
/// You may want more functionality such as polygons and particle effects and in that case you should use SDL's OpenGL/Direct3D support, the SDL3 GPU API,
/// or one of the many good 3D engines.
///
/// These functions must be called from the main thread.
/// See this bug for details: https://github.com/libsdl-org/SDL/issues/986
pub const render = @import("render.zig");

/// Defines keyboard scancodes.
///
/// Please refer to the Best Keyboard Practices document for details on what this information means and how best to use it.
///
/// https://wiki.libsdl.org/SDL3/BestKeyboardPractices
pub const Scancode = @import("scancode.zig").Scancode;

/// SDL sensor management.
///
/// These APIs grant access to gyros and accelerometers on various platforms.
///
/// In order to use these functions, `init.init()` must have been called with the `sensor` flag.
/// This causes SDL to scan the system for sensors, and load appropriate drivers.
pub const sensor = @import("sensor.zig");
pub const stdinc = @import("stdinc.zig");

/// The storage API is a high-level API designed to abstract away the portability issues that come up when using something lower-level.
///
/// See https://wiki.libsdl.org/SDL3/CategoryStorage for more details.
pub const storage = @import("storage.zig");

/// SDL surfaces are buffers of pixels in system RAM.
/// These are useful for passing around and manipulating images that are not stored in GPU memory.
///
/// `surface.Surface` makes serious efforts to manage images in various formats, and provides a reasonable toolbox for transforming the data,
/// including copying between surfaces, filling rectangles in the image data, etc.
///
/// There is also a simple .bmp loader, `surface.loadBmp()`.
/// SDL itself does not provide loaders for various other file formats, but there are several excellent external libraries that do, including its own satellite library,
/// SDL_image:
/// https://github.com/libsdl-org/SDL_image
pub const surface = @import("surface.zig");

/// SDL offers cross-platform thread management functions.
/// These are mostly concerned with starting threads, setting their priority, and dealing with their termination.
///
/// In addition, there is support for Thread Local Storage (data that is unique to each thread, but accessed from a single key).
///
/// On platforms without thread support (such as Emscripten when built without pthreads),
/// these functions still exist, but things like `thread.Thread.init()` will report failure without doing anything.
///
/// If you're going to work with threads, you almost certainly need to have a good understanding of `mutex` as well.
///
/// This part of the SDL API handles management of threads, but an app also will need locks to manage thread safety.
/// Those pieces are in `mutex`.
pub const thread = @import("thread.zig");

/// SDL realtime clock and date/time routines.
///
/// There are two data types that are used in this category: `time.Time`, which represents the nanoseconds since a specific moment (an "epoch"),
/// and `time.DateTime`, which breaks time down into human-understandable components: years, months, days, hours, etc.
///
/// Much of the functionality is involved in converting those two types to other useful forms.
pub const time = @import("time.zig");

/// SDL provides time management functionality.
/// It is useful for dealing with (usually) small durations of time.
///
/// This is not to be confused with calendar time management, which is provided by `time`.
///
/// This category covers measuring time elapsed (`timer.getMillisecondsSinceInit()`, `timer.getPerformanceCounter()`),
/// putting a thread to sleep for a certain amount of time (`timer.delayMilliseconds()`, `timer.delayNanoseconds()`, `timer.delayNanosecondsPrecise()`),
/// and firing a callback function after a certain amount of time has elasped (`timer.Timer.initMilliseconds()`, etc).
///
/// There are also useful functions to convert between time units, like `timer.secondsToNanoseconds()` and such.
pub const timer = @import("timer.zig");

/// SDL offers a way to add items to the "system tray" (more correctly called the "notification area" on Windows).
/// On platforms that offer this concept, an SDL app can add a tray icon, submenus, checkboxes, and clickable entries,
/// and register a callback that is fired when the user clicks on these pieces.
pub const tray = @import("tray.zig");

/// SDL offers touch input, on platforms that support it.
/// It can manage multiple touch devices and track multiple fingers on those devices.
///
/// Touches are mostly dealt with through the event system, in the `event.Type.finger_down`, `event.Type.finger_motion`, and `event.Type.finger_up` events,
/// but there are also functions to query for hardware details, etc.
///
/// The touch system, by default, will also send virtual mouse events; this can be useful for making a some desktop apps work on a phone without significant changes.
/// For apps that care about mouse and touch input separately, they should ignore mouse events that have a which field of `touch.ID.mouse`.
pub const touch = @import("touch.zig");

/// Functionality to query the current SDL version, both as headers the app was compiled against, and a library the app is linked to.
pub const Version = @import("version.zig").Version;
pub const video = @import("video.zig");

/// Functions for creating Vulkan surfaces on SDL windows.
///
/// For the most part, Vulkan operates independent of SDL, but it benefits from a little support during setup.
///
/// Use `vulkan.getInstanceExtensions()` to get platform-specific bits for creating a `vulkan.Instance`,
/// then `vulkan.getVkGetInstanceProcAddr()` to get the appropriate function for querying Vulkan entry points.
/// Then `vulkan.Surface.init()` will get you the final pieces you need to prepare for rendering into a `video.Window` with Vulkan.
///
/// Unlike OpenGL, most of the details of "context" creation and window buffer swapping are handled by the Vulkan API directly,
/// so SDL doesn't provide Vulkan equivalents of `video.gl.swapWindow()`, etc; they aren't necessary.
pub const vulkan = @import("vulkan.zig");

// Others.
const extension_options = @import("extension_options");
const std = @import("std");

/// Return values for optional main callbacks.
///
/// Returning Success or Failure from `SDL_AppInit(), `SDL_AppEvent()`,
/// or `SDL_AppIterate()` will terminate the program and report success/failure to the operating system.
/// What that means is platform-dependent.
/// On Unix, for example, on success, the process error code will be zero, and on failure it will be 1.
/// This interface doesn't allow you to return specific exit codes, just whether there was an error generally or not.
///
/// Returning Continue from these functions will let the app continue to run.
///
/// See Main callbacks in SDL3 for complete details.
///
/// This enum is available since SDL 3.2.0.
pub const AppResult = enum(c_uint) {
    /// Value that requests that the app continue from the main callbacks.
    run = c.SDL_APP_CONTINUE,
    /// Value that requests termination with success from the main callbacks.
    success = c.SDL_APP_SUCCESS,
    /// Value that requests termination with error from the main callbacks.
    failure = c.SDL_APP_FAILURE,
};

/// Function pointer typedef for `SDL_AppEvent()`.
///
/// ## Function Parameters
/// * `app_state`: An optional pointer, provided by the app in `SDL_AppInit()`.
/// * `event`: The new event for the app to examine.
///
/// ## Return Value
/// Returns `sdl3.AppResult.failure` to terminate with an error, `sdl3.AppResult.success` to terminate with success, `sdl3.AppResult.run` to continue.
///
/// ## Remarks
/// These are used by `main.enterAppMainCallbacks()`.
/// This mechanism operates behind the scenes for apps using the optional main callbacks.
/// Apps that want to use this should just implement `SDL_AppEvent()` directly.
///
/// ## Version
/// This datatype is available since SDL 3.2.0.
pub const AppEventCallback = *const fn (app_state: ?*anyopaque, event: [*c]c.SDL_Event) callconv(.C) c_uint;

/// Function pointer typedef for `SDL_AppInit()`.
///
/// ## Function Parameters
/// * `app_state`: A place where the app can optionally store a pointer for future use.
/// * `arg_count`: The standard ANSI C main's argc; number of elements in `arg_values`.
/// * `arg_values`: The standard ANSI C main's argv; array of command line arguments.
///
/// ## Return Value
/// Returns `sdl3.AppResult.failure` to terminate with an error, `sdl3.AppResult.success` to terminate with success, `sdl3.AppResult.run` to continue.
///
/// ## Remarks
/// These are used by `main.enterAppMainCallbacks()`.
/// This mechanism operates behind the scenes for apps using the optional main callbacks.
/// Apps that want to use this should just implement `SDL_AppInit()` directly.
///
/// ## Version
/// This datatype is available since SDL 3.2.0.
pub const AppInitCallback = *const fn (app_state: [*c]?*anyopaque, arg_count: c_int, arg_values: [*c][*c]u8) callconv(.C) c_uint;

/// Function pointer typedef for `SDL_AppIterate()`.
///
/// ## Function Parameters
/// * `app_state`: An optional pointer, provided by the app in `SDL_AppInit()`.
///
/// ## Return Value
/// Returns `sdl3.AppResult.failure` to terminate with an error, `sdl3.AppResult.success` to terminate with success, `sdl3.AppResult.run` to continue.
///
/// ## Remarks
/// These are used by `main.enterAppMainCallbacks()`.
/// This mechanism operates behind the scenes for apps using the optional main callbacks.
/// Apps that want to use this should just implement `SDL_AppIterate()` directly.
///
/// ## Version
/// This datatype is available since SDL 3.2.0.
pub const AppIterateCallback = *const fn (app_state: ?*anyopaque) callconv(.C) c_uint;

/// Function pointer typedef for `SDL_AppQuit()`.
///
/// ## Function Parameters
/// * `app_state`: An optional pointer, provided by the app in `SDL_AppInit()`.
/// * `result`: The result code that terminated the app (success or failure).
///
/// ## Remarks
/// These are used by `main.enterAppMainCallbacks()`.
/// This mechanism operates behind the scenes for apps using the optional main callbacks.
/// Apps that want to use this should just implement `SDL_AppEvent()` directly.
///
/// ## Version
/// This datatype is available since SDL 3.2.0.
pub const AppQuitCallback = *const fn (app_state: ?*anyopaque, result: c_uint) callconv(.C) void;

// Add all tests from subsystems.
test {
    std.testing.refAllDecls(@This());
    // std.testing.refAllDeclsRecursive(@This());
}
