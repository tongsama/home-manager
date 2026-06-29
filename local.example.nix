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
  # 指定しないキーは既定 true (= 全部入る)。false にすると外せる。
  # core (bash/ssh/starship/gui/wslg/fcitx5/vim) は常時有効で切り替え対象外。
  # modules = {
  #   nvim = true;
  #   nodejs = true;
  #   oci = true;
  #   kubernetes = true;   # OKE。実行時はOCI認証が必要
  #   fonts = true;
  # };
}
