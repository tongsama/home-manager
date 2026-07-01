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

  # fcitx5.nix は home-manager 24.05 系と i18n.inputMethod API が非互換
  # (24.05: i18n.inputMethod.enabled / 25.05+: .enable + .type)。
  # mkIf false でもオプションパスの存在検証で落ちるため、そもそも読み込まない。
  # Android にデスクトップ入力メソッドは不要なので実害なし。
  disabledModules = [
    ./fcitx5.nix
  ];

  # PC 前提の重いモジュール / デスクトップ統合は既定で無効化する。
  # 必要なら nix-on-droid 側で my.modules.xxx = true 等に上書きできる。
  my.modules = {
    # vim は埋め込み python3 付きで重く、nixpkgs のバージョンにも敏感なので
    # 既定で無効。使うなら nix-on-droid 側で my.modules.vim = true に。
    vim = lib.mkDefault false;
    nvim = lib.mkDefault false;
    nodejs = lib.mkDefault false;
    oci = lib.mkDefault false;
    kubernetes = lib.mkDefault false;
    fonts = lib.mkDefault false;
  };

  # my.fcitx5.enable は fcitx5.nix が定義する option。上で disabledModules に
  # 入れたのでここでは設定しない (設定すると存在しない option でエラーになる)。
  my.gui.profile = lib.mkDefault "none";
  my.googleDrive.dir = lib.mkDefault "";

  # local.nix 機構 (flake + --impure) は使わないのでガードを無効化する。
  my.guard.enable = lib.mkDefault false;

  # home.nix は mkDefault "26.05" を持つ。nix-on-droid stable が 24.05 系の
  # home-manager なので、こちらで 24.05 に上書きする (plain 値は mkDefault に勝つ)。
  # nix-on-droid を 26.05 系で動かす場合はこの行を消す (または上書きする)。
  home.stateVersion = "24.05";
}
