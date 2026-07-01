{ lib, pkgs, ... }:

let
  # optional モジュールの ON/OFF (bool)。
  mkToggle = default: description:
    lib.mkOption {
      type = lib.types.bool;
      inherit default;
      inherit description;
    };

  # version manager 群の導入方法。
  #   false  : 無効
  #   true   : 既定 source で有効
  #   "clone": git clone で導入
  #   "nix"  : nixpkgs から導入
  mkVersionManager = description:
    lib.mkOption {
      type = lib.types.either lib.types.bool (lib.types.enum [ "clone" "nix" ]);
      default = false;
      inherit description;
    };
in
{
  # 全環境共通の設定トグル。
  # PC 用は flake.nix が local.nix の値を流し込む。
  # nix-on-droid など他ホストは nix-on-droid.nix / 各自の設定で上書きする。
  options.my = {
    modules = {
      vim = mkToggle true "Vim (埋め込み python3 付き) を導入する";
      nvim = mkToggle true "Neovim を導入する";
      nodejs = mkToggle true "Node.js を導入する";
      oci = mkToggle true "OCI CLI と関連 secrets を導入する";
      kubernetes = mkToggle true "Kubernetes / OKE ツールを導入する";
      fonts = mkToggle true "フォントを導入する";

      goenv = mkVersionManager "goenv (false | true | \"clone\" | \"nix\")";
      pyenv = mkVersionManager "pyenv (false | true | \"clone\" | \"nix\")";
      rustup = mkVersionManager "rustup (false | true | \"nix\")";
      nodenv = mkVersionManager "nodenv (false | true | \"clone\" | \"nix\")";
      plenv = mkVersionManager "plenv (false | true | \"clone\" | \"nix\")";
    };

    googleDrive.dir = lib.mkOption {
      type = lib.types.str;
      default = "~/Gdrive_kwatan";
      description = ''
        Google Drive のマウント先。
        空文字 "" にすると Google Drive 連携を無効化する。
      '';
    };

    vim.python = lib.mkOption {
      type = lib.types.package;
      default = pkgs.python314;
      defaultText = lib.literalExpression "pkgs.python314";
      description = ''
        vim (vim.nix) の埋め込み python3 と shell 共用 python に使う
        python インタプリタパッケージ。

        nixpkgs のバージョンにより利用可能な python が変わるため option 化。
        例: 26.05 系なら pkgs.python314、24.05 系なら pkgs.python313。
      '';
    };
  };
}
