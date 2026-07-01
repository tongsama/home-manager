{ pkgs, lib, config, ... }:

let
  # vimspector など +python3 を要求するプラグインのため、python3 provider を有効化する。
  # nvim の has('python3') は python3 host に pynvim が import できるかで判定されるので、
  # pynvim を同梱した neovim を構成する。
  # vimspector(pynvim) や joplin.vim(requests) 等が使う python3 provider のモジュール。
  # プラグインが import するものはここに足す。
  neovim = pkgs.neovim.override {
    withPython3 = true;
    extraPython3Packages = ps: with ps; [ pynvim requests ];
  };
in
lib.mkIf config.my.modules.nvim {
  home.packages = [
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
