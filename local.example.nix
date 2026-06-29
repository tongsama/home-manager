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
  #   # version manager 群 (既定 false)。
  #   # 値は false=無効 / true=既定source / "clone" / "nix" で source を選べる。
  #   # 既定source: rustup=nix、他(pyenv/goenv/nodenv/plenv)=clone。
  #   # nix導入はそのツールが nixpkgs にある場合のみ (無ければ明示エラー)。
  #   # nixpkgs にあるのは pyenv/rustup/nodenv。goenv/plenv は無い。
  #   pyenv = "clone";     # or "nix"
  #   nodenv = "clone";    # or "nix"。clone は ~/.nodenv (+node-build)
  #   rustup = "nix";      # rustup は nix のみ
  #   goenv = "clone";     # goenv は nixpkgs に無いので clone のみ
  #   plenv = "clone";     # plenv は nixpkgs に無いので clone のみ (~/.plenv +perl-build)
  # };
}
