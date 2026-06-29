{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    neovim
  ];

  # init.vim 本体は files/nvim/init.vim を out-of-store symlink で配置する。
  # ~/.vimrc と同様、~/.config/nvim/init.vim への編集はそのまま本リポジトリ
  # (files/nvim/init.vim) の変更となり、git 管理に乗る。
  # 中身は ~/.vimrc (= files/vim/dotvimrc) を source して vim と設定を共有する。
  home.file.".config/nvim/init.vim".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/home-manager/files/nvim/init.vim";
}
