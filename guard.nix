{ pkgs, lib, config, ... }:

let
  cfg = config.my.guard;

  localConfigLoadedFlag =
    if cfg.localConfigLoaded then "1" else "0";
in
{
  # local.nix の取り込みガード。
  # PC (flake.nix + --impure) 用の安全装置なので、nix-on-droid など
  # local.nix 機構を使わないホストでは my.guard.enable = false で無効化する。
  options.my.guard = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        local.nix の取り込みガード (guardLocalConfig) を有効にする。
        flake + --impure で運用する PC 環境向け。
      '';
    };

    localConfigLoaded = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        flake が local.nix を読み込んだかどうか。flake.nix が設定する。
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation.guardLocalConfig =
      lib.hm.dag.entryBefore [ "writeBoundary" ] ''
        set -eu

        expected_user="${config.home.username}"
        expected_home="${config.home.homeDirectory}"
        actual_user="$(${pkgs.coreutils}/bin/id -un)"
        actual_home="$HOME"

        local_config_loaded="${localConfigLoadedFlag}"
        runtime_local_config="''${HM_LOCAL_CONFIG:-$HOME/.config/home-manager/local.nix}"

        if [ -e "$runtime_local_config" ] && [ "$local_config_loaded" != "1" ]; then
          cat >&2 <<EOF
        [error] local config exists, but it was not loaded by the flake.

          detected local config:
            $runtime_local_config

        This usually means you forgot --impure.

        Run:

          home-manager switch --flake "$HOME/.config/home-manager#default" --impure -b backup

        or for first run:

          nix run github:nix-community/home-manager/release-26.05 -- \\
            switch --flake "$HOME/.config/home-manager#default" --impure -b backup

        No Home Manager files were modified.
        EOF
          exit 1
        fi

        if [ "$actual_user" != "$expected_user" ]; then
          cat >&2 <<EOF
        [error] current user does not match Home Manager config.

          actual user:
            $actual_user

          expected user:
            $expected_user

        Check local.nix or flake.nix.

        No Home Manager files were modified.
        EOF
          exit 1
        fi

        if [ "$actual_home" != "$expected_home" ]; then
          cat >&2 <<EOF
        [error] current HOME does not match Home Manager config.

          actual HOME:
            $actual_home

          expected HOME:
            $expected_home

        Check local.nix or flake.nix.

        No Home Manager files were modified.
        EOF
          exit 1
        fi
      '';
  };
}
