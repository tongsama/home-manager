{ lib, config, pkgs, ... }:

let
  npmGlobalDir = "${config.home.homeDirectory}/.local/share/npm-global";
in
{
  home.packages = with pkgs; [
    nodejs

    # よく使うならNixで入れる方が安定
    yarn
  ];

  home.activation.ensureNpmGlobalDir =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${lib.escapeShellArg npmGlobalDir}
    '';

  home.file.".config/bash/hm-extra.d/npm-global.bash".text = ''
    # Managed by Home Manager

    export NPM_GLOBAL_DIR="$HOME/.local/share/npm-global"

    path_prepend "$NPM_GLOBAL_DIR/bin"

    # Nixで入れたnodejs/npmを使っている時だけ、npm -g のprefixをHOME配下へ逃がす。
    # nvm利用中はNVM_BINが立つので、nvm側のnpm挙動を邪魔しない。
    npm() {
      if [ -z "''${NVM_BIN:-}" ]; then
        NPM_CONFIG_PREFIX="$NPM_GLOBAL_DIR" command npm "$@"
      else
        command npm "$@"
      fi
    }
  '';
}
