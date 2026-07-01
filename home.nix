{ pkgs, lib, ... }:

{
  # 全環境共通の Home Manager 設定。
  #
  # ここは特定ホストに依存しない共通部分だけを持つ。
  #   - PC 用の値 (username / homeDirectory / modules 等) は flake.nix が
  #     local.nix を読んで option として流し込む。
  #   - nix-on-droid など他ホストは nix-on-droid.nix 経由で import し、
  #     各自で option を上書きする。
  #
  # import は無条件。各モジュールの有効/無効は my.modules.* (options.nix) と
  # 各モジュール内の lib.mkIf で切り替える。
  # (imports を config に依存させると infinite recursion になるため)
  imports =
    [
      ./options.nix
      ./guard.nix

      # --- core (常時有効) ---
      ./bash.nix
      ./ssh.nix
      ./secrets-ssh.nix
      ./starship.nix

      # gui/wslg/fcitx5 は my.gui.profile 等で内部的に切り替わる
      ./gui.nix
      ./wslg.nix
      ./fcitx5.nix

      # vim は主エディタかつ nvim の依存元なので core
      ./vim.nix
      ./secrets-vim.nix
      ./skkdict.nix

      # --- toggleable (my.modules.* で制御) ---
      ./nvim.nix
      ./nodejs.nix
      ./oci.nix
      ./secrets-oci.nix
      ./k8s-tools.nix
      ./k8s-oci.nix
      ./fonts.nix
      ./goenv.nix
      ./pyenv.nix
      ./rustup.nix
      ./nodenv.nix
      ./plenv.nix
    ];

  home.stateVersion = lib.mkDefault "26.05";

  home.packages = with pkgs; [
    git
    tmux
    sops
    age
  ];

  programs.home-manager.enable = true;
}
