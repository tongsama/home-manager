{ pkgs, lib, config, ... }:

let
  nodenvDir = "${config.home.homeDirectory}/.nodenv";
  nodeBuildDir = "${nodenvDir}/plugins/node-build";
in
{
  # nodenv は nixpkgs に無いため、modules.nodenv 有効時に ~/.nodenv へ git clone する
  # (未取得のときのみ)。`nodenv install` 用に node-build プラグインも入れる。
  # バージョン更新は手動 (git -C ~/.nodenv pull)。
  home.activation.cloneNodenv =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d ${lib.escapeShellArg nodenvDir} ]; then
        ${pkgs.git}/bin/git clone --depth 1 https://github.com/nodenv/nodenv.git ${lib.escapeShellArg nodenvDir} \
          || echo "[warning] nodenv の clone に失敗 (オフライン?)。後で手動取得してください。" >&2
      fi
      if [ -d ${lib.escapeShellArg nodenvDir} ] && [ ! -d ${lib.escapeShellArg nodeBuildDir} ]; then
        ${pkgs.git}/bin/git clone --depth 1 https://github.com/nodenv/node-build.git ${lib.escapeShellArg nodeBuildDir} \
          || echo "[warning] node-build プラグインの clone に失敗 (オフライン?)。" >&2
      fi
    '';

  # シェル統合 (~/.profile / ~/.bashrc は触らず hm-extra.d 経由)
  home.file.".config/bash/hm-extra.d/nodenv.bash".source = ./files/bash/nodenv.bash;
}
