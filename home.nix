{ pkgs
, lib
, config
, username
, homeDirectory
, localConfigLoaded ? false
, localConfigPathString ? ""
#, wslgEnable ? false
, guiProfile ? "none"
, fcitx5Enable ? false
, ...
}:

let
  localConfigLoadedFlag =
    if localConfigLoaded then "1" else "0";
in
{
  imports = [
    ./bash.nix
    ./ssh.nix
    ./secrets-ssh.nix
    ./oci.nix
    ./secrets-oci.nix
    ./k8s-tools.nix
    ./k8s-oci.nix
    ./starship.nix

    ./gui.nix
    ./fonts.nix
    ./vim.nix
    ./secrets-vim.nix
    ./wslg.nix
    ./fcitx5.nix
  ];

  home.username = username;
  home.homeDirectory = homeDirectory;

  home.stateVersion = "26.05";

  #my.wslg.enable = wslgEnable;
  my.gui.profile = guiProfile;
  my.fcitx5.enable = fcitx5Enable;

  home.packages = with pkgs; [
    git
    tmux
    sops
    age
  ];

  programs.home-manager.enable = true;

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
}
