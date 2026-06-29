{ pkgs, ... }:

{
  # pyenv 本体は Nix で導入。python バージョン管理は ~/.pyenv 配下。
  home.packages = with pkgs; [
    pyenv
  ];

  # シェル統合 (~/.profile / ~/.bashrc は触らず hm-extra.d 経由)
  home.file.".config/bash/hm-extra.d/pyenv.bash".source = ./files/bash/pyenv.bash;
}
