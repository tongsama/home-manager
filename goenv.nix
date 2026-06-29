{ pkgs, ... }:

{
  # goenv 本体は Nix で導入。go バージョン管理は ~/.goenv 配下。
  home.packages = with pkgs; [
    goenv
  ];

  # シェル統合 (~/.profile / ~/.bashrc は触らず hm-extra.d 経由)
  home.file.".config/bash/hm-extra.d/goenv.bash".source = ./files/bash/goenv.bash;
}
