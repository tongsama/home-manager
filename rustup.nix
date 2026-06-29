{ pkgs, lib, modules ? {}, ... }:

let
  raw = modules.rustup or false;                             # false|true|"nix"
  src = if builtins.isString raw then raw else "nix";        # 既定 source = nix
in
{
  # rustup は git clone 方式が無い (公式は curl インストーラ) ため nix のみ対応。
  assertions = [
    {
      assertion = src == "nix";
      message = "rustup は nix 導入のみ対応です (clone 非対応)。modules.rustup = true または \"nix\" を使ってください。";
    }
  ];

  # rustup 本体は Nix で導入。toolchain は ~/.rustup、proxy は ~/.cargo/bin。
  home.packages = lib.optionals (src == "nix") [ pkgs.rustup ];

  # シェル統合 (~/.profile / ~/.bashrc は触らず hm-extra.d 経由)
  home.file.".config/bash/hm-extra.d/rustup.bash".source = ./files/bash/rustup.bash;
}
