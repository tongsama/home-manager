{ lib, pkgs, ... }:

{
  # nix-on-droid (Android / Termux) 用の Home Manager 入口。
  # nix-on-droid 側からはこれ 1 枚を import するだけでよい:
  #
  #   home-manager.config = {
  #     imports = [ (myhome + "/nix-on-droid_home.nix") ];
  #   };
  #
  # home.username / home.homeDirectory は nix-on-droid が設定するので
  # ここでは触らない。
  imports = [
    ./home.nix
  ];

  # PC 前提の重いモジュール / デスクトップ統合は既定で無効化する。
  # 必要なら nix-on-droid 側で my.modules.xxx = true 等に上書きできる。
  my.modules = {
    # vim は python313 (下記 my.vim.python) を使えば 24.05 系でも入る。
    # 埋め込み python 付きで多少重いので、不要なら nix-on-droid 側で
    # my.modules.vim = false に上書きする。
    vim = lib.mkDefault true;
    nvim = lib.mkDefault false;
    nodejs = lib.mkDefault false;
    oci = lib.mkDefault false;
    kubernetes = lib.mkDefault false;
    fonts = lib.mkDefault false;
  };

  # 24.05 系 nixpkgs は python314 が無い。python313 は greenlet 3.0.3 が
  # py3.13 C API 変更に未対応でビルドできない (requests のテスト依存で連鎖失敗)。
  # 安定してビルドできる python312 を使う。
  my.vim.python = lib.mkDefault pkgs.python312;

  # fcitx5 と GUI は Android では既定で無効。fcitx5.nix は 24.05/26.05 両対応
  # なので import 自体はしており、この 2 つの option で切り替えられる
  # (実際に有効化するには my.gui.profile を none 以外にする必要もある)。
  my.gui.profile = lib.mkDefault "none";
  my.fcitx5.enable = lib.mkDefault false;
  my.googleDrive.dir = lib.mkDefault "";

  # bash のログインシェル (ssh ログイン等) は ~/.bashrc を読まず、
  # ~/.bash_profile → ~/.bash_login → ~/.profile の順で探す。
  # home-manager の bash 設定 (bash.nix) は ~/.bashrc に注入されるため、
  # ログインシェルでも読まれるよう ~/.bash_profile から橋渡しする。
  home.file.".bash_profile".text = ''
    # Managed by Home Manager (nix-on-droid_home.nix)
    [ -r "$HOME/.profile" ] && . "$HOME/.profile"
    [ -r "$HOME/.bashrc" ]  && . "$HOME/.bashrc"
  '';

  # local.nix 機構 (flake + --impure) は使わないのでガードを無効化する。
  my.guard.enable = lib.mkDefault false;

  # home.nix は mkDefault "26.05" を持つ。nix-on-droid stable が 24.05 系の
  # home-manager なので、こちらで 24.05 に上書きする (plain 値は mkDefault に勝つ)。
  # nix-on-droid を 26.05 系で動かす場合はこの行を消す (または上書きする)。
  home.stateVersion = "24.05";
}
