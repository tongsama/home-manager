{ pkgs, lib, config, modules ? {}, ... }:

let
  raw = modules.pyenv or false;                              # false|true|"clone"|"nix"
  src = if builtins.isString raw then raw else "clone";      # 既定 source = clone
  pyenvDir = "${config.home.homeDirectory}/.pyenv";
in
{
  assertions = [
    {
      assertion = src == "clone" || src == "nix";
      message = "modules.pyenv は true/false/\"clone\"/\"nix\" のいずれかにしてください。";
    }
    {
      assertion = src != "nix" || (pkgs ? pyenv);
      message = "pyenv が nixpkgs に見つかりません。modules.pyenv = \"clone\" を使ってください。";
    }
  ];

  # シェル統合 (clone/nix どちらでも動く)
  home.file.".config/bash/hm-extra.d/pyenv.bash".source = ./files/bash/pyenv.bash;

  # nix 導入
  home.packages = lib.optionals (src == "nix" && (pkgs ? pyenv)) [ pkgs.pyenv ];

  # clone 導入 (python-build 同梱。git -C ~/.pyenv pull で版定義を最新化できる)
  home.activation = lib.mkIf (src == "clone") {
    clonePyenv =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -d ${lib.escapeShellArg pyenvDir} ]; then
          ${pkgs.git}/bin/git clone --depth 1 https://github.com/pyenv/pyenv.git ${lib.escapeShellArg pyenvDir} \
            || echo "[warning] pyenv の clone に失敗 (オフライン?)。" >&2
        fi
      '';
  };
}
