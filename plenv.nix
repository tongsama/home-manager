{ pkgs, lib, config, ... }:

let
  plenvDir = "${config.home.homeDirectory}/.plenv";
  perlBuildDir = "${plenvDir}/plugins/perl-build";
in
{
  # plenv は nixpkgs に無いため、modules.plenv 有効時に ~/.plenv へ git clone する
  # (未取得のときのみ)。`plenv install` 用に perl-build プラグインも入れる。
  # バージョン更新は手動 (git -C ~/.plenv pull)。
  home.activation.clonePlenv =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d ${lib.escapeShellArg plenvDir} ]; then
        ${pkgs.git}/bin/git clone --depth 1 https://github.com/tokuhirom/plenv.git ${lib.escapeShellArg plenvDir} \
          || echo "[warning] plenv の clone に失敗 (オフライン?)。後で手動取得してください。" >&2
      fi
      if [ -d ${lib.escapeShellArg plenvDir} ] && [ ! -d ${lib.escapeShellArg perlBuildDir} ]; then
        ${pkgs.git}/bin/git clone --depth 1 https://github.com/tokuhirom/Perl-Build.git ${lib.escapeShellArg perlBuildDir} \
          || echo "[warning] perl-build プラグインの clone に失敗 (オフライン?)。" >&2
      fi
    '';

  # シェル統合 (~/.profile / ~/.bashrc は触らず hm-extra.d 経由)
  home.file.".config/bash/hm-extra.d/plenv.bash".source = ./files/bash/plenv.bash;
}
