{ pkgs, lib, config, ... }:

let
  nvmDir = "${config.home.homeDirectory}/.nvm";
in
{
  # nvm は nixpkgs に無いため、modules.nvm 有効時に ~/.nvm へ git clone する
  # (未取得のときのみ)。バージョン更新は手動 (git -C ~/.nvm pull)。
  home.activation.cloneNvm =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d ${lib.escapeShellArg nvmDir} ]; then
        ${pkgs.git}/bin/git clone --depth 1 https://github.com/nvm-sh/nvm.git ${lib.escapeShellArg nvmDir} \
          || echo "[warning] nvm の clone に失敗 (オフライン?)。後で手動取得してください。" >&2
      fi
    '';

  # シェル統合 (~/.profile / ~/.bashrc は触らず hm-extra.d 経由)
  home.file.".config/bash/hm-extra.d/nvm.bash".source = ./files/bash/nvm.bash;
}
