{ pkgs, username, homeDirectory, ... }:

{
  imports = [
    ./bash.nix
    ./ssh.nix
    ./secrets-ssh.nix
  ];

  home.username = username;
  home.homeDirectory = homeDirectory; # Macの場合は "/Users/ユーザー名"

  home.stateVersion = "26.05";

  # 導入したいパッケージ一覧
  home.packages = with pkgs; [
    git
    vim
    tmux
    sops
    age
  ];

  # Home Manager自体（home-managerコマンド等）を管理下に置いて自動インストール
  programs.home-manager.enable = true;



}
