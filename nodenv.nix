{ pkgs, lib, config, modules ? {}, ... }:

let
  raw = modules.nodenv or false;                             # false|true|"clone"|"nix"
  src = if builtins.isString raw then raw else "clone";      # 既定 source = clone
  nodenvDir = "${config.home.homeDirectory}/.nodenv";
  nodeBuildDir = "${nodenvDir}/plugins/node-build";
in
{
  # source の妥当性 / nix在否は assertions (config層) でチェックする。
  # トップレベル assert で pkgs を参照すると module 構造評価で無限再帰になるため。
  assertions = [
    {
      assertion = src == "clone" || src == "nix";
      message = "modules.nodenv は true/false/\"clone\"/\"nix\" のいずれかにしてください。";
    }
    {
      assertion = src != "nix" || (pkgs ? nodenv);
      message = "nodenv が nixpkgs に見つかりません。modules.nodenv = \"clone\" を使ってください。";
    }
  ];

  # シェル統合 (clone/nix どちらでも動く)
  home.file.".config/bash/hm-extra.d/nodenv.bash".source = ./files/bash/nodenv.bash;

  # nix 導入 (pkgs に nodenv がある場合のみ。無ければ上の assertion がエラーを出す)
  home.packages = lib.optionals (src == "nix" && (pkgs ? nodenv)) [ pkgs.nodenv ];

  # clone 導入 (node-build プラグインも入れる)
  home.activation = lib.mkIf (src == "clone") {
    cloneNodenv =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -d ${lib.escapeShellArg nodenvDir} ]; then
          ${pkgs.git}/bin/git clone --depth 1 https://github.com/nodenv/nodenv.git ${lib.escapeShellArg nodenvDir} \
            || echo "[warning] nodenv の clone に失敗 (オフライン?)。" >&2
        fi
        if [ -d ${lib.escapeShellArg nodenvDir} ] && [ ! -d ${lib.escapeShellArg nodeBuildDir} ]; then
          ${pkgs.git}/bin/git clone --depth 1 https://github.com/nodenv/node-build.git ${lib.escapeShellArg nodeBuildDir} \
            || echo "[warning] node-build プラグインの clone に失敗 (オフライン?)。" >&2
        fi
      '';
  };
}
