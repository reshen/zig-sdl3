{
  pkgs,
  lib,
  inputs,
  # config,
  ...
}:
let
in
{
  # languages.zig.enable = true;

  # https://devenv.sh/languages/
  languages.zig = {
    enable = true;

    # uncomment these to use zig master
    package = inputs.zig-overlay.packages.${pkgs.system}."0.15.1";
    zls.package = inputs.zls-overlay.packages.${pkgs.system}.default;
  };

  # This is needed for libc headers
  # languages.c.enable = true;

  packages =
    with pkgs;
    [ ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      vulkan-validation-layers
    ];

  # https://github.com/allyourcodebase/SDL3
  # Not all of these dependencies in this example are required. Since both X11
  # and Wayland dependencies are listed, SDL will use its judgement to decide
  # which to prefer unless SDL_VIDEODRIVER is set.
  env.LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (
    with pkgs;
    [
      alsa-lib
      libdecor
      libusb1
      libxkbcommon
      vulkan-loader
      wayland
      xorg.libX11
      xorg.libXext
      xorg.libXi
      udev

      # alsa-lib
      # cmake
      # egl-wayland
      # jack2
      # libGL
      # libpulseaudio
      # libxkbcommon
      # pkg-config
      # sdl3
      # vulkan-headers
      # vulkan-loader
      # wayland
      # wayland-scanner
      # xorg.libX11
      # xorg.libXcursor
      # xorg.libXinerama
      # xorg.libXext
      # xorg.libXfixes
      # xorg.libXi
      # xorg.libXrandr
    ]
  );

  env.SDL_VIDEODRIVER = "wayland";

  enterShell = ''
    zig version
    zls version
  '';

  # See full reference at https://devenv.sh/reference/options/
}
