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

  # Google Drive のマウント先 (省略時は "~/Gdrive_kwatan")。
  # 空文字 "" にすると Google Drive 連携を無効化する。
  googleDriveDir = "~/Gdrive_kwatan";

  # 追加パッケージ群(optionalモジュール)の構成。
  # core (bash/ssh/starship/gui/wslg/fcitx5/vim) は常時有効で切り替え対象外。
  # 既定値は flake.nix の moduleConfig 参照 (下記コメントの値が既定)。
  # modules = {
  #   # 既定 true (指定しなければ入る)
  #   nvim = true;
  #   nodejs = true;
  #   oci = true;
  #   kubernetes = true;   # OKE。実行時はOCI認証が必要
  #   fonts = true;
  #
  #   # version manager 群 (既定 false。使うものだけ true にする)
  #   goenv = false;       # 本体は Nix で導入
  #   pyenv = false;       # 本体は Nix で導入
  #   rustup = false;      # 本体は Nix で導入
  #   nvm = false;         # 本体は手動導入前提 (~/.nvm があれば有効)
  #   plenv = false;       # 本体は手動導入前提 (~/.plenv があれば有効)
  # };
}
