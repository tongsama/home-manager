{ pkgs, ... }:

{
  # rustup 本体は Nix で導入。toolchain は ~/.rustup、proxy は ~/.cargo/bin。
  home.packages = with pkgs; [
    rustup
  ];

  # シェル統合 (~/.profile / ~/.bashrc は触らず hm-extra.d 経由)
  home.file.".config/bash/hm-extra.d/rustup.bash".source = ./files/bash/rustup.bash;
}
