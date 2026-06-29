{ pkgs, lib, config, ... }:

let
  pyenvDir = "${config.home.homeDirectory}/.pyenv";
in
{
  # pyenv は nix にもあるが、同梱の python-build のバージョン定義を最新に保てるよう
  # clone 方式にする (git -C ~/.pyenv pull で新しい Python 定義を取り込める)。
  # pyenv リポジトリは plugins/python-build を同梱しているので本体の clone だけでよい。
  # ※ `pyenv install` での stdlib ビルドには別途 dev ライブラリが必要
  #    (libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libffi-dev liblzma-dev 等)。
  home.activation.clonePyenv =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d ${lib.escapeShellArg pyenvDir} ]; then
        ${pkgs.git}/bin/git clone --depth 1 https://github.com/pyenv/pyenv.git ${lib.escapeShellArg pyenvDir} \
          || echo "[warning] pyenv の clone に失敗 (オフライン?)。後で手動取得してください。" >&2
      fi
    '';

  # シェル統合 (~/.profile / ~/.bashrc は触らず hm-extra.d 経由)
  home.file.".config/bash/hm-extra.d/pyenv.bash".source = ./files/bash/pyenv.bash;
}
