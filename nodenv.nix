{ pkgs, lib, config, modules ? {}, ... }:

let
  raw = modules.nodenv or false;                             # false|true|"clone"|"nix"
  src = if builtins.isString raw then raw else "clone";      # 既定 source = clone
  nodenvDir = "${config.home.homeDirectory}/.nodenv";
  nodeBuildDir = "${nodenvDir}/plugins/node-build";
in
assert lib.assertMsg (src == "clone" || src == "nix")
  "modules.nodenv は true/false/\"clone\"/\"nix\" のいずれかにしてください (指定: ${toString raw})。";
assert lib.assertMsg (src != "nix" || (pkgs ? nodenv))
  "nodenv が nixpkgs に見つかりません。modules.nodenv = \"clone\" を使ってください。";
{
  # シェル統合 (clone/nix どちらでも動く)
  home.file.".config/bash/hm-extra.d/nodenv.bash".source = ./files/bash/nodenv.bash;

  # nix 導入 (nixpkgs に nodenv があれば)
  home.packages = lib.optionals (src == "nix") [ pkgs.nodenv ];

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
