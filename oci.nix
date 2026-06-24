{ lib, config, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;
  repoDir = "${homeDir}/.config/home-manager";

  installOciPublicFiles = pkgs.writeShellApplication {
    name = "install-oci-public-files";

    runtimeInputs = with pkgs; [
      coreutils
    ];

    text = ''
      set -eu

      oci_dir="$HOME/.oci"
      session_dir="$HOME/.oci/sessions/DEFAULT"

      mkdir -p "$session_dir"

      chmod 700 "$oci_dir"
      chmod 700 "$HOME/.oci/sessions"
      chmod 700 "$session_dir"

      install -m 600 "${repoDir}/files/oci/config" "$oci_dir/config"
      install -m 644 "${repoDir}/files/oci/sessions/DEFAULT/oci_api_key_public.pem" "$session_dir/oci_api_key_public.pem"
    '';
  };
in
{
  home.packages = with pkgs; [
    oci-cli
    installOciPublicFiles
  ];

  home.activation.installOciPublicFiles =
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      ${installOciPublicFiles}/bin/install-oci-public-files
    '';
}
