{ pkgs, lib, config, modules ? {}, ... }:

let
  raw = modules.goenv or false;                              # false|true|"clone"|"nix"
  src = if builtins.isString raw then raw else "clone";      # 既定 source = clone
  goenvDir = "${config.home.homeDirectory}/.goenv";
in
assert lib.assertMsg (src == "clone" || src == "nix")
  "modules.goenv は true/false/\"clone\"/\"nix\" のいずれかにしてください (指定: ${toString raw})。";
assert lib.assertMsg (src != "nix" || (pkgs ? goenv))
  "goenv が nixpkgs に見つかりません。modules.goenv = \"clone\" を使ってください。";
{
  # シェル統合 (clone/nix どちらでも動く)
  home.file.".config/bash/hm-extra.d/goenv.bash".source = ./files/bash/goenv.bash;

  # nix 導入 (nixpkgs に goenv があれば)
  home.packages = lib.optionals (src == "nix") [ pkgs.goenv ];

  # clone 導入
  home.activation = lib.mkIf (src == "clone") {
    cloneGoenv =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -d ${lib.escapeShellArg goenvDir} ]; then
          ${pkgs.git}/bin/git clone --depth 1 https://github.com/go-nv/goenv.git ${lib.escapeShellArg goenvDir} \
            || echo "[warning] goenv の clone に失敗 (オフライン?)。" >&2
        fi
      '';
  };
}
