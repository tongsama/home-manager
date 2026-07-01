{ pkgs, lib, config, ... }:

let
  raw = config.my.modules.plenv;                             # false|true|"clone"|"nix"
  src = if builtins.isString raw then raw else "clone";      # 既定 source = clone
  plenvDir = "${config.home.homeDirectory}/.plenv";
  perlBuildDir = "${plenvDir}/plugins/perl-build";
in
lib.mkIf (raw != false) {
  assertions = [
    {
      assertion = src == "clone" || src == "nix";
      message = "modules.plenv は true/false/\"clone\"/\"nix\" のいずれかにしてください。";
    }
    {
      assertion = src != "nix" || (pkgs ? plenv);
      message = "plenv が nixpkgs に見つかりません。modules.plenv = \"clone\" を使ってください。";
    }
  ];

  # シェル統合 (clone/nix どちらでも動く)
  home.file.".config/bash/hm-extra.d/plenv.bash".source = ./files/bash/plenv.bash;

  # nix 導入 (pkgs に plenv がある場合のみ)
  home.packages = lib.optionals (src == "nix" && (pkgs ? plenv)) [ pkgs.plenv ];

  # clone 導入 (`plenv install` 用に perl-build プラグインも入れる)
  home.activation = lib.mkIf (src == "clone") {
    clonePlenv =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -d ${lib.escapeShellArg plenvDir} ]; then
          ${pkgs.git}/bin/git clone --depth 1 https://github.com/tokuhirom/plenv.git ${lib.escapeShellArg plenvDir} \
            || echo "[warning] plenv の clone に失敗 (オフライン?)。" >&2
        fi
        if [ -d ${lib.escapeShellArg plenvDir} ] && [ ! -d ${lib.escapeShellArg perlBuildDir} ]; then
          ${pkgs.git}/bin/git clone --depth 1 https://github.com/tokuhirom/Perl-Build.git ${lib.escapeShellArg perlBuildDir} \
            || echo "[warning] perl-build プラグインの clone に失敗 (オフライン?)。" >&2
        fi
      '';
  };
}
