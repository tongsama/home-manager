{ pkgs, lib, config, ... }:

let
  # vim / gVim の埋め込み python3 (+python3) が使う python 環境。
  # joplin.vim 等のプラグインが import するモジュールはここに足す
  # (vim がリンクする python なので、pyenv 等の別 python では代替できない)。
  # shell 用の python/pip もこの環境を共用する。
  # python のバージョンはここで固定 (python314 = 3.14)。
  vimPython = pkgs.python314.withPackages (ps: with ps; [
    pip
    requests
  ]);

  vimPackage = pkgs.vim-full.override {
    guiSupport = "gtk3";
    # 埋め込み python3 を vimPython に差し替えてモジュールを使えるようにする
    python3 = vimPython;
  };

  vimPlug = pkgs.runCommand "plug.vim" { } ''
    plug="$(${pkgs.findutils}/bin/find ${pkgs.vimPlugins.vim-plug} -type f -name plug.vim | ${pkgs.coreutils}/bin/head -n 1)"

    if [ -z "$plug" ]; then
      echo "plug.vim not found in ${pkgs.vimPlugins.vim-plug}" >&2
      exit 1
    fi

    ${pkgs.coreutils}/bin/cp "$plug" "$out"
  '';
in
lib.mkIf config.my.modules.vim {
  # programs.vim は使わない
  programs.vim.enable = false;

  home.packages = with pkgs; [
    vimPackage

    # vim の埋め込み python3 と同じ環境を shell でも使う (python/pip/requests)。
    # グローバルな pip install は store が read-only なので不可。
    # 都度の利用は `pip install --user`、CLIアプリは pipx を使う。
    vimPython
    # nixpkgs 26.05 の pipx 1.8.0 は packaging ライブラリ差でテストが落ちるため
    # checkPhase を無効化してビルドする (機能には影響なし)。
    (pipx.overridePythonAttrs (old: { doCheck = false; }))
    universal-ctags
    w3m
    fzf
    ripgrep
  ];

  # .vimrc 本体は files/vim/dotvimrc を out-of-store symlink で配置する。
  # ~/.vimrc への編集はそのまま本リポジトリ (files/vim/dotvimrc) の変更となり、
  # git 管理に乗る。secret は secrets-vim.nix が ~/.vimrc-secrets を生成し、
  # dotvimrc 側で source する。
  home.file.".vimrc".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/home-manager/files/vim/dotvimrc";

  # coc.nvim 設定。~/.vim は vim/nvim 双方の runtimepath に入るので、
  # 1ファイルで両方に効く。~/.vimrc と同様 out-of-store symlink で編集を git 管理に乗せる。
  home.file.".vim/coc-settings.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/home-manager/files/vim/coc-settings.json";

  # vim-sonictemplate のユーザ追加テンプレート置き場 (ディレクトリごと out-of-store symlink)。
  # dotvimrc の g:sonictemplate_vim_template_dir が ~/.vim/sonic-template を参照する。
  home.file.".vim/sonic-template".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/home-manager/files/vim/sonic-template";

  home.file.".vim/autoload/plug.vim".source = vimPlug;

  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };
}
