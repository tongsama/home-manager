{
  # Replace this with the target login user.
  username = "new_user";

  # Usually /home on Ubuntu.
  homePrefix = "/home";

  # Target system.
  # Examples:
  #   x86_64-linux
  #   aarch64-linux
  system = "x86_64-linux";

  # Optional.
  # If set, this wins over homePrefix + username.
  # homeDirectory = "/home/new_user";

  # related fcitx5
  # Examples:
  #   none
  #   wslg-x11
  #   ubuntu-wayland
  #   ubuntu-x11
  guiProfile = "wslg-x11";

  # fcitx5
  fcitx5Enable= true;
}
