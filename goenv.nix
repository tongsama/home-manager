{ pkgs, lib, config, ... }:

let
  goenvDir = "${config.home.homeDirectory}/.goenv";
in
{
  # goenv は nixpkgs に無いため、modules.goenv 有効時に ~/.goenv へ git clone する
  # (未取得のときのみ)。バージョン更新は手動 (git -C ~/.goenv pull / goenv update)。
  home.activation.cloneGoenv =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d ${lib.escapeShellArg goenvDir} ]; then
        ${pkgs.git}/bin/git clone --depth 1 https://github.com/go-nv/goenv.git ${lib.escapeShellArg goenvDir} \
          || echo "[warning] goenv の clone に失敗 (オフライン?)。後で手動取得してください。" >&2
      fi
    '';

  # シェル統合 (~/.profile / ~/.bashrc は触らず hm-extra.d 経由)
  home.file.".config/bash/hm-extra.d/goenv.bash".source = ./files/bash/goenv.bash;
}
