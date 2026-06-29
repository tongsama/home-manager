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
, modules ? {}
, ...
}:

let
  localConfigLoadedFlag =
    if localConfigLoaded then "1" else "0";

  # optionalモジュールの有効/無効。
  # flake.nix が local.nix の `modules` とマージして渡す。
  # 既定値はここと flake.nix の moduleConfig を一致させること。
  m =
    {
      nvim = true;
      nodejs = true;
      oci = true;
      kubernetes = true;
      fonts = true;

      # version manager 群 (既定 false)
      goenv = false;
      pyenv = false;
      rustup = false;
      nodenv = false;
      plenv = false;
    }
    // modules;
in
{
  imports =
    [
      # --- core (常時有効) ---
      ./bash.nix
      ./ssh.nix
      ./secrets-ssh.nix
      ./starship.nix

      # gui/wslg/fcitx5 は my.gui.profile 等で内部的に切り替わるので常時import
      ./gui.nix
      ./wslg.nix
      ./fcitx5.nix

      # vim は主エディタかつ nvim の依存元なので core
      ./vim.nix
      ./secrets-vim.nix
      ./skkdict.nix
    ]
    # --- optional (local.nix の modules で組み替え) ---
    ++ lib.optional m.nvim ./nvim.nix
    ++ lib.optional m.nodejs ./nodejs.nix
    ++ lib.optionals m.oci [ ./oci.nix ./secrets-oci.nix ]
    ++ lib.optionals m.kubernetes [ ./k8s-tools.nix ./k8s-oci.nix ]
    ++ lib.optional m.fonts ./fonts.nix
    # version manager 群 (既定 false)
    ++ lib.optional m.goenv ./goenv.nix
    ++ lib.optional m.pyenv ./pyenv.nix
    ++ lib.optional m.rustup ./rustup.nix
    ++ lib.optional m.nodenv ./nodenv.nix
    ++ lib.optional m.plenv ./plenv.nix;

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
