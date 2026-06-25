{ lib, ... }:

{
  options.my.gui.profile = lib.mkOption {
    type = lib.types.enum [
      "none"
      "wslg-x11"
      "ubuntu-wayland"
      "ubuntu-x11"
    ];

    default = "none";

    description = ''
      GUI environment profile.

      none:
        No GUI integration.

      wslg-x11:
        WSL2 + WSLg. Prefer XWayland for fcitx5.

      ubuntu-wayland:
        Native Ubuntu desktop with Wayland session.

      ubuntu-x11:
        Native Ubuntu desktop with X11 session.
    '';
  };
}
