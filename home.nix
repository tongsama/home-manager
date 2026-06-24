{ pkgs, ... }:

{
  imports = [
    ./bash.nix
    ./ssh.nix
  ];

  home.username = "kwatanabe-nix";
  home.homeDirectory = "/home/kwatanabe-nix"; # Macの場合は "/Users/ユーザー名"

  home.stateVersion = "26.05";

  # 導入したいパッケージ一覧
  home.packages = with pkgs; [
    git
    vim
    tmux
  ];

  # Home Manager自体（home-managerコマンド等）を管理下に置いて自動インストール
  programs.home-manager.enable = true;



}
