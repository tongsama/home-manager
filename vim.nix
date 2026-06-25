{ pkgs, ... }:

let
  vimPackage = pkgs.vim-full.override {
    guiSupport = "gtk3";
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
{
  # programs.vim は使わない
  programs.vim.enable = false;

  home.packages = with pkgs; [
    vimPackage

    python3
    universal-ctags
    w3m
    fzf
    ripgrep
  ];

  # .vimrc は secrets-vim.nix が template + SOPS secret から生成する。
  home.file.".vim/autoload/plug.vim".source = vimPlug;

  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };
}
