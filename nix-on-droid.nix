{ lib, ... }:

{
  # nix-on-droid (Android / Termux) 用の Home Manager 入口。
  # nix-on-droid 側からはこれ 1 枚を import するだけでよい:
  #
  #   home-manager.config = {
  #     imports = [ ../home-manager/nix-on-droid.nix ];
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
    nvim = lib.mkDefault false;
    nodejs = lib.mkDefault false;
    oci = lib.mkDefault false;
    kubernetes = lib.mkDefault false;
    fonts = lib.mkDefault false;
  };

  my.gui.profile = lib.mkDefault "none";
  my.fcitx5.enable = lib.mkDefault false;
  my.googleDrive.dir = lib.mkDefault "";

  # local.nix 機構 (flake + --impure) は使わないのでガードを無効化する。
  my.guard.enable = lib.mkDefault false;

  # home.stateVersion は home.nix が mkDefault "26.05" を持つ。
  # nix-on-droid 側で別の値にしたい場合は、そのホストの設定で
  #   home.stateVersion = lib.mkForce "24.05";
  # のように上書きする。
}
